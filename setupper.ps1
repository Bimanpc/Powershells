<# 
SFX EXE Maker (IExpress-based)
- Single .ps1 GUI
- No external dependencies (uses Windows' iexpress.exe)
- Admin-aware (auto-elevate; can wrap post-install command in RunAs)
- Supports files/folders, custom extract dir, post-install command, silent mode
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Auto-elevate if needed ---
function Ensure-Admin {
    $current = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Attempting elevation..."
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        $psi.Verb = "runas"
        try {
            [System.Diagnostics.Process]::Start($psi) | Out-Null
            exit
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Elevation was canceled. Some actions may fail.", "SFX EXE Maker", 'OK', 'Warning')
        }
    }
}
Ensure-Admin

# --- Helpers ---
function New-TempDir {
    $p = Join-Path $env:TEMP ("SFX_" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $p -Force | Out-Null
    return $p
}
function Safe-Delete($path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return }
    try { Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}
function Copy-Items($items, $destRoot) {
    foreach ($it in $items) {
        if (Test-Path $it) {
            if ((Get-Item $it).PSIsContainer) {
                Copy-Item $it -Destination (Join-Path $destRoot (Split-Path $it -Leaf)) -Recurse -Force
            } else {
                $dir = Join-Path $destRoot "Files"
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Copy-Item $it -Destination $dir -Force
            }
        }
    }
}

# Build SED content for IExpress
function Build-SED {
    param(
        [string]$TargetName,
        [string]$FriendlyName,
        [string]$ExtractTitle,
        [string]$DefaultExtractDir,
        [string]$PostInstallCmd,
        [bool]$Silent,
        [string[]]$SourcePaths
    )

    # Create a staging folder and flatten inputs
    $stage = New-TempDir
    Copy-Items -items $SourcePaths -destRoot $stage

    # Enumerate files in staging
    $allFiles = Get-ChildItem -Path $stage -Recurse -File
    if ($allFiles.Count -eq 0) { throw "No files to package." }

    # IExpress requires CAB name; we'll base it on target
    $cabName = ([System.IO.Path]::GetFileNameWithoutExtension($TargetName)) + ".cab"

    # Build [SourceFiles] section with buckets (SourceFiles0)
    $sourceDir = $stage
    $sourceFilesSection = @()
    $sourceFilesHeader = "[SourceFiles]`r`nSourceFiles0=$sourceDir`r`n"
    $i = 0
    foreach ($f in $allFiles) {
        $relative = $f.FullName.Substring($sourceDir.Length).TrimStart('\')
        # Map each file in its bucket [SourceFiles0]
        $sourceFilesSection += "%FILE$i%=$sourceDir\$relative"
        $i++
    }
    $sourceFilesBlock = $sourceFilesHeader + "[SourceFiles0]`r`n" + ($sourceFilesSection -join "`r`n") + "`r`n"

    # Strings section for clean references
    $strings = @"
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$TargetName
FriendlyName=$FriendlyName
AppLaunched=$PostInstallCmd
PostInstallCmd=
"@

    # Options
    $showWindow = $Silent ? 0 : 1
    $hideAnim  = $Silent ? 1 : 0
    $installPrompt = $Silent ? "" : ""
    $finishMsg = $Silent ? "" : "Installation completed."

    $options = @"
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=$showWindow
HideExtractAnimation=$hideAnim
UseLongFileName=1
InsideCompressed=1
CAB_FixedSize=0
CAB_ResvSize=0
RebootMode=I
InstallPrompt=
DisplayLicense=
FinishMessage=$finishMsg
TargetName=$TargetName
FriendlyName=$FriendlyName
AppLaunched=$PostInstallCmd
PostInstallCmd=
DefaultExtractDir=$DefaultExtractDir
"@

    $version = @"
[Version]
Class=IEXPRESS
SEDVersion=3
"@

    # File mappings: Reference tokens in [SourceFiles0] require a [File] list
    # IExpress uses a [File] list (Packages built from buckets); we add each as a [File] with token FILEi
    $fileList = "[File]" + "`r`n" + (($sourceFilesSection | ForEach-Object {
        # Convert "%FILEi%=path" into "FILEi="
        $_ -replace '^%(.+?)%=', '$1='
    }) -join "`r`n") + "`r`n"

    # Final SED content
    $sedContent = $version + $options + $strings + $sourceFilesBlock + $fileList

    return [pscustomobject]@{
        SedContent = $sedContent
        StageDir   = $stage
        FilesCount = $allFiles.Count
        CabName    = $cabName
    }
}

function Build-IExpress {
    param(
        [string]$SedPath
    )
    $iexp = "$env:SystemRoot\System32\iexpress.exe"
    if (-not (Test-Path $iexp)) { throw "IExpress not found at $iexp" }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName  = $iexp
    $psi.Arguments = "/N /M `"$SedPath`""
    $psi.UseShellExecute = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.WaitForExit()
    return $p.ExitCode
}

# --- GUI ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "SFX EXE Maker (IExpress)"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(800, 600)

$lst = New-Object System.Windows.Forms.ListView
$lst.View = 'Details'
$lst.FullRowSelect = $true
$lst.Columns.Add("Path", 650) | Out-Null
$lst.Location = New-Object System.Drawing.Point(10, 10)
$lst.Size = New-Object System.Drawing.Size(760, 260)

$btnAddFiles = New-Object System.Windows.Forms.Button
$btnAddFiles.Text = "Add files"
$btnAddFiles.Location = New-Object System.Drawing.Point(10, 280)

$btnAddFolder = New-Object System.Windows.Forms.Button
$btnAddFolder.Text = "Add folder"
$btnAddFolder.Location = New-Object System.Drawing.Point(110, 280)

$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = "Remove selected"
$btnRemove.Location = New-Object System.Drawing.Point(220, 280)

$lblOut = New-Object System.Windows.Forms.Label
$lblOut.Text = "Output EXE:"
$lblOut.Location = New-Object System.Drawing.Point(10, 320)
$lblOut.AutoSize = $true

$txtOut = New-Object System.Windows.Forms.TextBox
$txtOut.Location = New-Object System.Drawing.Point(100, 318)
$txtOut.Size = New-Object System.Drawing.Size(560, 24)

$btnOut = New-Object System.Windows.Forms.Button
$btnOut.Text = "Browse"
$btnOut.Location = New-Object System.Drawing.Point(670, 316)

$lblFriendly = New-Object System.Windows.Forms.Label
$lblFriendly.Text = "Friendly name:"
$lblFriendly.Location = New-Object System.Drawing.Point(10, 350)
$lblFriendly.AutoSize = $true

$txtFriendly = New-Object System.Windows.Forms.TextBox
$txtFriendly.Location = New-Object System.Drawing.Point(120, 348)
$txtFriendly.Size = New-Object System.Drawing.Size(650, 24)
$txtFriendly.Text = "My SFX Installer"

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Extract title:"
$lblTitle.Location = New-Object System.Drawing.Point(10, 380)
$lblTitle.AutoSize = $true

$txtTitle = New-Object System.Windows.Forms.TextBox
$txtTitle.Location = New-Object System.Drawing.Point(100, 378)
$txtTitle.Size = New-Object System.Drawing.Size(670, 24)
$txtTitle.Text = "Extracting files..."

$lblExtractDir = New-Object System.Windows.Forms.Label
$lblExtractDir.Text = "Default extract dir:"
$lblExtractDir.Location = New-Object System.Drawing.Point(10, 410)
$lblExtractDir.AutoSize = $true

$txtExtractDir = New-Object System.Windows.Forms.TextBox
$txtExtractDir.Location = New-Object System.Drawing.Point(130, 408)
$txtExtractDir.Size = New-Object System.Drawing.Size(640, 24)
$txtExtractDir.Text = "%TEMP%\\MySFX"  # IExpress supports env vars

$lblCmd = New-Object System.Windows.Forms.Label
$lblCmd.Text = "Post-extract command:"
$lblCmd.Location = New-Object System.Drawing.Point(10, 440)
$lblCmd.AutoSize = $true

$txtCmd = New-Object System.Windows.Forms.TextBox
$txtCmd.Location = New-Object System.Drawing.Point(150, 438)
$txtCmd.Size = New-Object System.Drawing.Size(620, 24)
$txtCmd.Text = "cmd.exe /c setup.bat"

$chkSilent = New-Object System.Windows.Forms.CheckBox
$chkSilent.Text = "Silent (no UI)"
$chkSilent.Location = New-Object System.Drawing.Point(10, 470)
$chkSilent.AutoSize = $true

$chkElevate = New-Object System.Windows.Forms.CheckBox
$chkElevate.Text = "Elevate post-extract command (RunAs)"
$chkElevate.Location = New-Object System.Drawing.Point(130, 470)
$chkElevate.AutoSize = $true

$btnBuild = New-Object System.Windows.Forms.Button
$btnBuild.Text = "Build SFX EXE"
$btnBuild.Location = New-Object System.Drawing.Point(10, 510)
$btnBuild.Size = New-Object System.Drawing.Size(180, 30)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(200, 510)
$progress.Size = New-Object System.Drawing.Size(570, 30)
$progress.Style = 'Continuous'
$progress.Minimum = 0
$progress.Maximum = 100

# --- Wire up events ---
$btnAddFiles.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Multiselect = $true
    $ofd.Title = "Add files"
    if ($ofd.ShowDialog() -eq 'OK') {
        foreach ($f in $ofd.FileNames) {
            $item = New-Object System.Windows.Forms.ListViewItem($f)
            $lst.Items.Add($item) | Out-Null
        }
    }
})

$btnAddFolder.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "Add folder (will be copied recursively)"
    if ($fbd.ShowDialog() -eq 'OK') {
        $item = New-Object System.Windows.Forms.ListViewItem($fbd.SelectedPath)
        $lst.Items.Add($item) | Out-Null
    }
})

$btnRemove.Add_Click({
    foreach ($i in @($lst.SelectedItems)) { $lst.Items.Remove($i) }
})

$btnOut.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Title = "Output EXE"
    $sfd.Filter = "Executable (*.exe)|*.exe"
    if ($sfd.ShowDialog() -eq 'OK') { $txtOut.Text = $sfd.FileName }
})

$btnBuild.Add_Click({
    try {
        if ($lst.Items.Count -eq 0) { throw "Add files or a folder first." }
        if ([string]::IsNullOrWhiteSpace($txtOut.Text)) { throw "Set an output EXE path." }

        $progress.Value = 10

        # Collect sources
        $sources = @()
        foreach ($i in $lst.Items) { $sources += $i.Text }

        # Elevation wrapper if requested
        $postCmd = $txtCmd.Text
        if ($chkElevate.Checked -and -not [string]::IsNullOrWhiteSpace($postCmd)) {
            # Wrap the command to run elevated after extraction
            $escaped = $postCmd.Replace('"','\"')
            $postCmd = "powershell.exe -NoProfile -Command ""Start-Process -FilePath 'cmd.exe' -ArgumentList '/c $escaped' -Verb RunAs"""
        }

        $sedObj = Build-SED -TargetName $txtOut.Text `
                            -FriendlyName $txtFriendly.Text `
                            -ExtractTitle $txtTitle.Text `
                            -DefaultExtractDir $txtExtractDir.Text `
                            -PostInstallCmd $postCmd `
                            -Silent $chkSilent.Checked `
                            -SourcePaths $sources

        $progress.Value = 40

        # Write SED
        $sedPath = Join-Path $sedObj.StageDir "package.sed"
        [IO.File]::WriteAllText($sedPath, $sedObj.SedContent, [Text.Encoding]::Unicode)  # IExpress expects Unicode

        $progress.Value = 60

        # Build
        $code = Build-IExpress -SedPath $sedPath
        $progress.Value = 85

        if ($code -ne 0) {
            throw "IExpress failed with exit code $code."
        }

        $progress.Value = 100
        [System.Windows.Forms.MessageBox]::Show("SFX built: `n$($txtOut.Text)", "Success", 'OK', 'Information') | Out-Null

        # Cleanup staging
        Safe-Delete $sedObj.StageDir
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "SFX EXE Maker", 'OK', 'Error') | Out-Null
    }
})

# --- Layout ---
$form.Controls.AddRange(@(
    $lst, $btnAddFiles, $btnAddFolder, $btnRemove,
    $lblOut, $txtOut, $btnOut,
    $lblFriendly, $txtFriendly,
    $lblTitle, $txtTitle,
    $lblExtractDir, $txtExtractDir,
    $lblCmd, $txtCmd,
    $chkSilent, $chkElevate,
    $btnBuild, $progress
))

[void]$form.ShowDialog()
