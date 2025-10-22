<# 
MFA-OTP-AI.ps1
- Windows Forms GUI for TOTP/HOTP MFA codes
- Encrypted secrets store (DPAPI user scope)
- Optional AI assistant: generic LLM endpoint call with API key
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

# ------------------------------
# Config & paths
# ------------------------------
$AppName        = "MFA OTP + AI"
$StoreDir       = Join-Path $env:LOCALAPPDATA "MFA-OTP-AI"
$StoreFile      = Join-Path $StoreDir "accounts.json.enc"
$BackupFile     = Join-Path $StoreDir "accounts.backup.enc"
$LogFile        = Join-Path $StoreDir "app.log"
$DefaultPeriod  = 30         # seconds for TOTP
$DefaultDigits  = 6
$DefaultAlgo    = "SHA1"     # SHA1|SHA256|SHA512
$DefaultType    = "TOTP"     # TOTP|HOTP
$DefaultStep    = 0          # HOTP counter
$DefaultSkew    = 1          # allowed adjacent windows for verify (±1)
$AIEndpoint     = $env:AI_ENDPOINT # e.g., https://api.your-llm.com/v1/chat
$AIKey          = $env:AI_API_KEY
$AIModel        = $env:AI_MODEL     # optional, depends on endpoint
[System.IO.Directory]::CreateDirectory($StoreDir) | Out-Null

