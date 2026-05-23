Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =========================
# CONFIG
# =========================
# Path to Calibre's ebook-convert (adjust if needed)
$Global:EbookConvertPath = "C:\Program Files\Calibre2\ebook-convert.exe"

# Optional: AI pre/post-processing hook (local HTTP endpoint, python script, etc.)
function Invoke-AIPipeline {
    param(
        [string]$PdfPath,
        [string]$TempPdfPath,
        [string]$LogCallback
    )

    # Example: copy as-is (no AI). Replace this block with your AI pipeline.
    & $LogCallback "AI pipeline: passthrough (no-op)."
    Copy-Item -Path $PdfPath -Destination $TempPdfPath -Force
}

# =========================
# CORE CONVERSION
# =========================
function Convert-PdfToEpub {
    param(
        [string]$PdfPath,
        [string]$EpubPath,
        [System.Windows.Forms.TextBox]$LogBox,
        [System.Windows.Forms.ProgressBar]$ProgressBar
    )

    $log = {
        param($msg)
        $LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
        $LogBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }

    if (-not (Test-Path $PdfPath)) {
        & $log "ERROR: PDF not found."
        return
    }

    if (-not (Test-Path $Global:EbookConvertPath)) {
        & $log "ERROR: ebook-convert not found at: $Global:EbookConvertPath"
        return
    }

    try {
        $ProgressBar.Style = 'Marquee'
        $ProgressBar.MarqueeAnimationSpeed = 30
        & $log "Starting AI PDF → EPUB pipeline..."
        & $log "Input: $PdfPath"
        & $log "Output: $EpubPath"

        # Temp PDF after AI processing
        $tempPdf = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($EpubPath),
                                             ([System.IO.Path]::GetFileNameWithoutExtension($EpubPath) + "_ai.pdf"))

        # --- AI PIPELINE HOOK ---
        Invoke-AIPipeline -PdfPath $PdfPath -TempPdfPath $tempPdf -LogCallback $log

        if (-not (Test-Path $tempPdf)) {
            & $log "ERROR: AI pipeline did not produce temp PDF."
            return
        }

        & $log "Running ebook-convert..."
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Global:EbookConvertPath
        $psi.Arguments = "`"$tempPdf`" `"$EpubPath`""
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $psi
        $null = $p.Start()

        while (-not $p.HasExited) {
            $outLine = $p.StandardOutput.ReadLine()
            if ($outLine) { & $log $outLine }
            $errLine = $p.StandardError.ReadLine()
            if ($errLine) { & $log "ERR: $errLine" }
            Start-Sleep -Milliseconds 100
            [System.Windows.Forms.Application]::DoEvents()
        }

        # Flush remaining output
        while (-not $p.StandardOutput.EndOfStream) {
            & $log $p.StandardOutput.ReadLine()
        }
        while (-not $p.StandardError.EndOfStream) {
            & $log ("ERR: " + $p.StandardError.ReadLine())
        }

        if ($p.ExitCode -eq 0) {
            & $log "SUCCESS: EPUB created."
        } else {
            & $log "FAILED: ebook-convert exit code $($p.ExitCode)."
        }
    }
    catch {
        & $log "EXCEPTION: $($_.Exception.Message)"
    }
    finally {
        $ProgressBar.Style = 'Blocks'
        $ProgressBar.MarqueeAnimationSpeed = 0
        $ProgressBar.Value = 0
    }
}

# =========================
# GUI
# =========================
$form                  = New-Object System.Windows.Forms.Form
$form.Text             = "AI PDF → EPUB Converter"
$form.Size             = New-Object System.Drawing.Size(700, 450)
$form.StartPosition    = "CenterScreen"
$form.TopMost          = $false

# Input PDF
$lblPdf                = New-Object System.Windows.Forms.Label
$lblPdf.Text           = "PDF file:"
$lblPdf.Location       = New-Object System.Drawing.Point(10, 15)
$lblPdf.AutoSize       = $true

$txtPdf                = New-Object System.Windows.Forms.TextBox
$txtPdf.Location       = New-Object System.Drawing.Point(80, 10)
$txtPdf.Size           = New-Object System.Drawing.Size(480, 20)

$btnBrowsePdf          = New-Object System.Windows.Forms.Button
$btnBrowsePdf.Text     = "Browse..."
$btnBrowsePdf.Location = New-Object System.Drawing.Point(570, 8)
$btnBrowsePdf.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "PDF files (*.pdf)|*.pdf|All files (*.*)|*.*"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtPdf.Text = $ofd.FileName
        if (-not $txtEpub.Text) {
            $txtEpub.Text = [System.IO.Path]::ChangeExtension($ofd.FileName, ".epub")
        }
    }
})

# Output EPUB
$lblEpub                = New-Object System.Windows.Forms.Label
$lblEpub.Text           = "EPUB file:"
$lblEpub.Location       = New-Object System.Drawing.Point(10, 45)
$lblEpub.AutoSize       = $true

$txtEpub                = New-Object System.Windows.Forms.TextBox
$txtEpub.Location       = New-Object System.Drawing.Point(80, 40)
$txtEpub.Size           = New-Object System.Drawing.Size(480, 20)

$btnBrowseEpub          = New-Object System.Windows.Forms.Button
$btnBrowseEpub.Text     = "Browse..."
$btnBrowseEpub.Location = New-Object System.Drawing.Point(570, 38)
$btnBrowseEpub.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "EPUB files (*.epub)|*.epub|All files (*.*)|*.*"
    if ($txtEpub.Text) {
        $sfd.FileName = [System.IO.Path]::GetFileName($txtEpub.Text)
        $sfd.InitialDirectory = [System.IO.Path]::GetDirectoryName($txtEpub.Text)
    }
    if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtEpub.Text = $sfd.FileName
    }
})

# Convert button
$btnConvert              = New-Object System.Windows.Forms.Button
$btnConvert.Text         = "Convert"
$btnConvert.Location     = New-Object System.Drawing.Point(10, 75)
$btnConvert.Size         = New-Object System.Drawing.Size(100, 28)

# Progress bar
$progress                = New-Object System.Windows.Forms.ProgressBar
$progress.Location       = New-Object System.Drawing.Point(120, 78)
$progress.Size           = New-Object System.Drawing.Size(540, 20)
$progress.Style          = 'Blocks'

# Log textbox
$txtLog                  = New-Object System.Windows.Forms.TextBox
$txtLog.Location         = New-Object System.Drawing.Point(10, 115)
$txtLog.Size             = New-Object System.Drawing.Size(650, 280)
$txtLog.Multiline        = $true
$txtLog.ScrollBars       = "Vertical"
$txtLog.ReadOnly         = $true
$txtLog.Font             = New-Object System.Drawing.Font("Consolas", 9)

$btnConvert.Add_Click({
    $pdf  = $txtPdf.Text.Trim()
    $epub = $txtEpub.Text.Trim()

    if (-not $pdf) {
        [System.Windows.Forms.MessageBox]::Show("Select a PDF file first.","Missing input",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    if (-not $epub) {
        [System.Windows.Forms.MessageBox]::Show("Specify an EPUB output path.","Missing output",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    Convert-PdfToEpub -PdfPath $pdf -EpubPath $epub -LogBox $txtLog -ProgressBar $progress
})

$form.Controls.AddRange(@(
    $lblPdf, $txtPdf, $btnBrowsePdf,
    $lblEpub, $txtEpub, $btnBrowseEpub,
    $btnConvert, $progress,
    $txtLog
))

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)
