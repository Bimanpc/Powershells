# Requires: Windows PowerShell 5+ on Windows
# GUI: Greek labels; works with Azure Neural TTS or local SAPI if installed.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------- Configuration ----------------
$speechKey   = "YOUR_AZURE_SPEECH_KEY"   # e.g., "abcd1234..."
$speechRegion= "YOUR_REGION"             # e.g., "westeurope"
$azureVoices = @("el-GR-AthinaNeural","el-GR-NestorasNeural")

# Enforce TLS 1.2 for HTTPS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---------------- Local SAPI Helpers ----------------
$global:spVoice = $null
$global:sapiSpeaking = $false
function Get-LocalGreekVoices {
    try {
        $v = New-Object -ComObject SAPI.SpVoice
        $tokens = $v.GetVoices()
        $list = @()
        for ($i=0; $i -lt $tokens.Count; $i++) {
            $t = $tokens.Item($i)
            # 'Language' is a hex string of LANGIDs separated by semicolons. Greek = 0408
            $lang = $t.GetAttribute('Language')
            if ($lang -match '(^|;)0408(;|$)') {
                $list += [pscustomobject]@{ Name = $t.GetDescription(); Token = $t }
            }
        }
        $v = $null
        return $list
    } catch {
        return @()
    }
}

# ---------------- Azure TTS Helpers ----------------
function New-SSML {
    param(
        [string]$VoiceName,
        [string]$Text,
        [int]$RatePercent = 0,   # -50..50
        [int]$PitchSt   = 0      # -6..6 semitones
    )
    $esc = [System.Security.SecurityElement]::Escape($Text)
    $rateSign = ($RatePercent -ge 0) ? '+' : ''
    $pitchSign = ($PitchSt -ge 0) ? '+' : ''
    @"
<speak version='1.0' xml:lang='el-GR'>
  <voice name='$VoiceName'>
    <prosody rate='$rateSign$RatePercent%' pitch='$pitchSign$PitchStst'>$esc</prosody>
  </voice>
</speak>
"@
}

function Invoke-AzureTTS {
    param(
        [string]$SSML,
        [ValidateSet('riff-24khz-16bit-mono-pcm','audio-16khz-128kbitrate-mono-mp3')]
        [string]$Format = 'riff-24khz-16bit-mono-pcm'
    )
    if ([string]::IsNullOrWhiteSpace($speechKey) -or [string]::IsNullOrWhiteSpace($speechRegion)) {
        throw "Azure Speech key/region is not configured."
    }
    $uri = "https://$speechRegion.tts.speech.microsoft.com/cognitiveservices/v1"
    $headers = @{
        "Ocp-Apim-Subscription-Key" = $speechKey
        "X-Microsoft-OutputFormat"  = $Format
        "User-Agent"                = "PS-Greek-TTS"
    }
    $resp = Invoke-WebRequest -Method Post -Uri $uri -Headers $headers -ContentType "application/ssml+xml; charset=utf-8" -Body $SSML -TimeoutSec 60
    return $resp.Content  # byte[]
}

# ---------------- GUI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Κείμενο σε Ομιλία (Ελληνικά)"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(760, 520)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# Text input
$lblText = New-Object System.Windows.Forms.Label
$lblText.Text = "Κείμενο"
$lblText.Location = New-Object Drawing.Point(12,12)
$lblText.AutoSize = $true

$txt = New-Object System.Windows.Forms.TextBox
$txt.Multiline = $true
$txt.ScrollBars = "Vertical"
$txt.Font = New-Object Drawing.Font("Segoe UI", 10)
$txt.Location = New-Object Drawing.Point(12,36)
$txt.Size = New-Object Drawing.Size(720, 260)
$txt.Text = "Γράψε εδώ το κείμενο που θέλεις να ακουστεί..."

# Azure voice selection
$lblVoice = New-Object System.Windows.Forms.Label
$lblVoice.Text = "Φωνή (Azure)"
$lblVoice.Location = New-Object Drawing.Point(12,308)
$lblVoice.AutoSize = $true

$cmbVoice = New-Object System.Windows.Forms.ComboBox
$cmbVoice.DropDownStyle = "DropDownList"
$cmbVoice.Location = New-Object Drawing.Point(120,304)
$cmbVoice.Size = New-Object Drawing.Size(260,28)
[void]$cmbVoice.Items.AddRange($azureVoices)
$cmbVoice.SelectedIndex = 0

# Local SAPI toggle and voices
$chkLocal = New-Object System.Windows.Forms.CheckBox
$chkLocal.Text = "Χρήση τοπικής φωνής (SAPI)"
$chkLocal.Location = New-Object Drawing.Point(400,306)
$chkLocal.AutoSize = $true

