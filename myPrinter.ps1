# Load the required assemblies
Add-Type -AssemblyName PresentationFramework

# Read the XAML file
[xml]$xaml = Get-Content -Path "PrinterManager.xaml"

# Create the WPF window from XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Find controls
$btnAddPrinter = $Window.FindName('btnAddPrinter')
$btnRemovePrinter = $Window.FindName('btnRemovePrinter')
$btnListPrinters = $Window.FindName('btnListPrinters')
$txtPrinterName = $Window.FindName('txtPrinterName')
$lstPrinters = $Window.FindName('lstPrinters')

# Add Printer function
$btnAddPrinter.Add_Click({
    $printerName = $txtPrinterName.Text
    if ([string]::IsNullOrEmpty($printerName)) {
        [System.Windows.MessageBox]::Show("Please enter a printer name.")
    } else {
        Add-Printer -Name $printerName
        [System.Windows.MessageBox]::Show("Printer '$printerName' added successfully.")
    }
})

# Remove Printer function
$btnRemovePrinter.Add_Click({
    $printerName = $txtPrinterName.Text
    if ([string]::IsNullOrEmpty($printerName)) {
        [System.Windows.MessageBox]::Show("Please enter a printer name.")
    } else {
        Remove-Printer -Name $printerName
        [System.Windows.MessageBox]::Show("Printer '$printerName' removed successfully.")
    }
})

# List Printers function
$btnListPrinters.Add_Click({
    $lstPrinters.Items.Clear()
    $printers = Get-Printer | Select-Object -ExpandProperty Name
    foreach ($printer in $printers) {
        $lstPrinters.Items.Add($printer)
    }
})

# Show the Window
$Window.ShowDialog()
