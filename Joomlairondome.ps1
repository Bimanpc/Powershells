<#
AI Joomla Cyber Threat Checker (GUI)
PowerShell + Windows Forms

Description:
- Simple desktop GUI for analyzing a Joomla installation for common security issues.
- Uses a local or remote LLM API (OpenAI-compatible endpoint) to summarize findings.
- Checks:
  * Joomla version disclosure
  * Configuration file permissions
  * Suspicious PHP files
  * Writable critical directories
  * Known dangerous functions in PHP files
- Generates a structured report and sends it to an LLM for risk assessment.

Requirements:
- Windows PowerShell 5.1+ or PowerShell 7+
- Internet access if using a remote LLM API
- An OpenAI-compatible API endpoint

Usage:
1. Save as: JoomlaCyberThreatChecker.ps1
2. Run:
   powershell -ExecutionPolicy Bypass -File .\JoomlaCyberThreatChecker.ps1
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------
# Helper Functions
# -----------------------------

function Write-Log {
    param([string]$Message)
    $script:txtOutput.AppendText("[$(Get-Date -Format 'HH:mm:ss')] $Message`r`n")
    $script:txtOutput.SelectionStart = $script:txtOutput.Text.Length
    $script:txtOutput.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Get-FilePermissionSummary {
    param([string]$Path)

    try {
        $acl = Get-Acl $Path
        $acl.Access | ForEach-Object {
            "$($_.IdentityReference): $($_.FileSystemRights)"
        } | Sort-Object -Unique
    } catch {
        "Unable to read permissions: $_"
    }
}

function Find-SuspiciousPhpFiles {
    param([string]$Root)

    $patterns = @(
        'base64_decode\s*\(',
        'eval\s*\(',
        'gzinflate\s*\(',
        'shell_exec\s*\(',
        'system\s*\(',
        'passthru\s*\(',
        'assert\s*\('
    )

    $results = @()

    Get-ChildItem -Path $Root -Recurse -Include *.php -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $content = Get-Content $_.FullName -Raw -ErrorAction Stop
            foreach ($pattern in $patterns) {
                if ($content -match $pattern) {
                    $results += [PSCustomObject]@{
                        File    = $_.FullName
                        Pattern = $pattern
                    }
                }
            }
        } catch {
            # Ignore unreadable files
        }
    }

    $results
}

function Test-WritablePaths {
    param([string]$Root)

    $critical = @(
        "configuration.php",
        "administrator",
        "components",
        "modules",
        "plugins",
        "templates"
    )

    $findings = @()

    foreach ($item in $critical) {
        $path = Join-Path $Root $item
        if (Test-Path $path) {
            try {
                $acl = Get-Acl $path
                foreach ($access in $acl.Access) {
                    if ($access.FileSystemRights.ToString() -match 'Write|Modify|FullControl') {
                        $findings += [PSCustomObject]@{
                            Path      = $path
                            Principal = $access.IdentityReference.ToString()
                            Rights    = $access.FileSystemRights.ToString()
                        }
                    }
                }
            } catch {
                $findings += [PSCustomObject]@{
                    Path      = $path
                    Principal = "Unknown"
                    Rights    = "Unable to read ACL"
                }
            }
        }
    }

    $findings
}

function Get-JoomlaVersion {
    param([string]$Root)

    $versionFile = Join-Path $Root "libraries\src\Version.php"
    if (-not (Test-Path $versionFile)) {
        return "Unknown"
    }

    try {
        $content = Get-Content $versionFile -Raw
        if ($content -match 'public const VERSION\s*=\s*''([^'']+)''') {
            return $matches[1]
        }
    } catch {}

    "Unknown"
}

function Invoke-LLMAnalysis {
    param(
        [string]$Report,
        [string]$ApiUrl,
        [string]$ApiKey,
        [string]$Model = "gpt-4o-mini"
    )

    if ([string]::IsNullOrWhiteSpace($ApiUrl)) {
        return "No API URL configured. Raw report only."
    }

    $headers = @{
        "Content-Type" = "application/json"
    }

    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        $headers["Authorization"] = "Bearer $ApiKey"
    }

    $prompt = @"
You are a cybersecurity analyst specializing in Joomla CMS security.

Analyze the following scan report and provide:
1. Executive Summary
2. Severity Rating (Low/Medium/High/Critical)
3. Key Findings
4. Recommended Remediation Steps
5. Incident Response Priority

Scan Report:
$Report
"@

    $body = @{
        model = $Model
        messages = @(
            @{
                role = "system"
                content = "You are an expert in web application and CMS security."
            },
            @{
                role = "user"
                content = $prompt
            }
        )
        temperature = 0.2
    } | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $headers -Body $body -TimeoutSec 120
        return $response.choices[0].message.content
    } catch {
        return "LLM API Error: $_"
    }
}

