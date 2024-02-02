Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define the form
$form = New-Object Windows.Forms.Form
$form.Text = "CPU Information"
$form.Size = New-Object Drawing.Size(300,200)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"

# Define labels
$label1 = New-Object Windows.Forms.Label
$label1.Location = New-Object Drawing.Point(10, 20)
$label1.Size = New-Object Drawing.Size(280,20)
$label1.Text = "Processor Name: $(Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty Name)"

$label2 = New-Object Windows.Forms.Label
$label2.Location = New-Object Drawing.Point(10, 50)
$label2.Size = New-Object Drawing.Size(280,20)
$label2.Text = "Number of Cores: $(Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty NumberOfCores)"

$label3 = New-Object Windows.Forms.Label
$label3.Location = New-Object Drawing.Point(10, 80)
$label3.Size = New-Object Drawing.Size(280,20)
$label3.Text = "Processor ID: $(Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty ProcessorId)"

# Add labels to the form
$form.Controls.Add($label1)
$form.Controls.Add($label2)
$form.Controls.Add($label3)

# Run the form
$form.ShowDialog()
