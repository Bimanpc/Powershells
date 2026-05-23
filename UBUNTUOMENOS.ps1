# KDE Network Flusher + LLM helper (PowerShell .ps1)
# Usage: pwsh ./kde-network-flusher.ps1

# Configuration: set your LLM API key in env var LLM_API_KEY
$apiKey = $env:LLM_API_KEY

function Show-Dialog($text, $title="Network Flusher") {
    & kdialog --title $title --msgbox $text
}

function Ask-YesNo($text, $title="Confirm") {
    & kdialog --yesno "$text" --title "$title"
    return $LASTEXITCODE -eq 0
}

function Flush-Network() {
    Show-Dialog "Restarting NetworkManager..." "Network"
    # Use pkexec if available to prompt for password graphically
    if (Get-Command pkexec -ErrorAction SilentlyContinue) {
        & pkexec systemctl restart NetworkManager
    } else {
        sudo systemctl restart NetworkManager
    }
    Show-Dialog "NetworkManager restarted." "Network"
}

function Flush-DNS() {
    Show-Dialog "Flushing DNS caches..." "DNS"
    if (Get-Command resolvectl -ErrorAction SilentlyContinue) {
        if (Get-Command pkexec -ErrorAction SilentlyContinue) {
            & pkexec resolvectl flush-caches
        } else {
            sudo resolvectl flush-caches
        }
        Show-Dialog "DNS caches flushed." "DNS"
    } else {
        Show-Dialog "resolvectl not found on this system." "Error"
    }
}

function Query-LLM($prompt) {
    if (-not $apiKey) {
        Show-Dialog "LLM_API_KEY not set in environment." "LLM Error"
        return
    }
    $body = @{
        model = "gpt-4o-mini"
        prompt = $prompt
        max_tokens = 300
    } | ConvertTo-Json

    try {
        $resp = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
            -Method Post -Headers @{ Authorization = "Bearer $apiKey" } `
            -ContentType "application/json" -Body $body -ErrorAction Stop
        $text = $resp.choices[0].message.content
        Show-Dialog $text "LLM Response"
    } catch {
        Show-Dialog "LLM request failed: $($_.Exception.Message)" "LLM Error"
    }
}

# Main menu
while ($true) {
    $choice = & kdialog --menu "Choose action" "Flush Network" "Flush DNS" "Ask LLM" "Exit"
    switch ($choice) {
        "Flush Network" { if (Ask-YesNo "Restart NetworkManager now?") { Flush-Network } }
        "Flush DNS"     { if (Ask-YesNo "Flush DNS caches now?") { Flush-DNS } }
        "Ask LLM"       {
            $prompt = & kdialog --inputbox "Enter prompt for LLM:" "LLM Prompt"
            if ($prompt) { Query-LLM $prompt }
        }
        "Exit"          { break }
        default         { break }
    }
}
