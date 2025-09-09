Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,System.Drawing

# ------------------------------
# App settings and helpers
# ------------------------------

$global:AppState = [ordered]@{
    EndpointUrl = "http://localhost:11434/api/chat"   # Example: local LLM server URL
    Model       = "llama3.1"                           # Example model name
    SystemPrompt= "You are an assistant specialized in Byzantine chant. Be precise with modal theory (echoi), intervals, and ison practice."
    DronePlayer = $null
    DroneStream = $null
    IsDroneOn   = $false
}

function New-DroneWave {
    param(
        [int]$SampleRate = 44100,
        [int]$BitsPerSample = 16,
        [int]$Channels = 1,
        [double]$Frequency = 130.81,  # Default around C3
        [double]$Seconds = 5
    )
    # Create a 16-bit PCM mono WAV of a sine tone
    $samples = [int]($SampleRate * $Seconds)
    $blockAlign = [int](($BitsPerSample / 8) * $Channels)
    $byteRate = $SampleRate * $blockAlign
    $dataSize = $samples * $blockAlign
    $riffSize = 36 + $dataSize

    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)

    # RIFF header
    $bw.Write([Text.Encoding]::ASCII.GetBytes("RIFF"))
    $bw.Write([int]$riffSize)
    $bw.Write([Text.Encoding]::ASCII.GetBytes("WAVE"))

    # fmt chunk
    $bw.Write([Text.Encoding]::ASCII.GetBytes("fmt "))
    $bw.Write([int]16)                    # PCM chunk size
    $bw.Write([short]1)                   # Audio format PCM
    $bw.Write([short]$Channels)
    $bw.Write([int]$SampleRate)
    $bw.Write([int]$byteRate)
    $bw.Write([short]$blockAlign)
    $bw.Write([short]$BitsPerSample)

    # data chunk
    $bw.Write([Text.Encoding]::ASCII.GetBytes("data"))
    $bw.Write([int]$dataSize)

    # Generate samples with gentle roll-on/roll-off envelope to reduce clicks
    $amplitude = 0.25                      # Keep modest to avoid clipping
    $attackSamples = [int]($SampleRate * 0.05)
    $releaseSamples = [int]($SampleRate * 0.1)

    for ($n = 0; $n -lt $samples; $n++) {
        $t = $n / $SampleRate
        $envelope = 1.0
        if ($n -lt $attackSamples) {
            $envelope = $n / [double]$attackSamples
        } elseif ($n -gt ($samples - $releaseSamples)) {
            $envelope = [math]::Max(0.0, ($samples - $n) / [double]$releaseSamples)
        }
        $value = [math]::Sin(2 * [math]::PI * $Frequency * $t) * $amplitude * $envelope
        $sampleInt16 = [int]([math]::Round($value * [int16]::MaxValue))
        $bw.Write([int16]$sampleInt16)
    }

    $bw.Flush()
    $ms.Position = 0
    return $ms
}

function Start-Drone {
    param(
        [double]$Frequency
    )
    Stop-Drone
    # Build a short wav and loop it
    $global:AppState.DroneStream = New-DroneWave -Frequency $Frequency -Seconds 3
    $global:AppState.DronePlayer = New-Object System.Media.SoundPlayer($global:AppState.DroneStream)
    $global:AppState.DronePlayer.PlayLooping()
    $global:AppState.IsDroneOn = $true
}

function Stop-Drone {
    if ($global:AppState.DronePlayer) {
        $global:AppState.DronePlayer.Stop()
        $global:AppState.DronePlayer.Dispose()
        $global:AppState.DronePlayer = $null
    }
    if ($global:AppState.DroneStream) {
        $global:AppState.DroneStream.Dispose()
        $global:AppState.DroneStream = $null
    }
    $global:AppState.IsDroneOn = $false
}

