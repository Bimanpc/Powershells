Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Δημιουργία φόρμας
$form = New-Object System.Windows.Forms.Form
$form.Text = "Παραδοσιακό ISO Burner"
$form.Size = New-Object System.Drawing.Size(400, 250)
$form.StartPosition = "CenterScreen"

# Επιλογή ISO
$lblISO = New-Object System.Windows.Forms.Label
$lblISO.Text = "Επιλογή αρχείου ISO:"
$lblISO.Location = New-Object System.Drawing.Point(10,20)
$lblISO.Size = New-Object System.Drawing.Size(150,20)
$form.Controls.Add($lblISO)

$txtISO = New-Object System.Windows.Forms.TextBox
$txtISO.Location = New-Object System.Drawing.Point(10,40)
$txtISO.Size = New-Object System.Drawing.Size(280,20)
$form.Controls.Add($txtISO)

$btnBrowseISO = New-Object System.Windows.Forms.Button
$btnBrowseISO.Text = "Αναζήτηση"
$btnBrowseISO.Location = New-Object System.Drawing.Point(300, 38)
$btnBrowseISO.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "ISO Files (*.iso)|*.iso"
    if ($dlg.ShowDialog() -eq "OK") {
        $txtISO.Text = $dlg.FileName
    }
})
$form.Controls.Add($btnBrowseISO)

# Επιλογή δίσκου USB
$lblDrive = New-Object System.Windows.Forms.Label
$lblDrive.Text = "Γράμμα μονάδας USB (π.χ. E:)"
$lblDrive.Location = New-Object System.Drawing.Point(10,80)
$lblDrive.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($lblDrive)

$txtDrive = New-Object System.Windows.Forms.TextBox
$txtDrive.Location = New-Object System.Drawing.Point(10,100)
$txtDrive.Size = New-Object System.Drawing.Size(100,20)
$form.Controls.Add($txtDrive)

# Κουμπί εγγραφής
$btnBurn = New-Object System.Windows.Forms.Button
$btnBurn.Text = "Εγγραφή ISO"
$btnBurn.Location = New-Object System.Drawing.Point(10,140)
$btnBurn.Size = New-Object System.Drawing.Size(100,30)
$btnBurn.Add_Click({
    $isoPath = $txtISO.Text
    $usbDrive = $txtDrive.Text

    if (!(Test-Path $isoPath)) {
        [System.Windows.Forms.MessageBox]::Show("Το αρχείο ISO δεν υπάρχει.","Σφάλμα")
        return
    }

    if (!(Test-Path "$usbDrive\")) {
        [System.Windows.Forms.MessageBox]::Show("Το γράμμα δίσκου δεν είναι έγκυρο.","Σφάλμα")
        return
    }

    $confirmation = [System.Windows.Forms.MessageBox]::Show("Είσαι σίγουρος ότι θες να διαγράψεις όλα τα δεδομένα από το $usbDrive και να εγγράψεις το ISO;", "Επιβεβαίωση", "YesNo")
    if ($confirmation -eq "Yes") {
        Start-Process -FilePath dism.exe -ArgumentList "/Apply-Image /ImageFile:`"$isoPath`" /Index:1 /ApplyDir:`"$usbDrive\`"" -Wait -NoNewWindow
        [System.Windows.Forms.MessageBox]::Show("Η εγγραφή ολοκληρώθηκε.")
    }
})
$form.Controls.Add($btnBurn)

# Εκκίνηση
[void]$form.ShowDialog()
