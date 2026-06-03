#!/usr/bin/env pwsh
<#
.SYNOPSIS
  XAMPP-like LAMP stack installer for Ubuntu (Apache + MariaDB + PHP)

.USAGE
  pwsh ./setup-xampp-like.ps1
#>

# --- Config ---
$ApachePkg   = "apache2"
$MariaDbPkgs = @("mariadb-server", "mariadb-client")
$PhpPkgs     = @(
    "php",
    "libapache2-mod-php",
    "php-mysql",
    "php-cli",
    "php-curl",
    "php-xml",
    "php-mbstring",
    "php-zip",
    "php-gd"
)
$PhpMyAdminPkg = "phpmyadmin"   # optional; comment out if not needed

function Run-OrFail {
    param(
        [Parameter(Mandatory=$true)][string]$Cmd
    )
    Write-Host ">> $Cmd" -ForegroundColor Cyan
    bash -lc "$Cmd"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Command failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

Write-Host "=== XAMPP-like LAMP setup on Ubuntu ===" -ForegroundColor Green

# 1. Update package index
Run-OrFail "sudo apt-get update -y"

# 2. Install Apache
Write-Host "`n[1/4] Installing Apache..." -ForegroundColor Yellow
Run-OrFail "sudo apt-get install -y $ApachePkg"

# 3. Install MariaDB (MySQL-compatible)
Write-Host "`n[2/4] Installing MariaDB..." -ForegroundColor Yellow
Run-OrFail "sudo apt-get install -y $($MariaDbPkgs -join ' ')"

# Secure MariaDB (non-interactive basic hardening)
Write-Host "`nSecuring MariaDB (basic)..." -ForegroundColor Yellow
$SecureSql = @"
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
"@
$SecureSqlFile = "/tmp/secure_mariadb.sql"
$SecureSql | Out-File -FilePath $SecureSqlFile -Encoding ascii -Force
Run-OrFail "sudo mysql < $SecureSqlFile"
Run-OrFail "rm -f $SecureSqlFile"

# 4. Install PHP and extensions
Write-Host "`n[3/4] Installing PHP and extensions..." -ForegroundColor Yellow
Run-OrFail "sudo apt-get install -y $($PhpPkgs -join ' ')"

# 5. Optional: phpMyAdmin
Write-Host "`n[4/4] Installing phpMyAdmin (optional)..." -ForegroundColor Yellow
Write-Host "If prompted, choose Apache2 and set a phpMyAdmin password." -ForegroundColor DarkYellow
Run-OrFail "sudo apt-get install -y $PhpMyAdminPkg"

# 6. Enable Apache modules and restart
Write-Host "`nEnabling Apache modules and restarting..." -ForegroundColor Yellow
Run-OrFail "sudo a2enmod php* rewrite"
Run-OrFail "sudo systemctl restart apache2"
Run-OrFail "sudo systemctl enable apache2 mariadb"

# 7. Create a test PHP file
$WebRoot = "/var/www/html"
$InfoPhp = "$WebRoot/info.php"
Write-Host "`nCreating test PHP file at $InfoPhp ..." -ForegroundColor Yellow
$PhpInfo = '<?php phpinfo(); ?>'
echo $PhpInfo | sudo tee $InfoPhp | Out-Null

Write-Host "`n=== DONE ===" -ForegroundColor Green
Write-Host "Apache document root:  $WebRoot"
Write-Host "Test page:            http://localhost/info.php"
Write-Host "phpMyAdmin (if installed): http://localhost/phpmyadmin"