function Get-EchosTemplate {
    param(
        [string]$Echos,
        [double]$TonicHz
    )
    $map = @{
        "Protos"     = "Mode: Πρώτος (Protus). Characteristic interval patterns and cadences on base."
        "Devteros"   = "Mode: Δεύτερος (Devterus). Soft chromatic tendencies, focus on the base and phthora when relevant."
        "Tritos"     = "Mode: Τρίτος (Tritus). Diatonic with characteristic thirds and finales."
        "Tetartos"   = "Mode: Τέταρτος (Tetartus). Bright diatonic, emphasizes the base and fifth."
        "Plagal A"   = "Mode: Πλάγιος του Πρώτου (Plagal of First). Drone anchored on base; gentle motion."
        "Plagal B"   = "Mode: Πλάγιος του Δευτέρου (Plagal of Second). Chromatic color; careful intonation."
        "Varys"      = "Mode: Βαρύς (Varys). Lower register focus; drone stability is key."
        "Plagal 4"   = "Mode: Πλάγιος του Τετάρτου (Plagal of Fourth). Diatonic with solemn character."
    }
    $line = if ($map.ContainsKey($Echos)) { $map[$Echos] } else { "Mode: $Echos" }
    return "$line Tonic (ison) ≈ $([math]::Round($TonicHz,2)) Hz."
}

function Invoke-LLMChat {
    param(
        [string]$EndpointUrl,
        [string]$Model,
        [string]$SystemPrompt,
        [string]$UserPrompt
    )

    # Two common payload formats are supported below. The app tries one, then the other.
    $payload1 = @{
        model = $Model
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user";   content = $UserPrompt }
        )
        stream = $false
    }

    $payload2 = @{
        model = $Model
        input = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user";   content = $UserPrompt }
        )
    }

    try {
        $resp = Invoke-RestMethod -Uri $EndpointUrl -Method Post -Body ($payload1 | ConvertTo-Json -Depth 8) -ContentType "application/json"
        if ($resp) { return $resp }
    } catch {}

    try {
        $resp = Invoke-RestMethod -Uri $EndpointUrl -Method Post -Body ($payload2 | ConvertTo-Json -Depth 8) -ContentType "application/json"
        if ($resp) { return $resp }
    } catch {
        throw "LLM call failed. Check Endpoint URL and payload format."
    }
}

function Extract-LLMText {
    param($Response)
    # Try to handle common response shapes
    if ($Response -and $Response.choices) {
        foreach ($c in $Response.choices) {
            if ($c.message.content) { return $c.message.content }
            if ($c.text) { return $c.text }
        }
    }
    if ($Response -and $Response.message -and $Response.message.content) {
        return $Response.message.content
    }
    if ($Response -and $Response.output -and $Response.output.message -and $Response.output.message.content) {
        return $Response.output.message.content
    }
    if ($Response -and $Response.response) {
        return $Response.response
    }
    return ($Response | ConvertTo-Json -Depth 8)
}

