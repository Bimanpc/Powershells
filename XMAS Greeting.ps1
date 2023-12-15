Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$xaml = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Christmas GUI" Height="300" Width="400">
    <Grid>
        <Button Content="Click Me for Christmas Greetings!" HorizontalAlignment="Center" VerticalAlignment="Center" Width="200" Height="50" FontSize="14" FontWeight="Bold" Background="Green" Foreground="White" Name="btnGreet"/>
    </Grid>
</Window>
'@

# Create XAML reader
$reader = (New-Object System.Xml.XmlNodeReader $xaml)

# Create WPF window
$window = [Windows.Markup.XamlLoader]::Load($reader)

# Define the button click event
$button = $window.FindName('btnGreet')
$button.Add_Click({
    [System.Windows.MessageBox]::Show("Merry Christmas and Happy New Year!", "Christmas Greetings", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

# Show the window
[Windows.Markup.ComponentDispatcher]::Run()
