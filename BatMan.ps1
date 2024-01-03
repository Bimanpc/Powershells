# Load the WPF assembly
Add-Type -AssemblyName PresentationFramework

# XAML code for the GUI
[xml]$xaml = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Battery Manager" Height="200" Width="300">
    <Grid>
        <Label Content="Battery Status:" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10"/>
        <TextBlock x:Name="BatteryStatus" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="120,10,0,0"/>
        
        <Label Content="Battery Level:" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,40,0,0"/>
        <ProgressBar x:Name="BatteryLevel" HorizontalAlignment="Left" VerticalAlignment="Top" Width="200" Height="20" Margin="120,40,0,0"/>
        
        <Button Content="Refresh" HorizontalAlignment="Left" VerticalAlignment="Top" Width="80" Height="30" Margin="10,80,0,0" Click="RefreshButton_Click"/>
    </Grid>
</Window>
'@

# Create an XML reader for the XAML code
$reader = (New-Object System.Xml.XmlNodeReader $xaml)

# Create the GUI object
$window = [Windows.Markup.XamlLoader]::Load($reader)

# Define the event handler for the button click
$handler = {
    $BatteryStatus.Text = Get-BatteryStatus
    $BatteryLevel.Value = Get-BatteryLevel
}

# Attach the event handler to the button click event
$window.FindName('RefreshButton').Add_Click($handler)

# Function to get battery status
function Get-BatteryStatus {
    $batteryStatus = Get-WmiObject -Class Win32_Battery
    return $batteryStatus.BatteryStatus
}

# Function to get battery level
function Get-BatteryLevel {
    $batteryLevel = Get-WmiObject -Class Win32_Battery
    return $batteryLevel.EstimatedChargeRemaining
}

# Show the GUI
[Windows.Markup.ComponentDispatcher]::Run()
