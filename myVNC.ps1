<# 
    File: VncAiPanel.ps1
    Single-file PowerShell GUI:
      - VNC connection controls (host/port/password + "Connect" button stub)
      - AI LLM panel (prompt + response + "Ask AI" button)
    No telemetry, no external deps. 
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

#---------------- GUI XAML ----------------#
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VNC + AI LLM Panel" Height="520" Width="900"
        WindowStartupLocation="CenterScreen"
        Background="#1E1E1E" Foreground="White">
    <Grid Margin="10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="2*"/>
            <ColumnDefinition Width="3*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <DockPanel Grid.ColumnSpan="2" Grid.Row="0" Margin="0,0,0,10">
            <TextBlock Text="VNC Control + AI LLM Assistant"
                       FontSize="18" FontWeight="Bold"
                       VerticalAlignment="Center"/>
        </DockPanel>

        <!-- Left: VNC Controls -->
        <Border Grid.Column="0" Grid.Row="1" Margin="0,0,10,0"
                BorderBrush="#444" BorderThickness="1" CornerRadius="4" Padding="10">
            <StackPanel>
                <TextBlock Text="VNC Connection" FontSize="14" FontWeight="Bold" Margin="0,0,0,8"/>

                <TextBlock Text="Host:" Margin="0,0,0,2"/>
                <TextBox x:Name="txtVncHost" Text="127.0.0.1" Margin="0,0,0,6" Background="#2D2D30"/>

                <TextBlock Text="Port:" Margin="0,0,0,2"/>
                <TextBox x:Name="txtVncPort" Text="5900" Margin="0,0,0,6" Background="#2D2D30"/>

                <TextBlock Text="Password:" Margin="0,0,0,2"/>
                <PasswordBox x:Name="txtVncPassword" Margin="0,0,0,10" Background="#2D2D30"/>

                <Button x:Name="btnConnectVnc" Content="Connect (stub)"
                        Height="30" Margin="0,0,0,10" Background="#007ACC"/>

                <TextBlock Text="Notes:" Margin="0,0,0,2"/>
                <TextBox x:Name="txtVncNotes" AcceptsReturn="True" Height="200"
                         TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"
                         Background="#2D2D30"/>
            </StackPanel>
        </Border>

        <!-- Right: AI LLM Panel -->
        <Border Grid.Column="1" Grid.Row="1"
                BorderBrush="#444" BorderThickness="1" CornerRadius="4" Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="2*"/>
                </Grid.RowDefinitions>

                <!-- Conversation / Response -->
                <StackPanel Grid.Row="0" Margin="0,0,0,8">
                    <TextBlock Text="AI LLM Assistant" FontSize="14" FontWeight="Bold" Margin="0,0,0,6"/>
                    <TextBlock Text="Response:" Margin="0,0,0,2"/>
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Height="180">
                        <TextBox x:Name="txtAiResponse" IsReadOnly="True"
                                 TextWrapping="Wrap" AcceptsReturn="True"
                                 Background="#2D2D30" BorderThickness="0"/>
                    </ScrollViewer>
                </StackPanel>

                <!-- Prompt -->
                <StackPanel Grid.Row="1" Margin="0,0,0,8">
                    <TextBlock Text="Prompt to AI:" Margin="0,0,0,2"/>
                    <TextBox x:Name="txtAiPrompt" Height="60"
                             TextWrapping="Wrap" AcceptsReturn="True"
                             Background="#2D2D30"/>
                </StackPanel>

                <!-- Buttons / Status -->
                <DockPanel Grid.Row="2">
                    <StackPanel Orientation="Horizontal" DockPanel.Dock="Left">
                        <Button x:Name="btnAskAi" Content="Ask AI"
                                Width="100" Height="30" Margin="0,0,8,0"
                                Background="#007ACC"/>
                        <Button x:Name="btnClearAi" Content="Clear"
                                Width="80" Height="30"
                                Background="#444"/>
                    </StackPanel>
                    <TextBlock x:Name="lblStatus"
                               DockPanel.Dock="Right"
                               HorizontalAlignment="Right"
                               VerticalAlignment="Center"
                               Foreground="#CCCCCC"
                               Text="Idle"/>
                </DockPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

