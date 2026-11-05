# Onion SSH Client GUI (PowerShell + Windows Forms)
# Εκπαιδευτικό GUI για σύνδεση SSH μέσω Tor SOCKS5 Proxy (127.0.0.1:9050)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Onion SSH Client"
$form.Size = New-Object System.Drawing.Size(500,320)
$form.StartPosition = "CenterScreen"

# Host
$lblHost = New-Object System.Windows.Forms.Label
$lblHost.Text = "Host:"
$lblHost.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($lblHost)

$txtHost = New-Object System.Windows.Forms.TextBox
$txtHost.Location = New-Object System.Drawing.Point(120,20)
$txtHost.Width = 300
$form.Controls.Add($txtHost)

# Port
$lblPort = New-Object System.Windows.Forms.Label
$lblPort.Text = "Port:"
$lblPort.Location = New-Object System.Drawing.Point(20,60)
$form.Controls.Add($lblPort)

$txtPort = New-Object System.Windows.Forms.TextBox
$txtPort.Location = New-Object System.Drawing.Point(120,60)
$txtPort.Width = 80
$txtPort.Text = "22"
$form.Controls.Add($txtPort)

# Username
$lblUser = New-Object System.Windows.Forms.Label
$lblUser.Text = "Username:"
$lblUser.Location = New-Object System.Drawing.Point(20,100)
$form.Controls.Add($lblUser)

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Location = New-Object System.Drawing.Point(120,100)
$txtUser.Width = 200
$form.Controls.Add($txtUser)

# Connect Button
$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Connect"
$btnConnect.Location = New-Object System.Drawing.Point(120,140)
$form.Controls.Add($btnConnect)

# Terminal Output
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Location = New-Object System.Drawing.Point(20,180)
$outputBox.Size = New-Object System.Drawing.Size(440,80)
$form.Controls.Add($outputBox)

$btnConnect.Add_Click({

    $hostName = $txtHost.Text
    $port = $txtPort.Text
    $user = $txtUser.Text

    if (:IsNullOrWhiteSpace($hostName)) {
        [System.Windows.Forms.MessageBox]::Show("Enter host name")
        return
    }

    $outputBox.AppendText("Launching SSH connection...`r`n")

    # Requires OpenSSH client installed on Windows
    # Uses Tor SOCKS proxy on localhost:9050
    $sshCmd = "ssh.exe -o ProxyCommand=`"ncat --proxy 127.0.0.1:9050 --proxy-type socks5 %h %p`" $user@$hostName -p $port"

    $outputBox.AppendText($sshCmd + "`r`n")

    try {
        Start-Process powershell `
            -ArgumentList "-NoExit","-Command",$sshCmd
    }
    catch {
        $outputBox.AppendText("Error: $($_.Exception.Message)`r`n")
    }
})

[void]$form.ShowDialog()
