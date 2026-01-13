Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------- FORM ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI LLM Photo Editor"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"

# ---------- IMAGE BOX ----------
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Location = New-Object System.Drawing.Point(20,20)
$pictureBox.Size = New-Object System.Drawing.Size(350,350)
$pictureBox.SizeMode = "Zoom"
$form.Controls.Add($pictureBox)

# ---------- PROMPT ----------
$promptLabel = New-Object System.Windows.Forms.Label
$promptLabel.Text = "Edit Prompt:"
$promptLabel.Location = New-Object System.Drawing.Point(400,20)
$form.Controls.Add($promptLabel)

$promptBox = New-Object System.Windows.Forms.TextBox
$promptBox.Multiline = $true
$promptBox.Size = New-Object System.Drawing.Size(350,100)
$promptBox.Location = New-Object System.Drawing.Point(400,45)
$form.Controls.Add($promptBox)

# ---------- BUTTONS ----------
$loadBtn = New-Object System.Windows.Forms.Button
$loadBtn.Text = "Load Image"
$loadBtn.Location = New-Object System.Drawing.Point(20,390)
$form.Controls.Add($loadBtn)

$editBtn = New-Object System.Windows.Forms.Button
$editBtn.Text = "Edit with AI"
$editBtn.Location = New-Object System.Drawing.Point(120,390)
$form.Controls.Add($editBtn)

# ---------- STATUS ----------
$status = New-Object System.Windows.Forms.Label
$status.Text = "Status: Idle"
$status.Location = New-Object System.Drawing.Point(20,430)
$status.AutoSize = $true
$form.Controls.Add($status)

# ---------- IMAGE PATH ----------
$imagePath = $null

# ---------- LOAD IMAGE ----------
$loadBtn.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Images|*.png;*.jpg;*.jpeg"
    if ($ofd.ShowDialog() -eq "OK") {
        $imagePath = $ofd.FileName
        $pictureBox.Image = [System.Drawing.Image]::FromFile($imagePath)
        $status.Text = "Loaded image."
    }
})

# ---------- AI EDIT ----------
$editBtn.Add_Click({
    if (-not $imagePath -or -not $promptBox.Text) {
        [System.Windows.Forms.MessageBox]::Show("Image and prompt required.")
        return
    }

    $status.Text = "Sending to AI..."

    $apiKey = $env:OPENAI_API_KEY
    if (-not $apiKey) {
        [System.Windows.Forms.MessageBox]::Show("API key missing.")
        return
    }

    # ---- Example API Payload (OpenAI-style) ----
    $headers = @{
        "Authorization" = "Bearer $apiKey"
    }

    $body = @{
        model  = "gpt-image-1"
        prompt = $promptBox.Text
    }

    try {
        # Placeholder – replace with real endpoint
        # $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/edits" `
        #     -Method POST -Headers $headers -Form $body

        Start-Sleep 2
        $status.Text = "Edit complete (mock)."
        [System.Windows.Forms.MessageBox]::Show("Replace API call with real endpoint.")
    }
    catch {
        $status.Text = "Error."
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message)
    }
})

# ---------- RUN ----------
$form.ShowDialog()
