# PasswordManager.ps1 - A simple PowerShell GUI password manager with AES + HMAC encryption
# Tested on Windows PowerShell 5.1 and PowerShell 7.x on Windows.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

# ========== Configuration ==========
$VaultDir  = Join-Path $env:LOCALAPPDATA 'PwMgr'
$VaultFile = Join-Path $VaultDir 'vault.json'
$AppTitle  = 'PowerShell Password Manager'

# ========== Utility: Secure Random ==========
function New-RandomBytes {
    param([int]$Count)
    $bytes = New-Object byte[] $Count
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    return $bytes
}

# ========== Utility: Encoding ==========
$UTF8 = New-Object System.Text.UTF8Encoding($false) # no BOM

function ConvertTo-Bytes([string]$s) { $UTF8.GetBytes($s) }
function ConvertFrom-Bytes([byte[]]$b) { $UTF8.GetString($b) }

# ========== Cryptography (PBKDF2, AES-CBC, HMAC-SHA256) ==========
function Derive-Keys {
    param(
        [Parameter(Mandatory)] [string]$Password,
        [Parameter(Mandatory)] [byte[]]$Salt,
        [int]$Iterations = 200000
    )
    # Derive 64 bytes; split into two 32-byte keys (Enc and HMAC)
    $pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $Salt, $Iterations, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
    try {
        $keyMaterial = $pbkdf2.GetBytes(64)
    } finally {
        $pbkdf2.Dispose()
    }
    $encKey = $keyMaterial[0..31]
    $macKey = $keyMaterial[32..63]
    [PSCustomObject]@{
        EncKey = $encKey
        MacKey = $macKey
        Iter   = $Iterations
        Salt   = $Salt
    }
}

function Protect-Data {
    param(
        [Parameter(Mandatory)] [string]$Plaintext,
        [Parameter(Mandatory)] [byte[]]$EncKey,
        [Parameter(Mandatory)] [byte[]]$MacKey
    )
    $iv = New-RandomBytes 16
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = 'CBC'
    $aes.Padding = 'PKCS7'
    $aes.KeySize = 256
    $aes.BlockSize = 128
    $aes.Key = $EncKey
    $aes.IV = $iv

    try {
        $plainBytes = ConvertTo-Bytes $Plaintext
        $encryptor = $aes.CreateEncryptor()
        try {
            $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
        } finally {
            $encryptor.Dispose()
        }
    } finally {
        $aes.Dispose()
    }

    # HMAC over IV || ciphertext
    $mac = New-Object System.Security.Cryptography.HMACSHA256($MacKey)
    try {
        $toMac = New-Object byte[] ($iv.Length + $cipherBytes.Length)
        [Array]::Copy($iv, 0, $toMac, 0, $iv.Length)
        [Array]::Copy($cipherBytes, 0, $toMac, $iv.Length, $cipherBytes.Length)
        $tag = $mac.ComputeHash($toMac)
    } finally {
        $mac.Dispose()
    }

    [PSCustomObject]@{
        iv   = [Convert]::ToBase64String($iv)
        ct   = [Convert]::ToBase64String($cipherBytes)
        hmac = [Convert]::ToBase64String($tag)
    }
}

function Unprotect-Data {
    param(
        [Parameter(Mandatory)] [byte[]]$EncKey,
        [Parameter(Mandatory)] [byte[]]$MacKey,
        [Parameter(Mandatory)] [string]$IvB64,
        [Parameter(Mandatory)] [string]$CtB64,
        [Parameter(Mandatory)] [string]$HmacB64
    )
    $iv = [Convert]::FromBase64String($IvB64)
    $ct = [Convert]::FromBase64String($CtB64)
    $tag = [Convert]::FromBase64String($HmacB64)

    # Verify HMAC before decrypt
    $mac = New-Object System.Security.Cryptography.HMACSHA256($MacKey)
    try {
        $toMac = New-Object byte[] ($iv.Length + $ct.Length)
        [Array]::Copy($iv, 0, $toMac, 0, $iv.Length)
        [Array]::Copy($ct, 0, $toMac, $iv.Length, $ct.Length)
        $calc = $mac.ComputeHash($toMac)
    } finally {
        $mac.Dispose()
    }

    if (-not (Compare-ByteArraysConstantTime $calc $tag)) {
        throw "Integrity check failed (HMAC mismatch). Wrong password or corrupted vault."
    }

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = 'CBC'
    $aes.Padding = 'PKCS7'
    $aes.KeySize = 256
    $aes.BlockSize = 128
    $aes.Key = $EncKey
    $aes.IV = $iv

    try {
        $decryptor = $aes.CreateDecryptor()
        try {
            $plainBytes = $decryptor.TransformFinalBlock($ct, 0, $ct.Length)
        } finally {
            $decryptor.Dispose()
        }
    } finally {
        $aes.Dispose()
    }

    ConvertFrom-Bytes $plainBytes
}

