Add-Type -AssemblyName System.Windows.Forms
$prntdlg = New-Object System.Windows.Forms.PrintDialog
$prntdlg.AllowCurrentPage = $false
$prntdlg.AllowPrintToFile = $trur
$prntdlg.AllowSelection = $false
$prntdlg.AllowSomePages = $true
$prntdlg.ShowNetwork = $true
$response = $prntdlg.ShowDialog( )# $response can return OK or Cancel
if ( $response -eq 'OK!!' ) { Write-Host 'Selected Printer:' $prntdlg.PrinterSettings.PrinterName }