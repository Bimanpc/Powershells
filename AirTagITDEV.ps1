Add-Type -AssemblyName PresentationFramework

# XAML for the GUI
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AirTag Tracker" Height="300" Width="400">
    <Grid>
        <Label Content="AirTag Tracker" HorizontalAlignment="Center" VerticalAlignment="Top" FontSize="20" Margin="0,20,0,0"/>
        <Button Content="Track AirTag" HorizontalAlignment="Center" VerticalAlignment="Center" Width="100" Height="30"/>
    </Grid>
</Window>
"@

# Create the window
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Show the window
$window.ShowDialog()
