Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "SSD Trimer - Windows 11"
$form.Size = New-Object System.Drawing.Size(500,350)
$form.StartPosition = "CenterScreen"

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,10)
$listBox.Size = New-Object System.Drawing.Size(460,180)
$form.Controls.Add($listBox)

$refreshBtn = New-Object System.Windows.Forms.Button
$refreshBtn.Text = "Refresh Drives"
$refreshBtn.Location = New-Object System.Drawing.Point(10,210)
$refreshBtn.Size = New-Object System.Drawing.Size(140,35)
$form.Controls.Add($refreshBtn)

$trimBtn = New-Object System.Windows.Forms.Button
$trimBtn.Text = "Run TRIM"
$trimBtn.Location = New-Object System.Drawing.Point(170,210)
$trimBtn.Size = New-Object System.Drawing.Size(140,35)
$form.Controls.Add($trimBtn)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10,270)
$statusLabel.Size = New-Object System.Drawing.Size(460,40)
$form.Controls.Add($statusLabel)

function Load-Drives {
    $listBox.Items.Clear()

    Get-Volume |
        Where-Object DriveLetter |
        ForEach-Object {
            $drive = "$($_.DriveLetter):"
            $listBox.Items.Add($drive)
        }
}

$refreshBtn.Add_Click({
    Load-Drives
})

$trimBtn.Add_Click({

    if ($listBox.SelectedItem -eq $null) {
        [System.Windows.Forms.MessageBox]::Show(
            "Select a drive first.",
            "SSD Trimer",
            "OK",
            "Warning"
        )
        return
    }

    $drive = $listBox.SelectedItem.ToString()

    try {
        $statusLabel.Text = "Running TRIM on $drive ..."
        $form.Refresh()

        Optimize-Volume `
            -DriveLetter $drive.Replace(":","") `
            -ReTrim `
            -Verbose | Out-Null

        $statusLabel.Text = "TRIM completed successfully on $drive"
    }
    catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
    }
})

Load-Drives

[void]$form.ShowDialog()
