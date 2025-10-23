<# 
.SYNOPSIS
  GUI uptime checker for WordPress.com (and any HTTPS site), with response time, status, SSL, DNS, and traceroute.
  Optional AI summary via a local or cloud LLM endpoint (configure in Invoke-AISummary).

.NOTES
  - Single-file PowerShell WPF GUI (.ps1). Run with: powershell -ExecutionPolicy Bypass -File .\WP_Uptime.ps1
  - No admin required. Uses async tasks. Safe for continuous monitoring.
  - Extensible: add ports, headers, proxies, auth, or custom LLM providers.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

#---------------------- Config ----------------------
$Global:DefaultUrl = "https://pctechgreu.wordpress.com"
$Global:DefaultIntervalSec = 30
$Global:Results = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$Global:MonitorTimer = New-Object System.Timers.Timer
$Global:MonitorTimer.Interval = $Global:DefaultIntervalSec * 1000
$Global:MonitorTimer.AutoReset = $true

# LLM endpoint config (example: local OpenAI-compatible)
$Global:LLM = @{
    Enabled     = $false             # set true to enable AI summaries
    Endpoint    = "http://localhost:8080/v1/chat/completions"
    Model       = "gpt-4o-mini"      # change as needed
    ApiKeyEnv   = "OPENAI_API_KEY"   # or your custom env var
    TimeoutMs   = 15000
}

#---------------------- UI (XAML) ----------------------
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WordPress.com Uptime Check" Height="560" Width="920" WindowStartupLocation="CenterScreen"
        Background="#0F151B" Foreground="#E6EDF3" FontFamily="Segoe UI">
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Controls -->
        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,12">
            <TextBlock Text="URL:" VerticalAlignment="Center" Margin="0,0,8,0"/>
            <TextBox x:Name="UrlBox" Width="380" Text="https://wordpress.com" Margin="0,0,16,0"/>
            <TextBlock Text="Interval (sec):" VerticalAlignment="Center" Margin="0,0,8,0"/>
            <TextBox x:Name="IntervalBox" Width="80" Text="30" Margin="0,0,16,0"/>
            <CheckBox x:Name="SslCheckBox" Content="SSL check" IsChecked="True" Margin="0,0,12,0"/>
            <CheckBox x:Name="DnsCheckBox" Content="DNS check" IsChecked="True" Margin="0,0,12,0"/>
            <CheckBox x:Name="TraceCheckBox" Content="Traceroute" IsChecked="False" Margin="0,0,12,0"/>
            <CheckBox x:Name="AiCheckBox" Content="AI summary" IsChecked="False" Margin="0,0,12,0"/>
            <Button x:Name="StartBtn" Content="Start" Width="90" Margin="0,0,8,0"/>
            <Button x:Name="StopBtn" Content="Stop" Width="90" IsEnabled="False"/>
        </StackPanel>

        <!-- Status -->
        <StackPanel Orientation="Horizontal" Grid.Row="1" Margin="0,0,0,8">
            <TextBlock Text="Status:" VerticalAlignment="Center" Margin="0,0,8,0"/>
            <TextBlock x:Name="StatusText" Text="Idle" VerticalAlignment="Center" Foreground="#9CDCFE"/>
        </StackPanel>

        <!-- Results -->
        <DataGrid x:Name="Grid" Grid.Row="2" AutoGenerateColumns="False" ItemsSource="{Binding}" Background="#0F151B" Foreground="#E6EDF3"
                  HeadersVisibility="Column" GridLinesVisibility="Horizontal" CanUserAddRows="False" IsReadOnly="True">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Time" Binding="{Binding Time}" Width="140"/>
                <DataGridTextColumn Header="URL" Binding="{Binding Url}" Width="220"/>
                <DataGridTextColumn Header="HTTP" Binding="{Binding HttpStatus}" Width="80"/>
                <DataGridTextColumn Header="Resp ms" Binding="{Binding ResponseMs}" Width="90"/>
                <DataGridTextColumn Header="Up" Binding="{Binding Up}" Width="60"/>
                <DataGridTextColumn Header="SSL Days" Binding="{Binding SslDaysLeft}" Width="90"/>
                <DataGridTextColumn Header="IP" Binding="{Binding Ip}" Width="140"/>
                <DataGridTextColumn Header="Trace Hops" Binding="{Binding TraceHops}" Width="90"/>
                <DataGridTextColumn Header="Note" Binding="{Binding Note}" Width="*"/>
            </DataGrid.Columns>
        </DataGrid>

        <!-- Actions -->
        <StackPanel Orientation="Horizontal" Grid.Row="3" Margin="0,12,0,0">
            <Button x:Name="TestOnceBtn" Content="Test once" Width="110" Margin="0,0,8,0"/>
            <Button x:Name="ExportCsvBtn" Content="Export CSV" Width="110" Margin="0,0,8,0"/>
            <Button x:Name="ClearBtn" Content="Clear" Width="90" Margin="0,0,8,0"/>
            <Button x:Name="CopyRowBtn" Content="Copy selected" Width="130" Margin="0,0,8,0"/>
            <Button x:Name="AiSummBtn" Content="AI summary now" Width="140" Margin="0,0,8,0"/>
            <TextBlock Text="Tip: runs async, safe to minimize." VerticalAlignment="Center" Foreground="#7AA2F7"/>
        </StackPanel>
    </Grid>
