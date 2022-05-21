[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$inputform = New-Object System.Windows.Forms.Form
$inputform.Text = "Vasilis text box input"
$inputform.Size = New-Object System.Drawing.Size(300,300)
$inputform.StartPosition = "CenterScreen"
$OKB = New-Object System.Windows.Forms.Button
$OKB.Location = New-Object System.Drawing.Size(65,120)
$OKB.Size = New-Object System.Drawing.Size(65,23)
$OKB.Text = "Submit"
$OKB.Add_Click({Write-Host "Entered value..."$OTB.Text -ForegroundColor Green;$inputform.Close()})
$inputform.Controls.Add($OKB)
$CAB = New-Object System.Windows.Forms.Button
$CAB.Location = New-Object System.Drawing.Size(140,120)
$CAB.Size = New-Object System.Drawing.Size(65,23)
$CAB.Text = "Clear"
$CAB.Add_Click({Write-Host "No input" -ForegroundColor Red;$inputform.Close()})
$inputform.Controls.Add($CAB)
$Lbl = New-Object System.Windows.Forms.Label
$Lbl.Location = New-Object System.Drawing.Size(10,20)
$Lbl.Size = New-Object System.Drawing.Size(260,20)
$Lbl.Text = "Please provide a value"
$inputform.Controls.Add($Lbl)
$OTB = New-Object System. .Forms.TextBox
$OTB.Location = New-Object System.Drawing.Size(10,50)
$OTB.Size = New-Object System.Drawing.Size(240,20)
$inputform.Controls.Add($OTB)
$inputform.Topmost = $True
$inputform.Add_Shown({$inputform.Activate()})
[void] $inputform.ShowDialog()