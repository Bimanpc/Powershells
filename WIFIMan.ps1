#!/usr/bin/pwsh
# Wi-Fi Speed Test GUI for Ubuntu using PowerShell + Zenity

function Show-Message {
    param(
        [string]$text,
        [string]$title = "Wi-Fi Speed Test"
    )
    zenity --info --width=350 --height=200 --title="$title" --text="$text"
}

# Check dependencies
if (-not (Get-Command speedtest-cli -ErrorAction SilentlyContinue)) {
    Show-Message "speedtest-cli is not installed. Install it with:`nsudo apt install speedtest-cli`" "Missing Dependency"
    exit
}

if (-not (Get-Command zenity -ErrorAction SilentlyContinue)) {
    Write-Host "Zenity is not installed. Install it with: sudo apt install zenity"
    exit
}

# Ask user to start test
zenity --question --width=300 --title="Wi-Fi Speed Test" --text="Start Wi-Fi speed test?"
if ($LASTEXITCODE -ne 0) {
    exit
}

# Run speed test
$results = speedtest-cli --simple 2>&1

if ($LASTEXITCODE -ne 0) {
    Show-Message "Error running speed test:`n$results" "Error"
    exit
}

# Parse results
$ping = ($results | Select-String "Ping").ToString()
$download = ($results | Select-String "Download").ToString()
$upload = ($results | Select-String "Upload").ToString()

# Format output
$output = @"
<b>Wi-Fi Speed Test Results</b>

$ping
$download
$upload
"@

# Show results in GUI
zenity --info --width=350 --height=250 --title="Wi-Fi Speed Test Results" --text="$output" --html
