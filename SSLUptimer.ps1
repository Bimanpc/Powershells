<#
.SYNOPSIS
  SSL UPTIMER CHECKER - WinForms GUI to monitor HTTPS endpoints:
  - Checks HTTP availability (HEAD), status code, latency
  - Retrieves SSL certificate, validity, issuer, days-to-expiry
  - Auto-repeats on interval; color-coded results; CSV export/import

.NOTES
  Single-file .ps1. Run with: powershell -ExecutionPolicy Bypass -File .\SslUptimerChecker.ps1
  Tested on Windows 11 / PowerShell 5.1+. Requires .NET.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net.Http
Add-Type -AssemblyName System.Web

# Globals
$Urls = New-Object System.Collections.Generic.List[string]
$HttpClientHandler = [System.Net.Http.HttpClientHandler]::new()
$HttpClientHandler.AllowAutoRedirect = $true
$HttpClientHandler.ServerCertificateCustomValidationCallback = { param($msg,$cert,$chain,$errors) return $true } # allow fetch even if cert issues to still inspect
$HttpClient = [System.Net.Http.HttpClient]::new($HttpClientHandler)
$HttpClient.Timeout = [TimeSpan]::FromSeconds(10)

function Get-HostnamePort {
    param([string]$Url)
    try {
        if ($Url -notmatch '^https?://') { $Url = 'https://' + $Url }
        $uri = [Uri]$Url
        $host = $uri.Host
        $port = if ($uri.Port -gt 0) { $uri.Port } else { if ($uri.Scheme -eq 'https') {443} else {80} }
        return [PSCustomObject]@{ Uri=$uri; Host=$host; Port=$port }
    } catch {
        return $null
    }
}

function Get-SslCertificateInfo {
    param([string]$Host, [int]$Port = 443, [int]$TimeoutMs = 8000)

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $ct = New-Object System.Threading.CancellationTokenSource($TimeoutMs)
        $connectTask = $client.ConnectAsync($Host, $Port)
        $connectTask.Wait($TimeoutMs) | Out-Null
        if (-not $client.Connected) { throw "Connect timeout" }

        $ns = $client.GetStream()
        $ssl = [System.Net.Security.SslStream]::new($ns, $false, { $true })
        $ssl.AuthenticateAsClient($Host)
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $ssl.RemoteCertificate

        $now = [DateTime]::UtcNow
        $validFrom = $cert.NotBefore.ToUniversalTime()
        $validTo   = $cert.NotAfter.ToUniversalTime()
        $daysLeft  = [math]::Floor(($validTo - $now).TotalDays)
        $isValidNow = ($now -ge $validFrom) -and ($now -lt $validTo)

        return [PSCustomObject]@{
            Subject      = $cert.Subject
            Issuer       = $cert.Issuer
            NotBeforeUTC = $validFrom
            NotAfterUTC  = $validTo
            DaysLeft     = $daysLeft
            IsValidNow   = $isValidNow
            Thumbprint   = $cert.Thumbprint
            SANs         = ($cert.Extensions | ForEach-Object {
                                if ($_.Oid.Value -eq '2.5.29.17') {
                                    try { ($_.Format($true) -split '\s*,\s*') -join '; ' } catch { $null }
                                }
                            }) -join '; '
        }
    } catch {
        return [PSCustomObject]@{
            Subject      = ''
            Issuer       = ''
            NotBeforeUTC = $null
            NotAfterUTC  = $null
            DaysLeft     = $null
            IsValidNow   = $false
            Thumbprint   = ''
            SANs         = ''
            Error        = $_.Exception.Message
        }
    } finally {
        try { $client.Close() } catch {}
    }
}

function Test-HttpHead {
    param([Uri]$Uri)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $req = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Head, $Uri)
        $resp = $HttpClient.SendAsync($req)
        $resp.Wait(10000) | Out-Null
        if (-not $resp.IsCompleted) { throw "HTTP timeout" }
        $result = $resp.Result
        $sw.Stop()
        return [PSCustomObject]@{
            StatusCode = [int]$result.StatusCode
            Reason     = $result.ReasonPhrase
            LatencyMs  = [int]$sw.ElapsedMilliseconds
            Ok         = $result.IsSuccessStatusCode
        }
    } catch {
        $sw.Stop()
        return [PSCustomObject]@{
            StatusCode = $null
            Reason     = $_.Exception.Message
            LatencyMs  = [int]$sw.ElapsedMilliseconds
            Ok         = $false
        }
    }
}

# UI
$form = New-Object System.Windows.Forms.Form
$form.Text = "SSL UPTIMER CHECKER"
$form.Size = New-Object System.Drawing.Size(980, 600)
$form.StartPosition = "CenterScreen"

$lblUrl = New-Object System.Windows.Forms.Label
$lblUrl.Text = "URL:"
$lblUrl.Location = New-Object System.Drawing.Point(12, 15)
$lblUrl.AutoSize = $true

$txtUrl = New-Object System.Windows.Forms.TextBox
$txtUrl.Location = New-Object System.Drawing.Point(55, 12)
$txtUrl.Size = New-Object System.Drawing.Size(480, 22)
$txtUrl.Text = "https://example.com"

