#requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net.Http

function Get-SslScanPath {
    $candidates = @(
        "sslscan.exe",
        "$env:ProgramFiles\sslscan\sslscan.exe",
        "$env:ProgramFiles(x86)\sslscan\sslscan.exe"
    )
    foreach ($c in $candidates) {
        try {
            $p = (Get-Command $c -ErrorAction SilentlyContinue)?.Source
            if ($p) { return $p }
            if (Test-Path $c) { return (Resolve-Path $c).Path }
        } catch {}
    }
    return $null
}

function Test-TlsHandshake {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Host,
        [Parameter(Mandatory)][int]$Port,
        [ValidateSet('Tls','Tls11','Tls12','Tls13')]
        [string[]]$Protocols = @('Tls12','Tls13'),
        [int]$TimeoutMs = 8000
    )
    $results = @()

    foreach ($p in $Protocols) {
        # Map to [System.Security.Authentication.SslProtocols]
        $sslProto = switch ($p) {
            'Tls'   { [System.Security.Authentication.SslProtocols]::Tls }
            'Tls11' { [System.Security.Authentication.SslProtocols]::Tls11 }
            'Tls12' { [System.Security.Authentication.SslProtocols]::Tls12 }
            'Tls13' {
                # .NET Framework (PS 5.1) doesn't support TLS 1.3; .NET 5+ (PS 7+) does.
                if ([Enum]::GetNames([System.Security.Authentication.SslProtocols]) -contains 'Tls13') {
                    [System.Security.Authentication.SslProtocols]::Tls13
                } else {
                    $results += [pscustomobject]@{
                        Host       = $Host
                        Port       = $Port
                        Attempt    = 'Tls13'
                        Success    = $false
                        Error      = 'TLS1.3 not supported on this runtime'
                        Protocol   = $null
                        Cipher     = $null
                        Hash       = $null
                        KeyExchange= $null
                        Bits       = $null
                        CertSubject= $null
                        CertIssuer = $null
                        CertNotBefore = $null
                        CertNotAfter  = $null
                        CertThumbprint= $null
                        SANs       = $null
                    }
                    continue
                }
            }
        }

        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $cToken = New-Object System.Threading.CancellationTokenSource($TimeoutMs)
            $connectTask = $client.ConnectAsync($Host, $Port)
            $null = $connectTask.Wait($TimeoutMs)
            if (-not $client.Connected) { throw "Connect timeout after ${TimeoutMs}ms" }

            $stream = $client.GetStream()
            $sslStream = New-Object System.Net.Security.SslStream($stream, $false)
            # Authenticate
            $sslStream.AuthenticateAsClient($Host, $null, $sslProto, $false)

            $cert = $sslStream.RemoteCertificate
            $cert2 = if ($cert -is [System.Security.Cryptography.X509Certificates.X509Certificate2]) {
                $cert
            } else {
                New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cert)
            }

            # Parse SANs (if present)
            $SANs = @()
            try {
                $ext = $cert2.Extensions | Where-Object { $_.Oid.FriendlyName -eq 'Subject Alternative Name' -or $_.Oid.Value -eq '2.5.29.17' }
                if ($ext) {
                    $data = $ext.Format($true)
                    # Rough parse for DNS Names
                    $SANs = ($data -split "`r?`n") | ForEach-Object {
                        if ($_ -match 'DNS Name=(.+)$') { $Matches[1].Trim() }
                    }
                }
            } catch {}

            $results += [pscustomobject]@{
                Host       = $Host
                Port       = $Port
                Attempt    = $p
                Success    = $true
                Error      = $null
                Protocol   = $sslStream.SslProtocol.ToString()
                Cipher     = $sslStream.CipherAlgorithm.ToString()
                Hash       = $sslStream.HashAlgorithm.ToString()
                KeyExchange= $sslStream.KeyExchangeAlgorithm.ToString()
                Bits       = $sslStream.CipherStrength
                CertSubject= $cert2.Subject
                CertIssuer = $cert2.Issuer
                CertNotBefore = $cert2.NotBefore
                CertNotAfter  = $cert2.NotAfter
                CertThumbprint= $cert2.Thumbprint
                SANs       = ($SANs -join ', ')
            }

            $sslStream.Close()
            $stream.Close()
        } catch {
            $results += [pscustomobject]@{
                Host       = $Host
                Port       = $Port
                Attempt    = $p
                Success    = $false
                Error      = $_.Exception.Message
                Protocol   = $null
                Cipher     = $null
                Hash       = $null
                KeyExchange= $null
                Bits       = $null
                CertSubject= $null
                CertIssuer = $null
                CertNotBefore = $null
                CertNotAfter  = $null
                CertThumbprint= $null
                SANs       = $null
            }
        } finally {
            try { $client.Close() } catch {}
        }
    }

    return $results
}

