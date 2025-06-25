Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Δημιουργία Κύριου Παραθύρου
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ταβλί - Διαδικτυακή Έκδοση"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"

# Ταμπλό Ταβλιού (Panel)
$board = New-Object System.Windows.Forms.Panel
$board.Location = New-Object System.Drawing.Point(50, 50)
$board.Size = New-Object System.Drawing.Size(700, 400)
$board.BackColor = [System.Drawing.Color]::Beige
$form.Controls.Add($board)

# Κουμπί Σύνδεσης
$connectBtn = New-Object System.Windows.Forms.Button
$connectBtn.Text = "Σύνδεση"
$connectBtn.Location = New-Object System.Drawing.Point(50, 470)
$connectBtn.Size = New-Object System.Drawing.Size(100, 40)
$connectBtn.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Δεν έχει υλοποιηθεί ακόμα η σύνδεση.")
})
$form.Controls.Add($connectBtn)

# Κουμπί Ρίψης Ζαριών
$rollDiceBtn = New-Object System.Windows.Forms.Button
$rollDiceBtn.Text = "Ρίξε Ζάρια"
$rollDiceBtn.Location = New-Object System.Drawing.Point(170, 470)
$rollDiceBtn.Size = New-Object System.Drawing.Size(100, 40)
$rollDiceBtn.Add_Click({
    $rand = Get-Random -Minimum 1 -Maximum 7
    $rand2 = Get-Random -Minimum 1 -Maximum 7
    [System.Windows.Forms.MessageBox]::Show("Ζάρια: $rand και $rand2")
})
$form.Controls.Add($rollDiceBtn)

# Label Πληροφοριών
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Περιμένει σύνδεση..."
$statusLabel.Location = New-Object System.Drawing.Point(50, 520)
$statusLabel.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($statusLabel)

# Εκτέλεση
[void]$form.ShowDialog()
