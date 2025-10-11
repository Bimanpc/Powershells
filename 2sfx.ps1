#requires -version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

function New-ZipFromFolder {
    param(
        [Parameter(Mandatory=$true)][string]$SourceFolder,
        [Parameter(Mandatory=$true)][string]$ZipPath,
        [ValidateSet('Optimal','Fastest','NoCompression')][string]$Compression='Optimal'
    )
    if (Test-Path $ZipPath) { Remove-Item -Path $ZipPath -Force }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceFolder, $ZipPath, [System.IO.Compression.CompressionLevel]::$Compression, $false)
}

function New-ExtractorScript {
    param(
        [Parameter(Mandatory=$true)][string]$ZipPath,
        [Parameter(Mandatory=$true)][string]$OutputScriptPath,
        [string]$AppTitle = "Self-Extract Installer",
        [string]$DefaultExtractName = "Extracted"
    )

    # Read ZIP and convert to base64
    $bytes = [System.IO.File]::ReadAllBytes($ZipPath)
    $b64   = [System.Convert]::ToBase64String($bytes)

    # Minimal extractor stub with GUI
$stub = @"
# Self-extracting PowerShell archive
# Title: $AppTitle
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#requires -version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Base64 ZIP payload
\$PayloadBase64 = @'
$b64
'@

function Show-Extract-GUI {
    \$form = New-Object System.Windows.Forms.Form
    \$form.Text = "$AppTitle"
    \$form.Size = New-Object System.Drawing.Size(520,240)
    \$form.StartPosition = 'CenterScreen'
    \$form.TopMost = \$true

    \$lblDest = New-Object System.Windows.Forms.Label
    \$lblDest.Text = "Extract to folder:"
    \$lblDest.Location = New-Object System.Drawing.Point(12,20)
    \$lblDest.AutoSize = \$true

    \$tbDest = New-Object System.Windows.Forms.TextBox
    \$tbDest.Location = New-Object System.Drawing.Point(12,45)
    \$tbDest.Size = New-Object System.Drawing.Size(400,22)
    \$tbDest.Text = [System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), '$DefaultExtractName')

    \$btnBrowse = New-Object System.Windows.Forms.Button
    \$btnBrowse.Text = "Browse..."
    \$btnBrowse.Location = New-Object System.Drawing.Point(420,43)
    \$btnBrowse.Size = New-Object System.Drawing.Size(80,26)
    \$btnBrowse.Add_Click({
        \$fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        \$fbd.Description = "Choose destination folder"
        if (\$fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            \$tbDest.Text = \$fbd.SelectedPath
        }
    })

    \$pb = New-Object System.Windows.Forms.ProgressBar
    \$pb.Location = New-Object System.Drawing.Point(12,120)
    \$pb.Size = New-Object System.Drawing.Size(488,20)
    \$pb.Style = 'Continuous'
    \$pb.Minimum = 0
    \$pb.Maximum = 100
    \$pb.Value = 0

    \$lblStatus = New-Object System.Windows.Forms.Label
    \$lblStatus.Location = New-Object System.Drawing.Point(12,145)
    \$lblStatus.AutoSize = \$true
    \$lblStatus.Text = "Ready."

    \$btnExtract = New-Object System.Windows.Forms.Button
    \$btnExtract.Text = "Extract"
    \$btnExtract.Location = New-Object System.Drawing.Point(320,170)
    \$btnExtract.Size = New-Object System.Drawing.Size(90,28)

    \$btnCancel = New-Object System.Windows.Forms.Button
    \$btnCancel.Text = "Close"
    \$btnCancel.Location = New-Object System.Drawing.Point(410,170)
    \$btnCancel.Size = New-Object System.Drawing.Size(90,28)
    \$btnCancel.Add_Click({ \$form.Close() })

    \$btnExtract.Add_Click({
        try {
            if ([string]::IsNullOrWhiteSpace(\$tbDest.Text)) { throw "Destination is empty." }
            \$dest = \$tbDest.Text
            if (-not (Test-Path \$dest)) { [void](New-Item -ItemType Directory -Path \$dest -Force) }
            \$tmpZip = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "payload_" + [Guid]::NewGuid().ToString() + ".zip")

            \$lblStatus.Text = "Decoding payload..."
            \$pb.Value = 15
            [System.IO.File]::WriteAllBytes(\$tmpZip, [Convert]::FromBase64String(\$PayloadBase64))

            \$lblStatus.Text = "Extracting..."
            \$pb.Value = 60
            [System.IO.Compression.ZipFile]::ExtractToDirectory(\$tmpZip, \$dest)

            \$pb.Value = 100
            \$lblStatus.Text = "Completed."
            try { Remove-Item -Path \$tmpZip -Force -ErrorAction SilentlyContinue } catch {}
            [System.Windows.Forms.MessageBox]::Show("Files extracted to: `n" + \$dest, "$AppTitle", 'OK', 'Information')
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error: " + \$_.Exception.Message, "$AppTitle", 'OK', 'Error')
        }
    })

    \$form.Controls.AddRange(@(\$lblDest, \$tbDest, \$btnBrowse, \$pb, \$lblStatus, \$btnExtract, \$btnCancel))
    [void]\$form.ShowDialog()
}

Show-Extract-GUI
"@

    # Write extractor
    $dir = Split-Path -Path $OutputScriptPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($OutputScriptPath, $stub, [System.Text.Encoding]::UTF8)
}

