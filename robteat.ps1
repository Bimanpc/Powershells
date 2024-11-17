# Import required .NET assembly for GUI
Add-Type -AssemblyName PresentationFramework

# Create the GUI window
$window = New-Object System.Windows.Window
$window.Title = "Robot Controller"
$window.Width = 400
$window.Height = 300
$window.ResizeMode = "NoResize"

# Create a Grid layout for buttons
$grid = New-Object System.Windows.Controls.Grid
$window.Content = $grid

# Add rows and columns to the grid
for ($i = 0; $i -lt 3; $i++) {
    $rowDef = New-Object System.Windows.Controls.RowDefinition
    $grid.RowDefinitions.Add($rowDef)
}
for ($j = 0; $j -lt 3; $j++) {
    $colDef = New-Object System.Windows.Controls.ColumnDefinition
    $grid.ColumnDefinitions.Add($colDef)
}

# Add a TextBox to display the robot's status
$statusBox = New-Object System.Windows.Controls.TextBox
$statusBox.Text = "Status: Idle"
$statusBox.Margin = "10"
$statusBox.IsReadOnly = $true
$statusBox.HorizontalAlignment = "Stretch"
$statusBox.VerticalAlignment = "Bottom"
[System.Windows.Controls.Grid]::SetRow($statusBox, 2)
[System.Windows.Controls.Grid]::SetColumnSpan($statusBox, 3)
$grid.Children.Add($statusBox)

# Function to handle button clicks
function On-ButtonClick {
    param ($action)
    $statusBox.Text = "Status: $action"
    # Add logic here to send commands to the robot
    Write-Output "Robot action: $action"
}

# Create buttons for movement
$actions = @{
    "Forward"  = [0, 1]
    "Left"     = [1, 0]
    "Stop"     = [1, 1]
    "Right"    = [1, 2]
    "Backward" = [2, 1]
}

foreach ($action in $actions.Keys) {
    $button = New-Object System.Windows.Controls.Button
    $button.Content = $action
    $button.Margin = "10"
    $button.HorizontalAlignment = "Center"
    $button.VerticalAlignment = "Center"
    $button.Add_Click({ On-ButtonClick $action })

    $pos = $actions[$action]
    [System.Windows.Controls.Grid]::SetRow($button, $pos[0])
    [System.Windows.Controls.Grid]::SetColumn($button, $pos[1])
    $grid.Children.Add($button)
}

# Show the GUI window
$window.ShowDialog()
