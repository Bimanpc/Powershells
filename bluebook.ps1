Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =========================
# CONFIG (EDIT AS NEEDED)
# =========================

# Local LLM-style endpoint (OpenAI-compatible JSON API)
$Global:LLM_Endpoint = "http://localhost:8000/v1/chat/completions"
$Global:LLM_Model    = "local-llm"

# =========================
# CORE: FILE CRAWLER
# =========================

function Get-CDInfo {
    param(
        [string]$RootPath,
        [switch]$Recurse
    )

    if (-not (Test-Path $RootPath)) {
        throw "Path not found: $RootPath"
    }

    $opt = @{}
    if ($Recurse) { $opt.Recurse = $true }

    Get-ChildItem -LiteralPath $RootPath -File @opt | ForEach-Object {
        [PSCustomObject]@{
            Name      = $_.Name
            FullName  = $_.FullName
            Extension = $_.Extension
            Length    = $_.Length
            Created   = $_.CreationTime
            Modified  = $_.LastWriteTime
        }
    }
}

# =========================
# CORE: LLM ANALYSIS HOOK
# =========================

function Invoke-LLMAnalysis {
    param(
        [Parameter(Mandatory=$true)]
        [array]$FileInfoObjects
    )

    # Minimal prompt: summarize contents of this "CD"
    $summaryPrompt = @"
You are analyzing metadata of files from a mounted CD/DVD.
Summarize what kind of content this disc likely contains.
Focus on file types, sizes, and any patterns.

Here is the JSON metadata:
$(($FileInfoObjects | ConvertTo-Json -Depth 4))
"@

    $body = @{
        model = $Global:LLM_Model
        messages = @(
            @{
                role    = "user"
                content = $summaryPrompt
            }
        )
        temperature = 0.2
    } | ConvertTo-Json -Depth 5

    try {
        # NOTE: No telemetry beyond this explicit call.
        # Wire this to your local-only LLM endpoint.
        $resp = Invoke-RestMethod -Uri $Global:LLM_Endpoint -Method Post -ContentType "application/json" -Body $body -TimeoutSec 120

        # OpenAI-style response parsing
        if ($resp.choices -and $resp.choices[0].message.content) {
            return $resp.choices[0].message.content
        } else {
            return "LLM response did not contain expected 'choices[0].message.content'. Raw: " + ($resp | ConvertTo-Json -Depth 5)
        }
    }
    catch {
        return "LLM call failed: $($_.Exception.Message)"
    }
}

# =========================
# GUI
# =========================

$form                  = New-Object System.Windows.Forms.Form
$form.Text             = "AI CD Info Crawler (Ubuntu Mount Friendly)"
$form.Size             = New-Object System.Drawing.Size(900,600)
$form.StartPosition    = "CenterScreen"

# Path label
$lblPath               = New-Object System.Windows.Forms.Label
$lblPath.Text          = "Mounted path (Ubuntu CD/DVD, SMB, NFS, WSL, etc.):"
$lblPath.AutoSize      = $true
$lblPath.Location      = New-Object System.Drawing.Point(10,15)

# Path textbox
$txtPath               = New-Object System.Windows.Forms.TextBox
$txtPath.Location      = New-Object System.Drawing.Point(10,35)
$txtPath.Size          = New-Object System.Drawing.Size(650,20)
$txtPath.Text          = "/mnt/cdrom"  # adjust as needed

# Recurse checkbox
$chkRecurse            = New-Object System.Windows.Forms.CheckBox
$chkRecurse.Text       = "Recurse subdirectories"
$chkRecurse.AutoSize   = $true
$chkRecurse.Location   = New-Object System.Drawing.Point(10,60)
$chkRecurse.Checked    = $true

# Scan button
$btnScan               = New-Object System.Windows.Forms.Button
$btnScan.Text          = "Scan"
$btnScan.Location      = New-Object System.Drawing.Point(700,30)
$btnScan.Size          = New-Object System.Drawing.Size(80,30)

# Export button
$btnExport             = New-Object System.Windows.Forms.Button
$btnExport.Text        = "Export JSON"
$btnExport.Location    = New-Object System.Drawing.Point(790,30)
$btnExport.Size        = New-Object System.Drawing.Size(90,30)
$btnExport.Enabled     = $false

