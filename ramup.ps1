Add-Type -AssemblyName PresentationFramework

# Function to get RAM info
function Get-RAMInfo {
    $totalMemory = [Math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $freeMemory = [Math]::Round((Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
    $usedMemory = [Math]::Round($totalMemory - ($freeMemory / 1024), 2)
    return @{
        TotalMemory = "$totalMemory GB"
        FreeMemory = "$freeMemory MB"
        UsedMemory = "$usedMemory GB"
    }
}

# Create the window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="RAM Checkup" Height="200" Width="400">
    <Grid>
        <StackPanel>
            <TextBlock Name="TotalMemory" FontSize="16" Margin="10" />
            <TextBlock Name="FreeMemory" FontSize="16" Margin="10" />
            <TextBlock Name="UsedMemory" FontSize="16" Margin="10" />
            <Button Name="RefreshButton" Content="Refresh" Width="100" Height="30" Margin="10" HorizontalAlignment="Center" />
        </StackPanel>
    </Grid>
</Window>
"@

# Load the XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Error "Failed to load XAML: $_"
    exit
}

# Get references to the controls
$TotalMemoryTextBlock = $window.FindName("TotalMemory")
$FreeMemoryTextBlock = $window.FindName("FreeMemory")
$UsedMemoryTextBlock = $window.FindName("UsedMemory")
$RefreshButton = $window.FindName("RefreshButton")

# Function to refresh RAM info
function Refresh-RAMInfo {
    $ramInfo = Get-RAMInfo
    $TotalMemoryTextBlock.Text = "Total Memory: " + $ramInfo.TotalMemory
    $FreeMemoryTextBlock.Text = "Free Memory: " + $ramInfo.FreeMemory
    $UsedMemoryTextBlock.Text = "Used Memory: " + $ramInfo.UsedMemory
}

# Add the button click event
$RefreshButton.Add_Click({ Refresh-RAMInfo })

# Initial refresh
Refresh-RAMInfo

# Show the window
$window.ShowDialog() | Out-Null
