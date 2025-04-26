Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Cryptographed Password Manager"
$form.Size = New-Object System.Drawing.Size(400,300)
$form.StartPosition = "CenterScreen"

$labelUsername = New-Object System.Windows.Forms.Label
$labelUsername.Text = "Username:"
$labelUsername.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($labelUsername)

$textBoxUsername = New-Object System.Windows.Forms.TextBox
$textBoxUsername.Location = New-Object System.Drawing.Point(100,20)
$form.Controls.Add($textBoxUsername)

$labelPassword = New-Object System.Windows.Forms.Label
$labelPassword.Text = "Password:"
$labelPassword.Location = New-Object System.Drawing.Point(10,60)
$form.Controls.Add($labelPassword)

$textBoxPassword = New-Object System.Windows.Forms.TextBox
$textBoxPassword.Location = New-Object System.Drawing.Point(100,60)
$form.Controls.Add($textBoxPassword)

$buttonSave = New-Object System.Windows.Forms.Button
$buttonSave.Text = "Save"
$buttonSave.Location = New-Object System.Drawing.Point(100,100)
$buttonSave.Add_Click({ Save-Password })
$form.Controls.Add($buttonSave)

$buttonRetrieve = New-Object System.Windows.Forms.Button
$buttonRetrieve.Text = "Retrieve"
$buttonRetrieve.Location = New-Object System.Drawing.Point(200,100)
$buttonRetrieve.Add_Click({ Retrieve-Password })
$form.Controls.Add($buttonRetrieve)

$labelResult = New-Object System.Windows.Forms.Label
$labelResult.Location = New-Object System.Drawing.Point(10,140)
$labelResult.AutoSize = $true
$form.Controls.Add($labelResult)

$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
