Add-Type -AssemblyName PresentationFramework

Function Get-FixedDisk {
    [CmdletBinding()]
    # This param() block indicates the start of parameters declaration
    param (
        <# 
            This parameter accepts the name of the target computer.
            It is also set to mandatory so that the function does not execute without specifying the value.
        #>
        [Parameter(Mandatory)]
        [string]$Computer
    )
    <#
        WMI query command which gets the list of all logical disks and saves the results to a variable named $DiskInfo
    #>
    $DiskInfo = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter 'DriveType=3'
   $DiskInfo
}

#where is the XAML file?
$xamlFile = "C:\Users\june\source\repos\PoshGUI-sample\PoshGUI-sample\MainWindow.xaml"

#create window
$inputXML = Get-Content $xamlFile -Raw
$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[xml]$XAML = $inputXML
#Read XAML

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load( $reader )
}
Add-Type -AssemblyName System.Windows.Forms

$initialDirectory = [Environment]::GetFolderPath('Desktop')

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog

$OpenFileDialog.InitialDirectory = $initialDirectory

$OpenFileDialog.Filter = 'Script files (*.ps1;*.cmd;*.bat)|*.ps1;*.bat;*.cmd'

$OpenFileDialog.Multiselect = $false

$response = $OpenFileDialog.ShowDialog( ) # $response can return OK or Cancel

if ( $response -eq 'OK' ) { Write-Host 'You selected the file:' $OpenFileDialog.FileName }