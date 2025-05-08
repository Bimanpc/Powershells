Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ancient Greek Keyboard"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"

# Create a textbox to display the typed characters
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.Size = New-Object System.Drawing.Size(550, 100)
$textBox.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($textBox)

# Define the Ancient Greek characters
$ancientGreekChars = @(
    "Α", "Β", "Γ", "Δ", "Ε", "Ζ", "Η", "Θ", "Ι", "Κ", "Λ", "Μ",
    "Ν", "Ξ", "Ο", "Π", "Ρ", "Σ", "Τ", "Υ", "Φ", "Χ", "Ψ", "Ω"
)

# Create buttons for each character
$buttonSize = New-Object System.Drawing.Size(50, 50)
$buttonMargin = 10
$buttonStartX = 20
$buttonStartY = 140

for ($i = 0; $i -lt $ancientGreekChars.Length; $i++) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $ancientGreekChars[$i]
    $button.Size = $buttonSize
    $button.Location = New-Object System.Drawing.Point(
        $buttonStartX + ($buttonMargin + $buttonSize.Width) * ($i % 8),
        $buttonStartY + ($buttonMargin + $buttonSize.Height) * [math]::Floor($i / 8)
    )

    $button.Add_Click({
        $textBox.Text += $this.Text
    })

    $form.Controls.Add($button)
}

# Show the form
$form.ShowDialog()
