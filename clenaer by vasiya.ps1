Add-Type -AssemblyName System.Windows.Forms

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Cache Clearing GUI 2.0"
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = "CenterScreen"

# Create a button to trigger cache clearing
$button = New-Object System.Windows.Forms.Button
$button.Text = "Clear Cache"
$button.Size = New-Object System.Drawing.Size(100,40)
$button.Location = New-Object System.Drawing.Point(100, 70)
$button.Add_Click({
    # Add your cache clearing logic here
    # This is where you would implement the cache clearing action
    # This is just a placeholder message to demonstrate the button click
    [System.Windows.Forms.MessageBox]::Show("Cache cleared!")
})

# Add the button to the form
$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
