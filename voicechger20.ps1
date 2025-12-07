<#
AI Voice Changer GUI (.ps1)
Author: Copilot

Requirements:
- Windows PowerShell 5.1+ (for WinForms)
- NAudio DLLs placed next to this script:
    NAudio.dll
    NAudio.Core.dll (if applicable for your version)
    NAudio.Wasapi.dll (if applicable)
- Microphone access enabled (Windows privacy settings)

AI Endpoint (placeholder):
- Set $Global:AI_Endpoint to your voice conversion API.
- Default expects: POST multipart/form-data field "file", optional JSON params in "config".
- Response: binary audio (WAV or MP3). Adjust headers if your endpoint differs.

Extensibility:
- Add config UI (voice presets, pitch, style) by editing $Global:AI_Config.
- Swap WaveInEvent for WasapiCapture if needed.
- Handle MP3 with NAudio.Lame or decode via NAudio MediaFoundationReader (Win10+).
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Load NAudio from local directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$naudioCandidates = @(
    Join-Path $scriptDir "NAudio.dll"
)
foreach ($dll in $naudioCandidates) {
    if (Test-Path $dll) { Add-Type -Path $dll }
}

# Globals
$Global:AI_Endpoint = "http://localhost:5000/convert"  # Replace with your backend
$Global:AI_Config = @{ targetVoice = "female_warm"; enhance = $true } # Customize freely
$Global:OriginalPath = $null
$Global:ConvertedPath = $null
$Global:IsRecording = $false
$Global:WaveIn = $null
$Global:WavWriter = $null
$Global:PlaybackOut = $null
$Global:PlaybackReader = $null

function New-TempWav {
    $tmp = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ("rec_" + [guid]::NewGuid().ToString() + ".wav"))
    return $tmp
}

function New-TempFile([string]$ext = ".wav") {
    [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ("out_" + [guid]::NewGuid().ToString() + $ext))
}

function Stop-Playback {
    try {
        if ($Global:PlaybackOut) {
            $Global:PlaybackOut.Stop()
            $Global:PlaybackOut.Dispose()
            $Global:PlaybackOut = $null
        }
        if ($Global:PlaybackReader) {
            $Global:PlaybackReader.Dispose()
            $Global:PlaybackReader = $null
        }
    } catch {}
}

function Play-Audio([string]$path) {
    Stop-Playback
    if (-not (Test-Path $path)) { [System.Windows.Forms.MessageBox]::Show("File not found: $path"); return }
    try {
        # Use NAudio's AudioFileReader for WAV/MP3 (MediaFoundation on Win10+)
        $reader = New-Object NAudio.Wave.AudioFileReader($path)
        $out = New-Object NAudio.Wave.WaveOutEvent
        $out.Init($reader)
        $Global:PlaybackReader = $reader
        $Global:PlaybackOut = $out
        $out.Play()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Playback error: $($_.Exception.Message)")
        Stop-Playback
    }
}

function Start-Recording {
    if ($Global:IsRecording) { return }
    try {
        $Global:OriginalPath = New-TempWav
        $format = New-Object NAudio.Wave.WaveFormat(44100, 16, 1) # 44.1kHz, mono
        $waveIn = New-Object NAudio.Wave.WaveInEvent
        $waveIn.WaveFormat = $format
        $writer = New-Object NAudio.Wave.WaveFileWriter($Global:OriginalPath, $format)

        $waveIn.add_DataAvailable({
            param($sender, $e)
            $writer.Write($e.Buffer, 0, $e.BytesRecorded)
        })
        $waveIn.add_RecordingStopped({
            param($sender, $e)
            try { $writer.Dispose() } catch {}
            try { $waveIn.Dispose() } catch {}
            $Global:WavWriter = $null
            $Global:WaveIn = $null
            $Global:IsRecording = $false
        })

        $Global:WaveIn = $waveIn
        $Global:WavWriter = $writer
        $Global:IsRecording = $true
        $waveIn.StartRecording()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Recording error: $($_.Exception.Message)")
        Stop-Recording
    }
}

