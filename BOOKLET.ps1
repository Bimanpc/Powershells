#requires -version 5.1
<#
AI LLM PDF → Book App (GUI)
- Windows Forms
- PDF text extraction via pdftotext.exe (recommended)
- LLM calling via OpenAI-compatible REST (POST /v1/chat/completions or /v1/responses)
- Outputs Markdown; optional Pandoc to DOCX/EPUB
- Chunking with overlap; outline+chapter prompts

By Copilot — minimal, admin-aware, and extensible.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# -----------------------
# Config defaults
# -----------------------
$state = [ordered]@{
    PdfPath          = ""
    OutputDir        = [Environment]::GetFolderPath("MyDocuments")
    PdftotextPath    = ""   # e.g. C:\Tools\pdftotext.exe
    PandocPath       = ""   # e.g. C:\Program Files\Pandoc\pandoc.exe
    ApiBaseUrl       = "https://api.openai.com/v1"
    ApiKey           = ""
    Model            = "gpt-4o-mini"
    UseResponses     = $false # If your API supports /v1/responses
    ChunkSize        = 6000   # characters per chunk
    ChunkOverlap     = 800
    Temperature      = 0.2
    MaxRetries       = 2
    TimeoutSec       = 120
    OutlinePrompt    = @"
You are a professional book editor. Based on the provided PDF text excerpts and topic,
produce a detailed book outline with:
- Title and subtitle
- 8–12 chapter titles
- 3–5 subheadings per chapter
- A one-paragraph summary per chapter
Keep it coherent and logically ordered. Output as structured Markdown.
"@
    ChapterPromptTpl = @"
You are a skilled author. Write a full chapter for the book "{0}".
Chapter: "{1}"

Constraints:
- Engage, explain, and give actionable insights.
- Maintain consistent voice and flow across chapters.
- Use clear subheadings from the outline; expand them thoughtfully.
- Avoid fluff; be precise and helpful.
- Include examples or case studies where relevant.
- Output in Markdown.

Use the following source excerpts to inform content (do not copy verbatim; synthesize):
{2}
"@
    SystemPrompt    = "You are a helpful assistant that produces clean, well-structured Markdown books."
}