function Compare-ByteArraysConstantTime {
    param([byte[]]$a, [byte[]]$b)
    if ($a.Length -ne $b.Length) { return $false }
    $diff = 0
    for ($i=0; $i -lt $a.Length; $i++) {
        $diff = $diff -bor ($a[$i] -bxor $b[$i])
    }
    return ($diff -eq 0)
}

# ========== Vault I/O ==========
function New-EmptyVaultObject {
    # Entries stored as array of PSCustomObjects
    [PSCustomObject]@{
        entries = @()
    }
}

function Save-Vault {
    param(
        [Parameter(Mandatory)] $VaultObject,
        [Parameter(Mandatory)] [string]$Password,
        [Parameter(Mandatory)] [int]$Iterations,
        [Parameter(Mandatory)] [byte[]]$Salt,
        [Parameter(Mandatory)] [string]$Path
    )
    $keys = Derive-Keys -Password $Password -Salt $Salt -Iterations $Iterations
    $jsonPlain = ($VaultObject | ConvertTo-Json -Depth 6)
    $crypto = Protect-Data -Plaintext $jsonPlain -EncKey $keys.EncKey -MacKey $keys.MacKey
    $vaultRecord = [PSCustomObject]@{
        version = 1
        kdf     = @{
            alg  = 'PBKDF2-SHA256'
            iter = $Iterations
            salt = [Convert]::ToBase64String($Salt)
        }
        crypto  = $crypto
    }
    $out = $vaultRecord | ConvertTo-Json -Depth 6
    if (-not (Test-Path (Split-Path $Path))) { New-Item -ItemType Directory -Path (Split-Path $Path) -Force | Out-Null }
    Set-Content -Path $Path -Value $out -Encoding UTF8
}

function Load-Vault {
    param(
        [Parameter(Mandatory)] [string]$Password,
        [Parameter(Mandatory)] [string]$Path
    )
    if (-not (Test-Path $Path)) { throw "Vault file not found." }
    $raw = Get-Content -Path $Path -Raw -Encoding UTF8
    $obj = $raw | ConvertFrom-Json

    $iter = [int]$obj.kdf.iter
    $salt = [Convert]::FromBase64String([string]$obj.kdf.salt)
    $keys = Derive-Keys -Password $Password -Salt $salt -Iterations $iter

    $plain = Unprotect-Data -EncKey $keys.EncKey -MacKey $keys.MacKey -IvB64 $obj.crypto.iv -CtB64 $obj.crypto.ct -HmacB64 $obj.crypto.hmac
    $vaultObject = $plain | ConvertFrom-Json
    [PSCustomObject]@{
        Vault      = $vaultObject
        Iterations = $iter
        Salt       = $salt
    }
}