function Stop-Recording {
    if (-not $Global:IsRecording) { return }
    try {
        $Global:WaveIn?.StopRecording()
    } catch {
        $Global:IsRecording = $false
        try { $Global:WavWriter?.Dispose() } catch {}
        try { $Global:WaveIn?.Dispose() } catch {}
        $Global:WavWriter = $null
        $Global:WaveIn = $null
    }
}

function Convert-Audio {
    if (-not $Global:OriginalPath) {
        [System.Windows.Forms.MessageBox]::Show("No original audio. Record or load a file first.")
        return
    }
    try {
        $convertedTmp = New-TempFile ".wav" # expected response; adjust if MP3
        $boundary = [Guid]::NewGuid().ToString("N")
        $contentType = "multipart/form-data; boundary=$boundary"

        # Build multipart body: file + config (JSON)
        $fileBytes = [System.IO.File]::ReadAllBytes($Global:OriginalPath)
        $jsonConfig = (ConvertTo-Json $Global:AI_Config -Depth 5)

        $sb = New-Object System.Text.StringBuilder
        $writer = New-Object System.IO.MemoryStream
        $enc = [System.Text.Encoding]::UTF8

        function WriteString($s) {
            $bytes = $enc.GetBytes($s)
            $writer.Write($bytes, 0, $bytes.Length)
        }

        # Part: config
        WriteString("--$boundary`r`n")
        WriteString("Content-Disposition: form-data; name=""config""" + "`r`n")
        WriteString("Content-Type: application/json" + "`r`n`r`n")
        WriteString($jsonConfig + "`r`n")

        # Part: file
        WriteString("--$boundary`r`n")
        WriteString("Content-Disposition: form-data; name=""file""; filename=""input.wav""" + "`r`n")
        WriteString("Content-Type: audio/wav" + "`r`n`r`n")
        $writer.Write($fileBytes, 0, $fileBytes.Length)
        WriteString("`r`n--$boundary--`r`n")
        $writer.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null

        $headers = @{
            "Content-Type" = $contentType
        }

        $client = New-Object System.Net.WebClient
        foreach ($k in $headers.Keys) { $client.Headers.Add($k, $headers[$k]) }
        $responseBytes = $client.UploadData($Global:AI_Endpoint, "POST", $writer.ToArray())
        [System.IO.File]::WriteAllBytes($convertedTmp, $responseBytes)
        $Global:ConvertedPath = $convertedTmp

        [System.Windows.Forms.MessageBox]::Show("Conversion complete.")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Conversion error: $($_.Exception.Message)")
    }
}

function Load-Original {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Audio Files|*.wav;*.mp3;*.flac;*.aac;*.m4a|All Files|*.*"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $Global:OriginalPath = $dlg.FileName
    }
}

function Save-Converted {
    if (-not $Global:ConvertedPath) {
        [System.Windows.Forms.MessageBox]::Show("No converted audio available.")
        return
    }
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "WAV|*.wav|MP3|*.mp3|All Files|*.*"
    $dlg.FileName = [System.IO.Path]::GetFileName($Global:ConvertedPath)
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            [System.IO.File]::Copy($Global:ConvertedPath, $dlg.FileName, $true)
            [System.Windows.Forms.MessageBox]::Show("Saved: $($dlg.FileName)")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Save error: $($_.Exception.Message)")
        }
    }
}

# UI
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI Voice Changer"
$form.Size = New-Object System.Drawing.Size(640, 360)
$form.StartPosition = "CenterScreen"

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Ready"
$lblStatus.AutoSize = $true
$lblStatus.Location = New-Object System.Drawing.Point(20, 20)

$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Load file..."
$btnLoad.Location = New-Object System.Drawing.Point(20, 60)
$btnLoad.Add_Click({ Load-Original(); $lblStatus.Text = "Original: " + ($Global:OriginalPath ?? "None") })

