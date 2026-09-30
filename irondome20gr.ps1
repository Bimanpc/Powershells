Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "AI LLM File Scanner - Avast Style"
$form.Size = New-Object System.Drawing.Size(700,500)
$form.StartPosition = "CenterScreen"
$form.BackColor = "#0F172A"

$title = New-Object System.Windows.Forms.Label
$title.Text = "AI LLM File Scanner"
$title.ForeColor = "Lime"
$title.Font = New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle\]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(200,20)
$form.Controls.Add($title)

$fileBox = New-Object System.Windows.Forms.TextBox
$fileBox.Size = New-Object System.Drawing.Size(450,30)
$fileBox.Location = New-Object System.Drawing.Point(20,90)
$fileBox.Font = New-Object System.Drawing.Font("Segoe UI",10)
$form.Controls.Add($fileBox)

$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Text = "Browse"
$browseBtn.Size = New-Object System.Drawing.Size(120,30)
$browseBtn.Location = New-Object System.Drawing.Point(500,88)
$form.Controls.Add($browseBtn)

$scanBtn = New-Object System.Windows.Forms.Button
$scanBtn.Text = "AI Scan"
$scanBtn.Size = New-Object System.Drawing.Size(150,45)
$scanBtn.Location = New-Object System.Drawing.Point(250,140)
$scanBtn.BackColor = "#22C55E"
$scanBtn.ForeColor = "White"
$form.Controls.Add($scanBtn)

$resultBox = New-Object System.Windows.Forms.RichTextBox
$resultBox.Location = New-Object System.Drawing.Point(20,220)
$resultBox.Size = New-Object System.Drawing.Size(640,200)
$resultBox.BackColor = "#111827"
$resultBox.ForeColor = "White"
$resultBox.Font = New-Object System.Drawing.Font("Consolas",10)
$form.Controls.Add($resultBox)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20,190)
$progress.Size = New-Object System.Drawing.Size(640,20)
$form.Controls.Add($progress)

$browseBtn.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    if($ofd.ShowDialog() -eq "OK"){
        $fileBox.Text = $ofd.FileName
    }
})

$scanBtn.Add_Click({

    if(!(Test-Path $fileBox.Text)){
        [System.Windows.Forms.MessageBox]:::Show("Select a file!")
        return
    }

    $progress.Value = 0
    $resultBox.Clear()

    $file = Get-Item $fileBox.Text

    foreach($i in 1..100){
        $progress.Value = $i
        Start-Sleep -Milliseconds 10
    }

    $score = Get-Random -Minimum 0 -Maximum 100

    $resultBox.AppendText("=== AI FILE ANALYSIS ===`n`n")
    $resultBox.AppendText("Name: $($file.Name)`n")
    $resultBox.AppendText("Size: $([Math\]::Round($file.Length/1KB,2)) KB`n")
    $resultBox.AppendText("Extension: $($file.Extension)`n")
    $resultBox.AppendText("Created: $($file.CreationTime)`n`n")

    if($score -lt 30){
        $resultBox.SelectionColor = "Lime"
        $resultBox.AppendText("STATUS: SAFE`n")
    }
    elseif($score -lt 70){
        $resultBox.SelectionColor = "Orange"
        $resultBox.AppendText("STATUS: SUSPICIOUS`n")
    }
    else{
        $resultBox.SelectionColor = "Red"
        $resultBox.AppendText("STATUS: HIGH RISK`n")
    }

    $resultBox.SelectionColor = "White"
    $resultBox.AppendText("AI Risk Score: $score / 100`n")
})

[void]$form.ShowDialog()