# ========== Password Generation ==========
function New-RandomPassword {
    param(
        [int]$Length = 16,
        [bool]$UseLower = $true,
        [bool]$UseUpper = $true,
        [bool]$UseDigits = $true,
        [bool]$UseSymbols = $true
    )
    $sets = @()
    if ($UseLower)   { $sets += 'abcdefghijklmnopqrstuvwxyz' }
    if ($UseUpper)   { $sets += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' }
    if ($UseDigits)  { $sets += '0123456789' }
    if ($UseSymbols) { $sets += '!@#$%^&*()-_=+[]{};:,.<>/?' }

    if ($sets.Count -eq 0) { throw "Select at least one character set." }

    $all = ($sets -join '')
    $bytes = New-RandomBytes ($Length)
    $chars = New-Object char[] $Length
    for ($i=0; $i -lt $Length; $i++) {
        $idx = $bytes[$i] % $all.Length
        $chars[$i] = $all[$idx]
    }

    # Ensure at least one from each selected set
    $pos = 0
    foreach ($set in $sets) {
        $chars[$pos] = $set[(New-RandomBytes 1)[0] % $set.Length]
        $pos++
        if ($pos -ge $Length) { break }
    }

    -join $chars
}

# ========== Clipboard handling with auto-clear ==========
$ClipboardTimer = New-Object System.Windows.Forms.Timer
$ClipboardTimer.Interval = 15000 # 15 seconds
$ClipboardTimer.Add_Tick({
    try {
        [System.Windows.Forms.Clipboard]::Clear()
    } catch {}
    $ClipboardTimer.Stop()
})

function Copy-ToClipboardAutoClear([string]$text) {
    try {
        [System.Windows.Forms.Clipboard]::SetText($text)
        $ClipboardTimer.Stop()
        $ClipboardTimer.Start()
        [System.Windows.Forms.MessageBox]::Show("Password copied. It will be cleared from the clipboard in 15 seconds.", $AppTitle, 'OK', 'Information') | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to access clipboard: $($_.Exception.Message)", $AppTitle, 'OK', 'Error') | Out-Null
    }
}

# ========== Data Model and Binding ==========
$DataTable = New-Object System.Data.DataTable 'Entries'
$cols = @(
    @{Name='Id'; Type=[string]},
    @{Name='Name'; Type=[string]},
    @{Name='Username'; Type=[string]},
    @{Name='Password'; Type=[string]},
    @{Name='URL'; Type=[string]},
    @{Name='Notes'; Type=[string]},
    @{Name='UpdatedAt'; Type=[datetime]}
)
foreach ($c in $cols) { $null = $DataTable.Columns.Add($c.Name, $c.Type) }

function VaultToTable($vault) {
    $DataTable.Rows.Clear()
    foreach ($e in $vault.entries) {
        $row = $DataTable.NewRow()
        $row['Id']        = $e.id
        $row['Name']      = $e.name
        $row['Username']  = $e.username
        $row['Password']  = $e.password
        $row['URL']       = $e.url
        $row['Notes']     = $e.notes
        $row['UpdatedAt'] = Get-Date ($e.updatedAt)
        $DataTable.Rows.Add($row) | Out-Null
    }
}

function TableToVault() {
    $entries = foreach ($row in $DataTable.Rows) {
        [PSCustomObject]@{
            id        = $row['Id']
            name      = $row['Name']
            username  = $row['Username']
            password  = $row['Password']
            url       = $row['URL']
            notes     = $row['Notes']
            updatedAt = ($row['UpdatedAt']).ToString('o')
        }
    }
    [PSCustomObject]@{ entries = @($entries) }
}

# ========== Simple Dialogs ==========
function Prompt-ChooseVaultPath {
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Title = 'Create or select a vault file'
    $dlg.Filter = 'Vault (*.json)|*.json'
    $dlg.OverwritePrompt = $false
    $dlg.InitialDirectory = (Split-Path $VaultFile)
    $dlg.FileName = (Split-Path $VaultFile -Leaf)
    if ($dlg.ShowDialog() -eq 'OK') { return $dlg.FileName } else { return $null }
}

function Prompt-Password([string]$title, [bool]$confirm=$false) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Width = 400
    $form.Height = if ($confirm) { 240 } else { 180 }
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = if ($confirm) { 'Enter master password (and confirm):' } else { 'Enter master password:' }
    $lbl.AutoSize = $true
    $lbl.Top = 15; $lbl.Left = 15

    $pwd = New-Object System.Windows.Forms.MaskedTextBox
    $pwd.UseSystemPasswordChar = $true
    $pwd.Width = 340; $pwd.Left = 15; $pwd.Top = 45

    $pwd2 = $null
    if ($confirm) {
        $pwd2 = New-Object System.Windows.Forms.MaskedTextBox
        $pwd2.UseSystemPasswordChar = $true
        $pwd2.Width = 340; $pwd2.Left = 15; $pwd2.Top = 90
    }

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = 'OK'; $ok.Width = 90; $ok.Left = 185; $ok.Top = if ($confirm) { 130 } else { 85 }
    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = 'Cancel'; $cancel.Width = 90; $cancel.Left = 285; $cancel.Top = $ok.Top

    $ok.Add_Click({
        if ($confirm -and ($pwd.Text -ne $pwd2.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Passwords don't match.", $AppTitle, 'OK', 'Warning') | Out-Null
            return
        }
        $form.Tag = $pwd.Text
        $form.DialogResult = 'OK'
        $form.Close()
    })
    $cancel.Add_Click({ $form.DialogResult = 'Cancel'; $form.Close() })

    $form.Controls.AddRange(@($lbl, $pwd, $ok, $cancel))
    if ($confirm) { $form.Controls.Add($pwd2) }

    if ($form.ShowDialog() -eq 'OK') { return $form.Tag } else { return $null }
}

# ========== Main Form ==========
$form = New-Object System.Windows.Forms.Form
$form.Text = $AppTitle
$form.Width = 980
$form.Height = 620
$form.StartPosition = 'CenterScreen'

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = 'Search:'
$lblSearch.AutoSize = $true
$lblSearch.Left = 10; $lblSearch.Top = 12

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Left = 70; $txtSearch.Top = 8; $txtSearch.Width = 380

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Left = 10; $grid.Top = 40; $grid.Width = 600; $grid.Height = 530
$grid.ReadOnly = $true
$grid.SelectionMode = 'FullRowSelect'
$grid.MultiSelect = $false
$grid.AutoSizeColumnsMode = 'Fill'
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false

# Right panel
$panel = New-Object System.Windows.Forms.Panel
$panel.Left = 620; $panel.Top = 10; $panel.Width = 340; $panel.Height = 560
$panel.BorderStyle = 'None'

function New-Label($text, $top) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text; $l.AutoSize = $true; $l.Left = 5; $l.Top = $top
    $l
}

