# Load the required assemblies
Add-Type -AssemblyName PresentationFramework

# Create a new WPF window
$window = New-Object Windows.Window
$window.Title = "RightOne Maker"
$window.Width = 400
$window.Height = 300

# Create a StackPanel to hold the controls
$stackPanel = New-Object Windows.Controls.StackPanel

# Create a TextBox
$textBox = New-Object Windows.Controls.TextBox
$textBox.Width = 200
$textBox.Height = 30
$textBox.Margin = "10"
$stackPanel.Children.Add($textBox)

# Create a Button
$button = New-Object Windows.Controls.Button
$button.Content = "Make RightOne"
$button.Width = 100
$button.Height = 30
$button.Margin = "10"
$button.Add_Click({
    # Define what happens when the button is clicked
    $message = "RightOne Made: " + $textBox.Text
    [Windows.MessageBox]::Show($message, "Success", "OK", "Information")
})
$stackPanel.Children.Add($button)

# Add the StackPanel to the window
$window.Content = $stackPanel

# Show the window
$window.ShowDialog()
