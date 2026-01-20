Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net.Security
Add-Type -AssemblyName System.Security

# -----------------------
# Helper Function: SSL Check
# -----------------------
function Get-SSLCertificateInfo {
    param (
        [string]$Host,
        [int]$Port = 443
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient($Host, $Port)
        $sslStream = New-Object System.Net.Security.SslStream(
            $tcpClient.GetStream(),
            $false,
            ({ $true })
        )

        $sslStream.AuthenticateAsClient($Host)
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $sslStream.RemoteCertificate

        $sslStream.Close()
        $tcpClient.Close()

        return [PSCustomObject]@{
            Subject        = $cert.Subject
            Issuer         = $cert.Issuer
            NotBefore      = $cert.NotBefore
            NotAfter       = $cert.NotAfter
            DaysRemaining  = ($cert.NotAfter - (Get-Date)).Days
            Thumbprint     = $cert.Thumbprint
            SignatureAlgo  = $cert.SignatureAlgorithm.FriendlyName
        }
    }
    catch {
        return $null
    }
}

# -----------------------
# GUI Form
# -----------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI SSL Checker (Ethical Security Tool)"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"

# Domain Label
$labelDomain = New-Object System.Windows.Forms.Label
$labelDomain.Text = "Target Domain:"
$labelDomain.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($labelDomain)

# Domain TextBox
$textDomain = New-Object System.Windows.Forms.TextBox
$textDomain.Size = New-Object System.Drawing.Size(400, 20)
$textDomain.Location = New-Object System.Drawing.Point(120, 20)
$form.Controls.Add($textDomain)

# Check Button
$buttonCheck = New-Object System.Windows.Forms.Button
$buttonCheck.Text = "Check SSL"
$buttonCheck.Location = New-Object System.Drawing.Point(120, 55)
$form.Controls.Add($buttonCheck)

# Output Box
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 100)
$outputBox.Size = New-Object System.Drawing.Size(540, 300)
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

# -----------------------
# Button Click Event
# -----------------------
$buttonCheck.Add_Click({
    $outputBox.Clear()
    $domain = $textDomain.Text.Trim()

    if (-not $domain) {
        $outputBox.Text = "Please enter a domain name."
        return
    }

    $outputBox.AppendText("Checking SSL for $domain ...`n`n")

    $result = Get-SSLCertificateInfo -Host $domain

    if ($null -eq $result) {
        $outputBox.AppendText("❌ Failed to retrieve SSL certificate.`n")
        return
    }

    $outputBox.AppendText("✔ SSL Certificate Found`n")
    $outputBox.AppendText("---------------------------`n")
    $outputBox.AppendText("Subject: $($result.Subject)`n")
    $outputBox.AppendText("Issuer: $($result.Issuer)`n")
    $outputBox.AppendText("Valid From: $($result.NotBefore)`n")
    $outputBox.AppendText("Valid Until: $($result.NotAfter)`n")
    $outputBox.AppendText("Days Remaining: $($result.DaysRemaining)`n")
    $outputBox.AppendText("Signature Algorithm: $($result.SignatureAlgo)`n")
    $outputBox.AppendText("Thumbprint: $($result.Thumbprint)`n`n")

    # -----------------------
    # AI / LLM Analysis Placeholder
    # -----------------------
    $outputBox.AppendText("🤖 AI Security Analysis:`n")

    if ($result.DaysRemaining -lt 30) {
        $outputBox.AppendText("⚠ Certificate is close to expiration. Renewal recommended.`n")
    } else {
        $outputBox.AppendText("✔ Certificate validity period looks healthy.`n")
    }

    if ($result.SignatureAlgo -notmatch "sha256") {
        $outputBox.AppendText("⚠ Weak signature algorithm detected.`n")
    } else {
        $outputBox.AppendText("✔ Strong signature algorithm in use.`n")
    }

    $outputBox.AppendText("`n[LLM integration point: Send cert data to AI for deeper risk scoring]`n")
})

# Run Form
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
