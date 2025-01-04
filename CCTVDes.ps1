Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'CCTV Design App'
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = 'CenterScreen'

# Create Labels
$label1 = New-Object System.Windows.Forms.Label
$label1.Text = 'Camera Name'
$label1.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label1)

$label2 = New-Object System.Windows.Forms.Label
$label2.Text = 'Location'
$label2.Location = New-Object System.Drawing.Point(10, 60)
$form.Controls.Add($label2)

# Create TextBoxes
$textBox1 = New-Object System.Windows.Forms.TextBox
$textBox1.Location = New-Object System.Drawing.Point(120, 20)
$form.Controls.Add($textBox1)

$textBox2 = New-Object System.Windows.Forms.TextBox
$textBox2.Location = New-Object System.Drawing.Point(120, 60)
$form.Controls.Add($textBox2)

# Create Button
$button = New-Object System.Windows.Forms.Button
$button.Text = 'Add Camera'
$button.Location = New-Object System.Drawing.Point(10, 100)
$button.Add_Click({
    $cameraName = $textBox1.Text
    $cameraLocation = $textBox2.Text
    [System.Windows.Forms.MessageBox]::Show("Camera '$cameraName' added at '$cameraLocation'")
})
$form.Controls.Add($button)

# Show Form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
