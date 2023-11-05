# Simple Password Manager in PowerShell

# Initialize an empty dictionary to store passwords
$PasswordVault = @{}

# Function to add a new password
function Add-Password {
    param(
        [string]$name,
        [string]$password
    )
    
    if ($PasswordVault.ContainsKey($name)) {
        Write-Host "Password for $name already exists. Use Update-Password to change it."
    }
    else {
        $PasswordVault[$name] = $password
        Write-Host "Password for $name added."
    }
}

# Function to retrieve a password
function Get-Password {
    param(
        [string]$name
    )
    
    if ($PasswordVault.ContainsKey($name)) {
        return $PasswordVault[$name]
    }
    else {
        Write-Host "Password for $name not found."
    }
}

# Function to update an existing password
function Update-Password {
    param(
        [string]$name,
        [string]$newPassword
    )
    
    if ($PasswordVault.ContainsKey($name)) {
        $PasswordVault[$name] = $newPassword
        Write-Host "Password for $name updated."
    }
    else {
        Write-Host "Password for $name not found."
    }
}

# Function to remove a password
function Remove-Password {
    param(
        [string]$name
    )
    
    if ($PasswordVault.ContainsKey($name)) {
        $PasswordVault.Remove($name)
        Write-Host "Password for $name removed."
    }
    else {
        Write-Host "Password for $name not found."
    }
}

# Main script

while ($true) {
    Write-Host "Password Manager Menu"
    Write-Host "1. Add Password"
    Write-Host "2. Get Password"
    Write-Host "3. Update Password"
    Write-Host "4. Remove Password"
    Write-Host "5. Exit"
    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" { 
            $name = Read-Host "Enter a name for the password"
            $password = Read-Host "Enter the password"
            Add-Password -name $name -password $password
        }
        "2" {
            $name = Read-Host "Enter the name for the password"
            $password = Get-Password -name $name
            if ($password) {
                Write-Host "Password for $name: $password"
            }
        }
        "3" {
            $name = Read-Host "Enter the name for the password"
            $newPassword = Read-Host "Enter the new password"
            Update-Password -name $name -newPassword $newPassword
        }
        "4" {
            $name = Read-Host "Enter the name for the password"
            Remove-Password -name $name
        }
        "5" {
            Write-Host "Goodbye!"
            exit
        }
        default {
            Write-Host "Invalid choice. Please try again."
        }
    }
}
