Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO

# Αρχείο βάσης
$DatabaseFile = "$PSScriptRoot\chat_db.json"

# Αν δεν υπάρχει, δημιουργείται
if (-not (Test-Path $DatabaseFile)) {
    @() | ConvertTo-Json | Set-Content -Path $DatabaseFile -Encoding UTF8
}

function Load-ChatHistory {
    $json = Get-Content -Path $DatabaseFile -Raw | ConvertFrom-Json
    return $json
}

function Save-ChatMessage($question, $answer) {
    $history = Load-ChatHistory
    $newEntry = [PSCustomObject]@{
        Time     = (Get-Date).ToString("yyyy-MM-dd HH:mm")
        Question = $question
        Answer   = $answer
    }
    $history += $newEntry
    $history | ConvertTo-Json -Depth 5 | Set-Content -Path $DatabaseFile -Encoding UTF8
}

function Get-AutoAnswer($question) {
    # Εδώ μπαίνει μια υποτυπώδης λογική — όχι πραγματική AI
    switch -Wildcard ($question.ToLower()) {
        '*hello*' { return "Hello! How can I assist you offline?" }
        '*date*' { return "Today is: $(Get-Date -Format 'dddd dd MMMM yyyy')" }
        '*help*' { return "You can ask me simple offline questions like date, hello, etc." }
        default { return "Sorry, no answer available offline for that question." }
    }
}

# === GUI ===

$form = New-Object System.Windows.Forms.Form
$form.Text = "ChatGPT Offline DB"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"

# Ιστορικό
$txtHistory = New-Object System.Windows.Forms.TextBox
$txtHistory.Multiline = $true
$txtHistory.ScrollBars = "Vertical"
$txtHistory.ReadOnly = $true
$txtHistory.Size = New-Object System.Drawing.Size(560, 300)
$txtHistory.Location = New-Object System.Drawing.Point(10,10)

# Εισαγωγή ερώτησης
$txtInput = New-Object System.Windows.Forms.TextBox
$txtInput.Size = New-Object System.Drawing.Size(450, 30)
$txtInput.Location = New-Object System.Drawing.Point(10, 320)

# Κουμπί αποστολής
$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = "Send"
$btnSend.Size = New-Object System.Drawing.Size(90,30)
$btnSend.Location = New-Object System.Drawing.Point(470, 318)

# Φόρτωση ιστορικού
function Refresh-History {
    $txtHistory.Clear()
    $entries = Load-ChatHistory
    foreach ($entry in $entries) {
        $txtHistory.AppendText("[$($entry.Time)] You: $($entry.Question)`r`n")
        $txtHistory.AppendText("[$($entry.Time)] GPT: $($entry.Answer)`r`n`r`n")
    }
}

# Ενέργεια αποστολής
$btnSend.Add_Click({
    $q = $txtInput.Text.Trim()
    if ($q -ne "") {
        $a = Get-AutoAnswer $q
        Save-ChatMessage $q $a
        Refresh-History
        $txtInput.Clear()
    }
})

# Προσθήκη στοιχείων
$form.Controls.Add($txtHistory)
$form.Controls.Add($txtInput)
$form.Controls.Add($btnSend)

Refresh-History
$form.ShowDialog()