function New-TextBox($top, [bool]$multiline=$false, [bool]$password=$false) {
    if ($password) {
        $tb = New-Object System.Windows.Forms.MaskedTextBox
        $tb.UseSystemPasswordChar = $true
    } else {
        $tb = New-Object System.Windows.Forms.TextBox
    }
    $tb.Left = 5; $tb.Top = $top; $tb.Width = 320
    if ($multiline) { $tb.Height = 100; $tb.Multiline = $true; $tb.ScrollBars = 'Vertical' }
    $tb
}

$lblName = New-Label 'Name' 10
$txtName = New-TextBox 30

$lblUser = New-Label 'Username' 65
$txtUser = New-TextBox 85

$lblPass = New-Label 'Password' 120
$txtPass = New-TextBox 140 $false $true

$chkShow = New-Object System.Windows.Forms.CheckBox
$chkShow.Left = 5; $chkShow.Top = 170; $chkShow.Text = 'Show password'; $chkShow.AutoSize = $true
$chkShow.Add_CheckedChanged({
    if ($txtPass -is [System.Windows.Forms.MaskedTextBox]) {
        $txtPass.UseSystemPasswordChar = -not $chkShow.Checked
    }
})

$lblUrl = New-Label 'URL' 195
$txtUrl = New-TextBox 215

$lblNotes = New-Label 'Notes' 250
$txtNotes = New-TextBox 270 $true

$btnNew = New-Object System.Windows.Forms.Button
$btnNew.Text = 'New'; $btnNew.Left = 5; $btnNew.Top = 380; $btnNew.Width = 70

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = 'Save'; $btnSave.Left = 80; $btnSave.Top = 380; $btnSave.Width = 70

$btnDelete = New-Object System.Windows.Forms.Button
$btnDelete.Text = 'Delete'; $btnDelete.Left = 155; $btnDelete.Top = 380; $btnDelete.Width = 70

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = 'Copy Password'; $btnCopy.Left = 230; $btnCopy.Top = 380; $btnCopy.Width = 95

$grpGen = New-Object System.Windows.Forms.GroupBox
$grpGen.Text = 'Generator'; $grpGen.Left = 5; $grpGen.Top = 415; $grpGen.Width = 320; $grpGen.Height = 120

$lblLen = New-Object System.Windows.Forms.Label
$lblLen.Text = 'Length:'; $lblLen.Left = 10; $lblLen.Top = 25; $lblLen.AutoSize = $true

