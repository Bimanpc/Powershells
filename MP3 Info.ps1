Add-Type -Path ".\TagLibSharp.dll"

# XAML for the GUI
[xml]$xaml = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MP3 Info" Height="300" Width="400">
    <Grid>
        <StackPanel Margin="10">
            <Label Content="MP3 File:"/>
            <TextBox x:Name="txtFilePath" Width="300" Margin="0,0,0,10"/>
            <Button Content="Load MP3" Width="80" Height="30" Margin="0,0,0,10" Click="LoadMp3_Click"/>
            <TextBlock x:Name="txtInfo" TextWrapping="Wrap"/>
        </StackPanel>
    </Grid>
</Window>
'@

# Create XML reader
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlLoader]::Load($reader)

# Define the event handler
$window.FindName('LoadMp3_Click').Add_Click({
    $filePath = $window.FindName('txtFilePath').Text
    if (Test-Path $filePath -and $filePath -match '\.mp3$') {
        # Load MP3 file information
        $file = [TagLib.File]::Create($filePath)
        $tag = $file.GetTag()

        # Display MP3 file information in the GUI
        $info = "Title: $($tag.Title)`n"
        $info += "Artist: $($tag.Artists)`n"
        $info += "Album: $($tag.Album)`n"
        $info += "Year: $($tag.Year)`n"
        $info += "Genre: $($tag.Genres -join ', ')`n"
        $info += "Duration: $($file.Properties.Duration.ToString())"

        $window.FindName('txtInfo').Text = $info
    } else {
        $window.FindName('txtInfo').Text = "Invalid or non-existent MP3 file."
    }
})

# Show the GUI
[Windows.Markup.XamlLoader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
[Windows.Markup.XamlLoader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
[Windows.Markup.XamlLoader]::Load((New-Object System.Xml.XmlNodeReader $xaml))

# Start the GUI event loop
[Windows.Markup.XamlLoader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
[Windows.Markup.XamlLoader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
[Windows.Markup.XamlLoader]::Load((New-Object System.Xml.XmlNodeReader $xaml))

# Display the GUI
[Windows.Markup.XamlLoader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
[Windows.Markup.XamlLoader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
[Windows.Markup.XamlLoader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