# -----------------------
# Helpers
# -----------------------
function Show-Error([string]$msg) {
    [System.Windows.Forms.MessageBox]::Show($msg, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}

function Show-Info([string]$msg) {
    [System.Windows.Forms.MessageBox]::Show($msg, "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Extract-PdfText {
    param(
        [string]$Pdf,
        [string]$PdftotextExe
    )
    if (-not (Test-Path $Pdf)) { throw "PDF not found: $Pdf" }

    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("pdf2book_" + [Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tmpDir | Out-Null
    $txtOut = Join-Path $tmpDir "extracted.txt"

    if ($PdftotextExe -and (Test-Path $PdftotextExe)) {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $PdftotextExe
        $psi.Arguments = "`"$Pdf`" `"$txtOut`" -enc UTF-8 -layout"
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        $p.WaitForExit()
        if ($p.ExitCode -ne 0 -or -not (Test-Path $txtOut)) {
            throw "pdftotext failed or output missing."
        }
        $text = Get-Content -LiteralPath $txtOut -Raw
        Remove-Item $tmpDir -Recurse -Force
        return $text
    }
    else {
        throw "pdftotext.exe not set. Please set path or paste raw text."
    }
}

function Split-TextChunks {
    param(
        [string]$Text,
        [int]$ChunkSize = 6000,
        [int]$Overlap = 800
    )
    $chunks = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($Text)) { return $chunks }

    $len = $Text.Length
    $start = 0
    while ($start -lt $len) {
        $end = [Math]::Min($start + $ChunkSize, $len)
        $chunks.Add($Text.Substring($start, $end - $start))
        $start = $end - $Overlap
        if ($start -lt 0) { $start = 0 }
        if ($start -ge $len) { break }
    }
    return $chunks
}

function Invoke-LLM {
    param(
        [string]$BaseUrl,
        [string]$ApiKey,
        [string]$Model,
        [string]$SystemPrompt,
        [string]$UserPrompt,
        [double]$Temperature = 0.2,
        [int]$TimeoutSec = 120,
        [switch]$UseResponses
    )

    if ([string]::IsNullOrWhiteSpace($ApiKey)) { throw "API key is missing." }

    $uri = if ($UseResponses) { "$BaseUrl/responses" } else { "$BaseUrl/chat/completions" }

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type"  = "application/json"
    }

    if ($UseResponses) {
        $body = @{
            model = $Model
            input = $UserPrompt
            temperature = $Temperature
            system = $SystemPrompt
        } | ConvertTo-Json -Depth 6
    } else {
        $body = @{
            model = $Model
            temperature = $Temperature
            messages = @(
                @{ role = "system"; content = $SystemPrompt },
                @{ role = "user"; content = $UserPrompt }
            )
        } | ConvertTo-Json -Depth 6
    }

    $attempt = 0
    do {
        $attempt++
        try {
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -TimeoutSec $TimeoutSec
            if ($UseResponses) {
                # Expected: response.output_text or similar
                $text = $response.output_text
                if (-not $text) {
                    # fallback if provider returns choices-like format
                    if ($response.output -and $response.output[0].content[0].text) {
                        $text = $response.output[0].content[0].text
                    }
                }
                return ($text ?? "")
            } else {
                return ($response.choices[0].message.content ?? "")
            }
        } catch {
            if ($attempt -gt $state.MaxRetries) { throw $_ }
            Start-Sleep -Seconds ([Math]::Min(2 * $attempt, 6))
        }
    } while ($true)
}

function Build-BookMarkdown {
    param(
        [string]$Title,
        [string]$OutlineMd,
        [hashtable]$ChaptersContent # key: ChapterTitle, value: ChapterMarkdown
    )

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# $Title")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("## Outline")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine($OutlineMd.Trim())
    [void]$sb.AppendLine()
    foreach ($kvp in $ChaptersContent.GetEnumerator()) {
        [void]$sb.AppendLine("# " + $kvp.Key)
        [void]$sb.AppendLine()
        [void]$sb.AppendLine($kvp.Value.Trim())
        [void]$sb.AppendLine()
    }
    return $sb.ToString()
}

function Save-Outputs {
    param(
        [string]$OutputDir,
        [string]$BaseName,
        [string]$Markdown,
        [string]$PandocPath
    )

    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir | Out-Null
    }
    $mdPath = Join-Path $OutputDir ($BaseName + ".md")
    Set-Content -LiteralPath $mdPath -Value $Markdown -Encoding UTF8
    $paths = @{
        Markdown = $mdPath
        Docx     = $null
        Epub     = $null
    }

    if ($PandocPath -and (Test-Path $PandocPath)) {
        $docxPath = Join-Path $OutputDir ($BaseName + ".docx")
        $epubPath = Join-Path $OutputDir ($BaseName + ".epub")

        foreach ($target in @(@{Out=$docxPath;Fmt="docx"}, @{Out=$epubPath;Fmt="epub"})) {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $PandocPath
            $psi.Arguments = "`"$mdPath`" -o `"$($target.Out)`""
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $p = [System.Diagnostics.Process]::Start($psi)
            $p.WaitForExit()
            if ($p.ExitCode -eq 0 -and (Test-Path $target.Out)) {
                if ($target.Fmt -eq "docx") { $paths.Docx = $target.Out } else { $paths.Epub = $target.Out }
            }
        }
    }
    return $paths
}

# -----------------------
# GUI
# -----------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI LLM PDF → Book"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(920, 640)
$form.MaximizeBox = $true

# Labels and inputs
$lblPdf = New-Object System.Windows.Forms.Label
$lblPdf.Text = "PDF file:"
$lblPdf.Location = New-Object System.Drawing.Point(20, 20)
$lblPdf.AutoSize = $true

$txtPdf = New-Object System.Windows.Forms.TextBox
$txtPdf.Location = New-Object System.Drawing.Point(140, 18)
$txtPdf.Size = New-Object System.Drawing.Size(640, 24)

$btnBrowsePdf = New-Object System.Windows.Forms.Button
$btnBrowsePdf.Text = "Browse"
$btnBrowsePdf.Location = New-Object System.Drawing.Point(800, 16)
$btnBrowsePdf.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "PDF|*.pdf|All files|*.*"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtPdf.Text = $dlg.FileName
    }
})

