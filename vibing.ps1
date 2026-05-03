Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "VIBE CODE IDE - AI LLM"
$form.Size = New-Object System.Drawing.Size(1000,700)
$form.StartPosition = "CenterScreen"

# Editor Label
$editorLabel = New-Object System.Windows.Forms.Label
$editorLabel.Text = "Code Editor"
$editorLabel.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($editorLabel)

# Code Editor
$editor = New-Object System.Windows.Forms.RichTextBox
$editor.Location = New-Object System.Drawing.Point(10,30)
$editor.Size = New-Object System.Drawing.Size(600,400)
$editor.Font = "Consolas,10"
$form.Controls.Add($editor)

# Output Label
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = "Output Console"
$outputLabel.Location = New-Object System.Drawing.Point(10,440)
$form.Controls.Add($outputLabel)

# Output Box
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(10,460)
$outputBox.Size = New-Object System.Drawing.Size(600,180)
$outputBox.ReadOnly = $true
$outputBox.BackColor = "Black"
$outputBox.ForeColor = "Lime"
$form.Controls.Add($outputBox)

# AI Prompt Label
$aiLabel = New-Object System.Windows.Forms.Label
$aiLabel.Text = "AI Prompt"
$aiLabel.Location = New-Object System.Drawing.Point(620,10)
$form.Controls.Add($aiLabel)

# AI Prompt Box
$aiBox = New-Object System.Windows.Forms.TextBox
$aiBox.Location = New-Object System.Drawing.Point(620,30)
$aiBox.Size = New-Object System.Drawing.Size(350,100)
$aiBox.Multiline = $true
$form.Controls.Add($aiBox)

# Run Button
$runBtn = New-Object System.Windows.Forms.Button
$runBtn.Text = "Run Code"
$runBtn.Location = New-Object System.Drawing.Point(620,150)
$form.Controls.Add($runBtn)

# AI Button
$aiBtn = New-Object System.Windows.Forms.Button
$aiBtn.Text = "Ask AI"
$aiBtn.Location = New-Object System.Drawing.Point(720,150)
$form.Controls.Add($aiBtn)

# Save Button
$saveBtn = New-Object System.Windows.Forms.Button
$saveBtn.Text = "Save"
$saveBtn.Location = New-Object System.Drawing.Point(820,150)
$form.Controls.Add($saveBtn)

# Run Code Logic (Python)
$runBtn.Add_Click({
    $tempFile = "$env:TEMP\vibe_code.py"
    $editor.Text | Out-File $tempFile -Encoding UTF8

    try {
        $result = python $tempFile 2>&1
        $outputBox.Text = $result
    } catch {
        $outputBox.Text = $_
    }
})

# Save File
$saveBtn.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "Python Files (*.py)|*.py|All Files (*.*)|*.*"

    if ($dialog.ShowDialog() -eq "OK") {
        $editor.Text | Out-File $dialog.FileName
    }
})

# AI Button (Mock LLM)
$aiBtn.Add_Click({
    $prompt = $aiBox.Text

    # Placeholder AI logic
    $response = "AI Suggestion:`n" +
                "--------------------------------`n" +
                "You asked: $prompt`n" +
                "Try improving your code structure or adding comments."

    $outputBox.Text = $response
})

# Default Code
$editor.Text = @"
print("Hello from VIBE CODE IDE")
"@

# Run Form
$form.ShowDialog()