$lblLocalVoice = New-Object System.Windows.Forms.Label
$lblLocalVoice.Text = "Τοπική φωνή"
$lblLocalVoice.Location = New-Object Drawing.Point(12,344)
$lblLocalVoice.AutoSize = $true

$cmbLocal = New-Object System.Windows.Forms.ComboBox
$cmbLocal.DropDownStyle = "DropDownList"
$cmbLocal.Location = New-Object Drawing.Point(120,340)
$cmbLocal.Size = New-Object Drawing.Size(260,28)
$cmbLocal.Enabled = $false
$lblLocalVoice.Enabled = $false

# Rate and Pitch
$lblRate = New-Object System.Windows.Forms.Label
$lblRate.Text = "Ταχύτητα (%)"
$lblRate.Location = New-Object Drawing.Point(400,344)
$lblRate.AutoSize = $true

$nudRate = New-Object System.Windows.Forms.NumericUpDown
$nudRate.Minimum = -50
$nudRate.Maximum = 50
$nudRate.Value   = 0
$nudRate.Location= New-Object Drawing.Point(520,340)
$nudRate.Size    = New-Object Drawing.Size(80,28)

$lblPitch = New-Object System.Windows.Forms.Label
$lblPitch.Text = "Τόνος (semitones)"
$lblPitch.Location = New-Object Drawing.Point(610,344)
$lblPitch.AutoSize = $true

$nudPitch = New-Object System.Windows.Forms.NumericUpDown
$nudPitch.Minimum = -6
$nudPitch.Maximum = 6
$nudPitch.Value   = 0
$nudPitch.Location= New-Object Drawing.Point(720,340)
$nudPitch.Size    = New-Object Drawing.Size(12,28)  # Hidden numeric up-down grip
$nudPitch.Width   = 40

# Buttons
$btnPlay = New-Object System.Windows.Forms.Button
$btnPlay.Text = "▶ Αναπαραγωγή"
$btnPlay.Location = New-Object Drawing.Point(12,388)
$btnPlay.Size = New-Object Drawing.Size(160,36)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "■ Διακοπή"
$btnStop.Location = New-Object Drawing.Point(184,388)
$btnStop.Size = New-Object Drawing.Size(120,36)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "💾 Αποθήκευση σε WAV"
$btnSave.Location = New-Object Drawing.Point(316,388)
$btnSave.Size = New-Object Drawing.Size(190,36)

# Status
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Κατάσταση: έτοιμο"
$lblStatus.Location = New-Object Drawing.Point(12,440)
$lblStatus.AutoSize = $true

$form.Controls.AddRange(@(
    $lblText,$txt,$lblVoice,$cmbVoice,$chkLocal,$lblLocalVoice,$cmbLocal,
    $lblRate,$nudRate,$lblPitch,$nudPitch,$btnPlay,$btnStop,$btnSave,$lblStatus
))

# Sound player for Azure WAV
$global:player = New-Object System.Media.SoundPlayer
$global:tempWav = $null

# Populate local voices
$localVoices = Get-LocalGreekVoices
if ($localVoices.Count -gt 0) {
    $lblLocalVoice.Enabled = $true
    $cmbLocal.Enabled = $false  # will enable when checkbox is checked
    foreach ($v in $localVoices) { [void]$cmbLocal.Items.Add($v.Name) }
    $cmbLocal.SelectedIndex = 0
} else {
    $chkLocal.Enabled = $false
    $lblLocalVoice.Text += " (δεν βρέθηκαν)"
}

# Checkbox behavior
$chkLocal.Add_CheckedChanged({
    $useLocal = $chkLocal.Checked
    $cmbLocal.Enabled = $useLocal -and ($localVoices.Count -gt 0)
    $lblLocalVoice.Enabled = $useLocal
    $cmbVoice.Enabled = -not $useLocal
    $lblVoice.Enabled = -not $useLocal
    $nudPitch.Enabled = -not $useLocal   # SAPI has no pitch control
})