$lblOut = New-Object System.Windows.Forms.Label
$lblOut.Text = "Output directory:"
$lblOut.Location = New-Object System.Drawing.Point(20, 58)
$lblOut.AutoSize = $true

$txtOut = New-Object System.Windows.Forms.TextBox
$txtOut.Location = New-Object System.Drawing.Point(140, 56)
$txtOut.Size = New-Object System.Drawing.Size(640, 24)
$txtOut.Text = $state.OutputDir

$btnBrowseOut = New-Object System.Windows.Forms.Button
$btnBrowseOut.Text = "Browse"
$btnBrowseOut.Location = New-Object System.Drawing.Point(800, 54)
$btnBrowseOut.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtOut.Text = $dlg.SelectedPath
    }
})

$lblPdftotext = New-Object System.Windows.Forms.Label
$lblPdftotext.Text = "pdftotext.exe path:"
$lblPdftotext.Location = New-Object System.Drawing.Point(20, 96)
$lblPdftotext.AutoSize = $true

$txtPdftotext = New-Object System.Windows.Forms.TextBox
$txtPdftotext.Location = New-Object System.Drawing.Point(140, 94)
$txtPdftotext.Size = New-Object System.Drawing.Size(640, 24)

$btnBrowsePdftotext = New-Object System.Windows.Forms.Button
$btnBrowsePdftotext.Text = "Browse"
$btnBrowsePdftotext.Location = New-Object System.Drawing.Point(800, 92)
$btnBrowsePdftotext.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Executable|*.exe|All files|*.*"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtPdftotext.Text = $dlg.FileName
    }
})

$lblPandoc = New-Object System.Windows.Forms.Label
$lblPandoc.Text = "Pandoc path (optional):"
$lblPandoc.Location = New-Object System.Drawing.Point(20, 134)
$lblPandoc.AutoSize = $true

$txtPandoc = New-Object System.Windows.Forms.TextBox
$txtPandoc.Location = New-Object System.Drawing.Point(170, 132)
$txtPandoc.Size = New-Object System.Drawing.Size(610, 24)

$btnBrowsePandoc = New-Object System.Windows.Forms.Button
$btnBrowsePandoc.Text = "Browse"
$btnBrowsePandoc.Location = New-Object System.Drawing.Point(800, 130)
$btnBrowsePandoc.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Executable|*.exe|All files|*.*"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtPandoc.Text = $dlg.FileName
    }
})

$lblApiBase = New-Object System.Windows.Forms.Label
$lblApiBase.Text = "LLM base URL:"
$lblApiBase.Location = New-Object System.Drawing.Point(20, 172)
$lblApiBase.AutoSize = $true

$txtApiBase = New-Object System.Windows.Forms.TextBox
$txtApiBase.Location = New-Object System.Drawing.Point(140, 170)
$txtApiBase.Size = New-Object System.Drawing.Size(640, 24)
$txtApiBase.Text = $state.ApiBaseUrl

$lblApiKey = New-Object System.Windows.Forms.Label
$lblApiKey.Text = "API key:"
$lblApiKey.Location = New-Object System.Drawing.Point(20, 210)
$lblApiKey.AutoSize = $true

$txtApiKey = New-Object System.Windows.Forms.TextBox
$txtApiKey.Location = New-Object System.Drawing.Point(140, 208)
$txtApiKey.Size = New-Object System.Drawing.Size(640, 24)
$txtApiKey.UseSystemPasswordChar = $true

