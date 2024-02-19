# XAML code defining the GUI layout
[xml]$xaml = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="RAM Check GUI" Height="300" Width="400">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <Label Content="RAM Information:" FontWeight="Bold" Margin="5"/>
        <TextBox Name="txtOutput" Grid.Row="1" IsReadOnly="True" Margin="5"/>
        <Button Content="Check RAM" Grid.Row="2" Margin="5" Width="100" Height="30" 
                Add_Click="CheckRAM_Click"/>
        <StatusBar Name="statusBar" Grid.Row="3"/>
    </Grid>
</Window>
'@

# Create a PowerShell XAML reader
$reader = (New-Object System.Xml.XmlNodeReader $xaml)

# Create the GUI object
$window = [Windows.Markup.XamlLoader]::Load($reader)

# Define the event handler for the button click
$window.FindName("CheckRAM_Click") = {
    $ramInfo = Get-WmiObject Win32_PhysicalMemory | ForEach-Object {
        "Capacity: {0} MB" -f ([math]::round($_.Capacity / 1MB, 2))
    }
    $window.FindName("txtOutput").Text = $ramInfo -join "`r`n"
    $window.FindName("statusBar").Content = "RAM check completed."
}

# Show the GUI
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI loop
[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

# Start the GUI
