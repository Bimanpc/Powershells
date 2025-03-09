Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a new form (window)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Great Orthodox Lent"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedSingle'

# Add a label with the message
$label = New-Object System.Windows.Forms.Label
$label.Text = "Happy Great Orthodox Lent!"
$label.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(90, 50)
$form.Controls.Add($label)

# Add an image (optional)
$imagePath = "C:\Path\To\OrthodoxLentImage.jpg"  # Change this to the actual image path
if (Test-Path $imagePath) {
    $pictureBox = New-Object System.Windows.Forms.PictureBox
    $pictureBox.Image = [System.Drawing.Image]::FromFile($imagePath)
    $pictureBox.SizeMode = "StretchImage"
    $pictureBox.Size = New-Object System.Drawing.Size(200, 150)
    $pictureBox.Location = New-Object System.Drawing.Point(100, 80)
    $form.Controls.Add($pictureBox)
}

# Add a close button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Close"
$button.Size = New-Object System.Drawing.Size(80, 30)
$button.Location = New-Object System.Drawing.Point(150, 240)
$button.Add_Click({ $form.Close() })
$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
