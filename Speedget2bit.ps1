# Import the required module for WPF
Add-Type -AssemblyName PresentationFramework

# Create the Window
$window = New-Object system.windows.window
$window.Title = "Network Speed Booster"
$window.Width = 300
$window.Height = 200

# Create a Grid to hold the UI elements
$grid = New-Object System.Windows.Controls.Grid
$window.Content = $grid

# Create a TextBlock for instructions
$instructions = New-Object System.Windows.Controls.TextBlock
$instructions.Text = "Click 'Boost' to optimize network settings."
$instructions.Margin = "10"
$instructions.VerticalAlignment = "Top"
$instructions.HorizontalAlignment = "Center"
$grid.Children.Add($instructions)

# Create a Button to perform the network optimization
$boostButton = New-Object System.Windows.Controls.Button
$boostButton.Content = "Boost"
$boostButton.Margin = "10"
$boostButton.VerticalAlignment = "Center"
$boostButton.HorizontalAlignment = "Center"
$boostButton.Width = 100
$grid.Children.Add($boostButton)

# Create a TextBlock for status messages
$status = New-Object System.Windows.Controls.TextBlock
$status.Text = ""
$status.Margin = "10"
$status.VerticalAlignment = "Bottom"
$status.HorizontalAlignment = "Center"
$grid.Children.Add($status)

# Define the function to optimize network settings
function Optimize-Network {
    # Example optimization settings
    Write-Output "Optimizing network settings..."

    # TCP Optimizations
    netsh int tcp set global autotuninglevel=normal
    netsh int tcp set global chimney=enabled
    netsh int tcp set global dca=enabled
    netsh int tcp set global netdma=enabled
    netsh int tcp set global ecncapability=disabled
    netsh int tcp set global congestionprovider=ctcp

    Write-Output "Network settings optimized."
}

# Define the event handler for the button click
$boostButton.Add_Click({
    $status.Text = "Optimizing..."
    Optimize-Network
    $status.Text = "Network optimized successfully."
})

# Show the Window
$window.ShowDialog()