function Invoke-ExternalSslscan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Host,
        [Parameter(Mandatory)][int]$Port,
        [switch]$XmlOut,
        [string]$XmlFile = (Join-Path $env:TEMP "sslscan_$([Guid]::NewGuid().ToString('n')).xml")
    )

    $args = @("$Host`:$Port", "--no-colour")
    if ($XmlOut) { $args += @("--xml=$XmlFile") }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Path
    $psi.Arguments = ($args -join ' ')
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    return [pscustomobject]@{
        StdOut = $stdout
        StdErr = $stderr
        ExitCode = $proc.ExitCode
        XmlFile = if ($XmlOut) { $XmlFile } else { $null }
    }
}

# Build GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "SSL/TLS Scanner"
$form.Size = New-Object System.Drawing.Size(900,600)
$form.StartPosition = 'CenterScreen'

$lblHost = New-Object System.Windows.Forms.Label
$lblHost.Text = "Host"
$lblHost.Location = '10,10'
$lblHost.AutoSize = $true

$txtHost = New-Object System.Windows.Forms.TextBox
$txtHost.Location = '60,8'
$txtHost.Size = New-Object System.Drawing.Size(250,22)
$txtHost.Text = "example.com"

$lblPort = New-Object System.Windows.Forms.Label
$lblPort.Text = "Port"
$lblPort.Location = '330,10'
$lblPort.AutoSize = $true

$txtPort = New-Object System.Windows.Forms.NumericUpDown
$txtPort.Location = '370,8'
$txtPort.Minimum = 1
$txtPort.Maximum = 65535
$txtPort.Value = 443

$grpProto = New-Object System.Windows.Forms.GroupBox
$grpProto.Text = "Protocols to test"
$grpProto.Location = '10,40'
$grpProto.Size = New-Object System.Drawing.Size(420,70)

$chkTls  = New-Object System.Windows.Forms.CheckBox
$chkTls.Text = "TLS 1.0"
$chkTls.Location = '10,20'
$chkTls.Checked = $false

$chkTls11 = New-Object System.Windows.Forms.CheckBox
$chkTls11.Text = "TLS 1.1"
$chkTls11.Location = '110,20'
$chkTls11.Checked = $false

$chkTls12 = New-Object System.Windows.Forms.CheckBox
$chkTls12.Text = "TLS 1.2"
$chkTls12.Location = '210,20'
$chkTls12.Checked = $true

$chkTls13 = New-Object System.Windows.Forms.CheckBox
$chkTls13.Text = "TLS 1.3"
$chkTls13.Location = '310,20'
$chkTls13.Checked = $true

$grpProto.Controls.AddRange(@($chkTls,$chkTls11,$chkTls12,$chkTls13))

$chkUseSslscan = New-Object System.Windows.Forms.CheckBox
$chkUseSslscan.Text = "Use sslscan if available (full cipher enumeration)"
$chkUseSslscan.Location = '10,120'
$chkUseSslscan.AutoSize = $true
$chkUseSslscan.Checked = $true

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "Scan"
$btnScan.Location = '10,150'
$btnScan.Size = New-Object System.Drawing.Size(100,30)

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export JSON"
$btnExport.Location = '120,150'
$btnExport.Size = New-Object System.Drawing.Size(120,30)
$btnExport.Enabled = $false