$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = "Add"
$btnAdd.Location = New-Object System.Drawing.Point(545, 10)
$btnAdd.Size = New-Object System.Drawing.Size(70, 26)

$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = "Remove"
$btnRemove.Location = New-Object System.Drawing.Point(620, 10)
$btnRemove.Size = New-Object System.Drawing.Size(80, 26)

$btnCheckNow = New-Object System.Windows.Forms.Button
$btnCheckNow.Text = "Check now"
$btnCheckNow.Location = New-Object System.Drawing.Point(705, 10)
$btnCheckNow.Size = New-Object System.Drawing.Size(95, 26)

$lblInterval = New-Object System.Windows.Forms.Label
$lblInterval.Text = "Interval (sec):"
$lblInterval.Location = New-Object System.Drawing.Point(12, 45)
$lblInterval.AutoSize = $true

$numInterval = New-Object System.Windows.Forms.NumericUpDown
$numInterval.Location = New-Object System.Drawing.Point(110, 42)
$numInterval.Size = New-Object System.Drawing.Size(80, 22)
$numInterval.Minimum = 5
$numInterval.Maximum = 3600
$numInterval.Value = 60

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start"
$btnStart.Location = New-Object System.Drawing.Point(200, 40)
$btnStart.Size = New-Object System.Drawing.Size(70, 26)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "Stop"
$btnStop.Location = New-Object System.Drawing.Point(275, 40)
$btnStop.Size = New-Object System.Drawing.Size(70, 26)
$btnStop.Enabled = $false

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export CSV"
$btnExport.Location = New-Object System.Drawing.Point(350, 40)
$btnExport.Size = New-Object System.Drawing.Size(90, 26)

$btnImport = New-Object System.Windows.Forms.Button
$btnImport.Text = "Import CSV"
$btnImport.Location = New-Object System.Drawing.Point(445, 40)
$btnImport.Size = New-Object System.Drawing.Size(90, 26)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(12, 75)
$grid.Size = New-Object System.Drawing.Size(940, 470)
$grid.AllowUserToAddRows = $false
$grid.ReadOnly = $true
$grid.SelectionMode = 'FullRowSelect'
$grid.MultiSelect = $false
$grid.AutoSizeColumnsMode = 'Fill'

# Columns
$cols = @(
    @{Name='Url'; Header='URL'; Width=250},
    @{Name='HttpStatus'; Header='HTTP'; Width=70},
    @{Name='Latency'; Header='Latency (ms)'; Width=90},
    @{Name='SslValid'; Header='SSL valid'; Width=80},
    @{Name='DaysLeft'; Header='Days left'; Width=80},
    @{Name='NotAfter'; Header='Expires (UTC)'; Width=160},
    @{Name='Issuer'; Header='Issuer'; Width=200},
    @{Name='LastChecked'; Header='Checked at'; Width=140},
    @{Name='Message'; Header='Message'; Width=200}
)
foreach ($c in $cols) {
    $col = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $col.Name = $c.Name
    $col.HeaderText = $c.Header
    $col.Width = $c.Width
    $grid.Columns.Add($col) | Out-Null
}

# Timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = [int]$numInterval.Value * 1000

function Add-UrlRow {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return }
    $parsed = Get-HostnamePort -Url $Url
    if (-not $parsed) { [System.Windows.Forms.MessageBox]::Show("Invalid URL: $Url"); return }
    $canon = $parsed.Uri.AbsoluteUri
    if ($Urls.Contains($canon)) { return }
    $Urls.Add($canon)
    $rowIndex = $grid.Rows.Add()
    $row = $grid.Rows[$rowIndex]
    $row.Cells['Url'].Value = $canon
    $row.Cells['Message'].Value = ''
    $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::White
}

function Remove-SelectedRow {
    if ($grid.SelectedRows.Count -gt 0) {
        $row = $grid.SelectedRows[0]
        $url = [string]$row.Cells['Url'].Value
        [void]$Urls.Remove($url)
        $grid.Rows.Remove($row)
    }
}

