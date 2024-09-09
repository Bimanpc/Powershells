Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Setup Creator" Height="200" Width="400">
    <Grid>
        <Label Content="Application Name:" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,10,0,0"/>
        <TextBox Name="AppName" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="120,10,0,0" Width="250"/>
        <Button Content="Create Setup" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,50,0,0" Width="100" Click="CreateSetup_Click"/>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$window.Add_Loaded({
    $window.FindName("AppName").Text = "MyApp"
})

$window.FindName("CreateSetup_Click").Add_Click({
    $appName = $window.FindName("AppName").Text
    [System.Windows.MessageBox]::Show("Creating setup for $appName")
})

$window.ShowDialog()
