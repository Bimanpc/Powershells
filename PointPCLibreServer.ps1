Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '600,800'
$Form.text                       = "Form"
$Form.TopMost                    = $false

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "1)"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(44,46)
$Label1.Font                     = 'Microsoft Sans Serif,10'



$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 287
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(107,172)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'

$TextBox2                        = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline              = $false
$TextBox2.width                  = 287
$TextBox2.height                 = 20
$TextBox2.location               = New-Object System.Drawing.Point(107,224)
$TextBox2.Font                   = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "PCOne Server Name"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(169,136)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$Label3                          = New-Object system.Windows.Forms.Label
$Label3.text                     = "PCOne DB Name"
$Label3.AutoSize                 = $true
$Label3.width                    = 25
$Label3.height                   = 10
$Label3.location                 = New-Object System.Drawing.Point(184,200)
$Label3.Font                     = 'Microsoft Sans Serif,10'

$Label4                          = New-Object system.Windows.Forms.Label
$Label4.text                     = "2)"
$Label4.AutoSize                 = $true
$Label4.width                    = 25
$Label4.height                   = 10
$Label4.location                 = New-Object System.Drawing.Point(44,165)
$Label4.Font                     = 'Microsoft Sans Serif,10'

$LoadDB                            = New-Object system.Windows.Forms.Button
$LoadDB.text                       = "Connect"
$LoadDB.width                      = 106
$LoadDB.height                     = 30
$LoadDB.location                   = New-Object System.Drawing.Point(197,260)
$LoadDB.Font                       = 'Microsoft Sans Serif,10'

$Label7                      = New-Object system.Windows.Forms.Label
$Label7.AutoSize                 = $true
$Label7.width               = 60
$Label7.height              = 30
$Label7.location            = New-Object System.Drawing.Point(422,260)
$Label7.Font                = 'Microsoft Sans Serif,10'

$Label5                          = New-Object system.Windows.Forms.Label
$Label5.text                     = "3)"
$Label5.AutoSize                 = $true
$Label5.width                    = 25
$Label5.height                   = 10
$Label5.location                 = New-Object System.Drawing.Point(43,382)
$Label5.Font                     = 'Microsoft Sans Serif,10'

$outputBox = New-Object System.Windows.Forms.TextBox 
$outputBox.width              = 400
$outputBox.height             = 200
$outputBox.location           = New-Object System.Drawing.Point(69,416)
$outputBox.MultiLine = $True 
$outputBox.ScrollBars = "Vertical"



$Label6                          = New-Object system.Windows.Forms.Label
$Label6.text                     = "Insert Point  Servers"
$Label6.AutoSize                 = $true
$Label6.width                    = 25
$Label6.height                   = 10
$Label6.location                 = New-Object System.Drawing.Point(176,380)
$Label6.Font                     = 'Microsoft Sans Serif,10'

$Label7                      = New-Object system.Windows.Forms.Label
$Label7.AutoSize                 = $true
$Label7.width               = 60
$Label7.height              = 30
$Label7.location            = New-Object System.Drawing.Point(432,40)
$Label7.Font                = 'Microsoft Sans Serif,10'


$Loadservers                     = New-Object system.Windows.Forms.Button
$Loadservers.text                = "Load Servers....."
$Loadservers.width               = 107
$Loadservers.height              = 30
$Loadservers.location            = New-Object System.Drawing.Point(321,687)
$Loadservers.Font                = 'Microsoft Sans Serif,10'

$Reset                       = New-Object system.Windows.Forms.Button
$Reset.text                    = "Reset"
$Reset.width                   = 99
$Reset.height                  = 30
$Reset.location                = New-Object System.Drawing.Point(78,687)
$Reset.Font                    = 'Microsoft Sans Serif,10'

$Label8                          = New-Object system.Windows.Forms.Label
$Label8.AutoSize                 = $true
$Label8.width                    = 60
$Label8.height                   = 31
$Label8.location                  = New-Object System.Drawing.Point(432,165)
$Label8.Font                     = 'Microsoft Sans Serif,10'

$LoadModule                             = New-Object system.Windows.Forms.Button
$LoadModule.text                        = "Load the PCOne Server Directory"
$LoadModule.width                       = 240
$LoadModule.height                      = 30
$LoadModule.location                    = New-Object System.Drawing.Point(120,36)
$LoadModule.Font                        = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($Label1,$TextBox1,$TextBox2,$Label2,$Label3,$Label4,$Label5,$Label6,$Label7,$Label8,$outputbox,$Loadservers,$LoadModule,$LoadDB,$Reset))





#Import PCOne Module 
$LoadModule.Add_click({

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.rootfolder = "MyComputer"
    $foldername.ShowDialog()
	$global:FilePath = $foldername.SelectedPath + '\Intercerve.SQLSentry.Powershell.psd1'
	
#Error Catcher 	
if(!(Test-Path -Path $global:FilePath)){

 $Label7.Text = "Cannot Import Module"

}Else{
 
  Try { 
Import-Module $Global:FilePath -ErrorAction Stop 
  $Label7.Text = "Module Imported"
 
}
Catch{
 $Label7.Text = "Import Failed"


}}})


#Connect to PCOne DB
$LoadDB.Add_click({

#Error Catcher
Try {
Connect-SQLSentry -ServerName $TextBox1.Text -DatabaseName $TextBox2.Text -ErrorAction Stop 
  $Label8.Text = "Repository Loaded"

}
Catch {
$Label8.Text = "Connection Failed"



}})



#Add Targets
$Loadservers.Add_Click({



$global:string = $outputbox.text -split "`r`n"

$i = 0


#Loop through text box 
ForEach ($line in $($global:string -split "`r`n")){

 If ($line -eq ""){}Else{ 
$i= $i+1
Write-Progress -Activity “Add Target + $line” -status “Found Service $i + `r`n” `
-percentComplete ($i / $global:string.count*100)


$string2 = $String2 + $line
#Error Catcher
try {
Register-Connection -ConnectionType SqlServer -Name $line -ErrorAction Stop 
$string2 = $string2  + "      Success" + "`r`n"}
catch [System.Exception] {
$string2 = $string2 + "      Failed" + "`r`n" 
}

$Outputbox.Text = $string2


}}
$Outputbox.ReadOnly = $true;
})



$Reset.Add_Click({
$Outputbox.Text = $global:string
$Outputbox.ReadOnly = $False
})


$Form.showdialog()