function Update-Row {
    param(
        [int]$RowIndex,
        [string]$HttpStatus,
        [int]$Latency,
        [bool]$SslValid,
        [object]$DaysLeft,
        [string]$NotAfter,
        [string]$Issuer,
        [string]$Message
    )
    $row = $grid.Rows[$RowIndex]
    $row.Cells['HttpStatus'].Value = $HttpStatus
    $row.Cells['Latency'].Value = $Latency
    $row.Cells['SslValid'].Value = $SslValid
    $row.Cells['DaysLeft'].Value = $DaysLeft
    $row.Cells['NotAfter'].Value = $NotAfter
    $row.Cells['Issuer'].Value = $Issuer
    $row.Cells['LastChecked'].Value = [DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss')
    $row.Cells['Message'].Value = $Message

    # Color coding
    $color = [System.Drawing.Color]::White
    try {
        if (-not $SslValid) { $color = [System.Drawing.Color]::LightPink }
        elseif ([int]$DaysLeft -le 7) { $color = [System.Drawing.Color]::Khaki }
        elseif (-not $HttpStatus -or ($HttpStatus -as [int]) -ge 400) { $color = [System.Drawing.Color]::LightSalmon }
        else { $color = [System.Drawing.Color]::Honeydew }
    } catch { $color = [System.Drawing.Color]::White }
    $row.DefaultCellStyle.BackColor = $color
}

function Check-All {
    # sequential to keep UI responsive enough without thread complexity
    for ($i = 0; $i -lt $grid.Rows.Count; $i++) {
        $url = [string]$grid.Rows[$i].Cells['Url'].Value
        $parsed = Get-HostnamePort -Url $url
        if (-not $parsed) {
            Update-Row -RowIndex $i -HttpStatus '' -Latency 0 -SslValid $false -DaysLeft '' -NotAfter '' -Issuer '' -Message 'Invalid URL'
            continue
        }

        $http = Test-HttpHead -Uri $parsed.Uri
        $ssl  = $null
        if ($parsed.Uri.Scheme -eq 'https') {
            $ssl = Get-SslCertificateInfo -Host $parsed.Host -Port $parsed.Port
        } else {
            $ssl = [PSCustomObject]@{ IsValidNow = $false; DaysLeft = ''; NotAfterUTC=''; Issuer=''; }
        }

        $httpStatus = if ($http.StatusCode) { [string]$http.StatusCode } else { '' }
        $latency    = $http.LatencyMs
        $sslValid   = [bool]$ssl.IsValidNow
        $daysLeft   = $ssl.DaysLeft
        $notAfter   = if ($ssl.NotAfterUTC) { ([DateTime]$ssl.NotAfterUTC).ToString('yyyy-MM-dd HH:mm:ss') } else { '' }
        $issuer     = $ssl.Issuer
        $msg        = ''
        if (-not $http.Ok) { $msg = "HTTP: $($http.Reason)" }
        if ($ssl.Error) { $msg = ($msg + (if ($msg){' | '}else{''}) + "SSL: $($ssl.Error)") }

        Update-Row -RowIndex $i -HttpStatus $httpStatus -Latency $latency -SslValid $sslValid -DaysLeft $daysLeft -NotAfter $notAfter -Issuer $issuer -Message $msg
        Start-Sleep -Milliseconds 100  # small pause to keep UI smooth
    }
}

# Events
$btnAdd.Add_Click({ Add-UrlRow -Url $txtUrl.Text })
$btnRemove.Add_Click({ Remove-SelectedRow })
$btnCheckNow.Add_Click({ Check-All })
$numInterval.Add_ValueChanged({ $timer.Interval = [int]$numInterval.Value * 1000 })
$btnStart.Add_Click({
    if ($Urls.Count -eq 0 -and $txtUrl.Text) { Add-UrlRow -Url $txtUrl.Text }
    $btnStart.Enabled = $false
    $btnStop.Enabled  = $true
    $timer.Start()
})
$btnStop.Add_Click({
    $timer.Stop()
    $btnStart.Enabled = $true
    $btnStop.Enabled  = $false
})
$timer.Add_Tick({ Check-All })

$btnExport.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "CSV files|*.csv"
    $dlg.FileName = "ssl-uptimer-results.csv"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $lines = @("URL,HTTP,LatencyMs,SSLValid,DaysLeft,ExpiresUTC,Issuer,CheckedAt,Message")
        foreach ($row in $grid.Rows) {
            $vals = @(
                $row.Cells['Url'].Value,
                $row.Cells['HttpStatus'].Value,
                $row.Cells['Latency'].Value,
                $row.Cells['SslValid'].Value,
                $row.Cells['DaysLeft'].Value,
                $row.Cells['NotAfter'].Value,
                $row.Cells['Issuer'].Value,
                $row.Cells['LastChecked'].Value,
                $row.Cells['Message'].Value
            ) | ForEach-Object { [System.Web.HttpUtility]::HtmlEncode([string]$_) -replace ',', ';' } # simple escape
            $lines += ($vals -join ',')
        }
        [IO.File]::WriteAllLines($dlg.FileName, $lines)
        [System.Windows.Forms.MessageBox]::Show("Exported: $($dlg.FileName)")
    }
})

$btnImport.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "CSV files|*.csv"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $lines = [IO.File]::ReadAllLines($dlg.FileName)
            foreach ($line in $lines | Select-Object -Skip 1) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $url = ($line -split ',')[0] -replace ';', ',' # reverse simple escape
                Add-UrlRow -Url $url
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Import failed: $($_.Exception.Message)")
        }
    }
})

# Layout
$form.Controls.AddRange(@($lblUrl,$txtUrl,$btnAdd,$btnRemove,$btnCheckNow,$lblInterval,$numInterval,$btnStart,$btnStop,$btnExport,$btnImport,$grid))

# Seed example
Add-UrlRow -Url "https://example.com"
Add-UrlRow -Url "https://expired.badssl.com"
Add-UrlRow -Url "https://sha256.badssl.com"

[void]$form.ShowDialog()