#---------------- Parse XAML ----------------#
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

#---------------- Find Controls ----------------#
$txtVncHost     = $window.FindName("txtVncHost")
$txtVncPort     = $window.FindName("txtVncPort")
$txtVncPassword = $window.FindName("txtVncPassword")
$txtVncNotes    = $window.FindName("txtVncNotes")
$btnConnectVnc  = $window.FindName("btnConnectVnc")

$txtAiPrompt   = $window.FindName("txtAiPrompt")
$txtAiResponse = $window.FindName("txtAiResponse")
$btnAskAi      = $window.FindName("btnAskAi")
$btnClearAi    = $window.FindName("btnClearAi")
$lblStatus     = $window.FindName("lblStatus")

#---------------- LLM Call (stub) ----------------#
function Invoke-LocalLLM {
    param(
        [string]$Prompt,
        [string]$VncHost,
        [int]$VncPort,
        [string]$Notes
    )

    # TODO: Replace this stub with your real LLM backend call.
    # Example for a local HTTP endpoint (commented out):
    <#
    $body = @{
        prompt  = $Prompt
        context = @{
            vnc_host = $VncHost
            vnc_port = $VncPort
            notes    = $Notes
        }
    } | ConvertTo-Json -Depth 5

    $response = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/generate" `
                                  -Method POST `
                                  -Body $body `
                                  -ContentType "application/json"
    return $response.text
    #>

    # Offline demo response:
    $summary = @"
[DEMO LLM OUTPUT]

Prompt:
$Prompt

Context:
- VNC Host: $VncHost
- VNC Port: $VncPort
- Notes length: $($Notes.Length)

Wire this function to your local LLM endpoint.
"@
    return $summary
}

#---------------- Event Handlers ----------------#

# VNC Connect (stub)
$btnConnectVnc.Add_Click({
    $host = $txtVncHost.Text
    $port = $txtVncPort.Text
    $lblStatus.Text = "VNC connect stub: $host:$port"

    # Here you can launch your VNC client, e.g.:
    # & "C:\Path\To\vncviewer.exe" "$host::$port"
})

# Ask AI
$btnAskAi.Add_Click({
    $prompt = $txtAiPrompt.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($prompt)) {
        [System.Windows.MessageBox]::Show("Prompt is empty.","AI LLM", 'OK','Information') | Out-Null
        return
    }

    $lblStatus.Text = "Querying AI..."
    $window.Cursor = [System.Windows.Input.Cursors]::Wait

    try {
        $vncHost = $txtVncHost.Text
        $vncPort = [int]($txtVncPort.Text)
        $notes   = $txtVncNotes.Text

        $result = Invoke-LocalLLM -Prompt $prompt -VncHost $vncHost -VncPort $vncPort -Notes $notes

        if (-not [string]::IsNullOrWhiteSpace($txtAiResponse.Text)) {
            $txtAiResponse.AppendText("`r`n`r`n")
        }
        $txtAiResponse.AppendText(">>> Prompt:`r`n$prompt`r`n`r`n<<< Response:`r`n$result")
        $txtAiResponse.ScrollToEnd()
        $lblStatus.Text = "AI response received"
    }
    catch {
        $lblStatus.Text = "Error"
        [System.Windows.MessageBox]::Show("Error calling LLM: $($_.Exception.Message)","Error",'OK','Error') | Out-Null
    }
    finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})

# Clear AI
$btnClearAi.Add_Click({
    $txtAiPrompt.Clear()
    $txtAiResponse.Clear()
    $lblStatus.Text = "Idle"
})

#---------------- Run Window ----------------#
$window.Topmost = $false
$window.ShowDialog() | Out-Null
