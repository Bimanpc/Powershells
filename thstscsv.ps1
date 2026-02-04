<#
.SYNOPSIS
  Single-file PowerShell GUI: AI LLM CSV Opener

.DESCRIPTION
  - Open a CSV file and preview it in a grid.
  - Optional: send selected rows / whole CSV + prompt to an LLM backend.
  - Backend call is stubbed with a clear contract region for you to wire up.

.NOTES
  - Run with:  powershell.exe -ExecutionPolicy Bypass -File .\CsvAiOpener.ps1
  - Requires: .NET (WinForms) – standard on Windows.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#-----------------------------#
# Helper: Load CSV to DataTable
#-----------------------------#
function Import-CsvToDataTable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }

    $csv = Import-Csv -Path $Path
    $dt  = New-Object System.Data.DataTable

    if (-not $csv) {
        return $dt
    }

    # Create columns from first object
    $first = $csv[0]
    foreach ($prop in $first.PSObject.Properties.Name) {
        [void]$dt.Columns.Add($prop) 
    }

    # Add rows
    foreach ($row in $csv) {
        $dr = $dt.NewRow()
        foreach ($prop in $row.PSObject.Properties.Name) {
            $dr[$prop] = [string]$row.$prop
        }
        [void]$dt.Rows.Add($dr)
    }

    return $dt
}

#-----------------------------#
# Helper: Convert selected rows to CSV text
#-----------------------------#
function Get-SelectedRowsCsvText {
    param(
        [System.Windows.Forms.DataGridView]$Grid
    )

    if (-not $Grid.DataSource) {
        return ""
    }

    $dt = [System.Data.DataTable]$Grid.DataSource

    # If no rows selected, use all rows
    $rows = if ($Grid.SelectedRows.Count -gt 0) {
        $Grid.SelectedRows | ForEach-Object { $_.DataBoundItem }
    } else {
        $dt.Rows
    }

    if (-not $rows) {
        return ""
    }

    $sb = New-Object System.Text.StringBuilder

    # Header
    $cols = $dt.Columns | ForEach-Object { $_.ColumnName }
    [void]$sb.AppendLine(($cols -join ","))

    # Rows
    foreach ($r in $rows) {
        $values = foreach ($c in $cols) {
            # Basic CSV escaping
            $v = [string]$r[$c]
            if ($v -match '[",\r\n]') {
                '"' + $v.Replace('"','""') + '"'
            } else {
                $v
            }
        }
        [void]$sb.AppendLine(($values -join ","))
    }

    return $sb.ToString()
}

#-----------------------------#
# Main Form
#-----------------------------#
$form                  = New-Object System.Windows.Forms.Form
$form.Text             = "AI LLM CSV Opener"
$form.StartPosition    = "CenterScreen"
$form.Size             = New-Object System.Drawing.Size(1100, 700)
$form.MinimumSize      = New-Object System.Drawing.Size(900, 600)

#-----------------------------#
# Controls
#-----------------------------#

# Open button
$btnOpen               = New-Object System.Windows.Forms.Button
$btnOpen.Text          = "Open CSV..."
$btnOpen.Width         = 100
$btnOpen.Height        = 30
$btnOpen.Location      = New-Object System.Drawing.Point(10, 10)

# Label for file path
$lblFile               = New-Object System.Windows.Forms.Label
$lblFile.Text          = "No file loaded"
$lblFile.AutoSize      = $true
$lblFile.Location      = New-Object System.Drawing.Point(120, 16)

# Data grid
$grid                  = New-Object System.Windows.Forms.DataGridView
$grid.Location         = New-Object System.Drawing.Point(10, 50)
$grid.Size             = New-Object System.Drawing.Size(760, 600)
$grid.Anchor           = "Top,Left,Bottom"
$grid.ReadOnly         = $true
$grid.AllowUserToAddRows    = $false
$grid.AllowUserToDeleteRows = $false
$grid.SelectionMode    = "FullRowSelect"
$grid.MultiSelect      = $true
$grid.AutoSizeColumnsMode = "DisplayedCells"

# Prompt label
$lblPrompt             = New-Object System.Windows.Forms.Label
$lblPrompt.Text        = "Prompt to LLM:"
$lblPrompt.AutoSize    = $true
$lblPrompt.Location    = New-Object System.Drawing.Point(780, 50)

# Prompt textbox
$txtPrompt             = New-Object System.Windows.Forms.TextBox
$txtPrompt.Multiline   = $true
$txtPrompt.ScrollBars  = "Vertical"
$txtPrompt.Location    = New-Object System.Drawing.Point(780, 70)
$txtPrompt.Size        = New-Object System.Drawing.Size(290, 150)
$txtPrompt.Anchor      = "Top,Right"

# Options label
$lblOptions            = New-Object System.Windows.Forms.Label
$lblOptions.Text       = "Scope:"
$lblOptions.AutoSize   = $true
$lblOptions.Location   = New-Object System.Drawing.Point(780, 230)

# Radio buttons: all rows vs selected
$rbAllRows             = New-Object System.Windows.Forms.RadioButton
$rbAllRows.Text        = "Use all rows"
$rbAllRows.Location    = New-Object System.Drawing.Point(780, 250)
$rbAllRows.AutoSize    = $true
$rbAllRows.Checked     = $true

$rbSelectedRows        = New-Object System.Windows.Forms.RadioButton
$rbSelectedRows.Text   = "Use selected rows"
$rbSelectedRows.Location = New-Object System.Drawing.Point(780, 275)
$rbSelectedRows.AutoSize = $true

