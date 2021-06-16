# Init PowerShell Gui
Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$LocalPrinterForm                    = New-Object system.Windows.Forms.Form

# Define the size, title and background color
$LocalPrinterForm.ClientSize         = '500,300'
$LocalPrinterForm.text               = "LazyAdmin - PowerShell GUI Example"
$LocalPrinterForm.BackColor          = "#ffffff"

# Display the form
[void]$LocalPrinterForm.ShowDialog()
# Create a Title for our form. We will use a label for it.
$Titel                           = New-Object system.Windows.Forms.Label

# The content of the label
$Titel.text                      = "Adding new printer"

# Make sure the label is sized the height and length of the content
$Titel.AutoSize                  = $true

# Define the minial width and height (not nessary with autosize true)
$Titel.width                     = 25
$Titel.height                    = 10

# Position the element
$Titel.location                  = New-Object System.Drawing.Point(20,20)

# Define the font type and size
$Titel.Font                      = 'Microsoft Sans Serif,13'

# Other elemtents
$Description                     = New-Object system.Windows.Forms.Label
$Description.text                = "Add a new construction site WIFI  to your computer. Make sure you are connected to the network of the  site."
$Description.AutoSize            = $false
$Description.width               = 450
$Description.height              = 50
$Description.location            = New-Object System.Drawing.Point(20,50)
$Description.Font                = 'Microsoft Sans Serif,10'

$PrinterStatus                   = New-Object system.Windows.Forms.Label
$PrinterStatus.text              = "Status:"
$PrinterStatus.AutoSize          = $true
$PrinterStatus.location          = New-Object System.Drawing.Point(20,115)
$PrinterStatus.Font              = 'Microsoft Sans Serif,10,style=Bold'

$PrinterFound                    = New-Object system.Windows.Forms.Label
$PrinterFound.text               = "Searching for WIFI..."
$PrinterFound.AutoSize           = $true
$PrinterFound.location           = New-Object System.Drawing.Point(75,115)
$PrinterFound.Font               = 'Microsoft Sans Serif,10'

# ADD OTHER ELEMENTS ABOVE THIS LINE

# Add the elements to the form
$LocalWIFIForm.controls.AddRange(@($Titel,$Description,$PrinterStatus,$WIFIFound))

# THIS SHOULD BE AT THE END OF YOUR SCRIPT FOR NOW
# Display the form
[void]$LocalWIFIForm.ShowDialog()
$PrinterType                     = New-Object system.Windows.Forms.ComboBox
$PrinterType.text                = ""
$PrinterType.width               = 170
$printerType.autosize            = $true

# Add the items in the dropdown list
@('Canon','Hp') | ForEach-Object {[void] $WIFIType.Items.Add($_)}

# Select the default value
$PrinterType.SelectedIndex       = 0
$PrinterType.location            = New-Object System.Drawing.Point(20,210)
$PrinterType.Font                = 'Microsoft Sans Serif,10'
$AddPrinterBtn                   = New-Object system.Windows.Forms.Button
$AddPrinterBtn.BackColor         = "#a4ba67"
$AddPrinterBtn.text              = "Add WIFI"
$AddPrinterBtn.width             = 90
$AddPrinterBtn.height            = 30
$AddPrinterBtn.location          = New-Object System.Drawing.Point(370,250)
$AddPrinterBtn.Font              = 'Microsoft Sans Serif,10'
$AddPrinterBtn.ForeColor         = "#ffffff"

$cancelBtn                       = New-Object system.Windows.Forms.Button
$cancelBtn.BackColor             = "#ffffff"
$cancelBtn.text                  = "Cancel"
$cancelBtn.width                 = 90
$cancelBtn.height                = 30
$cancelBtn.location              = New-Object System.Drawing.Point(260,250)
$cancelBtn.Font                  = 'Microsoft Sans Serif,10'
$cancelBtn.ForeColor             = "#000"
$cancelBtn.DialogResult          = [System.Windows.Forms.DialogResult]::Cancel
$LocalPrinterForm.CancelButton   = $cancelBtn
$LocalPrinterForm.Controls.Add($cancelBtn)