function Start-JoomlaThreatScan {
    param(
        [string]$Path,
        [string]$ApiUrl,
        [string]$ApiKey,
        [string]$Model
    )

    if (-not (Test-Path $Path)) {
        throw "Invalid Joomla path."
    }

    Write-Log "Starting scan of: $Path"

    $report = New-Object System.Text.StringBuilder

    # Version
    Write-Log "Detecting Joomla version..."
    $version = Get-JoomlaVersion -Root $Path
    [void]$report.AppendLine("Joomla Version: $version")
    [void]$report.AppendLine()

    # Configuration permissions
    $configPath = Join-Path $Path "configuration.php"
    if (Test-Path $configPath) {
        Write-Log "Checking configuration.php permissions..."
        [void]$report.AppendLine("configuration.php Permissions:")
        Get-FilePermissionSummary -Path $configPath | ForEach-Object {
            [void]$report.AppendLine("  $_")
        }
        [void]$report.AppendLine()
    }

    # Writable paths
    Write-Log "Checking writable critical paths..."
    $writable = Test-WritablePaths -Root $Path
    [void]$report.AppendLine("Writable Critical Paths:")
    if ($writable.Count -gt 0) {
        foreach ($item in $writable) {
            [void]$report.AppendLine("  $($item.Path) | $($item.Principal) | $($item.Rights)")
        }
    } else {
        [void]$report.AppendLine("  None detected.")
    }
    [void]$report.AppendLine()

    # Suspicious files
    Write-Log "Scanning PHP files for suspicious patterns..."
    $suspicious = Find-SuspiciousPhpFiles -Root $Path
    [void]$report.AppendLine("Suspicious PHP Patterns:")
    if ($suspicious.Count -gt 0) {
        foreach ($item in $suspicious | Select-Object -First 200) {
            [void]$report.AppendLine("  $($item.File) -> $($item.Pattern)")
        }
    } else {
        [void]$report.AppendLine("  None detected.")
    }
    [void]$report.AppendLine()

    $rawReport = $report.ToString()

    Write-Log "Sending report to LLM..."
    $analysis = Invoke-LLMAnalysis -Report $rawReport -ApiUrl $ApiUrl -ApiKey $ApiKey -Model $Model

    Write-Log "Scan complete."

    return @"
================ RAW SCAN REPORT ================

$rawReport

================ LLM ANALYSIS ===================

$analysis
"@
}

# -----------------------------
# GUI Setup
# -----------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "AI Joomla Cyber Threat Checker"
$form.Size = New-Object System.Drawing.Size(1000, 720)
$form.StartPosition = "CenterScreen"

# Joomla Path
$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text = "Joomla Path:"
$lblPath.Location = New-Object System.Drawing.Point(10, 15)
$lblPath.AutoSize = $true
$form.Controls.Add($lblPath)

$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = New-Object System.Drawing.Point(110, 12)
$txtPath.Size = New-Object System.Drawing.Size(700, 20)
$form.Controls.Add($txtPath)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse"
$btnBrowse.Location = New-Object System.Drawing.Point(820, 10)
$form.Controls.Add($btnBrowse)

# API URL
$lblApi = New-Object System.Windows.Forms.Label
$lblApi.Text = "API URL:"
$lblApi.Location = New-Object System.Drawing.Point(10, 45)
$lblApi.AutoSize = $true
$form.Controls.Add($lblApi)

$txtApi = New-Object System.Windows.Forms.TextBox
$txtApi.Location = New-Object System.Drawing.Point(110, 42)
$txtApi.Size = New-Object System.Drawing.Size(780, 20)
$txtApi.Text = "https://api.openai.com/v1/chat/completions"
$form.Controls.Add($txtApi)

# API Key
$lblKey = New-Object System.Windows.Forms.Label
$lblKey.Text = "API Key:"
$lblKey.Location = New-Object System.Drawing.Point(10, 75)
$lblKey.AutoSize = $true
$form.Controls.Add($lblKey)

$txtKey = New-Object System.Windows.Forms.TextBox
$txtKey.Location = New-Object System.Drawing.Point(110, 72)
$txtKey.Size = New-Object System.Drawing.Size(780, 20)
$txtKey.UseSystemPasswordChar = $true
$form.Controls.Add($txtKey)

# Model
$lblModel = New-Object System.Windows.Forms.Label
$lblModel.Text = "Model:"
$lblModel.Location = New-Object System.Drawing.Point(10, 105)
$lblModel.AutoSize = $true
$form.Controls.Add($lblModel)

$txtModel = New-Object System.Windows.Forms.TextBox
$txtModel.Location = New-Object System.Drawing.Point(110, 102)
$txtModel.Size = New-Object System.Drawing.Size(200, 20)
$txtModel.Text = "gpt-4o-mini"
$form.Controls.Add($txtModel)

# Scan Button
$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "Start Threat Scan"
$btnScan.Location = New-Object System.Drawing.Point(330, 100)
$btnScan.Size = New-Object System.Drawing.Size(150, 25)
$form.Controls.Add($btnScan)

# Output
$script:txtOutput = New-Object System.Windows.Forms.RichTextBox
$script:txtOutput.Location = New-Object System.Drawing.Point(10, 140)
$script:txtOutput.Size = New-Object System.Drawing.Size(960, 530)
$script:txtOutput.Font = New-Object System.Drawing.Font("Consolas", 10)
$script:txtOutput.ReadOnly = $true
$script:txtOutput.WordWrap = $false
$form.Controls.Add($script:txtOutput)

# Folder Browser
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog

$btnBrowse.Add_Click({
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $txtPath.Text = $folderBrowser.SelectedPath
    }
})

$btnScan.Add_Click({
    try {
        $script:txtOutput.Clear()

        $result = Start-JoomlaThreatScan `
            -Path $txtPath.Text `
            -ApiUrl $txtApi.Text `
            -ApiKey $txtKey.Text `
            -Model $txtModel.Text

        $script:txtOutput.Text = $result
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "Scan Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# Run GUI
[void]$form.ShowDialog()