$numLen = New-Object System.Windows.Forms.NumericUpDown
$numLen.Left = 65; $numLen.Top = 22; $numLen.Width = 60; $numLen.Minimum = 8; $numLen.Maximum = 128; $numLen.Value = 16

$chkLower = New-Object System.Windows.Forms.CheckBox
$chkLower.Text = 'a-z'; $chkLower.Left = 140; $chkLower.Top = 22; $chkLower.Checked = $true; $chkLower.AutoSize = $true
$chkUpper = New-Object System.Windows.Forms.CheckBox
$chkUpper.Text = 'A-Z'; $chkUpper.Left = 190; $chkUpper.Top = 22; $chkUpper.Checked = $true; $chkUpper.AutoSize = $true
$chkDigits = New-Object System.Windows.Forms.CheckBox
$chkDigits.Text = '0-9'; $chkDigits.Left = 240; $chkDigits.Top = 22; $chkDigits.Checked = $true; $chkDigits.AutoSize = $true
$chkSymbols = New-Object System.Windows.Forms.CheckBox
$chkSymbols.Text = 'Symbols'; $chkSymbols.Left = 10; $chkSymbols.Top = 50; $chkSymbols.Checked = $true; $chkSymbols.AutoSize = $true

$btnGen = New-Object System.Windows.Forms.Button
$btnGen.Text = 'Generate'; $btnGen.Left = 200; $btnGen.Top = 70; $btnGen.Width = 100

$grpGen.Controls.AddRange(@($lblLen, $numLen, $chkLower, $chkUpper, $chkDigits, $chkSymbols, $btnGen))

$panel.Controls.AddRange(@(
    $lblName,$txtName,
    $lblUser,$txtUser,
    $lblPass,$txtPass,$chkShow,
    $lblUrl,$txtUrl,
    $lblNotes,$txtNotes,
    $btnNew,$btnSave,$btnDelete,$btnCopy,
    $grpGen
))

$form.Controls.AddRange(@($lblSearch,$txtSearch,$grid,$panel))

# ========== State ==========
$global:MasterPassword = $null
$global:KdfSalt = $null
$global:KdfIter = 200000
$global:VaultPath = $VaultFile

# ========== Helpers ==========
function Grid-Bind() {
    $grid.DataSource = $DataTable
    foreach ($col in @('Password','Id','Notes')) {
        if ($grid.Columns.Contains($col)) { $grid.Columns[$col].Visible = $false }
    }
}

function Clear-Details() {
    $txtName.Text=''; $txtUser.Text=''; $txtPass.Text=''; $txtUrl.Text=''; $txtNotes.Text=''
}

function Load-DetailsFromRow($row) {
    if (-not $row) { return }
    $txtName.Text = [string]$row.Cells['Name'].Value
    $txtUser.Text = [string]$row.Cells['Username'].Value
    $txtPass.Text = [string]$row.Cells['Password'].Value
    $txtUrl.Text  = [string]$row.Cells['URL'].Value
    $txtNotes.Text= [string]$row.Cells['Notes'].Value
}

function Save-DetailsToTable() {
    $now = Get-Date
    if ($grid.SelectedRows.Count -eq 1) {
        # Update existing
        $row = $grid.SelectedRows[0]
        $row.Cells['Name'].Value = $txtName.Text
        $row.Cells['Username'].Value = $txtUser.Text
        $row.Cells['Password'].Value = $txtPass.Text
        $row.Cells['URL'].Value = $txtUrl.Text
        $row.Cells['Notes'].Value = $txtNotes.Text
        $row.Cells['UpdatedAt'].Value = $now
    } else {
        # New
        $r = $DataTable.NewRow()
        $r['Id'] = [guid]::NewGuid().ToString()
        $r['Name'] = $txtName.Text
        $r['Username'] = $txtUser.Text
        $r['Password'] = $txtPass.Text
        $r['URL'] = $txtUrl.Text
        $r['Notes'] = $txtNotes.Text
        $r['UpdatedAt'] = $now
        $DataTable.Rows.Add($r) | Out-Null
    }
}

function Save-All() {
    $vault = TableToVault
    Save-Vault -VaultObject $vault -Password $global:MasterPassword -Iterations $global:KdfIter -Salt $global:KdfSalt -Path $global:VaultPath
}

