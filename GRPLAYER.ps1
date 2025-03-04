[void] [System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')

# Create XAML for GUI
$XAML = @"
<Window xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
        Title=""PowerShell Video Player"" Height=""400"" Width=""600"">
    <Grid>
        <MediaElement Name=""videoPlayer"" Stretch=""Fill"" Grid.Row=""0"" Grid.RowSpan=""2"" LoadedBehavior=""Manual"" />
        <StackPanel Orientation=""Horizontal"" VerticalAlignment=""Bottom"" Background=""Gray"">
            <Button Name=""btnOpen"" Content=""Open"" Width=""80"" />
            <Button Name=""btnPlay"" Content=""Play"" Width=""80"" />
            <Button Name=""btnPause"" Content=""Pause"" Width=""80"" />
            <Button Name=""btnStop"" Content=""Stop"" Width=""80"" />
        </StackPanel>
    </Grid>
</Window>
"@

# Load XAML
$reader = (New-Object System.Xml.XmlNodeReader ((New-Object System.Xml.XmlDocument).LoadXml($XAML)))
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Get Controls
$videoPlayer = $Window.FindName("videoPlayer")
$btnOpen = $Window.FindName("btnOpen")
$btnPlay = $Window.FindName("btnPlay")
$btnPause = $Window.FindName("btnPause")
$btnStop = $Window.FindName("btnStop")

# Open File Dialog to select video file
$btnOpen.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Video Files|*.mp4;*.avi;*.mkv;*.wmv"
    if ($ofd.ShowDialog() -eq 'OK') {
        $videoPlayer.Source = [System.Uri]$ofd.FileName
    }
})

# Play video
$btnPlay.Add_Click({ $videoPlayer.Play() })

# Pause video
$btnPause.Add_Click({ $videoPlayer.Pause() })

# Stop video
$btnStop.Add_Click({ $videoPlayer.Stop() })

# Run GUI
$Window.ShowDialog()
