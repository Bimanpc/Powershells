#!/usr/bin/pwsh
# KDE Plasma MFA Auth App (TOTP) - Single-file PowerShell GUI
# Requirements: PowerShell 7+, .NET WinForms, libgdiplus (for Linux), KDE/X11

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#-------------------- Config --------------------
$Global:ConfigPath = Join-Path $HOME ".kde-mfa-accounts.json"
$Global:TimeStep   = 30   # seconds
$Global:Digits     = 6

#-------------------- Storage --------------------
function Load-Accounts {
    if (Test-Path $Global:ConfigPath) {
        try {
            $json = Get-Content $Global:ConfigPath -Raw
            if ($json.Trim()) {
                return $json | ConvertFrom-Json
            }
        } catch {}
    }
    return @()
}

function Save-Accounts {
    param([array]$Accounts)
    $Accounts | ConvertTo-Json -Depth 5 | Set-Content -Path $Global:ConfigPath -Encoding UTF8
}

#-------------------- Base32 / TOTP --------------------
$Global:Base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

function Decode-Base32 {
    param([string]$Input)

    $input = $Input.ToUpper().Replace("=", "").Replace(" ", "")
    $bits = ""
    foreach ($c in $input.ToCharArray()) {
        $idx = $Global:Base32Alphabet.IndexOf($c)
        if ($idx -lt 0) { continue }
        $bits += [Convert]::ToString($idx, 2).PadLeft(5, '0')
    }

    $bytes = New-Object System.Collections.Generic.List[byte]
    for ($i = 0; $i + 8 -le $bits.Length; $i += 8) {
        $chunk = $bits.Substring($i, 8)
        $bytes.Add([Convert]::ToByte($chunk, 2))
    }
    return $bytes.ToArray()
}

function Get-Totp {
    param(
        [string]$SecretBase32,
        [int]$Digits = 6,
        [int]$TimeStep = 30
    )

    $keyBytes = Decode-Base32 $SecretBase32
    if (-not $keyBytes -or $keyBytes.Length -eq 0) { return "" }

    $unixTime = [int][double]::Parse((Get-Date -Date (Get-Date).ToUniversalTime() -UFormat %s))
    $counter  = [int64]([math]::Floor($unixTime / $TimeStep))

    $counterBytes = [BitConverter]::GetBytes([System.Net.IPAddress]::HostToNetworkOrder($counter))

    $hmac = New-Object System.Security.Cryptography.HMACSHA1
    $hmac.Key = $keyBytes
    $hash = $hmac.ComputeHash($counterBytes)

    $offset = $hash[$hash.Length - 1] -band 0x0F
    $binary =
        (($hash[$offset]   -band 0x7F) -shl 24) -bor
        (($hash[$offset+1] -band 0xFF) -shl 16) -bor
        (($hash[$offset+2] -band 0xFF) -shl 8)  -bor
        (($hash[$offset+3] -band 0xFF))

    $otp = $binary % [math]::Pow(10, $Digits)
    return ([int]$otp).ToString().PadLeft($Digits, '0')
}

function Get-SecondsRemaining {
    param([int]$TimeStep = 30)
    $unixTime = [int][double]::Parse((Get-Date -Date (Get-Date).ToUniversalTime() -UFormat %s))
    return $TimeStep - ($unixTime % $TimeStep)
}

#-------------------- GUI Helpers --------------------
$Global:Accounts = Load-Accounts

$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "KDE Plasma MFA Auth"
$form.Size            = New-Object System.Drawing.Size(480, 320)
$form.StartPosition   = "CenterScreen"
$form.TopMost         = $false

$listAccounts         = New-Object System.Windows.Forms.ListBox
$listAccounts.Location= New-Object System.Drawing.Point(10, 10)
$listAccounts.Size    = New-Object System.Drawing.Size(220, 230)
$listAccounts.Anchor  = "Top,Left,Bottom"
$form.Controls.Add($listAccounts)

