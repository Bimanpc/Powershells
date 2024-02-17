Add-Type -AssemblyName System.Windows.Forms

$Form = New-Object system.Windows.Forms.Form
$Form.Text = "Windows Version"
$Form.TopMost = $true

$Label = New-Object System.Windows.Forms.Label
$Label.Text = (Get-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion" -Name ProductName).ProductName
$Label.AutoSize = $true

$Form.Controls.Add($Label)

[void]$Form.ShowDialog()