# Send button
$btnSend               = New-Object System.Windows.Forms.Button
$btnSend.Text          = "Send to LLM"
$btnSend.Width         = 120
$btnSend.Height        = 35
$btnSend.Location      = New-Object System.Drawing.Point(780, 310)

# Response label
$lblResponse           = New-Object System.Windows.Forms.Label
$lblResponse.Text      = "LLM Response:"
$lblResponse.AutoSize  = $true
$lblResponse.Location  = New-Object System.Drawing.Point(780, 355)

# Response textbox
$txtResponse           = New-Object System.Windows.Forms.TextBox
$txtResponse.Multiline = $true
$txtResponse.ScrollBars = "Vertical"
$txtResponse.Location  = New-Object System.Drawing.Point(780, 375)
$txtResponse.Size      = New-Object System.Drawing.Size(290, 275)
$txtResponse.Anchor    = "Top,Right,Bottom"

# Status strip
$statusStrip           = New-Object System.Windows.Forms.StatusStrip
$statusLabel           = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text      = "Ready"
[void]$statusStrip.Items.Add($statusLabel)

#-----------------------------#
# Events
#-----------------------------#

# Open CSV
$btnOpen.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
    $ofd.Title  = "Select CSV file"

    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $statusLabel.Text = "Loading CSV..."
            $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

            $dt = Import-CsvToDataTable -Path $ofd.FileName
            $grid.DataSource = $dt
            $lblFile.Text = $ofd.FileName

            $statusLabel.Text = "Loaded: $($dt.Rows.Count) rows, $($dt.Columns.Count) columns"
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Failed to load CSV:`r`n$($_.Exception.Message)",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            $statusLabel.Text = "Error loading CSV"
        } finally {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
        }
    }
})

# Send to LLM
$btnSend.Add_Click({
    if (-not $grid.DataSource) {
        [System.Windows.Forms.MessageBox]::Show(
            "No CSV loaded.",
            "Info",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $prompt = $txtPrompt.Text.Trim()
    if (-not $prompt) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please enter a prompt for the LLM.",
            "Info",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $statusLabel.Text = "Preparing data..."
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    try {
        # Decide scope
        if ($rbSelectedRows.Checked -and $grid.SelectedRows.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "No rows selected. Either select rows or choose 'Use all rows'.",
                "Info",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
            $statusLabel.Text = "Ready"
            return
        }

        $csvText = Get-SelectedRowsCsvText -Grid $grid
        if (-not $csvText) {
            [System.Windows.Forms.MessageBox]::Show(
                "No data available to send.",
                "Info",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
            $statusLabel.Text = "Ready"
            return
        }

        #-----------------------------#
        # LLM BACKEND CONTRACT REGION
        #-----------------------------#
        <#
            You wire this up to your LLM endpoint.

            INPUTS YOU HAVE:
              - $prompt  : string (user's natural language instruction)
              - $csvText : string (CSV text of all or selected rows)

            RECOMMENDED REQUEST SHAPE (example JSON):

              {
                "prompt": "<user prompt>",
                "csv": "<csv text>",
                "options": {
                  "model": "gpt-4.1-mini",
                  "task": "analysis|summary|transformation"
                }
              }

            EXPECTED OUTPUT:
              - Plain text response (analysis, summary, transformed data, etc.)

            IMPLEMENTATION SKETCH (replace with your real call):

              $body = @{
                  prompt = $prompt
                  csv    = $csvText
                  options = @{
                      model = "your-model-name"
                      task  = "analysis"
                  }
              } | ConvertTo-Json -Depth 5

              $headers = @{
                  "Authorization" = "Bearer YOUR_API_KEY"
                  "Content-Type"  = "application/json"
              }

              $uri = "https://your-llm-endpoint.example.com/v1/csv-analyze"

              $resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -TimeoutSec 120

              $llmText = $resp.result  # adapt to your schema

            For now, we simulate a response so the GUI is fully runnable.
        #>

        # --- BEGIN: SIMULATED LLM CALL (replace with real backend) ---
        Start-Sleep -Milliseconds 600
        $llmText = @"
[SIMULATED LLM RESPONSE]

Prompt:
$prompt

CSV snippet (first 300 chars):
$($csvText.Substring(0, [Math]::Min(300, $csvText.Length)))

(Replace this block with your real LLM HTTP call.)
"@
        # --- END: SIMULATED LLM CALL ---

        $txtResponse.Text = $llmText
        $statusLabel.Text = "LLM call completed (simulated). Replace with real backend."
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error during LLM operation:`r`n$($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        $statusLabel.Text = "Error during LLM call"
    } finally {
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
})

#-----------------------------#
# Add controls to form
#-----------------------------#
$form.Controls.Add($btnOpen)
$form.Controls.Add($lblFile)
$form.Controls.Add($grid)
$form.Controls.Add($lblPrompt)
$form.Controls.Add($txtPrompt)
$form.Controls.Add($lblOptions)
$form.Controls.Add($rbAllRows)
$form.Controls.Add($rbSelectedRows)
$form.Controls.Add($btnSend)
$form.Controls.Add($lblResponse)
$form.Controls.Add($txtResponse)
$form.Controls.Add($statusStrip)

#-----------------------------#
# Run
#-----------------------------#
[void][System.Windows.Forms.Application]::EnableVisualStyles()
[void]$form.ShowDialog()