</Window>
"@

#---------------------- Build Window ----------------------
$reader = (New-Object System.Xml.XmlNodeReader ([xml]$Xaml))
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$UrlBox       = $Window.FindName("UrlBox")
$IntervalBox  = $Window.FindName("IntervalBox")
$SslCheckBox  = $Window.FindName("SslCheckBox")
$DnsCheckBox  = $Window.FindName("DnsCheckBox")
$TraceCheckBox= $Window.FindName("TraceCheckBox")
$AiCheckBox   = $Window.FindName("AiCheckBox")
$StartBtn     = $Window.FindName("StartBtn")
$StopBtn      = $Window.FindName("StopBtn")
$Grid         = $Window.FindName("Grid")
$StatusText   = $Window.FindName("StatusText")
$TestOnceBtn  = $Window.FindName("TestOnceBtn")
$ExportCsvBtn = $Window.FindName("ExportCsvBtn")
$ClearBtn     = $Window.FindName("ClearBtn")
$CopyRowBtn   = $Window.FindName("CopyRowBtn")
$AiSummBtn    = $Window.FindName("AiSummBtn")

$Grid.ItemsSource = $Global:Results

#---------------------- Helpers ----------------------
function Get-NowStr { (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }

function Resolve-HostIp {
    param([string]$Url)
    try {
        $host = ([System.Uri]$Url).Host
        $ips = [System.Net.Dns]::GetHostAddresses($host) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
        if ($ips) { ($ips | Select-Object -First 1).ToString() } else { "" }
    } catch { "" }
}

function Check-SSL {
    param([string]$Url)
    try {
        $uri = [System.Uri]$Url
        if ($uri.Scheme -ne "https") { return [pscustomobject]@{ DaysLeft = $null; Note = "non-HTTPS" } }
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($uri.Host, 443)
        $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, ({ $true }))
        $ssl.AuthenticateAsClient($uri.Host)
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $ssl.RemoteCertificate
        $daysLeft = ([System.TimeSpan]::FromTicks(($cert.NotAfter - (Get-Date)).Ticks)).TotalDays
        $tcp.Close()
        [pscustomobject]@{ DaysLeft = [int][math]::Floor($daysLeft); Note = $cert.Subject }
    } catch {
        [pscustomobject]@{ DaysLeft = $null; Note = "SSL error: $($_.Exception.Message)" }
    }
}

function Invoke-HttpCheck {
    param([string]$Url)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $handler = New-Object System.Net.Http.HttpClientHandler
        $handler.AllowAutoRedirect = $true
        $client = [System.Net.Http.HttpClient]::new($handler)
        $client.Timeout = [TimeSpan]::FromMilliseconds(10000)
        $resp = $client.GetAsync($Url).GetAwaiter().GetResult()
        $sw.Stop()
        [pscustomobject]@{
            StatusCode  = [int]$resp.StatusCode
            ResponseMs  = [int]$sw.Elapsed.TotalMilliseconds
            Up          = $resp.IsSuccessStatusCode
            Note        = $resp.ReasonPhrase
        }
    } catch {
        $sw.Stop()
        [pscustomobject]@{
            StatusCode  = 0
            ResponseMs  = [int]$sw.Elapsed.TotalMilliseconds
            Up          = $false
            Note        = "HTTP error: $($_.Exception.Message)"
        }
    } finally {
        if ($client) { $client.Dispose() }
        if ($handler) { $handler.Dispose() }
    }
}

