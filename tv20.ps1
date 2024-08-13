# Load the required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Simple TV Player"
$form.Size = New-Object System.Drawing.Size(400, 200)

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter Stream URL:"
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

# Create a textbox for URL input
$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Size = New-Object System.Drawing.Size(250, 20)
$textbox.Location = New-Object System.Drawing.Point(120, 20)
$form.Controls.Add($textbox)

# Create a button to play the stream
$button = New-Object System.Windows.Forms.Button
$button.Text = "Play"
$button.Location = New-Object System.Drawing.Point(150, 60)
$form.Controls.Add($button)

# Add event handler for the button click
$button.Add_Click({
    $url = $textbox.Text
    if ($url) {
        Start-Process "vlc.exe" $url
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid URL.")
    }
})

# Show the form
$form.ShowDialog()
