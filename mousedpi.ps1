Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text = "Mouse DPI Changer"
$form.Size = New-Object Drawing.Size(300,200)

$button = New-Object Windows.Forms.Button
$button.Text = "Change DPI"
$button.Size = New-Object Drawing.Size(100,30)
$button.Location = New-Object Drawing.Point(100,80)
$button.Add_Click({
    # Call the function to change DPI
    Change-MouseDPI
})

$form.Controls.Add($button)
$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
