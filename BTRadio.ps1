# Toggle Bluetooth On or Off
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)][ValidateSet('Off', 'On')][string]$BluetoothStatus
)

# Start the Bluetooth service if it's stopped
If ((Get-Service bthserv).Status -eq 'Stopped') {
    Start-Service bthserv
}

# Interact with WinRT to control Bluetooth
Add-Type -AssemblyName System.Runtime.WindowsRuntime

# Define a function to await asynchronous tasks
Function Await($WinRtTask, $ResultType) {
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0]
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

# Load the necessary WinRT types
[Windows.Devices.Radios.Radio,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
[Windows.Devices.Radios.RadioAccessStatus,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null

# Toggle Bluetooth radio based on user input
If ($BluetoothStatus -eq 'Off') {
    # Disable Bluetooth
    [Windows.Devices.Radios.Radio]::RequestAccessAsync() | Await -ResultType [Windows.Devices.Radios.RadioAccessStatus]
    [Windows.Devices.Radios.Radio]::GetRadiosAsync() | Await -ResultType [System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]] | ForEach-Object {
        $_.State = [Windows.Devices.Radios.RadioState]::Off
    }
}
Else {
    # Enable Bluetooth
    [Windows.Devices.Radios.Radio]::RequestAccessAsync() | Await -ResultType [Windows.Devices.Radios.RadioAccessStatus]
    [Windows.Devices.Radios.Radio]::GetRadiosAsync() | Await -ResultType [System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]] | ForEach-Object {
        $_.State = [Windows.Devices.Radios.RadioState]::On
    }
}