# ----------------------
# Builder GUI
# ----------------------
function Show-Builder-GUI {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Self-Extract Builder"
    $form.Size = New-Object System.Drawing.Size(640, 340)
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true

    $lblSrc = New-Object System.Windows.Forms.Label
    $lblSrc.Text = "Source folder to package:"
    $lblSrc.Location = New-Object System.Drawing.Point(12,20)
    $lblSrc.AutoSize = $true

    $tbSrc = New-Object System.Windows.Forms.TextBox
    $tbSrc.Location = New-Object System.Drawing.Point(12,45)
    $tbSrc.Size = New-Object System.Drawing.Size(500,22)

    $btnBrowseSrc = New-Object System.Windows.Forms.Button
    $btnBrowseSrc.Text = "Browse..."
    $btnBrowseSrc.Location = New-Object System.Drawing.Point(520,43)
    $btnBrowseSrc.Size = New-Object System.Drawing.Size(90,26)
    $btnBrowseSrc.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "Choose source folder to package"
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $tbSrc.Text = $fbd.SelectedPath
        }
    })

    $lblOut = New-Object System.Windows.Forms.Label
    $lblOut.Text = "Output .ps1 (self-extract script):"
    $lblOut.Location = New-Object System.Drawing.Point(12,90)
    $lblOut.AutoSize = $true

    $tbOut = New-Object System.Windows.Forms.TextBox
    $tbOut.Location = New-Object System.Drawing.Point(12,115)
    $tbOut.Size = New-Object System.Drawing.Size(500,22)
    $tbOut.Text = [System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), "SelfExtract.ps1")

    $btnBrowseOut = New-Object System.Windows.Forms.Button
    $btnBrowseOut.Text = "Browse..."
    $btnBrowseOut.Location = New-Object System.Drawing.Point(520,113)
    $btnBrowseOut.Size = New-Object System.Drawing.Size(90,26)
    $btnBrowseOut.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "PowerShell Script (*.ps1)|*.ps1"
        $sfd.Title = "Save self-extract script"
        $sfd.FileName = "SelfExtract.ps1"
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $tbOut.Text = $sfd.FileName
        }
    })

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Extractor window title:"
    $lblTitle.Location = New-Object System.Drawing.Point(12,160)
    $lblTitle.AutoSize = $true

    $tbTitle = New-Object System.Windows.Forms.TextBox
    $tbTitle.Location = New-Object System.Drawing.Point(12,185)
    $tbTitle.Size = New-Object System.Drawing.Size(300,22)
    $tbTitle.Text = "Self-Extract Installer"

    $lblDefaultName = New-Object System.Windows.Forms.Label
    $lblDefaultName.Text = "Default destination folder name:"
    $lblDefaultName.Location = New-Object System.Drawing.Point(330,160)
    $lblDefaultName.AutoSize = $true

    $tbDefaultName = New-Object System.Windows.Forms.TextBox
    $tbDefaultName.Location = New-Object System.Drawing.Point(330,185)
    $tbDefaultName.Size = New-Object System.Drawing.Size(280,22)
    $tbDefaultName.Text = "Extracted"

    $lblCompression = New-Object System.Windows.Forms.Label
    $lblCompression.Text = "Compression level:"
    $lblCompression.Location = New-Object System.Drawing.Point(12,220)
    $lblCompression.AutoSize = $true

    $cbCompression = New-Object System.Windows.Forms.ComboBox
    $cbCompression.Location = New-Object System.Drawing.Point(12,245)
    $cbCompression.Size = New-Object System.Drawing.Size(150,22)
    $cbCompression.DropDownStyle = 'DropDownList'
    [void]$cbCompression.Items.AddRange(@('Optimal','Fastest','NoCompression'))
    $cbCompression.SelectedItem = 'Optimal'

    $pb = New-Object System.Windows.Forms.ProgressBar
    $pb.Location = New-Object System.Drawing.Point(12,280)
    $pb.Size = New-Object System.Drawing.Size(598,20)
    $pb.Style = 'Continuous'
    $pb.Minimum = 0
    $pb.Maximum = 100
    $pb.Value = 0

    $btnBuild = New-Object System.Windows.Forms.Button
    $btnBuild.Text = "Build"
    $btnBuild.Location = New-Object System.Drawing.Point(520,240)
    $btnBuild.Size = New-Object System.Drawing.Size(90,28)

    $btnBuild.Add_Click({
        try {
            if (-not (Test-Path $tbSrc.Text)) { throw "Source folder not found." }
            if ([string]::IsNullOrWhiteSpace($tbOut.Text)) { throw "Output script path is empty." }

            $tempZip = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "pkg_" + [Guid]::NewGuid().ToString() + ".zip")

            $pb.Value = 10
            $pb.Refresh()

            New-ZipFromFolder -SourceFolder $tbSrc.Text -ZipPath $tempZip -Compression $cbCompression.SelectedItem
            $pb.Value = 60

            New-ExtractorScript -ZipPath $tempZip -OutputScriptPath $tbOut.Text -AppTitle $tbTitle.Text -DefaultExtractName $tbDefaultName.Text
            $pb.Value = 95

            try { Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue } catch {}
            $pb.Value = 100

            [System.Windows.Forms.MessageBox]::Show("Self-extract script created:`n$($tbOut.Text)", "Builder", 'OK', 'Information')
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error: " + $_.Exception.Message, "Builder", 'OK', 'Error')
        }
    })

    $form.Controls.AddRange(@(
        $lblSrc,$tbSrc,$btnBrowseSrc,
        $lblOut,$tbOut,$btnBrowseOut,
        $lblTitle,$tbTitle,
        $lblDefaultName,$tbDefaultName,
        $lblCompression,$cbCompression,
        $pb,$btnBuild
    ))

    [void]$form.ShowDialog()
}

Show-Builder-GUI