$lblCode              = New-Object System.Windows.Forms.Label
$lblCode.Location     = New-Object System.Drawing.Point(240, 20)
$lblCode.Size         = New-Object System.Drawing.Size(220, 40)
$lblCode.Font         = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
$lblCode.TextAlign    = "MiddleCenter"
$form.Controls.Add($lblCode)

$lblRemaining         = New-Object System.Windows.Forms.Label
$lblRemaining.Location= New-Object System.Drawing.Point(240, 70)
$lblRemaining.Size    = New-Object System.Drawing.Size(220, 20)
$lblRemaining.TextAlign = "MiddleCenter"
$form.Controls.Add($lblRemaining)

$btnCopy              = New-Object System.Windows.Forms.Button
$btnCopy.Text         = "Copy"
$btnCopy.Location     = New-Object System.Drawing.Point(240, 100)
$btnCopy.Size         = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($btnCopy)

$btnAdd               = New-Object System.Windows.Forms.Button
$btnAdd.Text          = "Add"
$btnAdd.Location      = New-Object System.Drawing.Point(10, 250)
$btnAdd.Size          = New-Object System.Drawing.Size(70, 30)
$btnAdd.Anchor        = "Left,Bottom"
$form.Controls.Add($btnAdd)

$btnEdit              = New-Object System.Windows.Forms.Button
$btnEdit.Text         = "Edit"
$btnEdit.Location     = New-Object System.Drawing.Point(90, 250)
$btnEdit.Size         = New-Object System.Drawing.Size(70, 30)
$btnEdit.Anchor       = "Left,Bottom"
$form.Controls.Add($btnEdit)

$btnDelete            = New-Object System.Windows.Forms.Button
$btnDelete.Text       = "Delete"
$btnDelete.Location   = New-Object System.Drawing.Point(170, 250)
$btnDelete.Size       = New-Object System.Drawing.Size(70, 30)
$btnDelete.Anchor     = "Left,Bottom"
$form.Controls.Add($btnDelete)

$btnClose             = New-Object System.Windows.Forms.Button
$btnClose.Text        = "Close"
$btnClose.Location    = New-Object System.Drawing.Point(360, 250)
$btnClose.Size        = New-Object System.Drawing.Size(100, 30)
$btnClose.Anchor      = "Right,Bottom"
$form.Controls.Add($btnClose)

#-------------------- Account Dialog --------------------
function Show-AccountDialog {
    param(
        [string]$Title,
        [string]$Name = "",
        [string]$Secret = ""
    )

    $dlg          = New-Object System.Windows.Forms.Form
    $dlg.Text     = $Title
    $dlg.Size     = New-Object System.Drawing.Size(360, 200)
    $dlg.StartPosition = "CenterParent"

    $lblName      = New-Object System.Windows.Forms.Label
    $lblName.Text = "Account name:"
    $lblName.Location = New-Object System.Drawing.Point(10, 20)
    $lblName.Size  = New-Object System.Drawing.Size(100, 20)
    $dlg.Controls.Add($lblName)

    $txtName      = New-Object System.Windows.Forms.TextBox
    $txtName.Location = New-Object System.Drawing.Point(120, 18)
    $txtName.Size  = New-Object System.Drawing.Size(200, 20)
    $txtName.Text  = $Name
    $dlg.Controls.Add($txtName)

    $lblSecret    = New-Object System.Windows.Forms.Label
    $lblSecret.Text = "Secret (Base32):"
    $lblSecret.Location = New-Object System.Drawing.Point(10, 60)
    $lblSecret.Size  = New-Object System.Drawing.Size(100, 20)
    $dlg.Controls.Add($lblSecret)

    $txtSecret    = New-Object System.Windows.Forms.TextBox
    $txtSecret.Location = New-Object System.Drawing.Point(120, 58)
    $txtSecret.Size  = New-Object System.Drawing.Size(200, 20)
    $txtSecret.Text  = $Secret
    $dlg.Controls.Add($txtSecret)

    $btnOk        = New-Object System.Windows.Forms.Button
    $btnOk.Text   = "OK"
    $btnOk.Location = New-Object System.Drawing.Point(160, 110)
    $btnOk.Size   = New-Object System.Drawing.Size(70, 30)
    $btnOk.Add_Click({
        if (-not $txtName.Text.Trim()) {
            [System.Windows.Forms.MessageBox]::Show("Name is required.","Error","OK","Error")
            return
        }
        if (-not $txtSecret.Text.Trim()) {
            [System.Windows.Forms.MessageBox]::Show("Secret is required.","Error","OK","Error")
            return
        }
        $dlg.Tag = @{
            Name   = $txtName.Text.Trim()
            Secret = $txtSecret.Text.Trim()
        }
        $dlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $dlg.Close()
    })
    $dlg.Controls.Add($btnOk)

    $btnCancel    = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(250, 110)
    $btnCancel.Size = New-Object System.Drawing.Size(70, 30)
    $btnCancel.Add_Click({
        $dlg.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $dlg.Close()
    })
    $dlg.Controls.Add($btnCancel)

    $result = $dlg.ShowDialog($form)
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dlg.Tag
    }
    return $null
}

