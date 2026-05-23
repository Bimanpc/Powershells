#!/usr/bin/pwsh
# PPT → MP4 Converter GUI for Ubuntu
# Local-only, admin-safe, no telemetry

function Show-Dialog {
    param($Message, $Type="info")
    zenity --$Type --text="$Message" 2>/dev/null
}

function Select-PPT {
    zenity --file-selection --title="Select PPT/PPTX File" --file-filter="*.ppt *.pptx" 2>/dev/null
}

function Select-Output {
    zenity --file-selection --save --confirm-overwrite --title="Save MP4 As" --filename="output.mp4" 2>/dev/null
}

# -------------------------
# MAIN GUI FLOW
# -------------------------

$ppt = Select-PPT
if (-not $ppt) { Show-Dialog "No file selected." "error"; exit }

$out = Select-Output
if (-not $out) { Show-Dialog "No output selected." "error"; exit }

$temp = "/tmp/ppt2mp4_$(Get-Random)"
mkdir $temp | Out-Null

Show-Dialog "Converting PPT to images..."

# BACKEND CONTRACT: PPT → PNG
libreoffice --headless --convert-to png --outdir $temp $ppt 2>/dev/null

$images = Get-ChildItem "$temp" -Filter "*.png" | Sort-Object Name
if ($images.Count -eq 0) {
    Show-Dialog "Conversion failed. No images generated." "error"
    exit
}

Show-Dialog "Rendering MP4 video..."

# BACKEND CONTRACT: PNG → MP4
ffmpeg -y -framerate 1 -i "$temp/%03d.png" -c:v libx264 -pix_fmt yuv420p "$out" 2>/dev/null

if ($LASTEXITCODE -ne 0) {
    Show-Dialog "FFmpeg failed to create the video." "error"
    exit
}

Show-Dialog "Conversion complete! Saved to:`n$out" "info"

rm -r $temp
