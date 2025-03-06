Add-Type -AssemblyName System.Windows.Forms

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Update List Finder"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"

# Create ListBox
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,10)
$listBox.Size = New-Object System.Drawing.Size(560,300)
$form.Controls.Add($listBox)

# Create Button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Find Updates"
$button.Location = New-Object System.Drawing.Point(10,320)
$button.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($button)

# Button Click Event
$button.Add_Click({
    $listBox.Items.Clear()
    $updates = Get-HotFix | Select-Object -Property Description, HotFixID, InstalledOn
    foreach ($update in $updates) {
        $listBox.Items.Add("$($update.HotFixID) - $($update.Description) - Installed on: $($update.InstalledOn)")
    }
})

# Show Form
$form.ShowDialog()