# ------------------------------
# XAML UI
# ------------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Isokates - Byzantine Ison + LLM" Height="680" Width="980" WindowStartupLocation="CenterScreen"
        Background="#111318" Foreground="#EDEDED">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Connection row -->
    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
      <TextBlock Text="Endpoint:" VerticalAlignment="Center" Margin="0,0,6,0"/>
      <TextBox x:Name="EndpointBox" Width="420" Margin="0,0,12,0"/>
      <TextBlock Text="Model:" VerticalAlignment="Center" Margin="0,0,6,0"/>
      <TextBox x:Name="ModelBox" Width="160" Margin="0,0,12,0"/>
      <Button x:Name="TestConnBtn" Content="Test endpoint" Width="130" />
    </StackPanel>

    <!-- Ison controls -->
    <Border Grid.Row="1" Padding="10" CornerRadius="6" Background="#1A1D24" Margin="0,0,0,8">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="2*"/>
          <ColumnDefinition Width="2*"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <StackPanel>
          <TextBlock Text="Echos (Mode)" FontWeight="Bold" Margin="0,0,0,4"/>
          <ComboBox x:Name="EchosBox" SelectedIndex="0">
            <ComboBoxItem Content="Protos"/>
            <ComboBoxItem Content="Devteros"/>
            <ComboBoxItem Content="Tritos"/>
            <ComboBoxItem Content="Tetartos"/>
            <ComboBoxItem Content="Plagal A"/>
            <ComboBoxItem Content="Plagal B"/>
            <ComboBoxItem Content="Varys"/>
            <ComboBoxItem Content="Plagal 4"/>
          </ComboBox>
        </StackPanel>

        <StackPanel Grid.Column="1" Margin="12,0,0,0">
          <TextBlock Text="Tonic (ison) frequency [Hz]" FontWeight="Bold" Margin="0,0,0,4"/>
          <StackPanel Orientation="Horizontal">
            <Slider x:Name="FreqSlider" Minimum="70" Maximum="330" Value="130.81" Width="220" TickPlacement="BottomRight" IsSnapToTickEnabled="False"/>
            <TextBox x:Name="FreqBox" Width="70" Margin="8,0,0,0" TextAlignment="Right"/>
          </StackPanel>
          <TextBlock x:Name="FreqNote" FontStyle="Italic" Opacity="0.75" Margin="0,4,0,0"/>
        </StackPanel>

        <StackPanel Grid.Column="2" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Bottom">
          <Button x:Name="StartDroneBtn" Content="Start ison" Width="110" Margin="0,0,8,0"/>
          <Button x:Name="StopDroneBtn" Content="Stop" Width="80"/>
        </StackPanel>
      </Grid>
    </Border>

    <!-- Chat area -->
    <Grid Grid.Row="2">
      <Grid.RowDefinitions>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>

      <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto" Background="#0F1116" Margin="0,0,0,8">
        <TextBox x:Name="ChatBox" TextWrapping="Wrap" AcceptsReturn="True" IsReadOnly="True" Background="#0F1116" BorderThickness="0" FontFamily="Consolas" FontSize="13" />
      </ScrollViewer>

      <StackPanel Grid.Row="1">
        <TextBox x:Name="PromptBox" Height="72" TextWrapping="Wrap" AcceptsReturn="True" Background="#151822" BorderBrush="#2B2E3A" />
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,8,0,0">
          <Button x:Name="ExplainBtn" Content="Ask about mode" Width="140" Margin="0,0,8,0"/>
          <Button x:Name="SendBtn" Content="Send prompt" Width="120"/>
        </StackPanel>
      </StackPanel>
    </Grid>

    <!-- Status bar -->
    <StatusBar Grid.Row="3" Background="#1A1D24">
      <StatusBarItem>
        <TextBlock x:Name="StatusText" Text="Ready."/>
      </StatusBarItem>
    </StatusBar>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Grab controls
$EndpointBox   = $window.FindName("EndpointBox")
$ModelBox      = $window.FindName("ModelBox")
$TestConnBtn   = $window.FindName("TestConnBtn")
$EchosBox      = $window.FindName("EchosBox")
$FreqSlider    = $window.FindName("FreqSlider")
$FreqBox       = $window.FindName("FreqBox")
$FreqNote      = $window.FindName("FreqNote")
$StartDroneBtn = $window.FindName("StartDroneBtn")
$StopDroneBtn  = $window.FindName("StopDroneBtn")
$ChatBox       = $window.FindName("ChatBox")
$PromptBox     = $window.FindName("PromptBox")
$ExplainBtn    = $window.FindName("ExplainBtn")
$SendBtn       = $window.FindName("SendBtn")
$StatusText    = $window.FindName("StatusText")

