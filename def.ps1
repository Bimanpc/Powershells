# Import .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Speech

# Create the form and its controls
$form = New-Object System.Windows.Forms.Form
$form.Text = "Deaf Support App"
$form.Size = New-Object System.Drawing.Size(400,300)

$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter text:"
$label.Location = New-Object System.Drawing.Point(10,20)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(360,20)
$textBox.Location = New-Object System.Drawing.Point(10,50)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Speak"
$button.Location = New-Object System.Drawing.Point(150,100)

# Add controls to the form
$form.Controls.Add($label)
$form.Controls.Add($textBox)
$form.Controls.Add($button)

# Define the button click event
$button.Add_Click({
    $text = $textBox.Text
    $speech = New-Object -ComObject SAPI.SPVoice
    $speech.Speak($text)
})

# Run the form
[System.Windows.Forms.Application]::Run($form)
