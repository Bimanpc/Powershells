Add-Type -AssemblyName PresentationFramework

# Function to get motherboard information
function Get-MotherboardInfo {
    $wmi = Get-WmiObject Win32_BaseBoard
    return @{
        "Manufacturer" = $wmi.Manufacturer
        "Model" = $wmi.Product
        "SerialNumber" = $wmi.SerialNumber
        "Version" = $wmi.Version
    }
}

# Get motherboard info
$motherboardInfo = Get-MotherboardInfo

# Create the GUI window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Motherboard Information" Height="200" Width="400">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Row="0" Grid.Column="0" Margin="5" Text="Manufacturer:"/>
        <TextBlock Grid.Row="0" Grid.Column="1" Margin="5" Name="ManufacturerText"/>

        <TextBlock Grid.Row="1" Grid.Column="0" Margin="5" Text="Model:"/>
        <TextBlock Grid.Row="1" Grid.Column="1" Margin="5" Name="ModelText"/>

        <TextBlock Grid.Row="2" Grid.Column="0" Margin="5" Text="Serial Number:"/>
        <TextBlock Grid.Row="2" Grid.Column="1" Margin="5" Name="SerialNumberText"/>

        <TextBlock Grid.Row="3" Grid.Column="0" Margin="5" Text="Version:"/>
        <TextBlock Grid.Row="3" Grid.Column="1" Margin="5" Name="VersionText"/>
    </Grid>
</Window>
"@

# Load the XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Set the values
$window.FindName("ManufacturerText").Text = $motherboardInfo["Manufacturer"]
$window.FindName("ModelText").Text = $motherboardInfo["Model"]
$window.FindName("SerialNumberText").Text = $motherboardInfo["SerialNumber"]
$window.FindName("VersionText").Text = $motherboardInfo["Version"]

# Show the window
$window.ShowDialog()