#-------------------- GUI Logic --------------------
function Refresh-AccountList {
    $listAccounts.Items.Clear()
    foreach ($acc in $Global:Accounts) {
        [void]$listAccounts.Items.Add($acc.Name)
    }
}

function Get-SelectedAccount {
    if ($listAccounts.SelectedIndex -lt 0) { return $null }
    return $Global:Accounts[$listAccounts.SelectedIndex]
}

function Update-CodeDisplay {
    $acc = Get-SelectedAccount
    if (-not $acc) {
        $lblCode.Text = ""
        $lblRemaining.Text = "No account selected"
        return
    }
    try {
        $code = Get-Totp -SecretBase32 $acc.Secret -Digits $Global:Digits -TimeStep $Global:TimeStep
        $lblCode.Text = $code
    } catch {
        $lblCode.Text = "ERR"
    }
    $remaining = Get-SecondsRemaining -TimeStep $Global:TimeStep
    $lblRemaining.Text = "Valid for: $remaining s"
}

# Timer for live update
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({ Update-CodeDisplay })
$timer.Start()

# Events
$listAccounts.Add_SelectedIndexChanged({ Update-CodeDisplay })

$btnCopy.Add_Click({
    if (-not $lblCode.Text) { return }
    [System.Windows.Forms.Clipboard]::SetText($lblCode.Text)
})

$btnAdd.Add_Click({
    $res = Show-AccountDialog -Title "Add account"
    if ($res) {
        $Global:Accounts += [PSCustomObject]@{
            Name   = $res.Name
            Secret = $res.Secret
        }
        Save-Accounts -Accounts $Global:Accounts
        Refresh-AccountList
    }
})

$btnEdit.Add_Click({
    $idx = $listAccounts.SelectedIndex
    if ($idx -lt 0) { return }
    $acc = $Global:Accounts[$idx]
    $res = Show-AccountDialog -Title "Edit account" -Name $acc.Name -Secret $acc.Secret
    if ($res) {
        $Global:Accounts[$idx] = [PSCustomObject]@{
            Name   = $res.Name
            Secret = $res.Secret
        }
        Save-Accounts -Accounts $Global:Accounts
        Refresh-AccountList
        $listAccounts.SelectedIndex = [Math]::Min($idx, $listAccounts.Items.Count-1)
    }
})

$btnDelete.Add_Click({
    $idx = $listAccounts.SelectedIndex
    if ($idx -lt 0) { return }
    $acc = $Global:Accounts[$idx]
    $r = [System.Windows.Forms.MessageBox]::Show(
        "Delete account '$($acc.Name)'?",
        "Confirm",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($r -eq [System.Windows.Forms.DialogResult]::Yes) {
        $Global:Accounts = @($Global:Accounts | Where-Object { $_.Name -ne $acc.Name })
        Save-Accounts -Accounts $Global:Accounts
        Refresh-AccountList
        Update-CodeDisplay
    }
})

$btnClose.Add_Click({ $form.Close() })

# Init
Refresh-AccountList
if ($listAccounts.Items.Count -gt 0) { $listAccounts.SelectedIndex = 0 }

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)
