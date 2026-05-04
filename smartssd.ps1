# Requires: smartctl installed

function Get-Drives {
    lsblk -d -o NAME,TYPE | Where-Object { $_ -match "disk" } |
    ForEach-Object {
        ($_ -split "\s+")[0]
    }
}

function Get-SMARTData {
    param ($drive)

    $output = smartctl -A /dev/$drive 2>$null

    if ($output -match "SMART support is: Available") {
        $output | Select-String "Reallocated_Sector_Ct|Power_On_Hours|Temperature_Celsius|Wear_Leveling_Count" |
        ForEach-Object {
            $parts = ($_ -split "\s+") | Where-Object { $_ -ne "" }
            [PSCustomObject]@{
                Drive = $drive
                Attribute = $parts[1]
                Value = $parts[-1]
            }
        }
    }
}

$drives = Get-Drives

$data = foreach ($d in $drives) {
    Get-SMARTData -drive $d
}

$data | Format-Table -AutoSize