$txtOut = New-Object System.Windows.Forms.TextBox
$txtOut.Location = '10,190'
$txtOut.Size = New-Object System.Drawing.Size(860,360)
$txtOut.Multiline = $true
$txtOut.ScrollBars = 'Both'
$txtOut.Font = New-Object System.Drawing.Font('Consolas', 9)
$txtOut.ReadOnly = $true

$form.Controls.AddRange(@($lblHost,$txtHost,$lblPort,$txtPort,$grpProto,$chkUseSslscan,$btnScan,$btnExport,$txtOut))

$global:lastJson = $null

$btnScan.Add_Click({
    $host = $txtHost.Text.Trim()
    $port = [int]$txtPort.Value

    if ([string]::IsNullOrWhiteSpace($host)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a host.","Input required",'OK','Warning') | Out-Null
        return
    }

    $txtOut.Text = "Scanning $host:$port ...`r`n"
    $useExt = $chkUseSslscan.Checked
    $sslscanPath = if ($useExt) { Get-SslScanPath } else { $null }

    if ($useExt -and $sslscanPath) {
        $txtOut.AppendText("Running sslscan at: $sslscanPath`r`n")
        $res = Invoke-ExternalSslscan -Path $sslscanPath -Host $host -Port $port -XmlOut
        if ($res.ExitCode -ne 0) {
            $txtOut.AppendText("sslscan error (exit $($res.ExitCode)):`r`n$($res.StdErr)`r`n")
        } else {
            $txtOut.AppendText("sslscan output:`r`n$($res.StdOut)`r`n")
            if ($res.XmlFile) {
                $txtOut.AppendText("XML saved to: $($res.XmlFile)`r`n")
            }
        }
    } elseif ($useExt) {
        $txtOut.AppendText("sslscan not found on PATH. Proceeding with native probes.`r`n")
    }

    $protos = @()
    if ($chkTls.Checked)   { $protos += 'Tls' }
    if ($chkTls11.Checked) { $protos += 'Tls11' }
    if ($chkTls12.Checked) { $protos += 'Tls12' }
    if ($chkTls13.Checked) { $protos += 'Tls13' }
    if ($protos.Count -eq 0) { $protos = @('Tls12','Tls13') }

    $txtOut.AppendText("Native handshake tests: $($protos -join ', ')`r`n`r`n")

    $data = Test-TlsHandshake -Host $host -Port $port -Protocols $protos
    $global:lastJson = $data | ConvertTo-Json -Depth 4

    foreach ($row in $data) {
        $txtOut.AppendText( ("[{0}:{1} {2}] Success={3} {4}`r`n" -f $row.Host,$row.Port,$row.Attempt,$row.Success, (if($row.Error){ "Error=$($row.Error)" } else { "" })) )
        if ($row.Success) {
            $txtOut.AppendText( ("  Negotiated: {0} | Cipher={1}({2} bits) Hash={3} Kx={4}`r`n" -f $row.Protocol,$row.Cipher,$row.Bits,$row.Hash,$row.KeyExchange) )
            $txtOut.AppendText( ("  Cert: Subject={0}`r`n        Issuer={1}`r`n        Valid={2} .. {3}`r`n        Thumbprint={4}`r`n        SANs={5}`r`n" -f $row.CertSubject,$row.CertIssuer,$row.CertNotBefore,$row.CertNotAfter,$row.CertThumbprint,$row.SANs) )
        }
        $txtOut.AppendText("`r`n")
    }

    $btnExport.Enabled = $true
})

$btnExport.Add_Click({
    if (-not $global:lastJson) {
        [System.Windows.Forms.MessageBox]::Show("No results to export yet.","Export",'OK','Information') | Out-Null
        return
    }
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*"
    $sfd.FileName = "tls-scan-$([DateTime]::Now.ToString('yyyyMMdd-HHmmss')).json"
    if ($sfd.ShowDialog() -eq 'OK') {
        Set-Content -Path $sfd.FileName -Value $global:lastJson -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Saved: $($sfd.FileName)","Export",'OK','Information') | Out-Null
    }
})

[void]$form.ShowDialog()
