Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Requires: pdftk or exiftool or custom PDF metadata tool in PATH
# Adjust $PdfMetaGetCmd and $PdfMetaSetCmd to your tooling.
# AI: adjust $AiCommand to your local LLM endpoint/CLI.

$PdfMetaGetCmd = "exiftool -j"
$PdfMetaSetCmd = "exiftool"
$AiCommand     = "python llm_helper.py"   # placeholder

function New-MainForm {
    $form                  = New-Object System.Windows.Forms.Form
    $form.Text             = "AI LLM PDF Metadata Editor"
    $form.StartPosition    = "CenterScreen"
    $form.Size             = New-Object System.Drawing.Size(900,600)

    # Controls
    $btnOpen               = New-Object System.Windows.Forms.Button
    $btnOpen.Text          = "Open PDF"
    $btnOpen.Location      = New-Object System.Drawing.Point(10,10)
    $btnOpen.Size          = New-Object System.Drawing.Size(100,30)

    $lblPath               = New-Object System.Windows.Forms.Label
    $lblPath.Text          = "No file loaded"
    $lblPath.Location      = New-Object System.Drawing.Point(120,15)
    $lblPath.Size          = New-Object System.Drawing.Size(750,20)
    $lblPath.AutoEllipsis  = $true

    $grid                  = New-Object System.Windows.Forms.DataGridView
    $grid.Location         = New-Object System.Drawing.Point(10,50)
    $grid.Size             = New-Object System.Drawing.Size(430,500)
    $grid.AllowUserToAddRows    = $false
    $grid.AllowUserToDeleteRows = $false
    $grid.RowHeadersVisible     = $false
    $grid.AutoSizeColumnsMode   = "Fill"
    $grid.SelectionMode         = "FullRowSelect"
    $grid.MultiSelect           = $false

    $colKey = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colKey.HeaderText = "Field"
    $colKey.ReadOnly   = $true
    $colVal = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colVal.HeaderText = "Value"
    $grid.Columns.AddRange(@($colKey,$colVal))

    # AI panel
    $lblAiIn               = New-Object System.Windows.Forms.Label
    $lblAiIn.Text          = "AI Prompt / Instructions"
    $lblAiIn.Location      = New-Object System.Drawing.Point(450,50)
    $lblAiIn.Size          = New-Object System.Drawing.Size(200,20)

    $txtAiPrompt           = New-Object System.Windows.Forms.TextBox
    $txtAiPrompt.Location  = New-Object System.Drawing.Point(450,70)
    $txtAiPrompt.Size      = New-Object System.Drawing.Size(420,100)
    $txtAiPrompt.Multiline = $true
    $txtAiPrompt.ScrollBars= "Vertical"

    $btnAiSuggest          = New-Object System.Windows.Forms.Button
    $btnAiSuggest.Text     = "Ask AI for metadata suggestions"
    $btnAiSuggest.Location = New-Object System.Drawing.Point(450,180)
    $btnAiSuggest.Size     = New-Object System.Drawing.Size(250,30)

    $lblAiOut              = New-Object System.Windows.Forms.Label
    $lblAiOut.Text         = "AI Suggestions (click to apply)"
    $lblAiOut.Location     = New-Object System.Drawing.Point(450,220)
    $lblAiOut.Size         = New-Object System.Drawing.Size(250,20)

    $lstAiSuggestions      = New-Object System.Windows.Forms.ListBox
    $lstAiSuggestions.Location = New-Object System.Drawing.Point(450,240)
    $lstAiSuggestions.Size     = New-Object System.Drawing.Size(420,200)

    $btnApplySuggestion    = New-Object System.Windows.Forms.Button
    $btnApplySuggestion.Text = "Apply selected suggestion to grid"
    $btnApplySuggestion.Location = New-Object System.Drawing.Point(450,450)
    $btnApplySuggestion.Size     = New-Object System.Drawing.Size(250,30)

    $btnSave               = New-Object System.Windows.Forms.Button
    $btnSave.Text          = "Save Metadata"
    $btnSave.Location      = New-Object System.Drawing.Point(450,500)
    $btnSave.Size          = New-Object System.Drawing.Size(150,30)

    $form.Controls.AddRange(@(
        $btnOpen,$lblPath,$grid,
        $lblAiIn,$txtAiPrompt,$btnAiSuggest,
        $lblAiOut,$lstAiSuggestions,$btnApplySuggestion,
        $btnSave
    ))

    # State
    $script:CurrentPdf = $null
    $script:CurrentMeta = @{}

    # Helpers
    function Load-PdfMetadata {
        param($path)
        $grid.Rows.Clear()
        $script:CurrentMeta = @{}

        if (-not (Test-Path $path)) { return }

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName  = "cmd.exe"
        $psi.Arguments = "/c $PdfMetaGetCmd `"$path`""
        $psi.RedirectStandardOutput = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $p = [System.Diagnostics.Process]::Start($psi)
        $out = $p.StandardOutput.ReadToEnd()
        $p.WaitForExit()

        try {
            $json = $out | ConvertFrom-Json
            $meta = $json[0]
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to parse metadata JSON.`nAdjust $PdfMetaGetCmd.","Error","OK","Error")
            return
        }

        foreach ($prop in $meta.PSObject.Properties) {
            if ($prop.Name -eq "SourceFile") { continue }
            $rowIndex = $grid.Rows.Add()
            $grid.Rows[$rowIndex].Cells[0].Value = $prop.Name
            $grid.Rows[$rowIndex].Cells[1].Value = [string]$prop.Value
            $script:CurrentMeta[$prop.Name] = [string]$prop.Value
        }
    }

    function Save-PdfMetadata {
        param($path)
        if (-not (Test-Path $path)) { return }

        $args = @()
        foreach ($row in $grid.Rows) {
            $key = [string]$row.Cells[0].Value
            $val = [string]$row.Cells[1].Value
            if ([string]::IsNullOrWhiteSpace($key)) { continue }
            $args += "-$key=`"$val`""
        }

        $cmd = "$PdfMetaSetCmd " + ($args -join " ") + " `"$path`""
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName  = "cmd.exe"
        $psi.Arguments = "/c $cmd"
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $p = [System.Diagnostics.Process]::Start($psi)
        $out = $p.StandardOutput.ReadToEnd()
        $err = $p.StandardError.ReadToEnd()
        $p.WaitForExit()

        if ($p.ExitCode -ne 0) {
            [System.Windows.Forms.MessageBox]::Show("Error saving metadata:`n$err","Error","OK","Error")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Metadata saved.","OK","OK","Information")
        }
    }

    function Call-AIForSuggestions {
        param($path,$prompt,$meta)

        $lstAiSuggestions.Items.Clear()
        if (-not $path) {
            [System.Windows.Forms.MessageBox]::Show("Load a PDF first.","AI","OK","Information")
            return
        }

        $metaJson = ($meta | ConvertTo-Json -Depth 5)
        $tempMeta = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempMeta -Value $metaJson -Encoding UTF8

        $cmd = "$AiCommand --pdf `"$path`" --meta `"$tempMeta`" --prompt `"$prompt`""
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName  = "cmd.exe"
        $psi.Arguments = "/c $cmd"
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $p = [System.Diagnostics.Process]::Start($psi)
        $out = $p.StandardOutput.ReadToEnd()
        $err = $p.StandardError.ReadToEnd()
        $p.WaitForExit()

        if ($p.ExitCode -ne 0) {
            [System.Windows.Forms.MessageBox]::Show("AI error:`n$err","AI","OK","Error")
            return
        }

        # Expect one suggestion per line: "Title=New title;Author=New author;..."
        $out -split "`r?`n" | ForEach-Object {
            $line = $_.Trim()
            if ($line.Length -gt 0) {
                [void]$lstAiSuggestions.Items.Add($line)
            }
        }
    }

    function Apply-AISuggestionToGrid {
        param($suggestion)
        if (-not $suggestion) { return }

        # Parse "Key=Value;Key2=Value2"
        $pairs = $suggestion -split ";"
        foreach ($pair in $pairs) {
            $kv = $pair -split "=",2
            if ($kv.Count -ne 2) { continue }
            $key = $kv[0].Trim()
            $val = $kv[1].Trim()

            foreach ($row in $grid.Rows) {
                if ([string]$row.Cells[0].Value -eq $key) {
                    $row.Cells[1].Value = $val
                    break
                }
            }
        }
    }

    # Events
    $btnOpen.Add_Click({
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Filter = "PDF files (*.pdf)|*.pdf|All files (*.*)|*.*"
        $dlg.Multiselect = $false
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $script:CurrentPdf = $dlg.FileName
            $lblPath.Text = $script:CurrentPdf
            Load-PdfMetadata -path $script:CurrentPdf
        }
    })

    $btnSave.Add_Click({
        if (-not $script:CurrentPdf) {
            [System.Windows.Forms.MessageBox]::Show("No PDF loaded.","Error","OK","Information")
            return
        }
        Save-PdfMetadata -path $script:CurrentPdf
    })

    $btnAiSuggest.Add_Click({
        $prompt = $txtAiPrompt.Text
        if ([string]::IsNullOrWhiteSpace($prompt)) {
            $prompt = "Suggest improved, consistent, and SEO-friendly metadata for this PDF."
        }
        Call-AIForSuggestions -path $script:CurrentPdf -prompt $prompt -meta $script:CurrentMeta
    })

    $btnApplySuggestion.Add_Click({
        $sel = $lstAiSuggestions.SelectedItem
        if (-not $sel) {
            [System.Windows.Forms.MessageBox]::Show("Select a suggestion first.","AI","OK","Information")
            return
        }
        Apply-AISuggestionToGrid -suggestion $sel
    })

    return $form
}

[void][System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-MainForm
[System.Windows.Forms.Application]::Run($form)