# Initialize fields
$EndpointBox.Text = $global:AppState.EndpointUrl
$ModelBox.Text    = $global:AppState.Model
$FreqBox.Text     = "{0:N2}" -f $FreqSlider.Value
$FreqNote.Text    = "Guidance: Common base range ~ 110–180 Hz; adjust to your choir's reference."

# Utilities
function Append-Chat {
    param([string]$who, [string]$text)
    $stamp = (Get-Date).ToString("HH:mm")
    $prefix = if ($who -eq "You") { "You" } else { "LLM" }
    $ChatBox.AppendText("[$stamp] $prefix:`r`n$text`r`n`r`n")
    $ChatBox.ScrollToEnd()
}

function Set-Status { param([string]$msg) $StatusText.Text = $msg }

# Event wiring
$FreqSlider.Add_ValueChanged({
    $FreqBox.Text = "{0:N2}" -f $FreqSlider.Value
} )

$FreqBox.Add_TextChanged({
    if ([double]::TryParse($FreqBox.Text, [ref]([double]$null))) {
        $v = [double]$FreqBox.Text
        if ($v -ge $FreqSlider.Minimum -and $v -le $FreqSlider.Maximum) {
            $FreqSlider.Value = $v
        }
    }
})

$StartDroneBtn.Add_Click({
    try {
        $freq = [double]$FreqSlider.Value
        Start-Drone -Frequency $freq
        Set-Status "Ison ON at $([math]::Round($freq,2)) Hz."
    } catch {
        Set-Status "Failed to start ison: $($_.Exception.Message)"
    }
})

$StopDroneBtn.Add_Click({
    Stop-Drone
    Set-Status "Ison OFF."
})

$TestConnBtn.Add_Click({
    try {
        $global:AppState.EndpointUrl = $EndpointBox.Text.Trim()
        $global:AppState.Model       = $ModelBox.Text.Trim()
        $pingPrompt = "Respond with the single word: PONG."
        $resp = Invoke-LLMChat -EndpointUrl $global:AppState.EndpointUrl -Model $global:AppState.Model -SystemPrompt $global:AppState.SystemPrompt -UserPrompt $pingPrompt
        $text = Extract-LLMText $resp
        if ($text -match "PONG") {
            Set-Status "Endpoint OK."
        } else {
            Set-Status "Connected, but unexpected response."
        }
    } catch {
        Set-Status "Connection failed: $($_.Exception.Message)"
    }
})

$SendBtn.Add_Click({
    $userText = $PromptBox.Text.Trim()
    if (-not $userText) { return }
    $echosItem = ($EchosBox.SelectedItem).Content
    $tonicHz = [double]$FreqSlider.Value
    $context = Get-EchosTemplate -Echos $echosItem -TonicHz $tonicHz
    $finalPrompt = "$context`nUser question:`n$userText"
    Append-Chat "You" $userText
    Set-Status "Thinking..."
    try {
        $global:AppState.EndpointUrl = $EndpointBox.Text.Trim()
        $global:AppState.Model       = $ModelBox.Text.Trim()
        $resp = Invoke-LLMChat -EndpointUrl $global:AppState.EndpointUrl -Model $global:AppState.Model -SystemPrompt $global:AppState.SystemPrompt -UserPrompt $finalPrompt
        $text = Extract-LLMText $resp
        Append-Chat "LLM" $text
        Set-Status "Ready."
    } catch {
        Append-Chat "LLM" "Error: $($_.Exception.Message)"
        Set-Status "Error."
    }
})

$ExplainBtn.Add_Click({
    $echosItem = ($EchosBox.SelectedItem).Content
    $tonicHz = [double]$FreqSlider.Value
    $userText = "Explain the role of the ison and cadences for $echosItem in a short, practical way for rehearsal, tonic ≈ $([math]::Round($tonicHz,2)) Hz."
    $PromptBox.Text = $userText
})

# Clean-up on close
$window.Add_Closed({
    Stop-Drone
})

# Show
$window.Topmost = $false
$window.ShowDialog() | Out-Null
