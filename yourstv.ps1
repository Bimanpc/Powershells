Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="TV Stations Player" Height="200" Width="400">
    <Grid>
        <Button Name="btnStation1" Content="Play Station 1" HorizontalAlignment="Left" VerticalAlignment="Top" Width="150" Height="50" Margin="10"/>
        <Button Name="btnStation2" Content="Play Station 2" HorizontalAlignment="Right" VerticalAlignment="Top" Width="150" Height="50" Margin="10"/>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$btnStation1 = $window.FindName("btnStation1")
$btnStation2 = $window.FindName("btnStation2")

$btnStation1.Add_Click({
    Start-Process "http://example.com/station1"
})

$btnStation2.Add_Click({
    Start-Process "http://example.com/station2"
})

$window.ShowDialog()
