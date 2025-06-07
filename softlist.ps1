# Requires PowerShell 5.1 or later for Out-GridView -PassThru
# This script will list installed software and display it in a GridView GUI.

# Get installed applications from multiple sources for better coverage
function Get-InstalledApplications {
    $apps = @()

    # 1. Applications installed via MSI (Windows Installer)
    try {
        Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
            Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 -and $_.ParentKeyName -eq $null } |
            ForEach-Object {
                $app = [PSCustomObject]@{
                    Name        = $_.DisplayName
                    Version     = $_.DisplayVersion
                    Publisher   = $_.Publisher
                    InstallDate = $_.InstallDate
                    Source      = "MSI (System)"
                }
                $apps += $app
            }
    } catch {
        Write-Warning "Could not retrieve MSI applications from HKLM: $($_.Exception.Message)"
    }

    try {
        Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
            Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 -and $_.ParentKeyName -eq $null } |
            ForEach-Object {
                $app = [PSCustomObject]@{
                    Name        = $_.DisplayName
                    Version     = $_.DisplayVersion
                    Publisher   = $_.Publisher
                    InstallDate = $_.InstallDate
                    Source      = "MSI (User)"
                }
                $apps += $app
            }
    } catch {
        Write-Warning "Could not retrieve MSI applications from HKCU: $($_.Exception.Message)"
    }


    # 2. Applications installed via Programs and Features (64-bit and 32-bit on 64-bit OS)
    # This often overlaps with MSI, but can catch others.
    if ([System.Environment]::Is64BitOperatingSystem) {
        try {
            Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
                Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 -and $_.ParentKeyName -eq $null } |
                ForEach-Object {
                    $app = [PSCustomObject]@{
                        Name        = $_.DisplayName
                        Version     = $_.DisplayVersion
                        Publisher   = $_.Publisher
                        InstallDate = $_.InstallDate
                        Source      = "Programs and Features (x86)"
                    }
                    $apps += $app
                }
        } catch {
            Write-Warning "Could not retrieve x86 applications from HKLM:\Wow6432Node: $($_.Exception.Message)"
        }
    }

    # 3. Microsoft Store Apps (UWP Apps)
    try {
        Get-AppxPackage |
            Where-Object { $_.IsFramework -ne $true -and $_.SignatureKind -ne "System" -and $_.DisplayName -ne $null } |
            ForEach-Object {
                $app = [PSCustomObject]@{
                    Name        = $_.DisplayName
                    Version     = $_.Version
                    Publisher   = $_.Publisher
                    InstallDate = "N/A" # UWP apps don't typically expose InstallDate directly this way
                    Source      = "Microsoft Store (UWP)"
                }
                $apps += $app
            }
    } catch {
        Write-Warning "Could not retrieve Microsoft Store apps: $($_.Exception.Message)"
    }

    # Remove duplicates and sort
    $apps | Select-Object -Unique Name, Version, Publisher, InstallDate, Source | Sort-Object Name
}

Write-Host "Gathering installed software information..."
$installedSoftware = Get-InstalledApplications

if ($installedSoftware) {
    Write-Host "Displaying software in a GUI. You can filter and sort the list."
    $installedSoftware | Out-GridView -Title "Installed Software on This PC"
} else {
    Write-Warning "No installed software found or an error occurred during retrieval."
}
