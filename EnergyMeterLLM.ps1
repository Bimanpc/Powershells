# Requires: PowerShell 5+ on Windows
# Optional: For local LLMs, run Ollama (or any OpenAI-compatible endpoint) beforehand.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

# --------------------------
# Helpers: Data + LLM calls
# --------------------------

function Convert-DataTableToObjects {
    param(
        [Parameter(Mandatory)] [System.Data.DataTable] $DataTable
    )
    foreach ($row in $DataTable.Rows) {
        $obj = [ordered]@{}
        foreach ($col in $DataTable.Columns) {
            $obj[$col.ColumnName] = $row[$col.ColumnName]
        }
        [pscustomobject]$obj
    }
}

function Try-ParseDate {
    param([string]$s)
    $dt = $null
    if ([DateTime]::TryParse($s, [ref]$dt)) { return $dt }
    return $null
}

function Make-OpenAIChatBody {
    param(
        [string]$Model,
        [string]$SystemPrompt,
        [string]$UserPrompt
    )
    return @{
        model    = $Model
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user";   content = $UserPrompt }
        )
        temperature = 0.2
    } | ConvertTo-Json -Depth 8
}

function Make-OllamaChatBody {
    param(
        [string]$Model,
        [string]$SystemPrompt,
        [string]$UserPrompt
    )
    return @{
        model   = $Model
        stream  = $false
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user";   content = $UserPrompt }
        )
        options = @{ temperature = 0.2 }
    } | ConvertTo-Json -Depth 8
}

function Invoke-LLM {
    param(
        [Parameter(Mandatory)] [string]$Provider,  # "OpenAI" or "Ollama"
        [Parameter(Mandatory)] [string]$Endpoint,  # e.g. https://api.openai.com/v1/chat/completions or http://localhost:11434/api/chat
        [Parameter(Mandatory)] [string]$Model,
        [string]$ApiKey,
        [string]$SystemPrompt,
        [string]$UserPrompt
    )

    try {
        if ($Provider -eq "OpenAI") {
            $uri  = $Endpoint.TrimEnd('/')
            $body = Make-OpenAIChatBody -Model $Model -SystemPrompt $SystemPrompt -UserPrompt $UserPrompt
            $headers = @{}
            if ($ApiKey) { $headers["Authorization"] = "Bearer $ApiKey" }
            $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Body $body -TimeoutSec 120
            if ($resp.choices && $resp.choices[0].message.content) { return $resp.choices[0].message.content.Trim() }
            return ($resp | ConvertTo-Json -Depth 6)
        }
        elseif ($Provider -eq "Ollama") {
            $uri  = $Endpoint.TrimEnd('/')
            $body = Make-OllamaChatBody -Model $Model -SystemPrompt $SystemPrompt -UserPrompt $UserPrompt
            $resp = Invoke-RestMethod -Method Post -Uri $uri -ContentType "application/json" -Body $body -TimeoutSec 120
            if ($resp.message.content) { return $resp.message.content.Trim() }
            return ($resp | ConvertTo-Json -Depth 6)
        }
        else {
            throw "Unknown provider: $Provider"
        }
    }
    catch {
        return "Error calling LLM: $($_.Exception.Message)"
    }
}

function Build-UserPrompt {
    param(
        [string]$Action,       # "analyze" | "forecast" | "anomaly"
        [object[]]$DataRows,   # objects with Date, Reading (kWh)
        [string]$Notes
    )

    $dataSample = ($DataRows | ForEach-Object { @{ date = ($_.Date); reading = ($_.Reading) } }) | ConvertTo-Json -Depth 6
    $notesPart = if ([string]::IsNullOrWhiteSpace($Notes)) { "" } else { "User notes: $Notes`n" }

    switch ($Action) {
        "analyze" {
            @"
Analyze the following energy meter readings. Provide:
- Overall usage patterns
- Daily/weekly trends
- Peak usage times
- Any seasonality
- Practical tips to reduce consumption without losing comfort

Data (JSON array):
$dataSample

$notesPart
Output concise, with bullet points and a brief summary at the end.
"@
        }
        "forecast" {
            @"
Using the provided energy meter readings, produce a short-term forecast for the next 7 and 30 days.
- Include expected ranges and assumptions
- Note confidence or uncertainty
- If data is insufficient, state limitations

Data (JSON array):
$dataSample

$notesPart
Return a compact, readable explanation and a small table for 7-day and 30-day forecast (date, expected_kWh, low, high).
"@
        }
        "anomaly" {
            @"
Perform anomaly detection on the energy meter readings.
- Identify dates with unusual consumption (both spikes and dips)
- Explain likely causes and simple checks to confirm
- Suggest corrective actions

Data (JSON array):
$dataSample

$notesPart
Return a short list of anomalies with date, deviation estimate, and a one-line rationale.
"@
        }
        default {
            "Describe the data:"
        }
    }
}

