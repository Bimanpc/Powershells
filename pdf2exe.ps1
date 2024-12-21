# Define the paths to the PDF file and the output EXE file
$pdfFilePath = "C:\path\to\your\file.pdf"
$exeFilePath = "C:\path\to\your\output.exe"

# Define the path to the PDFtoEXE tool
$pdfToExeToolPath = "C:\path\to\pdftoexe.exe"

# Check if the PDF file exists
if (Test-Path $pdfFilePath) {
    # Construct the command to convert the PDF to EXE
    $command = "$pdfToExeToolPath $pdfFilePath $exeFilePath"

    # Execute the command
    try {
        Start-Process -FilePath $command -Wait -NoNewWindow
        Write-Output "Conversion completed successfully."
    } catch {
        Write-Error "An error occurred during the conversion: $_"
    }
} else {
    Write-Error "The PDF file does not exist at the specified path."
}
