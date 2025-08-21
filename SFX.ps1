Add-Type -AssemblyName PresentationFramework

# Create Window
$Window = New-Object Windows.Window
$Window.Title = "SFX Maker"
$Window.Width = 400
$Window.Height = 250
$Window.WindowStartupLocation = "CenterScreen"

# Create a Grid
$Grid = New-Object Windows.Controls.Grid
$Grid.Margin = '10'

# Define Rows
for ($i=0; $i -lt 4; $i++) {
    $Row = New-Object Windows.Controls.RowDefinition
    $Row.Height = "Auto"
    $Grid.RowDefinitions.Add($Row)
}

# Source File Selection
$lblSource = New-Object Windows.Controls.Label
$lblSource.Content = "Select Source File:"
$Grid.AddChild($lblSource)
[Windows.Controls.Grid]::SetRow($lblSource, 0)

$btnSource = New-Object Windows.Controls.Button
$btnSource.Content = "Browse..."
$btnSource.Margin = "0,5,0,5"
$btnSource.Add_Click({
    $ofd = New-Object Windows.Forms.OpenFileDialog
    $ofd.Filter = "All files (*.*)|*.*"
    if ($ofd.ShowDialog() -eq "OK") {
        $lblSource.Content = "Source: " + $ofd.FileName
    }
})
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[Windows.Controls.Grid]::SetRow($btnSource, 1)
$Grid.AddChild($btnSource)

# Output Folder Selection
$lblOutput = New-Object Windows.Controls.Label
$lblOutput.Content = "Select Output Folder:"
[Windows.Controls.Grid]::SetRow($lblOutput, 2)
$Grid.AddChild($lblOutput)

$btnOutput = New-Object Windows.Controls.Button
$btnOutput.Content = "Browse..."
$btnOutput.Margin = "0,5,0,5"
$btnOutput.Add_Click({
    $fbd = New-Object Windows.Forms.FolderBrowserDialog
    if ($fbd.ShowDialog() -eq "OK") {
        $lblOutput.Content = "Output: " + $fbd.SelectedPath
    }
})
[Windows.Controls.Grid]::SetRow($btnOutput, 3)
$Grid.AddChild($btnOutput)

# Build SFX Button
$btnBuild = New-Object Windows.Controls.Button
$btnBuild.Content = "Build SFX"
$btnBuild.Margin = "0,10,0,0"
$btnBuild.HorizontalAlignment = "Center"
$btnBuild.Add_Click({
    [System.Windows.MessageBox]::Show("This is where your SFX creation logic will run.")
})
$RowBuild = New-Object Windows.Controls.RowDefinition
$RowBuild.Height = "Auto"
$Grid.RowDefinitions.Add($RowBuild)
[Windows.Controls.Grid]::SetRow($btnBuild, 4)
$Grid.AddChild($btnBuild)

$Window.Content = $Grid
$Window.ShowDialog()
