Add-Type -AssemblyName System.Windows.Forms

# Δημιουργία παραθύρου
$form = New-Object System.Windows.Forms.Form
$form.Text = "Επείγουσα Κλήση"
$form.Size = New-Object System.Drawing.Size(300,150)
$form.StartPosition = "CenterScreen"

# Δημιουργία κουμπιού
$button = New-Object System.Windows.Forms.Button
$button.Text = "Κάλεσε Ασθενοφόρο"
$button.Size = New-Object System.Drawing.Size(200,50)
$button.Location = New-Object System.Drawing.Point(50,30)

# Όταν πατηθεί το κουμπί, ανοίγει η προεπιλεγμένη εφαρμογή τηλεφωνίας για να καλέσει το 112
$button.Add_Click({
    Start-Process "tel:112"
})

# Προσθήκη κουμπιού στο παράθυρο
$form.Controls.Add($button)

# Εμφάνιση παραθύρου
$form.ShowDialog()