# ------------------------------
# Logging helper
# ------------------------------
function Write-Log {
    param([string]$msg)
    $line = "{0} | {1}" -f ([DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")), $msg
    Add-Content -Path $LogFile -Value $line
}

# ------------------------------
# Crypto helpers (DPAPI user scope)
# ------------------------------
function Protect-Bytes {
    param([byte[]]$bytes)
    try {
        return [System.Security.Cryptography.ProtectedData]::Protect($bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    } catch {
        Write-Log "Protect-Bytes error: $($_.Exception.Message)"
        throw
    }
}
function Unprotect-Bytes {
    param([byte[]]$bytes)
    try {
        return [System.Security.Cryptography.ProtectedData]::Unprotect($bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    } catch {
        Write-Log "Unprotect-Bytes error: $($_.Exception.Message)"
        throw
    }
}

# ------------------------------
# Base32 decode (RFC 4648)
# ------------------------------
function Decode-Base32 {
    param([string]$base32)
    $alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    $clean = ($base32.ToUpper() -replace "[^A-Z2-7]","").TrimEnd("=")
    $bits = New-Object System.Collections.Generic.List[bool]
    foreach ($c in $clean.ToCharArray()) {
        $val = $alphabet.IndexOf($c)
        if ($val -lt 0) { continue }
        for ($i=4; $i -ge 0; $i--) {
            $bits.Add([bool](($val -band (1 -shl $i)) -ne 0))
        }
    }
    $bytes = New-Object System.Collections.Generic.List[byte]
    for ($i=0; $i -le $bits.Count-8; $i+=8) {
        $b = 0
        for ($j=0; $j -lt 8; $j++) {
            if ($bits[$i+$j]) { $b = $b -bor (1 -shl (7-$j)) }
        }
        $bytes.Add([byte]$b)
    }
    return $bytes.ToArray()
}

# ------------------------------
# HMAC digest selection
# ------------------------------
function Get-HMAC {
    param(
        [string]$algo,
        [byte[]]$key,
        [byte[]]$msg
    )
    switch ($algo.ToUpper()) {
        "SHA1"   { $h = New-Object System.Security.Cryptography.HMACSHA1($key) }
        "SHA256" { $h = New-Object System.Security.Cryptography.HMACSHA256($key) }
        "SHA512" { $h = New-Object System.Security.Cryptography.HMACSHA512($key) }
        default  { throw "Unsupported algo: $algo" }
    }
    try {
        return $h.ComputeHash($msg)
    } finally {
        $h.Dispose()
    }
}

# ------------------------------
# OTP core (RFC 4226 / 6238)
# ------------------------------
function Get-HOTP {
    param(
        [byte[]]$key,
        [UInt64]$counter,
        [int]$digits = $DefaultDigits,
        [string]$algo = $DefaultAlgo
    )
    $msg = [BitConverter]::GetBytes([UInt64]([System.Net.IPAddress]::HostToNetworkOrder([Int64]$counter)))
    $hash = Get-HMAC -algo $algo -key $key -msg $msg
    $offset = $hash[$hash.Length-1] -band 0x0F
    $code = (($hash[$offset] -band 0x7F) -shl 24) -bor ($hash[$offset+1] -shl 16) -bor ($hash[$offset+2] -shl 8) -bor $hash[$offset+3]
    $hotp = $code % ([math]::Pow(10, $digits))
    return $hotp.ToString("D$digits")
}

function Get-TOTP {
    param(
        [byte[]]$key,
        [int]$period = $DefaultPeriod,
        [int]$digits = $DefaultDigits,
        [string]$algo = $DefaultAlgo,
        [DateTime]$time = [DateTime]::UtcNow
    )
    $t = [UInt64]([math]::Floor((New-TimeSpan -Start (Get-Date "1970-01-01Z") -End $time).TotalSeconds / $period))
    return Get-HOTP -key $key -counter $t -digits $digits -algo $algo
}

function Verify-TOTP {
    param(
        [byte[]]$key,
        [string]$code,
        [int]$period = $DefaultPeriod,
        [int]$digits = $DefaultDigits,
        [string]$algo = $DefaultAlgo,
        [int]$skew = $DefaultSkew
    )
    $now = [DateTime]::UtcNow
    for ($w = -$skew; $w -le $skew; $w++) {
        $time = $now.AddSeconds($w * $period)
        if ((Get-TOTP -key $key -period $period -digits $digits -algo $algo -time $time) -eq $code) { return $true }
    }
    return $false
}

# ------------------------------
# Storage (accounts)
# ------------------------------
function Load-Accounts {
    if (-not (Test-Path $StoreFile)) { return @() }
    $enc = [IO.File]::ReadAllBytes($StoreFile)
    $jsonBytes = Unprotect-Bytes $enc
    $json = [Text.Encoding]::UTF8.GetString($jsonBytes)
    $list = ConvertFrom-Json -InputObject $json
    if ($list -eq $null) { return @() }
    return @($list)
}

function Save-Accounts {
    param([array]$accounts)
    $json = ($accounts | ConvertTo-Json -Depth 6)
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $enc = Protect-Bytes $bytes
    [IO.File]::WriteAllBytes($StoreFile, $enc)
    # lightweight backup
    Copy-Item -Path $StoreFile -Destination $BackupFile -Force
}

# ------------------------------
# Minimal AI call (configurable)
# ------------------------------
function Ask-AI {
    param(
        [string]$question
    )
    if ([string]::IsNullOrWhiteSpace($AIEndpoint) -or [string]::IsNullOrWhiteSpace($AIKey)) {
        return "AI endpoint or API key not configured. Set AI_ENDPOINT and AI_API_KEY environment variables."
    }
    try {
        $headers = @{ "Authorization" = "Bearer $AIKey"; "Content-Type" = "application/json" }
        $body = @{
            model = ($AIModel ?? "default")
            messages = @(
                @{ role="system"; content="You are an assistant helping with MFA, OTP, and authentication troubleshooting." },
                @{ role="user";   content=$question }
            )
        } | ConvertTo-Json -Depth 6
        $resp = Invoke-RestMethod -Method Post -Uri $AIEndpoint -Headers $headers -Body $body -TimeoutSec 30
        # Try common response shapes (OpenAI-like or generic)
        if ($resp.choices && $resp.choices[0].message.content) { return $resp.choices[0].message.content }
        elseif ($resp.reply) { return $resp.reply }
        elseif ($resp.output) { return $resp.output }
        else { return ($resp | ConvertTo-Json -Depth 8) }
    } catch {
        Write-Log "AI error: $($_.Exception.Message)"
        return "AI error: $($_.Exception.Message)"
    }
}

# ------------------------------
# GUI
# ------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = $AppName
$form.Size = New-Object System.Drawing.Size(900, 600)
$form.StartPosition = "CenterScreen"

# Split container: Left (Accounts/OTP), Right (AI)
$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = "Fill"
$split.Orientation = "Vertical"
$split.SplitterDistance = 520
$form.Controls.Add($split)

# -------- Left panel controls --------
$panelL = $split.Panel1

$lblAccounts = New-Object System.Windows.Forms.Label
$lblAccounts.Text = "Accounts"
$lblAccounts.Location = New-Object System.Drawing.Point(10,10)
$lblAccounts.AutoSize = $true
$panelL.Controls.Add($lblAccounts)

$listAccounts = New-Object System.Windows.Forms.ListBox
$listAccounts.Location = New-Object System.Drawing.Point(10,30)
$listAccounts.Size = New-Object System.Drawing.Size(250, 400)
$panelL.Controls.Add($listAccounts)

$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = "Add/Update"
$btnAdd.Location = New-Object System.Drawing.Point(10,440)
$btnAdd.Size = New-Object System.Drawing.Size(120,30)
$panelL.Controls.Add($btnAdd)

$btnDelete = New-Object System.Windows.Forms.Button
$btnDelete.Text = "Delete"
$btnDelete.Location = New-Object System.Drawing.Point(140,440)
$btnDelete.Size = New-Object System.Drawing.Size(120,30)
$panelL.Controls.Add($btnDelete)

$grpDetails = New-Object System.Windows.Forms.GroupBox
$grpDetails.Text = "Details"
$grpDetails.Location = New-Object System.Drawing.Point(270,10)
$grpDetails.Size = New-Object System.Drawing.Size(230, 270)
$panelL.Controls.Add($grpDetails)

function NewLabel([string]$text,[int]$x,[int]$y){ $l=New-Object System.Windows.Forms.Label; $l.Text=$text; $l.Location=New-Object System.Drawing.Point($x,$y); $l.AutoSize=$true; return $l }
function NewText([int]$x,[int]$y,[int]$w){ $t=New-Object System.Windows.Forms.TextBox; $t.Location=New-Object System.Drawing.Point($x,$y); $t.Size=New-Object System.Drawing.Size($w,22); return $t }

$grpDetails.Controls.Add((NewLabel "Issuer:" 10 25))
$txtIssuer = NewText 80 22 130; $grpDetails.Controls.Add($txtIssuer)

$grpDetails.Controls.Add((NewLabel "Account:" 10 55))
$txtAccount = NewText 80 52 130; $grpDetails.Controls.Add($txtAccount)

$grpDetails.Controls.Add((NewLabel "Secret (Base32):" 10 85))
$txtSecret = NewText 10 105 200; $grpDetails.Controls.Add($txtSecret)

$grpDetails.Controls.Add((NewLabel "Type:" 10 135))
$cmbType = New-Object System.Windows.Forms.ComboBox
$cmbType.Items.AddRange(@("TOTP","HOTP"))
$cmbType.SelectedItem = $DefaultType
$cmbType.DropDownStyle = "DropDownList"
$cmbType.Location = New-Object System.Drawing.Point(80,132)
$cmbType.Size = New-Object System.Drawing.Size(130,22)
$grpDetails.Controls.Add($cmbType)

$grpDetails.Controls.Add((NewLabel "Algo:" 10 165))
$cmbAlgo = New-Object System.Windows.Forms.ComboBox
$cmbAlgo.Items.AddRange(@("SHA1","SHA256","SHA512"))
$cmbAlgo.SelectedItem = $DefaultAlgo
$cmbAlgo.DropDownStyle = "DropDownList"
$cmbAlgo.Location = New-Object System.Drawing.Point(80,162)
$cmbAlgo.Size = New-Object System.Drawing.Size(130,22)
$grpDetails.Controls.Add($cmbAlgo)

$grpDetails.Controls.Add((NewLabel "Digits:" 10 195))
$numDigits = New-Object System.Windows.Forms.NumericUpDown
$numDigits.Minimum = 6; $numDigits.Maximum = 8; $numDigits.Value = $DefaultDigits
$numDigits.Location = New-Object System.Drawing.Point(80,192)
$numDigits.Size = New-Object System.Drawing.Size(60,22)
$grpDetails.Controls.Add($numDigits)

$grpDetails.Controls.Add((NewLabel "Period:" 10 225))
$numPeriod = New-Object System.Windows.Forms.NumericUpDown
$numPeriod.Minimum = 15; $numPeriod.Maximum = 60; $numPeriod.Value = $DefaultPeriod
$numPeriod.Location = New-Object System.Drawing.Point(80,222)
$numPeriod.Size = New-Object System.Drawing.Size(60,22)
$grpDetails.Controls.Add($numPeriod)

$grpHotp = New-Object System.Windows.Forms.GroupBox
$grpHotp.Text = "HOTP counter"
$grpHotp.Location = New-Object System.Drawing.Point(270,290)
$grpHotp.Size = New-Object System.Drawing.Size(230, 70)
$panelL.Controls.Add($grpHotp)

$grpHotp.Controls.Add((NewLabel "Step:" 10 30))
$numStep = New-Object System.Windows.Forms.NumericUpDown
$numStep.Minimum = 0; $numStep.Maximum = 2147483647; $numStep.Value = $DefaultStep
$numStep.Location = New-Object System.Drawing.Point(60,27)
$numStep.Size = New-Object System.Drawing.Size(100,22)
$grpHotp.Controls.Add($numStep)

$grpOTP = New-Object System.Windows.Forms.GroupBox
$grpOTP.Text = "OTP"
$grpOTP.Location = New-Object System.Drawing.Point(270,370)
$grpOTP.Size = New-Object System.Drawing.Size(230, 100)
$panelL.Controls.Add($grpOTP)

$lblCode = New-Object System.Windows.Forms.Label
$lblCode.Font = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
$lblCode.Text = "------"
$lblCode.Location = New-Object System.Drawing.Point(10,25)
$lblCode.AutoSize = $true
$grpOTP.Controls.Add($lblCode)

$lblCountdown = New-Object System.Windows.Forms.Label
$lblCountdown.Text = "Next in: --s"
$lblCountdown.Location = New-Object System.Drawing.Point(10,60)
$lblCountdown.AutoSize = $true
$grpOTP.Controls.Add($lblCountdown)

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = "Copy"
$btnCopy.Location = New-Object System.Drawing.Point(150,25)
$btnCopy.Size = New-Object System.Drawing.Size(60,28)
$grpOTP.Controls.Add($btnCopy)

$grpVerify = New-Object System.Windows.Forms.GroupBox
$grpVerify.Text = "Verify code"
$grpVerify.Location = New-Object System.Drawing.Point(270,480)
$grpVerify.Size = New-Object System.Drawing.Size(230, 80)
$panelL.Controls.Add($grpVerify)

$grpVerify.Controls.Add((NewLabel "Code:" 10 30))
$txtVerify = NewText 60 27 100; $grpVerify.Controls.Add($txtVerify)

$btnVerify = New-Object System.Windows.Forms.Button
$btnVerify.Text = "Check"
$btnVerify.Location = New-Object System.Drawing.Point(165,25)
$btnVerify.Size = New-Object System.Drawing.Size(55,28)
$grpVerify.Controls.Add($btnVerify)

# -------- Right panel (AI assistant) --------
$panelR = $split.Panel2

$lblAI = New-Object System.Windows.Forms.Label
$lblAI.Text = "AI assistant (optional)"
$lblAI.Location = New-Object System.Drawing.Point(10,10)
$lblAI.AutoSize = $true
$panelR.Controls.Add($lblAI)

$txtAIQuestion = New-Object System.Windows.Forms.TextBox
$txtAIQuestion.Multiline = $true
$txtAIQuestion.ScrollBars = "Vertical"
$txtAIQuestion.Location = New-Object System.Drawing.Point(10,30)
$txtAIQuestion.Size = New-Object System.Drawing.Size(330, 200)
$panelR.Controls.Add($txtAIQuestion)

$btnAskAI = New-Object System.Windows.Forms.Button
$btnAskAI.Text = "Ask"
$btnAskAI.Location = New-Object System.Drawing.Point(10,235)
$btnAskAI.Size = New-Object System.Drawing.Size(70,28)
$panelR.Controls.Add($btnAskAI)

$txtAIAnswer = New-Object System.Windows.Forms.TextBox
$txtAIAnswer.Multiline = $true
$txtAIAnswer.ScrollBars = "Vertical"
$txtAIAnswer.ReadOnly = $true
$txtAIAnswer.Location = New-Object System.Drawing.Point(10,270)
$txtAIAnswer.Size = New-Object System.Drawing.Size(330, 290)
$panelR.Controls.Add($txtAIAnswer)

# ------------------------------
# State & helpers
# ------------------------------
$accounts = Load-Accounts
$listAccounts.Items.Clear()
$accounts | ForEach-Object { $listAccounts.Items.Add("{0} | {1}" -f $_.Issuer, $_.Account) }

function CurrentAccount {
    if ($listAccounts.SelectedIndex -lt 0) { return $null }
    return $accounts[$listAccounts.SelectedIndex]
}

function RefreshCode {
    $acc = CurrentAccount
    if ($null -eq $acc) { 
        $lblCode.Text = "------"
        $lblCountdown.Text = "Next in: --s"
        return
    }
    try {
        $key = Decode-Base32 $acc.Secret
        if ($acc.Type -eq "TOTP") {
            $code = Get-TOTP -key $key -period [int]$acc.Period -digits [int]$acc.Digits -algo $acc.Algo
            $lblCode.Text = $code
            # countdown
            $epoch = [DateTime]::UtcNow
            $remain = $acc.Period - ([int][math]::Floor((New-TimeSpan -Start (Get-Date "1970-01-01Z") -End $epoch).TotalSeconds) % $acc.Period)
            $lblCountdown.Text = "Next in: {0}s" -f $remain
        } else {
            $code = Get-HOTP -key $key -counter [UInt64]$acc.Step -digits [int]$acc.Digits -algo $acc.Algo
            $lblCode.Text = $code
            $lblCountdown.Text = "HOTP step: {0}" -f $acc.Step
        }
    } catch {
        $lblCode.Text = "error"
        $lblCountdown.Text = $_.Exception.Message
        Write-Log "RefreshCode error: $($_.Exception.Message)"
    }
}

# timer for TOTP refresh
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({ 
    $acc = CurrentAccount
    if ($null -ne $acc -and $acc.Type -eq "TOTP") { RefreshCode }
})

# ------------------------------
# Events
# ------------------------------
$listAccounts.Add_SelectedIndexChanged({
    $acc = CurrentAccount
    if ($null -eq $acc) { return }
    $txtIssuer.Text  = $acc.Issuer
    $txtAccount.Text = $acc.Account
    $txtSecret.Text  = $acc.Secret
    $cmbType.SelectedItem = $acc.Type
    $cmbAlgo.SelectedItem = $acc.Algo
    $numDigits.Value = [decimal]$acc.Digits
    $numPeriod.Value = [decimal]$acc.Period
    $numStep.Value   = [decimal]$acc.Step
    RefreshCode
})

$btnAdd.Add_Click({
    $issuer  = $txtIssuer.Text.Trim()
    $account = $txtAccount.Text.Trim()
    $secret  = $txtSecret.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($issuer) -or [string]::IsNullOrWhiteSpace($account) -or [string]::IsNullOrWhiteSpace($secret)) {
        [System.Windows.Forms.MessageBox]::Show("Issuer, Account, and Secret are required.","Validation",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    # validate secret by attempting decode
    try { [void](Decode-Base32 $secret) } catch {
        [System.Windows.Forms.MessageBox]::Show("Invalid Base32 secret: $($_.Exception.Message)","Secret error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }
    $type   = $cmbType.SelectedItem
    $algo   = $cmbAlgo.SelectedItem
    $digits = [int]$numDigits.Value
    $period = [int]$numPeriod.Value
    $step   = [int]$numStep.Value

    $existing = $accounts | Where-Object { $_.Issuer -eq $issuer -and $_.Account -eq $account }
    if ($existing) {
        $existing.Secret = $secret
        $existing.Type   = $type
        $existing.Algo   = $algo
        $existing.Digits = $digits
        $existing.Period = $period
        $existing.Step   = $step
    } else {
        $accounts += [pscustomobject]@{
            Issuer=$issuer; Account=$account; Secret=$secret; Type=$type; Algo=$algo;
            Digits=$digits; Period=$period; Step=$step
        }
        $listAccounts.Items.Add("{0} | {1}" -f $issuer, $account)
        $listAccounts.SelectedIndex = $listAccounts.Items.Count-1
    }
    Save-Accounts $accounts
    RefreshCode
})

$btnDelete.Add_Click({
    $idx = $listAccounts.SelectedIndex
    if ($idx -lt 0) { return }
    $acc = $accounts[$idx]
    $res = [System.Windows.Forms.MessageBox]::Show("Delete account `"$($acc.Issuer) | $($acc.Account)`"?","Confirm",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
    if ($res -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    $accounts = @($accounts[0..($idx-1)] + $accounts[($idx+1)..($accounts.Count-1)]) -as [object[]]
    $listAccounts.Items.RemoveAt($idx)
    Save-Accounts $accounts
    $txtIssuer.Text=""; $txtAccount.Text=""; $txtSecret.Text=""
    RefreshCode
})

$btnCopy.Add_Click({
    if ($lblCode.Text -and $lblCode.Text -ne "------" -and $lblCode.Text -ne "error") {
        [Windows.Forms.Clipboard]::SetText($lblCode.Text)
    }
})

$btnVerify.Add_Click({
    $acc = CurrentAccount
    if ($null -eq $acc) { return }
    try {
        $key = Decode-Base32 $acc.Secret
        $code = $txtVerify.Text.Trim()
        $ok = $false
        if ($acc.Type -eq "TOTP") {
            $ok = Verify-TOTP -key $key -code $code -period $acc.Period -digits $acc.Digits -algo $acc.Algo -skew $DefaultSkew
        } else {
            $ok = (Get-HOTP -key $key -counter [UInt64]$acc.Step -digits $acc.Digits -algo $acc.Algo) -eq $code
        }
        [System.Windows.Forms.MessageBox]::Show(("Result: " + ($(if($ok){"Valid"}else{"Invalid"}))),"Verification",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Verify error: $($_.Exception.Message)","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        Write-Log "Verify error: $($_.Exception.Message)"
    }
})

$btnAskAI.Add_Click({
    $q = $txtAIQuestion.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($q)) { return }
    $txtAIAnswer.Text = "Thinking..."
    $txtAIAnswer.Refresh()
    $ans = Ask-AI -question $q
    $txtAIAnswer.Text = $ans
})

$form.Add_Shown({ $timer.Start() })
$form.Add_FormClosing({ $timer.Stop() })

# ------------------------------
# Launch
# ------------------------------
[void]$form.ShowDialog()