$lblModel = New-Object System.Windows.Forms.Label
$lblModel.Text = "Model:"
$lblModel.Location = New-Object System.Drawing.Point(20, 248)
$lblModel.AutoSize = $true

$txtModel = New-Object System.Windows.Forms.TextBox
$txtModel.Location = New-Object System.Drawing.Point(140, 246)
$txtModel.Size = New-Object System.Drawing.Size(640, 24)
$txtModel.Text = $state.Model

$chkResponses = New-Object System.Windows.Forms.CheckBox
$chkResponses.Text = "Use /v1/responses endpoint"
$chkResponses.Location = New-Object System.Drawing.Point(140, 276)
$chkResponses.AutoSize = $true
$chkResponses.Checked = $state.UseResponses

$lblChunk = New-Object System.Windows.Forms.Label
$lblChunk.Text = "Chunk size / overlap:"
$lblChunk.Location = New-Object System.Drawing.Point(20, 310)
$lblChunk.AutoSize = $true

$txtChunkSize = New-Object System.Windows.Forms.NumericUpDown
$txtChunkSize.Location = New-Object System.Drawing.Point(170, 308)
$txtChunkSize.Minimum = 1000
$txtChunkSize.Maximum = 20000
$txtChunkSize.Value = $state.ChunkSize

$txtOverlap = New-Object System.Windows.Forms.NumericUpDown
$txtOverlap.Location = New-Object System.Drawing.Point(310, 308)
$txtOverlap.Minimum = 0
$txtOverlap.Maximum = 5000
$txtOverlap.Value = $state.ChunkOverlap

$lblTemp = New-Object System.Windows.Forms.Label
$lblTemp.Text = "Temperature:"
$lblTemp.Location = New-Object System.Drawing.Point(420, 310)
$lblTemp.AutoSize = $true

$txtTemp = New-Object System.Windows.Forms.NumericUpDown
$txtTemp.Location = New-Object System.Drawing.Point(510, 308)
$txtTemp.Minimum = 0
$txtTemp.Maximum = 20
$txtTemp.DecimalPlaces = 2
$txtTemp.Increment = 0.05
$txtTemp.Value = [decimal]$state.Temperature

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Book title:"
$lblTitle.Location = New-Object System.Drawing.Point(20, 346)
$lblTitle.AutoSize = $true

$txtTitle = New-Object System.Windows.Forms.TextBox
$txtTitle.Location = New-Object System.Drawing.Point(140, 344)
$txtTitle.Size = New-Object System.Drawing.Size(640, 24)

$lblTopic = New-Object System.Windows.Forms.Label
$lblTopic.Text = "Book topic (guide for outline):"
$lblTopic.Location = New-Object System.Drawing.Point(20, 382)
$lblTopic.AutoSize = $true

$txtTopic = New-Object System.Windows.Forms.TextBox
$txtTopic.Location = New-Object System.Drawing.Point(240, 380)
$txtTopic.Size = New-Object System.Drawing.Size(540, 24)

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Log:"
$lblLog.Location = New-Object System.Drawing.Point(20, 420)
$lblLog.AutoSize = $true

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 440)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.Size = New-Object System.Drawing.Size(880, 120)
$txtLog.ReadOnly = $true

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20, 570)
$progress.Size = New-Object System.Drawing.Size(880, 20)
$progress.Minimum = 0
$progress.Maximum = 100

$btnExtract = New-Object System.Windows.Forms.Button
$btnExtract.Text = "1) Extract PDF → Text"
$btnExtract.Location = New-Object System.Drawing.Point(20, 410)
$btnExtract.Visible = $false # reserved if you want separate step

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Generate Book"
$btnRun.Location = New-Object System.Drawing.Point(800, 374)

