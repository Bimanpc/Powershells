function Generate-RandomPassword {
    param (
        [Parameter(Mandatory)]
        [int] $length,
        [int] $NumberOfSpecialChars = 1
    )

    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($length, $NumberOfSpecialChars)
}

# Usage:
$randomPassword = Generate-RandomPassword -length 10
Write-Output "Generated password: $randomPassword"
