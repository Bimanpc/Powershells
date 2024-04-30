# Import the required assembly for creating GUI
Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Microsoft Edge Addons List"
$form.Size = New-Object System.Drawing.Size(400,400)
$form.StartPosition = "CenterScreen"

# Create a listbox to display the addons
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,10)
$listBox.Size = New-Object System.Drawing.Size(380,300)

# Get the list of Microsoft Edge addons
$edgeAddons = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Extensions" | Select-Object -ExpandProperty Name

# Add addons to the listbox
foreach ($addon in $edgeAddons) {
    [void]$listBox.Items.Add($addon)
}

# Add the listbox to the form
$form.Controls.Add($listBox)

# Display the form
$form.ShowDialog()