$form.Controls.AddRange(@(
    $lblPdf,$txtPdf,$btnBrowsePdf,
    $lblOut,$txtOut,$btnBrowseOut,
    $lblPdftotext,$txtPdftotext,$btnBrowsePdftotext,
    $lblPandoc,$txtPandoc,$btnBrowsePandoc,
    $lblApiBase,$txtApiBase,
    $lblApiKey,$txtApiKey,
    $lblModel,$txtModel,$chkResponses,
    $lblChunk,$txtChunkSize,$txtOverlap,
    $lblTemp,$txtTemp,
    $lblTitle,$txtTitle,
    $lblTopic,$txtTopic,
    $lblLog,$txtLog,
    $progress,$btnRun
))

# -----------------------
# Main flow
# -----------------------
$btnRun.Add_Click({
    try {
        $progress.Value = 0
        $txtLog.AppendText("Starting..." + [Environment]::NewLine)

        $pdf = $txtPdf.Text.Trim()
        $outDir = $txtOut.Text.Trim()
        $pdftotext = $txtPdftotext.Text.Trim()
        $pandoc = $txtPandoc.Text.Trim()
        $apiBase = $txtApiBase.Text.Trim().TrimEnd("/")
        $apiKey = $txtApiKey.Text.Trim()
        $model = $txtModel.Text.Trim()
        $useResp = $chkResponses.Checked
        $chunkSize = [int]$txtChunkSize.Value
        $overlap = [int]$txtOverlap.Value
        $temp = [double]$txtTemp.Value
        $title = $txtTitle.Text.Trim()
        $topic = $txtTopic.Text.Trim()

        if ([string]::IsNullOrWhiteSpace($title)) { $title = [System.IO.Path]::GetFileNameWithoutExtension($pdf) }
        if ([string]::IsNullOrWhiteSpace($pdf) -or -not (Test-Path $pdf)) { Show-Error "Select a valid PDF."; return }
        if ([string]::IsNullOrWhiteSpace($apiKey)) { Show-Error "Enter API key."; return }

        $txtLog.AppendText("Extracting text..." + [Environment]::NewLine)
        $progress.Value = 5
        $text = Extract-PdfText -Pdf $pdf -PdftotextExe $pdftotext
        if ([string]::IsNullOrWhiteSpace($text)) { throw "No text extracted." }
        $txtLog.AppendText(("Extracted {0} chars." -f $text.Length) + [Environment]::NewLine)

        $txtLog.AppendText("Chunking..." + [Environment]::NewLine)
        $progress.Value = 10
        $chunks = Split-TextChunks -Text $text -ChunkSize $chunkSize -Overlap $overlap
        $txtLog.AppendText(("Chunks: {0}" -f $chunks.Count) + [Environment]::NewLine)

        $txtLog.AppendText("Generating outline..." + [Environment]::NewLine)
        $progress.Value = 20
        $outlineInput = "Topic: $topic`n`nRepresentative excerpts:`n" + ($chunks | Select-Object -First 3 | ForEach-Object { $_.Substring(0, [Math]::Min(2000, $_.Length)) + "`n---`n" } | Out-String)
        $outlineMd = Invoke-LLM -BaseUrl $apiBase -ApiKey $apiKey -Model $model -SystemPrompt $state.SystemPrompt -UserPrompt $state.OutlinePrompt + "`n`n$outlineInput" -Temperature $temp -TimeoutSec $state.TimeoutSec -UseResponses:($useResp)
        if ([string]::IsNullOrWhiteSpace($outlineMd)) { throw "Outline generation failed." }
        $txtLog.AppendText("Outline done." + [Environment]::NewLine)

        # Parse chapter titles from outline (simple heuristic: lines starting with '### ' or '- Chapter')
        $chapterTitles = New-Object System.Collections.Generic.List[string]
        foreach ($line in $outlineMd.Split("`n")) {
            $l = $line.Trim()
            if ($l.StartsWith("### ")) { $chapterTitles.Add($l.Substring(4)) }
            elseif ($l -match "^-+\s*(Chapter|Κεφάλαιο)\s*\d+[:\-]\s*(.+)$") { $chapterTitles.Add($Matches[2].Trim()) }
            elseif ($l -match "^-\s*(.+)$" -and $chapterTitles.Count -lt 14) { $chapterTitles.Add($Matches[1].Trim()) }
        }
        if ($chapterTitles.Count -eq 0) {
            # fallback: ask the LLM to list chapter titles only
            $txtLog.AppendText("No chapter headings detected; requesting explicit list..." + [Environment]::NewLine)
            $listPrompt = "From the outline below, list 10 concise chapter titles (one per line, no numbering):`n`n$outlineMd"
            $titlesRaw = Invoke-LLM -BaseUrl $apiBase -ApiKey $apiKey -Model $model -SystemPrompt $state.SystemPrompt -UserPrompt $listPrompt -Temperature $temp -TimeoutSec $state.TimeoutSec -UseResponses:($useResp)
            foreach ($l in $titlesRaw.Split("`n")) {
                $lt = $l.Trim("`r","`n","-","*"," ").Trim()
                if ($lt) { $chapterTitles.Add($lt) }
            }
        }
        $chapterTitles = ($chapterTitles | Where-Object { $_ }).Distinct()
        $txtLog.AppendText(("Chapters detected: {0}" -f $chapterTitles.Count) + [Environment]::NewLine)

        # Build chapters
        $progress.Value = 25
        $chaptersContent = @{}
        $total = [Math]::Max($chapterTitles.Count,1)
        $per = 70 / $total
        $bookTitle = $title

        for ($i=0; $i -lt $chapterTitles.Count; $i++) {
            $ct = $chapterTitles[$i]
            $txtLog.AppendText(("Writing chapter {0}/{1}: {2}" -f ($i+1), $chapterTitles.Count, $ct) + [Environment]::NewLine)

            # Select relevant excerpts for this chapter (simple heuristic: take 2 middle chunks)
            $excerpt = ($chunks | Select-Object -Index (([int]($chunks.Count/2)-1)..([int]($chunks.Count/2))) | ForEach-Object {
                $_.Substring(0, [Math]::Min(3000, $_.Length))
            }) -join "`n---`n"

            $prompt = [string]::Format($state.ChapterPromptTpl, $bookTitle, $ct, $excerpt)
            $chapterMd = Invoke-LLM -BaseUrl $apiBase -ApiKey $apiKey -Model $model -SystemPrompt $state.SystemPrompt -UserPrompt $prompt -Temperature $temp -TimeoutSec $state.TimeoutSec -UseResponses:($useResp)
            $chaptersContent[$ct] = $chapterMd
            $progress.Value = [Math]::Min(95, [int](25 + ($i+1)*$per))
        }

        # Assemble
        $txtLog.AppendText("Assembling book..." + [Environment]::NewLine)
        $bookMd = Build-BookMarkdown -Title $bookTitle -OutlineMd $outlineMd -ChaptersContent $chaptersContent

        $txtLog.AppendText("Saving outputs..." + [Environment]::NewLine)
        $baseName = ([System.IO.Path]::GetFileNameWithoutExtension($pdf)) + "_BOOK"
        $paths = Save-Outputs -OutputDir $outDir -BaseName $baseName -Markdown $bookMd -PandocPath $pandoc

        $progress.Value = 100
        $msg = "Done.`nMD: $($paths.Markdown)"
        if ($paths.Docx) { $msg += "`nDOCX: $($paths.Docx)" }
        if ($paths.Epub) { $msg += "`nEPUB: $($paths.Epub)" }
        $txtLog.AppendText($msg + [Environment]::NewLine)
        Show-Info($msg)
    } catch {
        Show-Error($_.Exception.Message)
        $txtLog.AppendText("Error: " + $_.Exception.Message + [Environment]::NewLine)
    }
})

# -----------------------
# Run
# -----------------------
$form.Add_Shown({ $form.Activate() })
[System.Windows.Forms.Application]::Run($form)
