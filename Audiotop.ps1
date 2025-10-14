# AI LLM GUI for Open-Source Audio Editor Workflows (Audacity, FFmpeg, Nyquist/LADSPA)
# Save as: AI-AudioAssistant.ps1
# Run: powershell -ExecutionPolicy Bypass -File .\AI-AudioAssistant.ps1

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type -AssemblyName System.Web

# -----------------------------
# Config (edit if desired)
# -----------------------------
$Global:LLM_Base  = $env:OPENAI_API_BASE
if (![string]::IsNullOrWhiteSpace($Global:LLM_Base)) {
    if (-not $Global:LLM_Base.EndsWith('/')) { $Global:LLM_Base += '/' }
    if (-not $Global:LLM_Base.ToLower().EndsWith('v1/')) { $Global:LLM_Base += 'v1/' }
}
$Global:LLM_Model = $env:OPENAI_MODEL
$Global:LLM_Key   = $env:OPENAI_API_KEY
$Global:LLM_TimeoutSec = 120

# Default fallbacks (safe to leave if env vars are set)
if ([string]::IsNullOrWhiteSpace($Global:LLM_Base))  { $Global:LLM_Base  = 'https://api.openai.com/v1/' }
if ([string]::IsNullOrWhiteSpace($Global:LLM_Model)) { $Global:LLM_Model = 'gpt-4o-mini' }
# $Global:LLM_Key must be set to actually call; UI will warn otherwise.

# -----------------------------
# UI (XAML)
# -----------------------------
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI Audio Assistant" Height="680" Width="980" WindowStartupLocation="CenterScreen"
        Background="#0f0f13" Foreground="#eaeaea" FontFamily="Segoe UI">
  <Grid Margin="16">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,12">
      <TextBlock Text="AI LLM Audio Assistant" FontSize="22" FontWeight="Bold" Margin="0,0,12,0"/>
      <TextBlock x:Name="ApiStatus" Text="API: Not configured" FontSize="12" Foreground="#cfcfcf" VerticalAlignment="Center"/>
      <Button x:Name="BtnConfig" Content="Config" Margin="16,0,0,0" Padding="12,4" />
    </StackPanel>

    <!-- File + Mode -->
    <DockPanel Grid.Row="1" LastChildFill="False" Margin="0,0,0,12">
      <Button x:Name="BtnSelectAudio" Content="Load audio..." Padding="12,6" />
      <TextBlock Text="  " />
      <ComboBox x:Name="ModeCombo" Width="280">
        <ComboBoxItem Content="Audacity Macro (.txt)" IsSelected="True"/>
        <ComboBoxItem Content="Audacity Chain (.txt - legacy)"/>
        <ComboBoxItem Content="FFmpeg Command"/>
        <ComboBoxItem Content="Nyquist/LADSPA snippet"/>
        <ComboBoxItem Content="Plain text notes"/>
      </ComboBox>
      <TextBlock Text="  " />
      <Button x:Name="BtnProbe" Content="Probe" Padding="12,6" />
      <TextBlock Text="  " />
      <Button x:Name="BtnClear" Content="Clear" Padding="12,6" />
    </DockPanel>

    <!-- Prompt -->
    <Grid Grid.Row="2">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <GroupBox Grid.Column="0" Header="Prompt" Margin="0,0,8,0">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <TextBox x:Name="PromptBox" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"
                   Background="#1a1a21" BorderBrush="#333" Foreground="#eaeaea" />
          <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,8,0,0">
            <Button x:Name="BtnSuggest" Content="Suggest prompt" Padding="10,6" />
            <TextBlock Text="  " />
            <Button x:Name="BtnRun" Content="Run LLM" Padding="14,6" />
          </StackPanel>
        </Grid>
      </GroupBox>

      <GroupBox Grid.Column="1" Header="Context" Margin="8,0,0,0">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
          </Grid.RowDefinitions>
          <TextBox x:Name="FileInfoBox" Height="70" IsReadOnly="True" TextWrapping="Wrap"
                   Background="#1a1a21" BorderBrush="#333" Foreground="#cfcfcf" />
          <TextBox x:Name="SystemPromptBox" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"
                   Background="#141419" BorderBrush="#333" Foreground="#eaeaea"
                   Text="You are an audio engineering assistant. When asked, produce concise, directly usable outputs for the selected mode (Audacity macro/chain, FFmpeg command, Nyquist/LADSPA snippet, or plain notes). Prefer safe default levels, avoid clipping, and annotate steps minimally."
          />
        </Grid>
      </GroupBox>
    </Grid>

    <!-- Output -->
    <GroupBox Grid.Row="3" Header="LLM output">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBox x:Name="OutputBox" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"
                 Background="#0f0f13" BorderBrush="#333" Foreground="#eaeaea" FontFamily="Consolas" />
        <DockPanel Grid.Row="1" LastChildFill="False" Margin="0,8,0,0">
          <Button x:Name="BtnCopy" Content="Copy" Padding="12,6" />
          <TextBlock Text="  " />
          <Button x:Name="BtnSave" Content="Save..." Padding="12,6" />
          <TextBlock Text="  " />
          <Button x:Name="BtnApplyHint" Content="Audacity import hint" Padding="12,6" />
        </DockPanel>
      </Grid>
    </GroupBox>

    <!-- Status -->
    <StatusBar Grid.Row="4" Background="#111">
      <StatusBarItem>
        <TextBlock x:Name="StatusText" Text="Ready."/>
      </StatusBarItem>
    </StatusBar>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$Xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Bind controls