# LLM analyze button
$btnLLM                = New-Object System.Windows.Forms.Button
$btnLLM.Text           = "Analyze with LLM"
$btnLLM.Location       = New-Object System.Drawing.Point(700,65)
$btnLLM.Size           = New-Object System.Drawing.Size(180,30)
$btnLLM.Enabled        = $false

# Status label
$lblStatus             = New-Object System.Windows.Forms.Label
$lblStatus.AutoSize    = $true
$lblStatus.Location    = New-Object System.Drawing.Point(10,90)
$lblStatus.Text        = "Ready."

# ListView for files
$listView              = New-Object System.Windows.Forms.ListView
$listView.Location     = New-Object System.Drawing.Point(10,115)
$listView.Size         = New-Object System.Drawing.Size(860,250)
$listView.View         = [System.Windows.Forms.View]::Details
$listView.FullRowSelect= $true
$listView.GridLines    = $true

[void]$listView.Columns.Add("Name",      200)
[void]$listView.Columns.Add("Extension", 80)
[void]$listView.Columns.Add("Size (B)",  100)
[void]$listView.Columns.Add("Created",   200)
[void]$listView.Columns.Add("Modified",  200)

# Textbox for LLM output
$txtLLM                = New-Object System.Windows.Forms.TextBox
$txtLLM.Location       = New-Object System.Drawing.Point(10,380)
$txtLLM.Size           = New-Object System.Drawing.Size(860,160)
$txtLLM.Multiline      = $true
$txtLLM.ScrollBars     = "Vertical"
$txtLLM.ReadOnly       = $true

# In-memory data
$Global:CurrentFiles   = @()

# =========================
# EVENT HANDLERS
# =========================

$btnScan.Add_Click({
    $path = $txtPath.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($path)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a path.","Missing Path","OK","Warning") | Out-Null
        return
    }

    $lblStatus.Text = "Scanning..."
    $form.Refresh()

    try {
        $recurse = $chkRecurse.Checked
        $files = Get-CDInfo -RootPath $path -Recurse:($recurse)

        $Global:CurrentFiles = $files

        $listView.Items.Clear()
        foreach ($f in $files) {
            $item = New-Object System.Windows.Forms.ListViewItem($f.Name)
            [void]$item.SubItems.Add($f.Extension)
            [void]$item.SubItems.Add([string]$f.Length)
            [void]$item.SubItems.Add($f.Created.ToString("yyyy-MM-dd HH:mm:ss"))
            [void]$item.SubItems.Add($f.Modified.ToString("yyyy-MM-dd HH:mm:ss"))
            [void]$listView.Items.Add($item)
        }

        $count = $files.Count
        $lblStatus.Text = "Scan complete. Files: $count"
        $btnExport.Enabled = $count -gt 0
        $btnLLM.Enabled    = $count -gt 0
    }
    catch {
        $lblStatus.Text = "Error: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Error","OK","Error") | Out-Null
    }
})

$btnExport.Add_Click({
    if (-not $Global:CurrentFiles -or $Global:CurrentFiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No data to export.","Info","OK","Information") | Out-Null
        return
    }

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*"
    $dialog.Title  = "Export CD file metadata as JSON"
    $dialog.FileName = "cd_metadata.json"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $json = $Global:CurrentFiles | ConvertTo-Json -Depth 5
            [System.IO.File]::WriteAllText($dialog.FileName, $json)
            $lblStatus.Text = "Exported to: $($dialog.FileName)"
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Export Error","OK","Error") | Out-Null
        }
    }
})

$btnLLM.Add_Click({
    if (-not $Global:CurrentFiles -or $Global:CurrentFiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No data to analyze.","Info","OK","Information") | Out-Null
        return
    }

    $lblStatus.Text = "Calling LLM..."
    $form.Refresh()

    $analysis = Invoke-LLMAnalysis -FileInfoObjects $Global:CurrentFiles
    $txtLLM.Text = $analysis
    $lblStatus.Text = "LLM analysis complete."
})

# =========================
# ADD CONTROLS & RUN
# =========================

$form.Controls.Add($lblPath)
$form.Controls.Add($txtPath)
$form.Controls.Add($chkRecurse)
$form.Controls.Add($btnScan)
$form.Controls.Add($btnExport)
$form.Controls.Add($btnLLM)
$form.Controls.Add($lblStatus)
$form.Controls.Add($listView)
$form.Controls.Add($txtLLM)

[void]$form.ShowDialog()
