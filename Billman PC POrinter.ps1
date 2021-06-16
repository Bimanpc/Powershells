# Init PowerShell Gui
Add-Type -AssemblyName System.Windows.Forms
# Create a new form
$LocalPrinterForm                    = New-Object system.Windows.Forms.Form
# Define the size, title and background color
$LocalPrinterForm.ClientSize         = '500,300'
$LocalPrinterForm.text               = "BILLMAN PC Printer"
$LocalPrinterForm.BackColor          = "#ffffff"
# Display the form
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
$Description.text                = "Add a new construction site printer to your computer. Make sure you are connected to the network of the construction site."
$Description.AutoSize            = $false
$Description.width               = 450
$Description.height              = 50
$Description.location            = New-Object System.Drawing.Point(20,50)
$Description.Font                = 'Microsoft Sans Serif,15'
$PrinterStatus                   = New-Object system.Windows.Forms.Label
$PrinterStatus.text              = "Status:"
$PrinterStatus.AutoSize          = $true
$PrinterStatus.location          = New-Object System.Drawing.Point(20,115)
$PrinterStatus.Font              = 'Microsoft Sans Serif,10,style=Bold'
$PrinterFound                    = New-Object system.Windows.Forms.Label
$PrinterFound.text               = "Searching for printer..."
$PrinterFound.AutoSize           = $true
$PrinterFound.location           = New-Object System.Drawing.Point(75,115)
$PrinterFound.Font               = 'Microsoft Sans Serif,10'
# ADD OTHER ELEMENTS ABOVE THIS LINE
# Add the elements to the form
$LocalPrinterForm.controls.AddRange(@($Titel,$Description,$PrinterStatus,$PrinterFound))
# THIS SHOULD BE AT THE END OF YOUR SCRIPT FOR NOW
# Display the form
[void]$LocalPrinterForm.ShowDialog()
[void]$LocalPrinterForm.ShowDialog()
