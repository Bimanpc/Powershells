# Load necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Speech

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI Text-to-Speech App"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter text to convert to speech:"
$label.Size = New-Object System.Drawing.Size(200, 20)
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

# Create a text box
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(360, 20)
$textBox.Location = New-Object System.Drawing.Point(10, 50)
$form.Controls.Add($textBox)

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Speak"
$button.Size = New-Object System.Drawing.Size(75, 23)
$button.Location = New-Object System.Drawing.Point(160, 90)
$form.Controls.Add($button)

# Add event handler for the button click
$button.Add_Click({
    # Get the text from the text box
    $text = $textBox.Text

    # Create a SpeechSynthesizer object
    $speechSynthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer

    # Speak the text
    $speechSynthesizer.Speak($text)
})

# Show the form
$form.Add_Shown({$textBox.Focus()})
[void] $form.ShowDialog()
