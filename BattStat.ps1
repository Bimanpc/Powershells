<#
Get-BatteryInfo.ps1
#>

$path = $env:temp
$computer = $env:COMPUTERNAME
$timestamp = Get-Date -UFormat "%Y%m%d"
$empty_line = ""

$batteries = Get-WmiObject Win32_Battery -ComputerName $computer
$compsys = Get-WmiObject -class Win32_ComputerSystem -ComputerName $computer
$compsysprod = Get-WMIObject -class Win32_ComputerSystemProduct -ComputerName $computer
$enclosure = Get-WmiObject -Class Win32_SystemEnclosure -ComputerName $computer
$number_of_batteries = ($batteries | Measure-Object).Count
$os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer

$obj_battery = @()

ForEach ($battery in $batteries) {
    Switch ($enclosure.ChassisTypes) {
        { $_ -lt 1 } { $chassis = "" }
        { $_ -eq 1 } { $chassis = "Other" }
        { $_ -eq 2 } { $chassis = "Unknown" }
        # ... (other chassis types)
    }

    $is_a_laptop = $false
    If ($enclosure | Where-Object { $_.ChassisTypes -eq 9 -or $_.ChassisTypes -eq 10 -or $_.ChassisTypes -eq 14}) {
        $is_a_laptop = $true
    }

    # ... (other checks for domain role, PC system type, etc.)

    Switch ($battery.Availability) {
        # ... (availability cases)
    }

    Switch ($battery.BatteryStatus) {
        # ... (battery status cases)
    }

    # Create custom object with relevant battery info
    $obj_battery += [PSCustomObject]@{
        "Battery" = $battery.DeviceID
        "Chassis" = $chassis
        "Laptop" = $is_a_laptop
        "DomainRole" = $domain_role
        "PCType" = $pc_type
        "ProductType" = $product_type
        "Availability" = $availability
        "Status" = $status
    }
}

# Display battery info
$obj_battery | Format-Table -AutoSize