$ApiStatus      = $Window.FindName('ApiStatus')
$BtnConfig      = $Window.FindName('BtnConfig')
$BtnSelectAudio = $Window.FindName('BtnSelectAudio')
$ModeCombo      = $Window.FindName('ModeCombo')
$BtnProbe       = $Window.FindName('BtnProbe')
$BtnClear       = $Window.FindName('BtnClear')
$PromptBox      = $Window.FindName('PromptBox')
$BtnSuggest     = $Window.FindName('BtnSuggest')
$BtnRun         = $Window.FindName('BtnRun')
$FileInfoBox    = $Window.FindName('FileInfoBox')
$SystemPromptBox= $Window.FindName('SystemPromptBox')
$OutputBox      = $Window.FindName('OutputBox')
$BtnCopy        = $Window.FindName('BtnCopy')
$BtnSave        = $Window.FindName('BtnSave')
$BtnApplyHint   = $Window.FindName('BtnApplyHint')
$StatusText     = $Window.FindName('StatusText')

$Global:CurrentAudio = $null

function Update-ApiStatus {
    $base = $Global:LLM_Base
    $model = $Global:LLM_Model
    $key = if ([string]::IsNullOrWhiteSpace($Global:LLM_Key)) { 'Missing API key' } else { 'Key set' }
    $ApiStatus.Text = "API: $base | Model: $model | $key"
}
Update-ApiStatus

# -----------------------------
# Helpers
# -----------------------------
function Show-OpenFile([string]$filter="Audio files|*.wav;*.mp3;*.flac;*.ogg;*.m4a;*.aiff;*.aac;*.wma|All files|*.*") {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = $filter
    $dlg.Multiselect = $false
    if ($dlg.ShowDialog() -eq 'OK') { return $dlg.FileName }
    return $null
}

