Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Δημιουργία παραθύρου
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI ERT Greece - Δεύτερο Λαϊκά"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"

# Ετικέτα
$label = New-Object System.Windows.Forms.Label
$label.Text = "Πάτησε το κουμπί για να ξεκινήσει ο σταθμός 'Δεύτερο Λαϊκά'"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(30,30)
$form.Controls.Add($label)

# Κουμπί Αναπαραγωγής
$playButton = New-Object System.Windows.Forms.Button
$playButton.Text = "▶ Αναπαραγωγή"
$playButton.Location = New-Object System.Drawing.Point(30,70)
$playButton.Size = New-Object System.Drawing.Size(120,30)
$form.Controls.Add($playButton)

# Κουμπί Τερματισμού
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "✖ Έξοδος"
$exitButton.Location = New-Object System.Drawing.Point(160,70)
$exitButton.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($exitButton)

# Stream URL (παράδειγμα – πρέπει να είναι ενεργός)
$streamUrl = "https://webradio.ert.gr/deftero-l"  # ← Εδώ βάλε το σωστό URL αν έχει αλλάξει

# Συνάρτηση για αναπαραγωγή
$playButton.Add_Click({
    Start-Process "wmplayer.exe" $streamUrl
})

# Συνάρτηση εξόδου
$exitButton.Add_Click({
    $form.Close()
})

# Εκτέλεση GUI
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
