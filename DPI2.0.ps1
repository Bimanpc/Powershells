﻿Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Data DPI'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

#For High DPI, We Set AutoScaleDimensions and AutoScaleMode
#The reason SizeF is set to 96 is that the standard Windows resolution for the display is 96.
#Maybe you shuld try that All object resets Drawing.Point And Drawing.Size
#In some cases, review the Drawing.Point and Drawing.Size of all objects, depending on the resolution of your display.
$form.AutoScaleDimensions =  New-Object System.Drawing.SizeF(96, 96)
$form.AutoScaleMode  = [System.Windows.Forms.AutoScaleMode]::Dpi

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,220)
$okButton.Size = New-Object System.Drawing.Size(75,50)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,220)
$cancelButton.Size = New-Object System.Drawing.Size(200,50)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(800,40)
$label.Text = 'Please enter the information in the space below:'
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,100)
$textBox.Size = New-Object System.Drawing.Size(800,20)
#For High DPI, We Set Font Size
#$Font = New-Object System.Drawing.Font("Yu Gothic UI",45,([System.Drawing.FontStyle]::Regular),[System.Drawing.GraphicsUnit]::Pixel)
$Font = New-Object System.Drawing.Font("",45,([System.Drawing.FontStyle]::Regular),[System.Drawing.GraphicsUnit]::Pixel)
$textBox.Font =  $Font 

$form.Controls.Add($textBox)

$form.Topmost = $true

$form.Add_Shown({$textBox.Select()})
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $textBox.Text
    $x
}
