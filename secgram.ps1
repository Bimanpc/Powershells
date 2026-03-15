#!/usr/bin/env pwsh
<#
    Simple Telegram-like GUI client with AES-encrypted local history.
    - Uses Telegram Bot API (sendMessage/getUpdates)
    - AES is used ONLY to encrypt/decrypt local message history (JSON file)
    - Requires:
        * PowerShell 7+
        * Desktop/X environment
        * WinForms assemblies available on your system
    NOTE:
        - This is NOT a full Telegram client.
        - You must create a bot and get:
            $BotToken and $ChatId
#>

# ================== USER CONFIG ==================
$BotToken = "<PUT_YOUR_BOT_TOKEN_HERE>"
$ChatId   = "<PUT_TARGET_CHAT_ID_HERE>"  # user/group/channel id
$HistoryFile = "$HOME/.telegram_gui_history.aes"
$AesPassword = "ChangeThisToAStrongPassphrase"
# =================================================

# ---------- AES HELPERS ----------
function New-AesKeyMaterial {
    param(
        [string]$Password,
        [byte[]]$Salt = $(1..16 | ForEach-Object { Get-Random -Maximum 256 })
    )
    $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $Salt, 100000)
    $key = $derive.GetBytes(32)
    $iv  = $derive.GetBytes(16)
    [PSCustomObject]@{
        Key  = $key
        IV   = $iv
        Salt = $Salt
    }
}

function Protect-StringAes {
    param(
        [Parameter(Mandatory)][string]$PlainText,
        [Parameter(Mandatory)][string]$Password
    )

    $material = New-AesKeyMaterial -Password $Password
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $material.Key
    $aes.IV  = $material.IV

    $ms = New-Object System.IO.MemoryStream
    $cs = New-Object System.Security.Cryptography.CryptoStream(
        $ms,
        $aes.CreateEncryptor(),
        [System.Security.Cryptography.CryptoStreamMode]::Write
    )
    $sw = New-Object System.IO.StreamWriter($cs)
    $sw.Write($PlainText)
    $sw.Flush()
    $cs.FlushFinalBlock()
    $sw.Dispose()
    $cs.Dispose()
    $aes.Dispose()

    $cipherBytes = $ms.ToArray()
    $ms.Dispose()

    # prepend salt so we can derive same key later
    $all = $material.Salt + $cipherBytes
    [Convert]::ToBase64String($all)
}

function Unprotect-StringAes {
    param(
        [Parameter(Mandatory)][string]$CipherText,
        [Parameter(Mandatory)][string]$Password
    )

    try {
        $allBytes = [Convert]::FromBase64String($CipherText)
    } catch {
        return ""
    }

    if ($allBytes.Length -lt 17) { return "" }

    $salt = $allBytes[0..15]
    $cipherBytes = $allBytes[16..($allBytes.Length-1)]

    $derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, 100000)
    $key = $derive.GetBytes(32)
    $iv  = $derive.GetBytes(16)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key
    $aes.IV  = $iv

    $ms = New-Object System.IO.MemoryStream(,$cipherBytes)
    $cs = New-Object System.Security.Cryptography.CryptoStream(
        $ms,
        $aes.CreateDecryptor(),
        [System.Security.Cryptography.CryptoStreamMode]::Read
    )
    $sr = New-Object System.IO.StreamReader($cs)
    try {
        $plain = $sr.ReadToEnd()
    } catch {
        $plain = ""
    }
    $sr.Dispose()
    $cs.Dispose()
    $aes.Dispose()
    $ms.Dispose()

    $plain
}

# ---------- HISTORY HELPERS ----------
function Load-History {
    if (-not (Test-Path $HistoryFile)) {
        return @()
    }
    $cipher = Get-Content $HistoryFile -Raw
    if (-not $cipher) { return @() }
    $json = Unprotect-StringAes -CipherText $cipher -Password $AesPassword
    if (-not $json) { return @() }
    try {
        $data = $json | ConvertFrom-Json
    } catch {
        $data = @()
    }
    if ($null -eq $data) { @() } else { $data }
}

function Save-History {
    param(
        [Parameter(Mandatory)][array]$History
    )
    $json = $History | ConvertTo-Json -Depth 5
    $cipher = Protect-StringAes -PlainText $json -Password $AesPassword
    $cipher | Set-Content -Path $HistoryFile -Encoding UTF8
}

