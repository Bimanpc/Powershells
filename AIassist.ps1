Add-Type -AssemblyName PresentationFramework

# Create a new WPF Window
$window = New-Object System.Windows.Window
$window.Title = "AI Assistant"
$window.Width = 400
$window.Height = 200

# Create a StackPanel to arrange elements vertically
$stackPanel = New-Object System.Windows.Controls.StackPanel
$stackPanel.Orientation = "Vertical"

# Create a TextBox for user input
$textBox = New-Object System.Windows.Controls.TextBox
$textBox.Margin = "10"
$stackPanel.Children.Add($textBox)

# Create a Button
$button = New-Object System.Windows.Controls.Button
$button.Content = "Submit"
$button.Margin = "10"
$stackPanel.Children.Add($button)

# Define button click event
$button.Add_Click({
    $userInput = $textBox.Text
    [System.Windows.MessageBox]::Show("You entered: $userInput", "User Input")
})

# Set the Content of the Window to the StackPanel
$window.Content = $stackPanel

# Show the Window
$window.ShowDialog()