# --------------------------
# GUI Setup
# --------------------------

$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "Energy Meter + LLM"
$form.Size            = New-Object System.Drawing.Size(1200, 750)
$form.StartPosition   = "CenterScreen"

# Top panel: Config
$panelTop = New-Object System.Windows.Forms.Panel
$panelTop.Dock = 'Top'
$panelTop.Height = 90
$form.Controls.Add($panelTop)

# Provider
$lblProvider = New-Object System.Windows.Forms.Label
$lblProvider.Text = "Provider"
$lblProvider.Location = '10,10'
$lblProvider.AutoSize = $true
$panelTop.Controls.Add($lblProvider)

$cmbProvider = New-Object System.Windows.Forms.ComboBox
$cmbProvider.Location = '10,30'
$cmbProvider.Width = 110
[void]$cmbProvider.Items.Add("OpenAI")
[void]$cmbProvider.Items.Add("Ollama")
$cmbProvider.SelectedItem = "OpenAI"
$panelTop.Controls.Add($cmbProvider)

# Endpoint
$lblEndpoint = New-Object System.Windows.Forms.Label
$lblEndpoint.Text = "Endpoint URL"
$lblEndpoint.Location = '140,10'
$lblEndpoint.AutoSize = $true
$panelTop.Controls.Add($lblEndpoint)

$txtEndpoint = New-Object System.Windows.Forms.TextBox
$txtEndpoint.Location = '140,30'
$txtEndpoint.Width = 360
$txtEndpoint.Text = "https://api.openai.com/v1/chat/completions" # For OpenAI-compatible
$panelTop.Controls.Add($txtEndpoint)

# Model
$lblModel = New-Object System.Windows.Forms.Label
$lblModel.Text = "Model"
$lblModel.Location = '520,10'
$lblModel.AutoSize = $true
$panelTop.Controls.Add($lblModel)

$txtModel = New-Object System.Windows.Forms.TextBox
$txtModel.Location = '520,30'
$txtModel.Width = 160
$txtModel.Text = "gpt-4o-mini"
$panelTop.Controls.Add($txtModel)

# API Key
$lblKey = New-Object System.Windows.Forms.Label
$lblKey.Text = "API Key"
$lblKey.Location = '700,10'
$lblKey.AutoSize = $true
$panelTop.Controls.Add($lblKey)

$txtKey = New-Object System.Windows.Forms.TextBox
$txtKey.Location = '700,30'
$txtKey.Width = 230
$txtKey.UseSystemPasswordChar = $true
$panelTop.Controls.Add($txtKey)

# Ollama hint button
$btnOllama = New-Object System.Windows.Forms.Button
$btnOllama.Text = "Use Ollama Defaults"
$btnOllama.Location = '950,28'
$btnOllama.Width = 200
$btnOllama.Add_Click({
    $cmbProvider.SelectedItem = "Ollama"
    $txtEndpoint.Text = "http://localhost:11434/api/chat"
    $txtModel.Text = "llama3.1"
    $txtKey.Text = ""
})
$panelTop.Controls.Add($btnOllama)

# Split container: left data/chart, right LLM output
$splitMain = New-Object System.Windows.Forms.SplitContainer
$splitMain.Dock = 'Fill'
$splitMain.SplitterDistance = 700
$form.Controls.Add($splitMain)

# Left side: tabs for Data and Chart
$tabsLeft = New-Object System.Windows.Forms.TabControl
$tabsLeft.Dock = 'Fill'
$splitMain.Panel1.Controls.Add($tabsLeft)

$tabData = New-Object System.Windows.Forms.TabPage
$tabData.Text = "Data"
$tabsLeft.TabPages.Add($tabData)

$tabChart = New-Object System.Windows.Forms.TabPage
$tabChart.Text = "Chart"
$tabsLeft.TabPages.Add($tabChart)

# Data grid and controls
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Dock = 'Top'
$grid.Height = 420
$grid.AllowUserToAddRows = $true
$grid.AllowUserToDeleteRows = $true
$grid.AutoSizeColumnsMode = 'Fill'
$tabData.Controls.Add($grid)

$panelDataControls = New-Object System.Windows.Forms.Panel
$panelDataControls.Dock = 'Bottom'
$panelDataControls.Height = 120
$tabData.Controls.Add($panelDataControls)

