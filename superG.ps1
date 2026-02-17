<#
AI LLM 5G FWA SPEED TEST GUI
Single-file, admin-safe PowerShell WPF app.

Backend contracts:
- Speed test: Invoke-SpeedTest should return a [pscustomobject] with:
    [double] PingMs
    [double] DownloadMbps
    [double] UploadMbps
    [double] JitterMs
    [string] Provider
    [string] Server
- LLM analysis: Invoke-LLMAnalysis should accept that object and return a string.

You can wire:
- Ookla CLI:   https://www.speedtest.net/apps/cli
- Local LLM:   HTTP endpoint, named pipe, or local CLI

This script runs fully local except whatever your speed test / LLM backend does.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

#---------------------------#
#  Backend: Speed test      #
#---------------------------#
function Invoke-SpeedTest {
    param()

    # Example implementation using Ookla CLI (speedtest.exe in PATH)
    # Adjust to your environment or replace entirely.
    $speedtestExe = "speedtest"
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $speedtestExe
    $psi.Arguments = "-f json"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute        = $false
    $psi.CreateNoWindow         = $true

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi

    if (-not $p.Start()) {
        throw "Failed to start speedtest CLI. Ensure 'speedtest' is installed and in PATH."
    }

    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()

    if ($p.ExitCode -ne 0) {
        throw "Speedtest CLI failed: $stderr"
    }

    $json = $stdout | ConvertFrom-Json

    # Map Ookla JSON to our contract
    [pscustomobject]@{
        PingMs       = [math]::Round($json.ping.latency, 2)
        JitterMs     = [math]::Round($json.ping.jitter, 2)
        DownloadMbps = [math]::Round($json.download.bandwidth * 8 / 1MB, 2)
        UploadMbps   = [math]::Round($json.upload.bandwidth   * 8 / 1MB, 2)
        Provider     = $json.isp
        Server       = $json.server.host
    }
}

#---------------------------#
#  Backend: LLM analysis    #
#---------------------------#
function Invoke-LLMAnalysis {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    # Skeleton for local LLM endpoint (HTTP example).
    # Replace URL and payload as needed, or swap to your own mechanism.
    # This is intentionally minimal and not called over the network unless you configure it.

    $body = @{
        model  = "local-5g-fwa-analyst"
        prompt = @"
You are a network performance analyst specializing in 5G FWA.
Given this speed test result, provide a concise assessment (max 5 sentences),
focusing on real-world experience for streaming, gaming, and remote work.

Result:
Ping:     $($Result.PingMs) ms
Jitter:   $($Result.JitterMs) ms
Download: $($Result.DownloadMbps) Mbps
Upload:   $($Result.UploadMbps) Mbps
Provider: $($Result.Provider)
Server:   $($Result.Server)
"@
        max_tokens = 256
    }

    # Example POST (commented out by default to keep this fully local until you wire it):
    # $response = Invoke-RestMethod -Uri "http://127.0.0.1:11434/v1/chat/completions" -Method Post -Body ($body | ConvertTo-Json -Depth 5) -ContentType "application/json"
    # return $response.choices[0].message.content

    return "LLM analysis not wired yet. Connect Invoke-LLMAnalysis to your local endpoint to enable AI commentary."
}

#---------------------------#
#  XAML UI                  #
#---------------------------#
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI LLM 5G FWA Speed Test"
        Height="420" Width="640"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResizeWithGrip">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="140"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Row="0" Grid.ColumnSpan="2"
                   Text="5G FWA Speed Test with AI LLM Insight"
                   FontSize="18" FontWeight="Bold" Margin="0,0,0,10"/>

        <TextBlock Grid.Row="1" Grid.Column="0" Text="Ping (ms):" VerticalAlignment="Center"/>
        <TextBox   Grid.Row="1" Grid.Column="1" Name="PingBox" IsReadOnly="True" Margin="5,2"/>

        <TextBlock Grid.Row="2" Grid.Column="0" Text="Jitter (ms):" VerticalAlignment="Center"/>
        <TextBox   Grid.Row="2" Grid.Column="1" Name="JitterBox" IsReadOnly="True" Margin="5,2"/>

        <TextBlock Grid.Row="3" Grid.Column="0" Text="Download (Mbps):" VerticalAlignment="Center"/>
        <TextBox   Grid.Row="3" Grid.Column="1" Name="DownBox" IsReadOnly="True" Margin="5,2"/>

        <TextBlock Grid.Row="4" Grid.Column="0" Text="Upload (Mbps):" VerticalAlignment="Center"/>
        <TextBox   Grid.Row="4" Grid.Column="1" Name="UpBox" IsReadOnly="True" Margin="5,2"/>

        <TextBlock Grid.Row="5" Grid.Column="0" Text="Provider / Server:" VerticalAlignment="Center"/>
        <TextBox   Grid.Row="5" Grid.Column="1" Name="ProviderBox" IsReadOnly="True" Margin="5,2"/>

        <GroupBox Grid.Row="6" Grid.ColumnSpan="2" Header="AI LLM Analysis & Log" Margin="0,10,0,10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="2*"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <TextBox Name="LLMBox" Grid.Row="0" Margin="5" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" AcceptsReturn="True" IsReadOnly="True"/>
                <TextBox Name="LogBox" Grid.Row="1" Margin="5" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" AcceptsReturn="True" IsReadOnly="True"/>
            </Grid>
        </GroupBox>

        <StackPanel Grid.Row="7" Grid.ColumnSpan="2" Orientation="Horizontal" HorizontalAlignment="Right">
            <ProgressBar Name="ProgressBar" Width="200" Height="18" Margin="0,0,10,0" Minimum="0" Maximum="100" Value="0"/>
            <Button Name="RunButton" Content="Run Speed Test" Width="140" Height="28" Margin="0,0,5,0"/>
            <Button Name="CloseButton" Content="Close" Width="80" Height="28"/>
        </StackPanel>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