function Get-FfprobeInfo([string]$path) {
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "ffprobe"
        $psi.Arguments = "-v quiet -print_format json -show_format -show_streams `"$path`""
        $psi.RedirectStandardOutput = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        $out = $p.StandardOutput.ReadToEnd()
        $p.WaitForExit()
        if ($p.ExitCode -eq 0 -and $out) {
            return (ConvertFrom-Json $out)
        }
    } catch {}
    return $null
}

function Build-LLMPayload([string]$systemPrompt, [string]$userPrompt) {
    # OpenAI-compatible chat payload
    @{
        model = $Global:LLM_Model
        messages = @(
            @{ role = "system"; content = $systemPrompt },
            @{ role = "user";   content = $userPrompt }
        )
        temperature = 0.2
    } | ConvertTo-Json -Depth 6
}

function Invoke-LLM([string]$payloadJson) {
    if ([string]::IsNullOrWhiteSpace($Global:LLM_Key)) {
        throw "No API key configured. Set OPENAI_API_KEY."
    }
    $url = ($Global:LLM_Base.TrimEnd('/')) + "/chat/completions"
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds($Global:LLM_TimeoutSec)
    $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, $url)
    $req.Headers.Add("Authorization", "Bearer $($Global:LLM_Key)")
    $req.Content = New-Object System.Net.Http.StringContent($payloadJson, [System.Text.Encoding]::UTF8, "application/json")

    $resp = $client.SendAsync($req).Result
    $content = $resp.Content.ReadAsStringAsync().Result
    if (-not $resp.IsSuccessStatusCode) {
        throw "LLM HTTP $($resp.StatusCode): $content"
    }
    $json = ConvertFrom-Json $content
    # Extract assistant content (OpenAI-style)
    $text = $json.choices[0].message.content
    return $text
}

function Mode-Instruction([string]$mode) {
    switch ($mode) {
        'Audacity Macro (.txt)' { 
            @"
Return only an Audacity macro .txt content. Use lines like:
SelectAll
Normalize:ApplyGain="-3"
Compressor:Threshold="-18" Ratio="3:1" AttackTime="0.01" ReleaseTime="0.3"
Limiter:Limit="-1"

Keep it minimal, safe, and importable via Tools > Macros. Avoid extra commentary.
"@
        }
        'Audacity Chain (.txt - legacy)' {
            @"
Return only an Audacity chain .txt content. Example:
SelectAll
Equalization:Curve="BassBoost"
Normalize:ApplyGain="-3"

No commentary. One operation per line.
"@
        }
        'FFmpeg Command' {
            @"
Return only a single ffmpeg command line that’s safe to run. Assume input file at {INPUT}. Keep audio-safe flags (dynaudnorm if needed, loudnorm optional). No prose. Example:
ffmpeg -i "{INPUT}" -af "loudnorm=I=-16:LRA=11:TP=-1" -c:a aac -b:a 192k "{OUTPUT}"
"@
        }
        'Nyquist/LADSPA snippet' {
            @"
Return only a Nyquist or LADSPA snippet that applies gentle noise reduction and a -3 dB ceiling. No prose, only code.
"@
        }
        default {
            "Return only concise plain text bullet steps with effect names and parameters. No fluff."
        }
    }
}

function Build-UserPrompt([string]$mode, [string]$audioPath, $probe, [string]$userText) {
    $fileName = if ($audioPath) { [System.IO.Path]::GetFileName($audioPath) } else { "(no file)" }
    $dur = $null
    $sr  = $null
    $ch  = $null
    $br  = $null
    if ($probe) {
        try {
            $dur = [math]::Round([double]$probe.format.duration,2)
            $sr  = ($probe.streams | Where-Object {$_.codec_type -eq 'audio'} | Select-Object -First 1).sample_rate
            $ch  = ($probe.streams | Where-Object {$_.codec_type -eq 'audio'} | Select-Object -First 1).channels
            $br  = $probe.format.bit_rate
        } catch {}
    }
    $ctx = @()
    $ctx += "File: $fileName"
    if ($dur) { $ctx += "Duration: $dur s" }
    if ($sr)  { $ctx += "SampleRate: $sr" }
    if ($ch)  { $ctx += "Channels: $ch" }
    if ($br)  { $ctx += "Bitrate: $br" }
    $ctxLine = ($ctx -join " | ")

    $modeInstr = Mode-Instruction -mode
