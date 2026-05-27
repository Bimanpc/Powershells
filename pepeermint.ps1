#!/usr/bin/env pwsh
<#
    PdfAiMerger.ps1
    - Ubuntu-friendly PowerShell script
    - GUI via zenity (GTK)
    - PDF merge via pdfunite (poppler-utils)
    - AI/LLM hook for future integration (local HTTP endpoint)
#>

# ---------------- CONFIG ----------------

# Path to pdfunite (Poppler)
$Global:PdfUnitePath = "pdfunite"   # assumes in PATH

# Optional: local LLM endpoint (you wire this yourself)
$Global:AiEndpoint = "http://127.0.0.1:11434/v1/merge-notes"  # example placeholder

# ---------------- HELPERS ----------------

function Test-Command {
    param(
        [Parameter(Mandatory=$true)][string]$Name
    )
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Show-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    if (Test-Command -Name "zenity") {
        zenity --error --text="$Message" | Out-Null
    }
}

function Show-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
    if (Test-Command -Name "zenity") {
        zenity --info --text="$Message" | Out-Null
    }
}

# ---------------- AI / LLM HOOK ----------------
# You can adapt this to your own local model / contract.

function Invoke-AiMergeNotes {
    param(
        [string[]]$PdfPaths
    )

    # Example: send list of PDFs to a local LLM for metadata / notes / summary.
    # This is a stub; adjust payload & endpoint to your backend.

    if (-not $Global:AiEndpoint) {
        return $null
    }

    try {
        $body = @{
            pdfs = $PdfPaths
            task = "Suggest logical order and title for merged PDF"
        } | ConvertTo-Json -Depth 5

        $response = Invoke-RestMethod -Uri $Global:AiEndpoint -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop

        return $response
    }
    catch {
        Show-Error "AI endpoint call failed: $($_.Exception.Message)"
        return $null
    }
}

# ---------------- GUI FLOW (ZENITY) ----------------

function Select-PdfFilesGui {
    if (-not (Test-Command -Name "zenity")) {
        Show-Error "zenity is not installed. Install it with: sudo apt install zenity"
        return $null
    }

    $cmd = 'zenity --file-selection --multiple --separator="|" --title="Select PDF files to merge" --file-filter="PDF files | *.pdf"'
    $selection = bash -lc $cmd 2>$null

    if ([string]::IsNullOrWhiteSpace($selection)) {
        return $null
    }

    $files = $selection -split '\|'
    # Normalize to full paths
    $files = $files | ForEach-Object { (Resolve-Path $_).Path }
    return $files
}

function Select-OutputFileGui {
    if (-not (Test-Command -Name "zenity")) {
        Show-Error "zenity is not installed. Install it with: sudo apt install zenity"
        return $null
    }

    $cmd = 'zenity --file-selection --save --confirm-overwrite --title="Save merged PDF as" --file-filter="PDF files | *.pdf"'
    $output = bash -lc $cmd 2>$null

    if ([string]::IsNullOrWhiteSpace($output)) {
        return $null
    }

    if (-not $output.ToLower().EndsWith(".pdf")) {
        $output += ".pdf"
    }

    $full = (Resolve-Path (Split-Path $output -Parent) -ErrorAction SilentlyContinue)
    if ($null -eq $full) {
        # If directory doesn't exist yet, just return raw path
        return $output
    }

    return (Join-Path $full $([IO.Path]::GetFileName($output)))
}

# ---------------- MERGE LOGIC ----------------

function Merge-PdfFiles {
    param(
        [Parameter(Mandatory=$true)][string[]]$InputFiles,
        [Parameter(Mandatory=$true)][string]$OutputFile
    )

    if (-not (Test-Command -Name $Global:PdfUnitePath)) {
        Show-Error "pdfunite not found. Install poppler-utils: sudo apt install poppler-utils"
        return $false
    }

    # Ensure directory exists
    $outDir = Split-Path $OutputFile -Parent
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $args = @()
    $args += $InputFiles
    $args += $OutputFile

    Show-Info "Merging PDFs..."
    try {
        & $Global:PdfUnitePath @args
        if ($LASTEXITCODE -ne 0) {
            Show-Error "pdfunite failed with exit code $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Show-Error "Error running pdfunite: $($_.Exception.Message)"
        return $false
    }

    Show-Info "Merged PDF created: $OutputFile"
    return $true
}

# ---------------- MAIN ----------------

function Start-PdfAiMerger {
    Write-Host "=== AI LLM PDF Merger (Ubuntu / PowerShell) ===" -ForegroundColor Green

    $pdfs = Select-PdfFilesGui
    if (-not $pdfs -or $pdfs.Count -eq 0) {
        Show-Error "No PDF files selected."
        return
    }

    # Optional AI step: ask LLM for suggestions (order, title, etc.)
    $aiResult = Invoke-AiMergeNotes -PdfPaths $pdfs

    if ($aiResult) {
        Write-Host "AI suggestion:" -ForegroundColor Yellow
        $aiResult | ConvertTo-Json -Depth 5 | Write-Host

        # If your AI returns a suggested title, you can use it here:
        if ($aiResult.title) {
            Write-Host "Suggested title: $($aiResult.title)" -ForegroundColor Yellow
        }
    }

    $output = Select-OutputFileGui
    if (-not $output) {
        Show-Error "No output file selected."
        return
    }

    $ok = Merge-PdfFiles -InputFiles $pdfs -OutputFile $output
    if ($ok) {
        Show-Info "Done."
    }
}

Start-PdfAiMerger
