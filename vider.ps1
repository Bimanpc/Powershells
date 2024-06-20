<#
.Description
This PowerShell script use ffprobe.exe to get the duration of each mp4 file in an input directiory. It then uses ffmpeg.exe to trim the beginning and end of each file based on the input parameters 'BeginTrimTime' and 'EndTrimTime'. The edited files are then saved to a seperate output directory.

.Parameters
    $ffmpegPath
        - The local system path where you have both ffprobe.exe and ffmpeg.exe downloaded
    $inputdir
        - The source directory containing the mp4 files to be edited
    $outputDir
        - The destination directory where edited files will be copied to
    $BeginTrimTime
        - The amount of time, in seconds, you want removed from the beginning of the mp4
    $EndTrimTime
        - The amount of time, in seconds, you want removed from the end of the mp4

.Example
    .\videoeditor.ps1 -ffmpegPath "C:\ffmpeg\bin" -inputDir "C:\Videos\in" -outputDir "C:\Videos\out" -BeginTrimTime 5 -EndTrimTime 5
#>
param(
    [string]$ffmpegPath,
    [string]$inputDir,
    [string]$outputDir,
    [int]$BeginTrimTime,
    [int]$EndTrimTime
)

# Ensure ffmpeg and ffprobe are in the system path
$env:Path += ";$ffmpegPath"

# Get all mp4 files in the input directory
$files = Get-ChildItem -Path $inputDir -Filter *.mp4

foreach ($file in $files) {
    # Get the full duration of the video file
    $duration = & ffprobe.exe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $file.FullName
    $duration = [math]::Round($duration)

    # Calculate the new end trim time
    $newEndTrimTime = $duration - $EndTrimTime

    # Trim the video file
    $outputFile = Join-Path -Path $outputDir -ChildPath $file.Name
    & ffmpeg.exe -i $file.FullName -ss $BeginTrimTime -to $newEndTrimTime -c copy $outputFile
}
