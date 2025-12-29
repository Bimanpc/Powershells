Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === MAIN WINDOW ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "C Language Mini IDE"
$form.Size = New-Object System.Drawing.Size(1100,700)
$form.StartPosition = "CenterScreen"

# === EDITOR LABEL ===
$lblEditor = New-Object System.Windows.Forms.Label
$lblEditor.Text = "C Source Code:"
$lblEditor.Location = New-Object System.Drawing.Point(10,10)
$lblEditor.AutoSize = $true
$form.Controls.Add($lblEditor)

# === C CODE EDITOR ===
$txtEditor = New-Object System.Windows.Forms.TextBox
$txtEditor.Multiline = $true
$txtEditor.ScrollBars = "Both"
$txtEditor.Font = New-Object System.Drawing.Font("Consolas",12)
$txtEditor.Size = New-Object System.Drawing.Size(650,600)
$txtEditor.Location = New-Object System.Drawing.Point(10,40)
$form.Controls.Add($txtEditor)

# === THEORY LABEL ===
$lblTheory = New-Object System.Windows.Forms.Label
$lblTheory.Text = "C Language Notes:"
$lblTheory.Location = New-Object System.Drawing.Point(680,10)
$lblTheory.AutoSize = $true
$form.Controls.Add($lblTheory)

# === THEORY BOX ===
$txtTheory = New-Object System.Windows.Forms.TextBox
$txtTheory.Multiline = $true
$txtTheory.ScrollBars = "Vertical"
$txtTheory.Font = New-Object System.Drawing.Font("Segoe UI",11)
$txtTheory.Size = New-Object System.Drawing.Size(380,600)
$txtTheory.Location = New-Object System.Drawing.Point(680,40)
$txtTheory.ReadOnly = $true
$form.Controls.Add($txtTheory)

# === LOAD THEORY TEXT ===
$txtTheory.Text = @"
Στις μεταβλητές τύπου char καταχωρούνται χαρακτήρες τύπου a, b, c,
σύμβολα όπως !,@ ή ακόμα και αριθμητικοί χαρακτήρες ‘0’, ‘1’, ’2’,…, ’9’.
Τοποθετούνται σε διπλά αυτάκια.

Οι μεταβλητές τύπου int μπορούν να περιέχουν ακέραιες τιμές.

Οι μεταβλητές τύπου float χρησιμοποιούνται όταν μια τιμή ενδεχομένως
να διαθέτει κλασματικό μέρος.
"@

# === COMPILE BUTTON ===
$btnCompile = New-Object System.Windows.Forms.Button
$btnCompile.Text = "Compile"
$btnCompile.Size = New-Object System.Drawing.Size(150,40)
$btnCompile.Location = New-Object System.Drawing.Point(10,650)
$form.Controls.Add($btnCompile)

# === RUN BUTTON ===
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run"
$btnRun.Size = New-Object System.Drawing.Size(150,40)
$btnRun.Location = New-Object System.Drawing.Point(170,650)
$form.Controls.Add($btnRun)

# === OUTPUT WINDOW ===
$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = "Vertical"
$txtOutput.Font = New-Object System.Drawing.Font("Consolas",11)
$txtOutput.Size = New-Object System.Drawing.Size(890,120)
$txtOutput.Location = New-Object System.Drawing.Point(10,700)
$txtOutput.ReadOnly = $true
$form.Controls.Add($txtOutput)

# === BUTTON ACTIONS ===
$btnCompile.Add_Click({
    $txtOutput.Text = "Compile pressed.`n(Σύνδεσε εδώ gcc/clang αν θέλεις πραγματικό compile.)"
})

$btnRun.Add_Click({
    $txtOutput.Text = "Run pressed.`n(Εδώ μπορείς να καλέσεις το compiled .exe)"
})

# === SHOW FORM ===
$form.ShowDialog()