# Play
$btnPlay.Add_Click({
    try {
        $text = $txt.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($text)) {
            [System.Windows.Forms.MessageBox]::Show("Παρακαλώ γράψε κείμενο.","Προειδοποίηση","OK","Warning") | Out-Null
            return
        }
        if ($chkLocal.Checked -and $localVoices.Count -gt 0) {
            if ($global:spVoice -eq $null) { $global:spVoice = New-Object -ComObject SAPI.SpVoice }
            $selIndex = $cmbLocal.SelectedIndex
            if ($selIndex -lt 0) { [System.Windows.Forms.MessageBox]::Show("Επίλεξε τοπική φωνή.","Σφάλμα","OK","Error") | Out-Null; return }
            $token = $localVoices[$selIndex].Token
            $global:spVoice.Voice = $token
            # Map -50..50% to SAPI Rate -10..10
            $sapiRate = [int][Math]::Round(($nudRate.Value / 50.0) * 10.0)
            $global:spVoice.Rate = $sapiRate
            $global:spVoice.Volume = 100
            $lblStatus.Text = "Κατάσταση: αναπαραγωγή (τοπική)"
            $global:sapiSpeaking = $true
            # 1 = SVSFlagsAsync
            $null = $global:spVoice.Speak($text, 1)
        } else {
            $voice = $cmbVoice.SelectedItem
            $ssml = New-SSML -VoiceName $voice -Text $text -RatePercent ([int]$nudRate.Value) -PitchSt ([int]$nudPitch.Value)
            $lblStatus.Text = "Κατάσταση: σύνθεση (Azure)..."
            $bytes = Invoke-AzureTTS -SSML $ssml -Format 'riff-24khz-16bit-mono-pcm'
            # Save to temp WAV and play
            if ($global:tempWav -and (Test-Path $global:tempWav)) { Remove-Item $global:tempWav -Force -ErrorAction SilentlyContinue }
            $global:tempWav = [System.IO.Path]::GetTempFileName().Replace(".tmp",".wav")
            [System.IO.File]::WriteAllBytes($global:tempWav, $bytes)
            $global:player.SoundLocation = $global:tempWav
            $global:player.Load()
            $lblStatus.Text = "Κατάσταση: αναπαραγωγή (Azure)"
            $global:player.Play()
        }
    } catch {
        $lblStatus.Text = "Κατάσταση: σφάλμα"
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Σφάλμα", "OK", "Error") | Out-Null
    }
})

# Stop
$btnStop.Add_Click({
    try {
        if ($chkLocal.Checked -and $localVoices.Count -gt 0 -and $global:spVoice) {
            # 2 = SVSFPurgeBeforeSpeak
            $null = $global:spVoice.Speak("", 2)
            $global:sapiSpeaking = $false
        } else {
            if ($global:player) { $global:player.Stop() }
        }
        $lblStatus.Text = "Κατάσταση: διακοπή"
    } catch {
        $lblStatus.Text = "Κατάσταση: σφάλμα"
    }
})

# Save WAV
$btnSave.Add_Click({
    try {
        $text = $txt.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($text)) {
            [System.Windows.Forms.MessageBox]::Show("Παρακαλώ γράψε κείμενο.","Προειδοποίηση","OK","Warning") | Out-Null
            return
        }
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "WAV (*.wav)|*.wav"
        $sfd.FileName = "speech_el.wav"
        if ($sfd.ShowDialog() -eq 'OK') {
            if ($chkLocal.Checked -and $localVoices.Count -gt 0) {
                if ($global:spVoice -eq $null) { $global:spVoice = New-Object -ComObject SAPI.SpVoice }
                $selIndex = $cmbLocal.SelectedIndex
                if ($selIndex -lt 0) { [System.Windows.Forms.MessageBox]::Show("Επίλεξε τοπική φωνή.","Σφάλμα","OK","Error") | Out-Null; return }
                $token = $localVoices[$selIndex].Token
                $global:spVoice.Voice = $token
                $sapiRate = [int][Math]::Round(($nudRate.Value / 50.0) * 10.0)
                $global:spVoice.Rate = $sapiRate
                $global:spVoice.Volume = 100
                $stream = New-Object -ComObject SAPI.SpFileStream
                # 3 = SSFMCreateForWrite
                $stream.Open($sfd.FileName, 3, $false)
                $oldOut = $global:spVoice.AudioOutputStream
                $global:spVoice.AudioOutputStream = $stream
                $null = $global:spVoice.Speak($text)
                $global:spVoice.AudioOutputStream = $oldOut
                $stream.Close()
            } else {
                $voice = $cmbVoice.SelectedItem
                $ssml = New-SSML -VoiceName $voice -Text $text -RatePercent ([int]$nudRate.Value) -PitchSt ([int]$nudPitch.Value)
                $lblStatus.Text = "Κατάσταση: αποθήκευση (Azure)..."
                $bytes = Invoke-AzureTTS -SSML $ssml -Format 'riff-24khz-16bit-mono-pcm'
                [System.IO.File]::WriteAllBytes($sfd.FileName, $bytes)
            }
            $lblStatus.Text = "Κατάσταση: αποθηκεύτηκε -> $($sfd.FileName)"
        }
    } catch {
        $lblStatus.Text = "Κατάσταση: σφάλμα"
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Σφάλμα", "OK", "Error") | Out-Null
    }
})

# Cleanup temp file on close
$form.Add_FormClosed({
    try {
        if ($global:player) { $global:player.Stop() }
        if ($global:tempWav -and (Test-Path $global:tempWav)) { Remove-Item $global:tempWav -Force -ErrorAction SilentlyContinue }
    } catch {}
})

[void]$form.ShowDialog()