#---------------------------#
#  UI element references    #
#---------------------------#
$PingBox     = $window.FindName("PingBox")
$JitterBox   = $window.FindName("JitterBox")
$DownBox     = $window.FindName("DownBox")
$UpBox       = $window.FindName("UpBox")
$ProviderBox = $window.FindName("ProviderBox")
$LLMBox      = $window.FindName("LLMBox")
$LogBox      = $window.FindName("LogBox")
$RunButton   = $window.FindName("RunButton")
$CloseButton = $window.FindName("CloseButton")
$ProgressBar = $window.FindName("ProgressBar")

#---------------------------#
#  Helpers                  #
#---------------------------#
function Add-LogLine {
    param([string]$Text)
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $LogBox.AppendText("[$timestamp] $Text`r`n")
    $LogBox.ScrollToEnd()
}

#---------------------------#
#  Event wiring             #
#---------------------------#
$CloseButton.Add_Click({
    $window.Close()
})

$RunButton.Add_Click({
    $RunButton.IsEnabled = $false
    $ProgressBar.Value   = 10
    Add-LogLine "Starting 5G FWA speed test..."

    $job = Start-Job -ScriptBlock {
        param()
        try {
            $result = Invoke-SpeedTest
            [pscustomobject]@{
                Ok     = $true
                Result = $result
                Error  = $null
            }
        }
        catch {
            [pscustomobject]@{
                Ok     = $false
                Result = $null
                Error  = $_.Exception.Message
            }
        }
    }

    # Poll job from UI thread without blocking WPF message pump
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(400)
    $timer.Add_Tick({
        if ($job.State -eq 'Running') {
            if ($ProgressBar.Value -lt 80) { $ProgressBar.Value += 5 }
            return
        }

        $timer.Stop()
        $ProgressBar.Value = 90

        $data = Receive-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force

        if (-not $data.Ok) {
            Add-LogLine "Speed test failed: $($data.Error)"
            $RunButton.IsEnabled = $true
            $ProgressBar.Value   = 0
            return
        }

        $r = $data.Result
        $PingBox.Text     = "{0:N2}" -f $r.PingMs
        $JitterBox.Text   = "{0:N2}" -f $r.JitterMs
        $DownBox.Text     = "{0:N2}" -f $r.DownloadMbps
        $UpBox.Text       = "{0:N2}" -f $r.UploadMbps
        $ProviderBox.Text = "$($r.Provider) / $($r.Server)"

        Add-LogLine "Speed test completed: Down=$($r.DownloadMbps) Mbps, Up=$($r.UploadMbps) Mbps, Ping=$($r.PingMs) ms"

        # LLM analysis (runs on UI thread; you can offload to a job if your LLM is slow)
        Add-LogLine "Requesting AI LLM analysis..."
        $ProgressBar.Value = 95
        try {
            $analysis = Invoke-LLMAnalysis -Result $r
            $LLMBox.Text = $analysis
            Add-LogLine "AI LLM analysis updated."
        }
        catch {
            Add-LogLine "LLM analysis failed: $($_.Exception.Message)"
        }

        $ProgressBar.Value = 100
        Start-Sleep -Milliseconds 500
        $ProgressBar.Value = 0
        $RunButton.IsEnabled = $true
    })
    $timer.Start()
})

#---------------------------#
#  Run window               #
#---------------------------#
$window.Topmost = $false
$window.ShowDialog() | Out-Null
