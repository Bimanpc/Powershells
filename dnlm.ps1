# Import necessary assemblies
Add-Type -AssemblyName PresentationFramework

# Define the XAML for the GUI
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Download Manager 2.0 " Height="200" Width="400">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        
        <TextBlock Grid.Row="0" Grid.Column="0" Margin="5" VerticalAlignment="Center">URL:</TextBlock>
        <TextBox Name="UrlTextBox" Grid.Row="0" Grid.Column="1" Margin="5"/>

        <TextBlock Grid.Row="1" Grid.Column="0" Margin="5" VerticalAlignment="Center">Destination Path:</TextBlock>
        <TextBox Name="PathTextBox" Grid.Row="1" Grid.Column="1" Margin="5"/>
        <Button Name="BrowseButton" Grid.Row="1" Grid.Column="2" Margin="5" Width="75">Browse...</Button>

        <Button Name="DownloadButton" Grid.Row="2" Grid.ColumnSpan="3" Margin="5" Width="100" HorizontalAlignment="Center">Download</Button>

        <TextBlock Name="StatusTextBlock" Grid.Row="3" Grid.ColumnSpan="3" Margin="5" TextWrapping="Wrap"/>
    </Grid>
</Window>
"@

# Load the XAML
[xml]$XamlReader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [Windows.Markup.XamlReader]::Load($XamlReader)

# Find elements
$UrlTextBox = $Window.FindName("UrlTextBox")
$PathTextBox = $Window.FindName("PathTextBox")
$BrowseButton = $Window.FindName("BrowseButton")
$DownloadButton = $Window.FindName("DownloadButton")
$StatusTextBlock = $Window.FindName("StatusTextBlock")

# Browse button click event handler
$BrowseButton.Add_Click({
    $FileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $FileDialog.Filter = "All files (*.*)|*.*"
    if ($FileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $PathTextBox.Text = $FileDialog.FileName
    }
})

# Download button click event handler
$DownloadButton.Add_Click({
    $Url = $UrlTextBox.Text
    $Path = $PathTextBox.Text

    if ([string]::IsNullOrEmpty($Url) -or [string]::IsNullOrEmpty($Path)) {
        $StatusTextBlock.Text = "Please enter both the URL and the destination path."
        return
    }

    try {
        $StatusTextBlock.Text = "Downloading..."
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($Url, $Path)
        $StatusTextBlock.Text = "Download completed successfully!"
    } catch {
        $StatusTextBlock.Text = "Error: $_"
    }
})

# Show the window
$Window.ShowDialog()