$btnRec = New-Object System.Windows.Forms.Button
$btnRec.Text = "Record"
$btnRec.Location = New-Object System.Drawing.Point(120, 60)
$btnRec.Add_Click({
    Start-Recording
    $lblStatus.Text = "Recording... (Press Stop)"
})

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "Stop"
$btnStop.Location = New-Object System.Drawing.Point(220, 60)
$btnStop.Add_Click({
    Stop-Recording
    $lblStatus.Text = "Original: " + ($Global:OriginalPath ?? "None")
})

$btnPlayOrig = New-Object System.Windows.Forms.Button
$btnPlayOrig.Text = "Play original"
$btnPlayOrig.Location = New-Object System.Drawing.Point(20, 110)
$btnPlayOrig.Add_Click({
    if ($Global:OriginalPath) { Play-Audio $Global:OriginalPath } else { [System.Windows.Forms.MessageBox]::Show("No original audio.") }
})

$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text = "Convert (AI)"
$btnConvert.Location = New-Object System.Drawing.Point(140, 110)
$btnConvert.Add_Click({
    $lblStatus.Text = "Converting..."
    Convert-Audio
    $lblStatus.Text = "Converted: " + ($Global:ConvertedPath ?? "None")
})

$btnPlayConv = New-Object System.Windows.Forms.Button
$btnPlayConv.Text = "Play converted"
$btnPlayConv.Location = New-Object System.Drawing.Point(260, 110)
$btnPlayConv.Add_Click({
    if ($Global:ConvertedPath) { Play-Audio $Global:ConvertedPath } else { [System.Windows.Forms.MessageBox]::Show("No converted audio.") }
})

$btnSaveConv = New-Object System.Windows.Forms.Button
$btnSaveConv.Text = "Save converted..."
$btnSaveConv.Location = New-Object System.Drawing.Point(380, 110)
$btnSaveConv.Add_Click({ Save-Converted })

$btnStopPlay = New-Object System.Windows.Forms.Button
$btnStopPlay.Text = "Stop playback"
$btnStopPlay.Location = New-Object System.Drawing.Point(500, 110)
$btnStopPlay.Add_Click({ Stop-Playback })

# Endpoint text box
$lblEndpoint = New-Object System.Windows.Forms.Label
$lblEndpoint.Text = "Endpoint:"
$lblEndpoint.AutoSize = $true
$lblEndpoint.Location = New-Object System.Drawing.Point(20, 170)

$txtEndpoint = New-Object System.Windows.Forms.TextBox
$txtEndpoint.Text = $Global:AI_Endpoint
$txtEndpoint.Width = 420
$txtEndpoint.Location = New-Object System.Drawing.Point(90, 166)
$txtEndpoint.Add_TextChanged({ $Global:AI_Endpoint = $txtEndpoint.Text })

# Config text box (JSON)
$lblConfig = New-Object System.Windows.Forms.Label
$lblConfig.Text = "Config (JSON):"
$lblConfig.AutoSize = $true
$lblConfig.Location = New-Object System.Drawing.Point(20, 205)

$txtConfig = New-Object System.Windows.Forms.TextBox
$txtConfig.Multiline = $true
$txtConfig.ScrollBars = "Vertical"
$txtConfig.Width = 560
$txtConfig.Height = 80
$txtConfig.Location = New-Object System.Drawing.Point(20, 225)
$txtConfig.Text = (ConvertTo-Json $Global:AI_Config -Depth 5)
$txtConfig.Add_TextChanged({
    try {
        $Global:AI_Config = ConvertFrom-Json $txtConfig.Text
        $lblStatus.Text = "Config OK"
    } catch {
        $lblStatus.Text = "Invalid JSON"
    }
})

$form.Controls.AddRange(@(
    $lblStatus, $btnLoad, $btnRec, $btnStop,
    $btnPlayOrig, $btnConvert, $btnPlayConv, $btnSaveConv, $btnStopPlay,
    $lblEndpoint, $txtEndpoint, $lblConfig, $txtConfig
))

$form.Add_FormClosing({
    Stop-Recording
    Stop-Playback
})

[void]$form.ShowDialog()
