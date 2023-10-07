# PC Cleanup Script

# Function to delete temporary files
function DeleteTemporaryFiles {
    Remove-Item -Path "C:\Windows\Temp\*" -Force -Recurse
}

# Function to clear the recycle bin
function ClearRecycleBin {
    Clear-RecycleBin -Force
}
