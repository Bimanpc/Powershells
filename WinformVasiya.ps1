Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell Vasiya GUI"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

$button = New-Object System.Windows.Forms.Button
$button.Text = "Click Me!!!"
$button.Location = New-Object System.Drawing.Point(100, 70)

$button.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Button clicked!", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

$form.Controls.Add($button)

$form.ShowDialog()
