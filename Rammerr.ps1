# Import the System.Diagnostics assembly
Add-Type -AssemblyName System.Diagnostics

# Get the current process
$currentProcess = [System.Diagnostics.Process]::GetCurrentProcess()

# Clear the working set (release physical memory)
$currentProcess.Refresh()
$currentProcess.MinWorkingSet = [IntPtr]::Zero
$currentProcess.MaxWorkingSet = [IntPtr]::Zero

Write-Host "RAM has been cleared for the current process."
