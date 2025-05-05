Add-Type -AssemblyName PresentationFramework

# Define the XAML for the GUI
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Simple Video Editor" Height="300" Width="400">
    <Grid>
        <Button Name="SelectVideoButton" Content="Select Video" HorizontalAlignment="Left" VerticalAlignment="Top" Width="100" Margin="10" />
        <TextBox Name="VideoPathTextBox" HorizontalAlignment="Left" VerticalAlignment="Top" Width="250" Margin="120,10,0,0" Height="23" />
        <Button Name="TrimVideoButton" Content="Trim Video" HorizontalAlignment="Left" VerticalAlignment="Top" Width="100" Margin="10,50,0,0" />
        <Label Content="Start Time (seconds):" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,90,0,0" />
        <TextBox Name="StartTimeTextBox" HorizontalAlignment="Left" VerticalAlignment="Top" Width="50" Margin="130,90,0,0" />
        <Label Content="End Time (seconds):" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,120,0,0" />
        <TextBox Name="EndTimeTextBox" HorizontalAlignment="Left" VerticalAlignment="Top" Width="50" Margin="130,120,0,0" />
    </Grid>
</Window>
"@

# Create a reader to read the XAML
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get the controls
$selectVideoButton = $window.FindName("SelectVideoButton")
$videoPathTextBox = $window.FindName("VideoPathTextBox")
$trimVideoButton = $window.FindName("TrimVideoButton")
$startTimeTextBox = $window.FindName("StartTimeTextBox")
$endTimeTextBox = $window.FindName("EndTimeTextBox")

# Define the event handler for the Select Video button
$selectVideoButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Video Files (*.mp4;*.avi;*.mov)|*.mp4;*.avi;*.mov|All Files (*.*)|*.*"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $videoPathTextBox.Text = $openFileDialog.FileName
    }
})

# Define the event handler for the Trim Video button
$trimVideoButton.Add_Click({
    $videoPath = $videoPathTextBox.Text
    $startTime = [int]$startTimeTextBox.Text
    $endTime = [int]$endTimeTextBox.Text

    if (-not $videoPath -or -not $startTime -or -not $endTime) {
        [System.Windows.MessageBox]::Show("Please provide all required information.", "Error", "OK", "Error")
        return
    }

    # Here you would call an external tool or library to trim the video
    # For example, using FFmpeg:
    # ffmpeg -i input.mp4 -ss $startTime -to $endTime -c copy output.mp4

    [System.Windows.MessageBox]::Show("Video trimmed successfully!", "Success", "OK", "Information")
})

# Show the window
$window.ShowDialog() | Out-Null