function Invoke-Trace {
    param([string]$Url, [int]$MaxHops = 15)
    try {
        $host = ([System.Uri]$Url).Host
        $p = Start-Process -FilePath "powershell" -ArgumentList "-NoProfile -Command `"Test-NetConnection -ComputerName $host -TraceRoute`"" -NoNewWindow -PassThru -RedirectStandardOutput ([System.IO.Path]::GetTempFileName())
        $p.WaitForExit()
        $out = Get-Content $p.RedirectStandardOutput -Raw
        Remove-Item $p.RedirectStandardOutput -ErrorAction SilentlyContinue
        $hops = ($out -split "`n" | Where-Object { $_ -match "Hop" }).Count
        if ($hops -eq 0 -and $out -match "TraceRoute") { $hops = ($out -split "`n" | Where-Object { $_ -match "^\s*\d+\s" }).Count }
        [pscustomobject]@{ Hops = $hops; Raw = $out }
    } catch {
        [pscustomobject]@{ Hops = $null; Raw = "Trace error: $($_.Exception.Message)" }
    }
}

function Add-ResultRow {
    param(
        [string]$Url,[int]$Http,[int]$Ms,[bool]$Up,[int]$SslDays,[string]$Ip,[int]$TraceHops,[string]$Note
    )
    $row = [pscustomobject]@{
        Time        = Get-NowStr
        Url         = $Url
        HttpStatus  = $Http
        ResponseMs  = $Ms
        Up          = $Up
        SslDaysLeft = $SslDays
        Ip          = $Ip
        TraceHops   = $TraceHops
        Note        = $Note
    }
    $Window.Dispatcher.Invoke({ $Global:Results.Insert(0, $row) }) | Out-Null
    return $row
}

function Validate-Url {
    param([string]$Url)
    try { [void][System.Uri]$Url; $true } catch { $false }
}

# Optional AI summary (OpenAI-compatible JSON). Toggle via checkbox.
function Invoke-AISummary {
    param([object[]]$Rows)
    if (-not $Global:LLM.Enabled) { return "AI disabled." }
    try {
        $apiKey = [Environment]::GetEnvironmentVariable($Global:LLM.ApiKeyEnv, "Process")
        if ([string]::IsNullOrWhiteSpace($apiKey)) { $apiKey = [Environment]::GetEnvironmentVariable($Global:LLM.ApiKeyEnv, "User") }
        if ([string]::IsNullOrWhiteSpace($apiKey)) { return "AI: missing API key env var." }

        $recent = $Rows | Select-Object -First 12 | ConvertTo-Json -Depth 3
        $body = @{
            model = $Global:LLM.Model
            messages = @(
                @{ role = "system"; content = "You summarize uptime logs: highlight outages, latency spikes, SSL risks, and DNS/trace anomalies." },
                @{ role = "user"; content = "Summarize these checks:\n$recent\nGive concise bullet points and one-line verdict." }
            )
            temperature = 0.2
        } | ConvertTo-Json -Depth 5

        $headers = @{
            "Authorization" = "Bearer $apiKey"
            "Content-Type"  = "application/json"
        }
        $resp = Invoke-RestMethod -Method Post -Uri $Global:LLM.Endpoint -Headers $headers -Body $body -TimeoutSec ([math]::Ceiling($Global:LLM.TimeoutMs/1000))
        if ($resp.choices[0].message.content) { return $resp.choices[0].message.content.Trim() }
        return "AI: no content."
    } catch {
        return "AI error: $($_.Exception.Message)"
    }
}

#---------------------- Core test ----------------------
function Run-Check {
    param([string]$Url, [bool]$DoSSL = $true, [bool]$DoDNS = $true, [bool]$DoTrace = $false)
    if (-not (Validate-Url $Url)) { return Add-ResultRow -Url $Url -Http 0 -Ms 0 -Up $false -SslDays $null -Ip "" -TraceHops $null -Note "Invalid URL" }

    $ip = if ($DoDNS) { Resolve-HostIp -Url $Url } else { "" }
    $ssl = if ($DoSSL) { Check-SSL -Url $Url } else { [pscustomobject]@{ DaysLeft = $null; Note = "" } }
    $http = Invoke-HttpCheck -Url $Url
    $trace = if ($DoTrace) { Invoke-Trace -Url $Url } else { [pscustomobject]@{ Hops = $null; Raw = "" } }

    $note = $http.Note
    if ($ssl.DaysLeft -ne $null -and $ssl.DaysLeft -le 14) { $note = "$note | SSL expiring in $($ssl.DaysLeft)d" }
    if ([string]::IsNullOrWhiteSpace($ip)) { $note = "$note | DNS unresolved" }

    Add-ResultRow -Url $Url -Http $http.StatusCode -Ms $http.ResponseMs -Up $http.Up -SslDays $ssl.DaysLeft -Ip $ip -TraceHops $trace.Hops -Note $note
}

