Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Management"
$form.Size = New-Object System.Drawing.Size(300,200)

# Create a button to list network adapters
$buttonList = New-Object System.Windows.Forms.Button
$buttonList.Text = "List Adapters"
$buttonList.Location = New-Object System.Drawing.Point(10,10)
$buttonList.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($buttonList)

# Create a textbox to display the results
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.ScrollBars = "Vertical"
$textBox.Location = New-Object System.Drawing.Point(10,50)
$textBox.Size = New-Object System.Drawing.Size(260,100)
$form.Controls.Add($textBox)

# Define the button click event
$buttonList.Add_Click({
    $adapters = Get-NetAdapter | Select-Object -Property Name, Status
    $textBox.Clear()
    foreach ($adapter in $adapters) {
        $textBox.AppendText("$($adapter.Name) - $($adapter.Status)`r`n")
    }
})

# Show the form
$form.ShowDialog()