$btnLoadCsv = New-Object System.Windows.Forms.Button
$btnLoadCsv.Text = "Load CSV"
$btnLoadCsv.Location = '10,10'
$panelDataControls.Controls.Add($btnLoadCsv)

$btnSaveCsv = New-Object System.Windows.Forms.Button
$btnSaveCsv.Text = "Save CSV"
$btnSaveCsv.Location = '110,10'
$panelDataControls.Controls.Add($btnSaveCsv)

$lblManual = New-Object System.Windows.Forms.Label
$lblManual.Text = "Manual Entry: Date (yyyy-mm-dd), Reading (kWh)"
$lblManual.Location = '10,45'
$lblManual.AutoSize = $true
$panelDataControls.Controls.Add($lblManual)

$txtDate = New-Object System.Windows.Forms.TextBox
$txtDate.Location = '10,70'
$txtDate.Width = 150
$panelDataControls.Controls.Add($txtDate)

$txtReading = New-Object System.Windows.Forms.TextBox
$txtReading.Location = '170,70'
$txtReading.Width = 100
$panelDataControls.Controls.Add($txtReading)

$btnAddRow = New-Object System.Windows.Forms.Button
$btnAddRow.Text = "Add"
$btnAddRow.Location = '280,68'
$panelDataControls.Controls.Add($btnAddRow)

# Chart
$chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chart.Dock = 'Fill'
$tabChart.Controls.Add($chart)

$chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$chartArea.AxisX.Title = "Date"
$chartArea.AxisY.Title = "kWh"
$chart.ChartAreas.Add($chartArea)

$series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
$series.Name = "Consumption"
$series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
$series.XValueType = [System.Windows.Forms.DataVisualization.Charting.ChartValueType]::DateTime
$chart.Series.Add($series)

# Right side: action panel + output
$panelRight = New-Object System.Windows.Forms.Panel
$panelRight.Dock = 'Fill'
$splitMain.Panel2.Controls.Add($panelRight)

$lblNotes = New-Object System.Windows.Forms.Label
$lblNotes.Text = "Notes / context for the model (optional)"
$lblNotes.Location = '10,10'
$lblNotes.AutoSize = $true
$panelRight.Controls.Add($lblNotes)

$txtNotes = New-Object System.Windows.Forms.TextBox
$txtNotes.Location = '10,30'
$txtNotes.Multiline = $true
$txtNotes.ScrollBars = 'Vertical'
$txtNotes.Width = 440
$txtNotes.Height = 120
$panelRight.Controls.Add($txtNotes)

$btnAnalyze  = New-Object System.Windows.Forms.Button
$btnForecast = New-Object System.Windows.Forms.Button
$btnAnomaly  = New-Object System.Windows.Forms.Button
$btnRefresh  = New-Object System.Windows.Forms.Button

$btnAnalyze.Text  = "Analyze"
$btnForecast.Text = "Forecast"
$btnAnomaly.Text  = "Detect Anomalies"
$btnRefresh.Text  = "Refresh Chart"

$btnAnalyze.Location  = '10,160'
$btnForecast.Location = '110,160'
$btnAnomaly.Location  = '220,160'
$btnRefresh.Location  = '360,160'

$panelRight.Controls.Add($btnAnalyze)
$panelRight.Controls.Add($btnForecast)
$panelRight.Controls.Add($btnAnomaly)
$panelRight.Controls.Add($btnRefresh)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = '10,200'
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = 'Vertical'
$txtOutput.Width = 440
$txtOutput.Height = 480
$txtOutput.ReadOnly = $true
$panelRight.Controls.Add($txtOutput)

# --------------------------
# Data model backing the grid
# --------------------------
$dataTable = New-Object System.Data.DataTable "Energy"
[void]$dataTable.Columns.Add("Date", [string])     # ISO date recommended
[void]$dataTable.Columns.Add("Reading", [double])  # kWh
$grid.DataSource = $dataTable

function Refresh-Chart {
    $series.Points.Clear()
    foreach ($row in $dataTable.Rows) {
        $d = Try-ParseDate $row["Date"]
        $v = $row["Reading"]
        if ($d -ne $null -and $v -ne $null) {
            [void]$series.Points.AddXY($d, [double]$v)
        }
    }
    $chart.ChartAreas[0].RecalculateAxesScale()
}

# --------------------------
# Events
# --------------------------