#---------------------- Monitoring ----------------------
$Global:MonitorTimer.add_Elapsed({
    try {
        $Window.Dispatcher.Invoke({
            $url   = $UrlBox.Text.Trim()
            $ssl   = $SslCheckBox.IsChecked
            $dns   = $DnsCheckBox.IsChecked
            $trace = $TraceCheckBox.IsChecked
            [void](Run-Check -Url $url -DoSSL $ssl -DoDNS $dns -DoTrace $trace)
            $StatusText.Text = "Last: $(Get-NowStr)"
        })
    } catch {
        $Window.Dispatcher.Invoke({ $StatusText.Text = "Timer error: $($_.Exception.Message)" })
    }
})

#---------------------- Wire UI events ----------------------
$StartBtn.Add_Click({
    try {
        $UrlBox.Text = $UrlBox.Text.Trim()
        if (-not (Validate-Url $UrlBox.Text)) { $StatusText.Text = "Invalid URL"; return }
        $interval = [int]([double]($IntervalBox.Text))
        if ($interval -lt 5) { $interval = 5 }
        $Global:MonitorTimer.Interval = $interval * 1000
        $Global:LLM.Enabled = [bool]$AiCheckBox.IsChecked
        $StartBtn.IsEnabled = $false
        $StopBtn.IsEnabled = $true
        $UrlBox.IsEnabled = $false
        $IntervalBox.IsEnabled = $false
        $StatusText.Text = "Monitoring..."
        $Global:MonitorTimer.Start()
    } catch {
        $StatusText.Text = "Start error: $($_.Exception.Message)"
    }
})

$StopBtn.Add_Click({
    try {
        $Global:MonitorTimer.Stop()
        $StartBtn.IsEnabled = $true
        $StopBtn.IsEnabled = $false
        $UrlBox.IsEnabled = $true
        $IntervalBox.IsEnabled = $true
        $StatusText.Text = "Stopped"
    } catch {
        $StatusText.Text = "Stop error: $($_.Exception.Message)"
    }
})

$TestOnceBtn.Add_Click({
    try {
        [void](Run-Check -Url $UrlBox.Text.Trim() -DoSSL $SslCheckBox.IsChecked -DoDNS $DnsCheckBox.IsChecked -DoTrace $TraceCheckBox.IsChecked)
        $StatusText.Text = "Tested at $(Get-NowStr)"
    } catch {
        $StatusText.Text = "Test error: $($_.Exception.Message)"
    }
})

$ExportCsvBtn.Add_Click({
    try {
        $path = Join-Path ([Environment]::GetFolderPath("Desktop")) ("wp-uptime-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".csv")
        $Global:Results | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
        $StatusText.Text = "Exported: $path"
    } catch {
        $StatusText.Text = "Export error: $($_.Exception.Message)"
    }
})

$ClearBtn.Add_Click({
    try {
        $Global:Results.Clear()
        $StatusText.Text = "Cleared"
    } catch {
        $StatusText.Text = "Clear error: $($_.Exception.Message)"
    }
})

$CopyRowBtn.Add_Click({
    try {
        $row = $Grid.SelectedItem
        if ($null -eq $row) { $StatusText.Text = "Select a row first"; return }
        $txt = ($row.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" }) -join "`r`n"
        [System.Windows.Clipboard]::SetText($txt)
        $StatusText.Text = "Copied selected row"
    } catch {
        $StatusText.Text = "Copy error: $($_.Exception.Message)"
    }
})

$AiSummBtn.Add_Click({
    try {
        $Global:LLM.Enabled = [bool]$AiCheckBox.IsChecked
        $rows = $Global:Results | Select-Object -First 20
        $summary = Invoke-AISummary -Rows $rows
        [System.Windows.MessageBox]::Show($summary, "AI summary")
    } catch {
        $StatusText.Text = "AI error: $($_.Exception.Message)"
    }
})

#---------------------- Show Window ----------------------
$Window.Add_SourceInitialized({
    $UrlBox.Text = $Global:DefaultUrl
    $IntervalBox.Text = "$($Global:DefaultIntervalSec)"
})
$Window.ShowDialog() | Out-Null
