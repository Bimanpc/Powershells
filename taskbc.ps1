<# 
Customize Taskbar in Windows 11 
Version 1.1 
Added Option to remove Copilot and updated remove Search 
#> 

param ( 
    [switch]$RemoveTaskView, 
    [switch]$RemoveCopilot, 
    [switch]$RemoveWidgets, 
    [switch]$RemoveChat, 
    [switch]$MoveStartLeft, 
    [switch]$RemoveSearch, 
    [switch]$StartMorePins, 
    [switch]$StartMoreRecommendations, 
    [switch]$RunForExistingUsers 
) 

[string]$RegValueName = "CustomizeTaskbar" 
[string]$FullRegKeyName = "HKLM:\\SOFTWARE\\ccmexec\\" 

# Create registry value if it doesn't exist 
If (! (Test-Path $FullRegKeyName)) { 
    New-Item -Path $FullRegKeyName -type Directory -force 
} 

New-itemproperty $FullRegKeyName -Name $RegValueName -Value "1" -Type STRING -Force 

REG LOAD HKLM\\Default C:\\Users\\Default\\NTUSER.DAT 

switch ($PSBoundParameters.Keys) { 
    # Removes Task View from the Taskbar 
    'RemoveTaskView' { 
        Write-Host "Attempting to run: $PSItem" 
        $reg = New-ItemProperty "HKLM:\\Default\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name "ShowTaskViewButton" -Value "0" -PropertyType Dword -Force 
        try { $reg.Handle.Close () } catch {} 
    } 
    # Removes Widgets from the Taskbar 
    'RemoveWidgets' { 
        Write-Host "Attempting to run: $PSItem" 
        $reg = New-ItemProperty "HKLM:\\Default\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name "TaskbarDa" -Value "0" -PropertyType Dword -Force 
        try { $reg.Handle.Close () } catch {} 
    } 
    # Removes Copilot from the Taskbar 
    'RemoveCopilot' { 
        Write-Host "Attempting to run: $PSItem" 
        $reg = New-ItemProperty "HKLM:\\Default\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name "ShowCopilotButton" -Value "0" -PropertyType Dword -Force 
        try { $reg.Handle.Close () } catch {} 
    } 
    # Removes Chat from the Taskbar 
    'RemoveChat' { 
        Write-Host "Attempting to run: $PSItem" 
        $reg = New-ItemProperty "HKLM:\\Default\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name "TaskbarMn" -Value "0" -PropertyType Dword -Force 
        try { $reg.Handle.Close () } catch {} 
    } 
    # Default StartMenu alignment 0=Left 
    'MoveStartLeft' { 
        Write-Host "Attempting to run: $PSItem" 
        $reg = New-ItemProperty "HKLM:\\Default\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name "TaskbarAl" -Value "0" -PropertyType Dword -Force 
        try { $reg.Handle.Close () } catch {} 
    } 
    # Default StartMenu pins layout 0=Default, 1=More Pins, 2=More Recommendations (requires Windows 11 22H2) 
    'StartMorePins' { 
        Write-Host "Attempting to run: $PSItem" 
        $reg = New-ItemProperty "HKLM:\\Default\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name "Start_Layout" -Value "1" -PropertyType Dword -Force 
        try { $reg.Handle.Close () } catch {} 
    } 
    # Default StartMenu pins layout 0=Default, 1=More Pins, 2=More Recommendations (requires Windows 11 22H2) 
    'StartMoreRecommendations' { 
        Write-Host "Attempting to run: $PSItem" 
        $reg = New-ItemProperty "HKLM:\\Default\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name "Start_Layout" -Value "2" -PropertyType Dword -Force 
        try { $reg.Handle.Close () } catch {} 
    } 
    # Removes search from the Taskbar 
    'RemoveSearch' { 
        Write-Host "Attempting to run: $PSItem" 
        $reg = New-ItemProperty "HKLM:\\Default\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name "TaskbarSrch" -Value "0" -PropertyType Dword -Force 
        try { $reg.Handle.Close () } catch {} 
    } 
} 