function Try-UnlockExistingVault() {
    $pwd = Prompt-Password -title 'Unlock Vault'
    if (-not $pwd) { return $false }
    try {
        $res = Load-Vault -Password $pwd -Path $global:VaultPath
        $global:MasterPassword = $pwd
        $global:KdfSalt = $res.Salt
        $global:KdfIter = $res.Iterations
        VaultToTable $res.Vault
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to unlock: $($_.Exception.Message)", $AppTitle, 'OK', 'Error') | Out-Null
        return $false
    }
}

function Create-NewVault() {
    $path = Prompt-ChooseVaultPath
    if (-not $path) { return $false }
    $pwd = Prompt-Password -title 'Create Master Password' -confirm $true
    if (-not $pwd) { return $false }
    $global:VaultPath = $path
    $global:MasterPassword = $pwd
    $global:KdfSalt = New-RandomBytes 16
    $global:KdfIter = 200000
    $empty = New-EmptyVaultObject
    Save-Vault -VaultObject $empty -Password $pwd -Iterations $global:KdfIter -Salt $global:KdfSalt -Path $global:VaultPath
    VaultToTable $empty
    return $true
}

function Ensure-VaultOpened() {
    if (Test-Path $global:VaultPath) {
        while (-not (Try-UnlockExistingVault())) {
            $retry = [System.Windows.Forms.MessageBox]::Show("Try again?", $AppTitle, 'YesNo', 'Question')
            if ($retry -ne 'Yes') { return $false }
        }
        return $true
    } else {
        return (Create-NewVault)
    }
}

# ========== Events ==========
$grid.Add_SelectionChanged({
    if ($grid.SelectedRows.Count -eq 1) { Load-DetailsFromRow $grid.SelectedRows[0] }
})

$btnNew.Add_Click({ $grid.ClearSelection(); Clear-Details() })

$btnSave.Add_Click({
    Save-DetailsToTable
    Save-All
    [System.Windows.Forms.MessageBox]::Show("Entry saved.", $AppTitle, 'OK', 'Information') | Out-Null
})

$btnDelete.Add_Click({
    if ($grid.SelectedRows.Count -ne 1) { return }
    $ans = [System.Windows.Forms.MessageBox]::Show("Delete selected entry?", $AppTitle, 'YesNo', 'Warning')
    if ($ans -eq 'Yes') {
        $row = $grid.SelectedRows[0]
        $DataTable.Rows.RemoveAt($row.Index)
        Save-All
        Clear-Details()
    }
})

$btnCopy.Add_Click({
    if ($grid.SelectedRows.Count -ne 1) { return }
    $pwd = [string]$grid.SelectedRows[0].Cells['Password'].Value
    if ([string]::IsNullOrEmpty($pwd)) { return }
    Copy-ToClipboardAutoClear $pwd
})

$btnGen.Add_Click({
    try {
        $pw = New-RandomPassword -Length ([int]$numLen.Value) -UseLower $chkLower.Checked -UseUpper $chkUpper.Checked -UseDigits $chkDigits.Checked -UseSymbols $chkSymbols.Checked
        $txtPass.Text = $pw
    } catch {
        [System.Windows.Forms.MessageBox]::Show($($_.Exception.Message), $AppTitle, 'OK', 'Warning') | Out-Null
    }
})

$txtSearch.Add_TextChanged({
    $dv = New-Object System.Data.DataView($DataTable)
    # Escape single quotes for RowFilter
    $q = $txtSearch.Text.Replace("'", "''")
    if ([string]::IsNullOrWhiteSpace($q)) {
        $dv.RowFilter = ''
    } else {
        $dv.RowFilter = "Name LIKE '%$q%' OR Username LIKE '%$q%' OR URL LIKE '%$q%' OR Notes LIKE '%$q%'"
    }
    $grid.DataSource = $dv
    foreach ($col in @('Password','Id','Notes')) {
        if ($grid.Columns.Contains($col)) { $grid.Columns[$col].Visible = $false }
    }
})

$form.Add_FormClosing({
    # Best-effort clear clipboard on exit
    try { [System.Windows.Forms.Clipboard]::Clear() } catch {}
})

# ========== Start ==========
Grid-Bind
if (-not (Ensure-VaultOpened)) { return }
$form.ShowDialog() | Out-Null
