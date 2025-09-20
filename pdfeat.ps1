Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PDF Reader"
$form.Width = 900
$form.Height = 700
$form.StartPosition = "CenterScreen"

# Create the Adobe PDF ActiveX control
$pdfControl = New-Object -ComObject AcroPDF.PDF
$pdfControl.src = "C:\Path\To\Your\File.pdf"
$pdfControl.Dock = 'Fill'

# Embed the control into the form
$form.Controls.Add($pdfControl)

# Show the form
$form.ShowDialog()
