Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "CSV to PDF AI App"
$form.Size = New-Object System.Drawing.Size(800,600)

# Button: Load CSV
$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Load CSV"
$btnLoad.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($btnLoad)

# Button: Export PDF
$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export to PDF"
$btnExport.Location = New-Object System.Drawing.Point(120,10)
$form.Controls.Add($btnExport)

# DataGridView to preview CSV
$dataGrid = New-Object System.Windows.Forms.DataGridView
$dataGrid.Location = New-Object System.Drawing.Point(10,50)
$dataGrid.Size = New-Object System.Drawing.Size(760,450)
$form.Controls.Add($dataGrid)

# Global variable
$global:csvData = $null

# Load CSV event
$btnLoad.Add_Click({
    $openFile = New-Object System.Windows.Forms.OpenFileDialog
    $openFile.Filter = "CSV files (*.csv)|*.csv"

    if ($openFile.ShowDialog() -eq "OK") {
        $global:csvData = Import-Csv $openFile.FileName
        $dataGrid.DataSource = $global:csvData
    }
})

# Export PDF event (basic text-based PDF)
$btnExport.Add_Click({
    if (-not $global:csvData) {
        [System.Windows.Forms.MessageBox]::Show("Load a CSV first!")
        return
    }

    $saveFile = New-Object System.Windows.Forms.SaveFileDialog
    $saveFile.Filter = "PDF files (*.pdf)|*.pdf"

    if ($saveFile.ShowDialog() -eq "OK") {

        # Simple PDF creation (text-based)
        $pdfPath = $saveFile.FileName

        # NOTE: This is a VERY basic PDF writer (plain text wrapped)
        $content = ""
        foreach ($row in $global:csvData) {
            $line = ($row.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" }) -join " | "
            $content += $line + "`n"
        }

        # Minimal PDF structure
        $pdfText = @"
%PDF-1.1
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>
endobj
4 0 obj
<< /Length 5 0 R >>
stream
BT
/F1 12 Tf
50 750 Td
($content) Tj
ET
endstream
endobj
5 0 obj
${content.Length}
endobj
xref
0 6
0000000000 65535 f
trailer
<< /Size 6 /Root 1 0 R >>
startxref
0
%%EOF
"@

        $pdfText | Out-File -Encoding ASCII $pdfPath

        [System.Windows.Forms.MessageBox]::Show("PDF Exported!")
    }
})

# Run App
$form.ShowDialog()
