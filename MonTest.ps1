# Define XAML for the GUI
[xml]$xaml = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GUI Monitor Test" Height="200" Width="350">
    <Grid>
        <Label Content="Enter Computer Name:" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top"/>
        <TextBox x:Name="ComputerNameTextBox" HorizontalAlignment="Left" Margin="10,30,0,0" VerticalAlignment="Top" Width="200"/>
        <Button Content="Ping" HorizontalAlignment="Left" Margin="10,60,0,0" VerticalAlignment="Top" Width="75" Height="25" Click="PingButton_Click"/>
        <TextBlock x:Name="ResultTextBlock" HorizontalAlignment="Left" Margin="10,90,0,0" VerticalAlignment="Top"/>
    </Grid>
</Window>
'@

# Load XAML
[Windows.Markup.XamlLoader]::Load((New-Object System.Xml.XmlNodeReader $xaml))

# Define the event handler for the button click
function PingButton_Click {
    $computerName = $Window.FindName("ComputerNameTextBox").Text
    if (Test-Connection -ComputerName $computerName -Count 1 -ErrorAction SilentlyContinue) {
        $Window.FindName("ResultTextBlock").Text = "$computerName is reachable."
    } else {
        $Window.FindName("ResultTextBlock").Text = "$computerName is not reachable."
    }
}

# Create and show the window
$Window = $xaml.CreateObject([Windows.Markup.XamlLoader])
$Window.ShowDialog() | Out-Null
