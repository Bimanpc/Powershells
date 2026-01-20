Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------- FORM ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI eBook Generator from PDF"
$form.Size = New-Object System.Drawing.Size(600,420)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# ---------- LABEL ----------
$lblPdf = New-Object System.Windows.Forms.Label
$lblPdf.Text = "PDF File:"
$lblPdf.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($lblPdf)

# ---------- TEXTBOX ----------
$txtPdf = New-Object System.Windows.Forms.TextBox
$txtPdf.Location = New-Object System.Drawing.Point(80,18)
$txtPdf.Size = New-Object System.Drawing.Size(400,20)
$form.Controls.Add($txtPdf)

# ---------- BROWSE BUTTON ----------
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse"
$btnBrowse.Location = New-Object System.Drawing.Point(490,16)
$form.Controls.Add($btnBrowse)

# ---------- OUTPUT ----------
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20,60)
$txtLog.Size = New-Object System.Drawing.Size(540,240)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$form.Controls.Add($txtLog)

# ---------- GENERATE BUTTON ----------
$btnGenerate = New-Object System.Windows.Forms.Button
$btnGenerate.Text = "Generate eBook"
$btnGenerate.Location = New-Object System.Drawing.Point(20,320)
$btnGenerate.Size = New-Object System.Drawing.Size(150,30)
$form.Controls.Add($btnGenerate)

# ---------- FILE DIALOG ----------
$openFile = New-Object System.Windows.Forms.OpenFileDialog
$openFile.Filter = "PDF Files (*.pdf)|*.pdf"

$btnBrowse.Add_Click({
    if ($openFile.ShowDialog() -eq "OK") {
        $txtPdf.Text = $openFile.FileName
    }
})

# ---------- GENERATION LOGIC ----------
$btnGenerate.Add_Click({

    if (-not (Test-Path $txtPdf.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Invalid PDF file.")
        return
    }

    $txtLog.AppendText("Extracting text from PDF...`r`n")

    $tempTxt = "$env:TEMP\pdf_text.txt"

    & pdftotext.exe "`"$($txtPdf.Text)`"" "`"$tempTxt`""

    if (-not (Test-Path $tempTxt)) {
        $txtLog.AppendText("PDF extraction failed.`r`n")
        return
    }

    $pdfText = Get-Content $tempTxt -Raw

    $txtLog.AppendText("Sending text to AI engine...`r`n")

    # ---- AI PLACEHOLDER ----
    $ebookContent = @"
TITLE: Generated eBook

CHAPTER 1
$(($pdfText -split "`n")[0..20] -join "`n")

[AI restructuring would occur here]
"@

    $outputFile = [System.IO.Path]::ChangeExtension($txtPdf.Text, ".ebook.txt")
    $ebookContent | Out-File $outputFile -Encoding UTF8

    $txtLog.AppendText("eBook created:`r`n$outputFile`r`n")
})

# ---------- SHOW FORM ----------
[void]$form.ShowDialog()
