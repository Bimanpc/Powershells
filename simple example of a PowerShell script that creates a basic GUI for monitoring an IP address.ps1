# XAML definition for the GUI
[xml]$xaml = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="IP Monitor" Height="200" Width="300">
    <Grid>
        <Label Content="Enter IP Address:" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top"/>
        <TextBox x:Name="txtIpAddress" HorizontalAlignment="Left" Margin="120,10,0,0" VerticalAlignment="Top" Width="150"/>
        <Button Content="Monitor" HorizontalAlignment="Left" Margin="10,40,0,0" VerticalAlignment="Top" Width="75" Click="StartMonitoring"/>
        <TextBox x:Name="txtResult" HorizontalAlignment="Left" Margin="10,70,0,0" VerticalAlignment="Top" Width="260" Height="80" IsReadOnly="True"/>
    </Grid>
</Window>
'@

# Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlLoader]::Load($reader)

# Define the function to start monitoring
function StartMonitoring {
    $ipAddress = $window.FindName("txtIpAddress").Text

    # Perform your IP monitoring logic here
    $result = "Monitoring IP: $ipAddress`r`n"
    # Add your monitoring logic and update $result accordingly

    $window.FindName("txtResult").Text = $result
}

# Show the window
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)

$window.ShowDialog()
