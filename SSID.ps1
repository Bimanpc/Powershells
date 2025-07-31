Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Δημιουργία του παραθύρου
$form = New-Object System.Windows.Forms.Form
$form.Text = "Προβολή SSID - LLM Tool"
$form.Size = New-Object System.Drawing.Size(500,400)
$form.StartPosition = "CenterScreen"

# Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Αποθηκευμένα SSID στο σύστημα:"
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(400,20)
$form.Controls.Add($label)

# ListBox για εμφάνιση SSID
$listbox = New-Object System.Windows.Forms.ListBox
$listbox.Location = New-Object System.Drawing.Point(10,50)
$listbox.Size = New-Object System.Drawing.Size(460,250)
$form.Controls.Add($listbox)

# Κουμπί Εξαγωγής
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10,310)
$button.Size = New-Object System.Drawing.Size(100,30)
$button.Text = "Εμφάνιση SSID"
$form.Controls.Add($button)

# Συνάρτηση ανάκτησης SSID
function Get-SSIDs {
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
        ($_ -split ":")[1].Trim()
    }
    return $profiles
}

# Συνάρτηση όταν πατηθεί το κουμπί
$button.Add_Click({
    $listbox.Items.Clear()
    $ssids = Get-SSIDs
    foreach ($ssid in $ssids) {
        $listbox.Items.Add($ssid)
    }
})

# Εκκίνηση GUI
$form.Topmost = $true
[void]$form.ShowDialog()
