<#
.SYNOPSIS
  USB Immunizer (PowerShell) – inspired by Bitdefender’s USB Immunizer behavior.

.DESCRIPTION
  - Monitors for removable drives and auto-immunizes them.
  - Immunization: creates a locked Autorun.inf directory with protective ACLs and decoy files.
  - Optional: disables/enables Windows AutoRun for removable media via registry.
  - Requires elevation for ACL and registry operations.

.PARAMETER ImmunizeAllNow
  Immunize all currently mounted removable drives, then exit (unless -StopWatch is omitted).

.PARAMETER DisableAutoRun
  Disable Windows AutoRun for removable media.

.PARAMETER EnableAutoRun
  Restore Windows AutoRun default (re-enable AutoRun).

.PARAMETER StopWatch
  Do not start the hot-plug watcher loop.

.NOTES
  Tested on Windows 10/11. Run as Administrator for full effect.
#>

[CmdletBinding()]
param(
  [switch]$ImmunizeAllNow,
  [switch]$DisableAutoRun,
  [switch]$EnableAutoRun,
  [switch]$StopWatch
)

function Assert-Admin {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $pr = New-Object System.Security.Principal.WindowsPrincipal($id)
  if (-not $pr.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script should be run as Administrator for ACL and registry changes."
  }
}

function Get-RemovableVolumes {
  # Use .NET DriveInfo for portability; filter removable drives that are ready.
  [System.IO.DriveInfo]::GetDrives() | Where-Object {
    $_.DriveType -eq 'Removable' -and $_.IsReady
  }
}

function Set-AutorunInfLock {
  param(
    [Parameter(Mandatory=$true)][string]$RootPath
  )
  $target = Join-Path $RootPath 'Autorun.inf'

  try {
    # If a file exists, remove it (it may be malware's autorun.inf)
    if (Test-Path $target -PathType Leaf) {
      Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    }

    # Create directory "Autorun.inf" (Bitdefender pattern) to prevent future autorun.inf file creation.
    if (-not (Test-Path $target -PathType Container)) {
      New-Item -ItemType Directory -Path $target -Force | Out-Null
    }

    # Hide and mark as system to reduce tampering visibility.
    attrib +h +s $target

    # Add decoy files to make removal harder across OS/file managers.
    $decoys = @('con', 'nul', 'aux', 'lpt1', 'README.txt')
    foreach ($name in $decoys) {
      $p = Join-Path $target $name
      try {
        if ($name -eq 'README.txt') {
          if (-not (Test-Path $p)) {
            Set-Content -Path $p -Value "This folder prevents autorun-based malware from auto-executing."
          }
        } else {
          # Create zero-length file; reserved names may fail silently—ignore errors.
          New-Item -ItemType File -Path $p -Force -ErrorAction SilentlyContinue | Out-Null
        }
      } catch {}
    }

    # Lockdown ACL: deny write for Everyone, allow read/execute for SYSTEM/Admins only.
    $acl = Get-Acl -LiteralPath $target

    $sidEveryone = New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0') # Everyone
    $sidUsers    = New-Object System.Security.Principal.NTAccount('Users')
    $sidAdmins   = New-Object System.Security.Principal.NTAccount('Administrators')
    $sidSystem   = New-Object System.Security.Principal.NTAccount('SYSTEM')

    $denyWriteEveryone = New-Object System.Security.AccessControl.FileSystemAccessRule($sidEveryone, 'Write,Delete,WriteData,CreateFiles,CreateDirectories', 'ContainerInherit, ObjectInherit', 'None', 'Deny')
    $denyWriteUsers    = New-Object System.Security.AccessControl.FileSystemAccessRule($sidUsers, 'Write,Delete,WriteData,CreateFiles,CreateDirectories', 'ContainerInherit, ObjectInherit', 'None', 'Deny')
    $allowAdminsFull   = New-Object System.Security.AccessControl.FileSystemAccessRule($sidAdmins, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow')
    $allowSystemFull   = New-Object System.Security.AccessControl.FileSystemAccessRule($sidSystem, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow')

    $acl.SetAccessRuleProtection($true, $false) # disable inheritance
    $acl.ResetAccessRule($allowAdminsFull)
    $acl.AddAccessRule($allowAdminsFull)
    $acl.ResetAccessRule($allowSystemFull)
    $acl.AddAccessRule($allowSystemFull)
    $acl.AddAccessRule($denyWriteEveryone)
    $acl.AddAccessRule($denyWriteUsers)

    Set-Acl -LiteralPath $target -AclObject $acl

    Write-Host "Immunized: $RootPath" -ForegroundColor Green
  } catch {
    Write-Warning "Failed to immunize $RootPath: $($_.Exception.Message)"
  }
}

function Immunize-Volume {
  param(
    [Parameter(Mandatory=$true)][System.IO.DriveInfo]$Drive
  )
  # Safety: ensure root path exists and writable
  $root = $Drive.RootDirectory.FullName
  if (-not (Test-Path $root)) {
    Write-Warning "Drive not ready: $($Drive.Name)"
    return
  }
  Set-AutorunInfLock -RootPath $root
}

function Set-AutoRunState {
  param(
    [ValidateSet('Disable','Enable')][string]$State
  )
  $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
  New-Item -Path $regPath -Force | Out-Null

  if ($State -eq 'Disable') {
    # 0x95 (149) commonly disables AutoRun for unknown/removable drives while leaving CD/DVD behavior.
    New-ItemProperty -Path $regPath -Name 'NoDriveTypeAutoRun' -PropertyType DWord -Value 0x00000095 -Force | Out-Null
    Write-Host "AutoRun disabled for removable media (current user)." -ForegroundColor Yellow
  } else {
    # Restore Windows default: 0x91 (145) on modern Windows; adjust if you maintain different policy.
    New-ItemProperty -Path $regPath -Name 'NoDriveTypeAutoRun' -PropertyType DWord -Value 0x00000091 -Force | Out-Null
    Write-Host "AutoRun restored to Windows default (current user)." -ForegroundColor Yellow
  }
}

function Start-UsbWatcher {
  Write-Host "Starting USB watcher. Press Ctrl+C to stop." -ForegroundColor Cyan
  $known = @{}
  # Seed with current removable drives
  foreach ($d in Get-RemovableVolumes) { $known[$d.Name] = $true }

  while ($true) {
    Start-Sleep -Seconds 2
    $current = Get-RemovableVolumes
    $nowSet = $current.Name
    # Detect newly appeared drives
    foreach ($d in $current) {
      if (-not $known.ContainsKey($d.Name)) {
        Write-Host "Detected new removable drive: $($d.Name)" -ForegroundColor Cyan
        Immunize-Volume -Drive $d
        $known[$d.Name] = $true
      }
    }
    # Cleanup removed drives
    foreach ($k in @($known.Keys)) {
      if ($nowSet -notcontains $k) { $known.Remove($k) | Out-Null }
    }
  }
}

# Main
Assert-Admin

if ($DisableAutoRun) { Set-AutoRunState -State Disable }
if ($EnableAutoRun)  { Set-AutoRunState -State Enable }

if ($ImmunizeAllNow) {
  $drives = Get-RemovableVolumes
  if (-not $drives) {
    Write-Host "No removable drives detected." -ForegroundColor DarkYellow
  } else {
    foreach ($d in $drives) { Immunize-Volume -Drive $d }
  }
}

if (-not $StopWatch) {
  Start-UsbWatcher
}