# ---------- TELEGRAM BOT API ----------
$BaseUrl = "https://api.telegram.org/bot$BotToken"

function Send-TgMessage {
    param(
        [Parameter(Mandatory)][string]$Text
    )
    $body = @{
        chat_id = $ChatId
        text    = $Text
    }
    try {
        Invoke-RestMethod -Uri "$BaseUrl/sendMessage" -Method Post -Body $body -ErrorAction Stop | Out-Null
        $true
    } catch {
        $false
    }
}

# simple polling for new messages
$Global:LastUpdateId = 0
function Get-TgUpdates {
    $params = @{
        offset = $Global:LastUpdateId + 1
        timeout = 0
    }
    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl/getUpdates" -Method Get -Body $params -ErrorAction Stop
    } catch {
        return @()
    }
    if (-not $resp.ok) { return @() }
    $updates = @()
    foreach ($u in $resp.result) {
        $Global:LastUpdateId = [Math]::Max($Global:LastUpdateId, [int]$u.update_id)
        if ($u.message -and $u.message.text) {
            $updates += [PSCustomObject]@{
                From = $u.message.from.username
                Text = $u.message.text
                Date = [DateTimeOffset]::FromUnixTimeSeconds($u.message.date).LocalDateTime
            }
        }
    }
    $updates
}

# ---------- GUI SETUP ----------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Telegram GUI (AES history)"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"

$txtChat = New-Object System.Windows.Forms.TextBox
$txtChat.Multiline = $true
$txtChat.ReadOnly = $true
$txtChat.ScrollBars = "Vertical"
$txtChat.Size = New-Object System.Drawing.Size(560, 350)
$txtChat.Location = New-Object System.Drawing.Point(10, 10)

$txtInput = New-Object System.Windows.Forms.TextBox
$txtInput.Multiline = $false
$txtInput.Size = New-Object System.Drawing.Size(460, 25)
$txtInput.Location = New-Object System.Drawing.Point(10, 370)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = "Send"
$btnSend.Size = New-Object System.Drawing.Size(80, 25)
$btnSend.Location = New-Object System.Drawing.Point(480, 370)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.AutoSize = $true
$lblStatus.Location = New-Object System.Drawing.Point(10, 410)
$lblStatus.Text = "Ready."

$form.Controls.Add($txtChat)
$form.Controls.Add($txtInput)
$form.Controls.Add($btnSend)
$form.Controls.Add($lblStatus)

# ---------- HISTORY LOAD ----------
$Global:History = Load-History
foreach ($m in $Global:History) {
    $txtChat.AppendText("[{0}] {1}: {2}`r`n" -f $m.Date, $m.From, $m.Text)
}

function Add-MessageToHistory {
    param(
        [string]$From,
        [string]$Text
    )
    $entry = [PSCustomObject]@{
        From = $From
        Text = $Text
        Date = (Get-Date)
    }
    $Global:History += $entry
    Save-History -History $Global:History
}

# ---------- SEND HANDLER ----------
$btnSend.Add_Click({
    $msg = $txtInput.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($msg)) { return }
    $lblStatus.Text = "Sending..."
    $form.Refresh()
    if (Send-TgMessage -Text $msg) {
        $txtChat.AppendText("[{0}] Me: {1}`r`n" -f (Get-Date), $msg)
        Add-MessageToHistory -From "Me" -Text $msg
        $txtInput.Text = ""
        $lblStatus.Text = "Sent."
    } else {
        $lblStatus.Text = "Failed to send."
    }
})

$txtInput.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        $e.SuppressKeyPress = $true
        $btnSend.PerformClick()
    }
})

# ---------- POLLING TIMER ----------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000  # 3 seconds
$timer.Add_Tick({
    $updates = Get-TgUpdates
    if ($updates.Count -gt 0) {
        foreach ($u in $updates) {
            $txtChat.AppendText("[{0}] {1}: {2}`r`n" -f $u.Date, $u.From, $u.Text)
            Add-MessageToHistory -From $u.From -Text $u.Text
        }
    }
})
$timer.Start()

# ---------- RUN ----------
[void]$form.ShowDialog()