$btnAddRow.Add_Click({
    $d = $txtDate.Text.Trim()
    $r = $txtReading.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($d) -or [string]::IsNullOrWhiteSpace($r)) {
        [System.Windows.Forms.MessageBox]::Show("Please provide both Date and Reading.")
        return
    }
    $val = $null
    if (-not [double]::TryParse($r, [ref]$val)) {
        [System.Windows.Forms.MessageBox]::Show("Reading must be a number.")
        return
    }
    $row = $dataTable.NewRow()
    $row["Date"] = $d
    $row["Reading"] = [double]$val
    $dataTable.Rows.Add($row)
    $txtDate.Text = ""
    $txtReading.Text = ""
    Refresh-Chart
})

$btnLoadCsv.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
    if ($dlg.ShowDialog() -eq 'OK') {
        try {
            $dt = New-Object System.Data.DataTable
            [void]$dt.Columns.Add("Date",[string])
            [void]$dt.Columns.Add("Reading",[double])
            $csv = Import-Csv -Path $dlg.FileName
            foreach ($rec in $csv) {
                $row = $dt.NewRow()
                $row["Date"] = [string]$rec.Date
                $row["Reading"] = [double]$rec.Reading
                $dt.Rows.Add($row)
            }
            $dataTable.Clear()
            foreach ($row in $dt.Rows) { $dataTable.ImportRow($row) }
            Refresh-Chart
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to load CSV: $($_.Exception.Message)")
        }
    }
})

$btnSaveCsv.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "CSV Files (*.csv)|*.csv"
    $dlg.FileName = "energy-data.csv"
    if ($dlg.ShowDialog() -eq 'OK') {
        try {
            $rows = Convert-DataTableToObjects -DataTable $dataTable
            $rows | Export-Csv -Path $dlg.FileName -NoTypeInformation -Encoding UTF8
            [System.Windows.Forms.MessageBox]::Show("Saved: $($dlg.FileName)")
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to save CSV: $($_.Exception.Message)")
        }
    }
})

$btnRefresh.Add_Click({ Refresh-Chart })

function Get-DataRows {
    $rows = @()
    foreach ($r in $dataTable.Rows) {
        $date = $r["Date"]
        $reading = $r["Reading"]
        if (-not [string]::IsNullOrWhiteSpace($date) -and $reading -ne $null) {
            $rows += [pscustomobject]@{
                Date    = $date
                Reading = [double]$reading
            }
        }
    }
    # Sort by date if possible
    $rows | Sort-Object {
        $dt = Try-ParseDate $_.Date
        if ($dt -eq $null) { Get-Date "1900-01-01" } else { $dt }
    }
}

function Run-LLM {
    param([string]$Action)

    $provider = $cmbProvider.SelectedItem
    $endpoint = $txtEndpoint.Text.Trim()
    $model    = $txtModel.Text.Trim()
    $apiKey   = $txtKey.Text
    $notes    = $txtNotes.Text

    if ([string]::IsNullOrWhiteSpace($endpoint) -or [string]::IsNullOrWhiteSpace($model)) {
        $txtOutput.Text = "Please set Endpoint and Model."
        return
    }

    $rows = Get-DataRows
    if (-not $rows -or $rows.Count -lt 3) {
        $txtOutput.Text = "Add or load some readings first (at least 3 rows recommended)."
        return
    }

    $system = @"
You are an energy analytics assistant. Be practical, concise, and numerate.
Prefer bullet points and short tables when helpful. If data is insufficient,
clearly state limitations and what would improve results.
"@

    $user = Build-UserPrompt -Action $Action -DataRows $rows -Notes $notes
    $txtOutput.Text = "Working..."
    $form.Refresh()

    $result = Invoke-LLM -Provider $provider -Endpoint $endpoint -Model $model -ApiKey $apiKey -SystemPrompt $system -UserPrompt $user
    $txtOutput.Text = $result
}

$btnAnalyze.Add_Click  { Run-LLM -Action "analyze" }
$btnForecast.Add_Click { Run-LLM -Action "forecast" }
$btnAnomaly.Add_Click  { Run-LLM -Action "anomaly" }

# Initial chart
Refresh-Chart

# If user picks OpenAI, keep default endpoint; if Ollama, hint typical values
$cmbProvider.Add_SelectedIndexChanged({
    if ($cmbProvider.SelectedItem -eq "OpenAI") {
        if ($txtEndpoint.Text -match "11434") {
            $txtEndpoint.Text = "https://api.openai.com/v1/chat/completions"
            $txtModel.Text = "gpt-4o-mini"
        }
    } elseif ($cmbProvider.SelectedItem -eq "Ollama") {
        if ($txtEndpoint.Text -notmatch "11434") {
            $txtEndpoint.Text = "http://localhost:11434/api/chat"
            $txtModel.Text = "llama3.1"
        }
    }
})

[void]$form.ShowDialog()
