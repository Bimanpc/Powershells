Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Easter Celebration"
$form.Size = New-Object System.Drawing.Size(400,300)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "Fixed3D"
$form.MaximizeBox = $false

# Add an Easter image
$image = [System.Drawing.Image]::FromFile("easter_image.jpg")
$picturebox = New-Object Windows.Forms.PictureBox
$picturebox.Image = $image
$picturebox.SizeMode = "StretchImage"
$picturebox.Size = New-Object Drawing.Size(300, 200)
$picturebox.Location = New-Object Drawing.Point(50, 30)
$form.Controls.Add($picturebox)

# Add an Easter greeting label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Happy Easter!"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(150, 250)
$form.Controls.Add($label)

# Run the form
$form.ShowDialog() | Out-Null
