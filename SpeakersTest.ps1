Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Speaker Test"
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = "CenterScreen"

# Create button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Play Test Sound"
$button.Size = New-Object System.Drawing.Size(200,40)
$button.Location = New-Object System.Drawing.Point(50,50)
$button.Add_Click({
    # Function to play test sound
    Function Play-TestSound {
        $soundFile = "C:\Windows\Media\Windows Notify System Generic.wav"
        $sound = New-Object System.Media.SoundPlayer $soundFile
        $sound.Play()
    }

    # Call the function to play the test sound
    Play-TestSound
})

# Add button to the form
$form.Controls.Add($button)

# Show the form
[Windows.Forms.Application]::Run($form)
