# Load the XAML GUI
Add-Type -AssemblyName PresentationFramework
$XAML = [System.IO.File]::ReadAllText('CpuSpecGui.xaml')
$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Define the event handler for the "Get CPU Info" button
$Button_GetCpuInfo_Click = {
    $cpuInfo = Get-WmiObject Win32_Processor
    $cpuInfoText.Text = "Processor: $($cpuInfo.Name)`r`nArchitecture: $($cpuInfo.Architecture)`r`nCores: $($cpuInfo.NumberOfCores)`r`nThreads: $($cpuInfo.NumberOfLogicalProcessors)"
}

$Window.FindName("Button_GetCpuInfo_Click").Add_Click($Button_GetCpuInfo_Click)

# Display the GUI
$Window.ShowDialog() | Out-Null
