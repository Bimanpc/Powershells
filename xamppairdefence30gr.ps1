# ==============================
# Joomla AI Cyber Defense Script
# ==============================

param(
    [string]$JoomlaPath = "C:\xampp\htdocs\joomla",
    [string]$LogFile = "C:\logs\joomla_scan.log",
    [string]$OpenAIKey = "YOUR_API_KEY"
)

# --- Initialize ---
Write-Host "Starting Joomla Security Scan..."
$date = Get-Date
Add-Content $LogFile "Scan started: $date"

# --- Suspicious Patterns ---
$patterns = @(
    "base64_decode",
    "eval\(",
    "shell_exec",
    "gzinflate",
    "str_rot13",
    "assert\(",
    "passthru",
    "system\("
)

# --- Scan Files ---
$results = @()

Get-ChildItem -Path $JoomlaPath -Recurse -Include *.php | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw

    foreach ($pattern in $patterns) {
        if ($content -match $pattern) {
            $finding = @{
                File = $file
                Pattern = $pattern
            }
            $results += $finding

            Add-Content $LogFile "Suspicious pattern '$pattern' found in $file"
        }
    }
}

# --- File Integrity Check (Hashing) ---
Write-Host "Calculating file hashes..."

$hashes = @()
Get-ChildItem -Path $JoomlaPath -Recurse -Include *.php | ForEach-Object {
    $hash = Get-FileHash $_.FullName -Algorithm SHA256
    $hashes += @{
        File = $_.FullName
        Hash = $hash.Hash
    }
}

# --- Prepare AI Analysis ---
if ($results.Count -gt 0) {
    Write-Host "Sending findings to AI for analysis..."

    $payload = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = "You are a cybersecurity analyst. Analyze Joomla vulnerabilities."
            },
            @{
                role = "user"
                content = ($results | ConvertTo-Json -Depth 3)
            }
        )
    } | ConvertTo-Json -Depth 5

    $headers = @{
        "Authorization" = "Bearer $OpenAIKey"
        "Content-Type"  = "application/json"
    }

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/chat/completions" `
            -Method Post `
            -Headers $headers `
            -Body $payload

        $analysis = $response.choices[0].message.content

        Add-Content $LogFile "`nAI Analysis:`n$analysis"
        Write-Host "AI Analysis Completed"
    }
    catch {
        Write-Host "Error calling AI API: $_"
    }
}
else {
    Write-Host "No obvious threats detected."
}

# --- Hardening Suggestions ---
Write-Host "`nBasic Hardening Recommendations:"
Write-Host "- Disable PHP execution in /images and /uploads"
Write-Host "- Keep Joomla core & extensions updated"
Write-Host "- Use Web Application Firewall (WAF)"
Write-Host "- Restrict admin access via IP"

Add-Content $LogFile "Scan completed: $(Get-Date)"
