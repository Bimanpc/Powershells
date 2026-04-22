Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------- Helper functions ----------
function Show-Message($text, $title = "Info") {
    [System.Windows.Forms.MessageBox]::Show($text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Log($text) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $global:txtLog.AppendText("$timestamp`t$text`r`n")
    $global:txtLog.ScrollToCaret()
}

function Launch-VNC($exePath, $host, $port, $password) {
    if (-not (Test-Path $exePath)) {
        Show-Message "VNC viewer not found at path: $exePath" "VNC Error"
        return
    }
    $args = ""
    # Common viewers accept different CLI args; adjust as needed for your viewer.
    # Example for TightVNC viewer: tvnviewer.exe host:port /password password
    $args = "$host`:$port"
    if ($password -and $password.Trim() -ne "") {
        # Many viewers accept a /password or -passwd flag; user may need to adjust.
        $args = "$args /password $password"
    }
    try {
        Start-Process -FilePath $exePath -ArgumentList $args -ErrorAction Stop
        Log "Launched VNC viewer $exePath $args"
    } catch {
        Show-Message "Failed to launch VNC viewer: $($_.Exception.Message)" "VNC Error"
        Log "VNC launch error: $($_.Exception.Message)"
    }
}

function Invoke-LLM($apiUrl, $apiKey, $model, $prompt, $systemPrompt = "") {
    if (-not $apiUrl) { throw "API URL is required." }
    if (-not $apiKey) { throw "API key is required." }
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "application/json"
    }

    # Build a chat-style payload compatible with OpenAI chat completions
    $messages = @()
    if ($systemPrompt -and $systemPrompt.Trim() -ne "") {
        $messages += @{ role = "system"; content = $systemPrompt }
    }
    $messages += @{ role = "user"; content = $prompt }

    $body = @{
        model = $model
        messages = $messages
        max_tokens = 800
        temperature = 0.2
    } | ConvertTo-Json -Depth 10

    try {
        Log "Sending prompt to LLM..."
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body -ErrorAction Stop
        # Try to extract text for OpenAI-like responses
        if ($response.choices -and $response.choices.Count -gt 0) {
            $text = $response.choices[0].message.content
            return $text
        } elseif ($response.output_text) {
            return $response.output_text
        } else {
            return ($response | ConvertTo-Json -Depth 5)
        }
    } catch {
        throw $_
    }
}

# ---------- Build UI ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI LLM + VNC App"
$form.Size = New-Object System.Drawing.Size(980,720)
$form.StartPosition = "CenterScreen"

# VNC Group
$grpVNC = New-Object System.Windows.Forms.GroupBox
$grpVNC.Text = "VNC Controls"
$grpVNC.Size = New-Object System.Drawing.Size(460,140)
$grpVNC.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($grpVNC)

$lblVncExe = New-Object System.Windows.Forms.Label
$lblVncExe.Text = "VNC Viewer Path"
$lblVncExe.Location = New-Object System.Drawing.Point(10,22)
$lblVncExe.Size = New-Object System.Drawing.Size(100,20)
$grpVNC.Controls.Add($lblVncExe)

$txtVncExe = New-Object System.Windows.Forms.TextBox
$txtVncExe.Location = New-Object System.Drawing.Point(120,20)
$txtVncExe.Size = New-Object System.Drawing.Size(320,20)
$txtVncExe.Text = "C:\Program Files\TightVNC\tvnviewer.exe"
$grpVNC.Controls.Add($txtVncExe)

$lblHost = New-Object System.Windows.Forms.Label
$lblHost.Text = "Host"
$lblHost.Location = New-Object System.Drawing.Point(10,52)
$lblHost.Size = New-Object System.Drawing.Size(100,20)
$grpVNC.Controls.Add($lblHost)

$txtHost = New-Object System.Windows.Forms.TextBox
$txtHost.Location = New-Object System.Drawing.Point(120,52)
$txtHost.Size = New-Object System.Drawing.Size(150,20)
$txtHost.Text = "192.168.1.100"
$grpVNC.Controls.Add($txtHost)

$lblPort = New-Object System.Windows.Forms.Label
$lblPort.Text = "Port"
$lblPort.Location = New-Object System.Drawing.Point(280,52)
$lblPort.Size = New-Object System.Drawing.Size(40,20)
$grpVNC.Controls.Add($lblPort)

$txtPort = New-Object System.Windows.Forms.TextBox
$txtPort.Location = New-Object System.Drawing.Point(320,52)
$txtPort.Size = New-Object System.Drawing.Size(60,20)
$txtPort.Text = "5900"
$grpVNC.Controls.Add($txtPort)

$lblVncPass = New-Object System.Windows.Forms.Label
$lblVncPass.Text = "Password"
$lblVncPass.Location = New-Object System.Drawing.Point(10,82)
$lblVncPass.Size = New-Object System.Drawing.Size(100,20)
$grpVNC.Controls.Add($lblVncPass)

$txtVncPass = New-Object System.Windows.Forms.TextBox
$txtVncPass.Location = New-Object System.Drawing.Point(120,82)
$txtVncPass.Size = New-Object System.Drawing.Size(150,20)
$txtVncPass.UseSystemPasswordChar = $true
$grpVNC.Controls.Add($txtVncPass)

$btnConnectVnc = New-Object System.Windows.Forms.Button
$btnConnectVnc.Text = "Connect VNC"
$btnConnectVnc.Location = New-Object System.Drawing.Point(290,80)
$btnConnectVnc.Size = New-Object System.Drawing.Size(150,25)
$grpVNC.Controls.Add($btnConnectVnc)

# LLM Group
$grpLLM = New-Object System.Windows.Forms.GroupBox
$grpLLM.Text = "LLM Controls"
$grpLLM.Size = New-Object System.Drawing.Size(460,420)
$grpLLM.Location = New-Object System.Drawing.Point(10,160)
$form.Controls.Add($grpLLM)

$lblApiUrl = New-Object System.Windows.Forms.Label
$lblApiUrl.Text = "API URL"
$lblApiUrl.Location = New-Object System.Drawing.Point(10,22)
$lblApiUrl.Size = New-Object System.Drawing.Size(100,20)
$grpLLM.Controls.Add($lblApiUrl)

$txtApiUrl = New-Object System.Windows.Forms.TextBox
$txtApiUrl.Location = New-Object System.Drawing.Point(120,20)
$txtApiUrl.Size = New-Object System.Drawing.Size(320,20)
$txtApiUrl.Text = "https://api.openai.com/v1/chat/completions"
$grpLLM.Controls.Add($txtApiUrl)

$lblApiKey = New-Object System.Windows.Forms.Label
$lblApiKey.Text = "API Key"
$lblApiKey.Location = New-Object System.Drawing.Point(10,52)
$lblApiKey.Size = New-Object System.Drawing.Size(100,20)
$grpLLM.Controls.Add($lblApiKey)

$txtApiKey = New-Object System.Windows.Forms.TextBox
$txtApiKey.Location = New-Object System.Drawing.Point(120,52)
$txtApiKey.Size = New-Object System.Drawing.Size(320,20)
$txtApiKey.UseSystemPasswordChar = $true
$grpLLM.Controls.Add($txtApiKey)

$lblModel = New-Object System.Windows.Forms.Label
$lblModel.Text = "Model"
$lblModel.Location = New-Object System.Drawing.Point(10,82)
$lblModel.Size = New-Object System.Drawing.Size(100,20)
$grpLLM.Controls.Add($lblModel)

$cbModel = New-Object System.Windows.Forms.ComboBox
$cbModel.Location = New-Object System.Drawing.Point(120,82)
$cbModel.Size = New-Object System.Drawing.Size(200,20)
$cbModel.DropDownStyle = "DropDown"
$cbModel.Items.AddRange(@("gpt-4o", "gpt-4", "gpt-3.5-turbo"))
$cbModel.Text = "gpt-3.5-turbo"
$grpLLM.Controls.Add($cbModel)

$lblSystem = New-Object System.Windows.Forms.Label
$lblSystem.Text = "System Prompt"
$lblSystem.Location = New-Object System.Drawing.Point(10,112)
$lblSystem.Size = New-Object System.Drawing.Size(100,20)
$grpLLM.Controls.Add($lblSystem)

$txtSystem = New-Object System.Windows.Forms.TextBox
$txtSystem.Location = New-Object System.Drawing.Point(120,112)
$txtSystem.Size = New-Object System.Drawing.Size(320,60)
$txtSystem.Multiline = $true
$txtSystem.ScrollBars = "Vertical"
$grpLLM.Controls.Add($txtSystem)

$lblPrompt = New-Object System.Windows.Forms.Label
$lblPrompt.Text = "Prompt"
$lblPrompt.Location = New-Object System.Drawing.Point(10,182)
$lblPrompt.Size = New-Object System.Drawing.Size(100,20)
$grpLLM.Controls.Add($lblPrompt)

$txtPrompt = New-Object System.Windows.Forms.TextBox
$txtPrompt.Location = New-Object System.Drawing.Point(120,182)
$txtPrompt.Size = New-Object System.Drawing.Size(320,120)
$txtPrompt.Multiline = $true
$txtPrompt.ScrollBars = "Vertical"
$grpLLM.Controls.Add($txtPrompt)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = "Send to LLM"
$btnSend.Location = New-Object System.Drawing.Point(120,310)
$btnSend.Size = New-Object System.Drawing.Size(150,30)
$grpLLM.Controls.Add($btnSend)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "Clear Prompt"
$btnClear.Location = New-Object System.Drawing.Point(280,310)
$btnClear.Size = New-Object System.Drawing.Size(160,30)
$grpLLM.Controls.Add($btnClear)

$lblResponse = New-Object System.Windows.Forms.Label
$lblResponse.Text = "Response"
$lblResponse.Location = New-Object System.Drawing.Point(10,350)
$lblResponse.Size = New-Object System.Drawing.Size(100,20)
$grpLLM.Controls.Add($lblResponse)

$txtResponse = New-Object System.Windows.Forms.TextBox
$txtResponse.Location = New-Object System.Drawing.Point(120,350)
$txtResponse.Size = New-Object System.Drawing.Size(320,60)
$txtResponse.Multiline = $true
$txtResponse.ScrollBars = "Vertical"
$txtResponse.ReadOnly = $true
$grpLLM.Controls.Add($txtResponse)

# Log area
$grpLog = New-Object System.Windows.Forms.GroupBox
$grpLog.Text = "Log"
$grpLog.Size = New-Object System.Drawing.Size(460,200)
$grpLog.Location = New-Object System.Drawing.Point(10,590)
$form.Controls.Add($grpLog)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(10,20)
$txtLog.Size = New-Object System.Drawing.Size(440,170)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$grpLog.Controls.Add($txtLog)

# Right side: quick controls and status
$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Text = "Status and Quick Actions"
$lblInfo.Location = New-Object System.Drawing.Point(490,10)
$lblInfo.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($lblInfo)

$btnTestApi = New-Object System.Windows.Forms.Button
$btnTestApi.Text = "Test API Key"
$btnTestApi.Location = New-Object System.Drawing.Point(490,40)
$btnTestApi.Size = New-Object System.Drawing.Size(140,30)
$form.Controls.Add($btnTestApi)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Ready"
$lblStatus.Location = New-Object System.Drawing.Point(490,80)
$lblStatus.Size = New-Object System.Drawing.Size(420,20)
$form.Controls.Add($lblStatus)

# Large log / console on right
$txtConsole = New-Object System.Windows.Forms.TextBox
$txtConsole.Location = New-Object System.Drawing.Point(490,110)
$txtConsole.Size = New-Object System.Drawing.Size(460,680)
$txtConsole.Multiline = $true
$txtConsole.ScrollBars = "Vertical"
$txtConsole.ReadOnly = $true
$form.Controls.Add($txtConsole)

# ---------- Event handlers ----------
$btnConnectVnc.Add_Click({
    $exe = $txtVncExe.Text.Trim()
    $host = $txtHost.Text.Trim()
    $port = $txtPort.Text.Trim()
    $pass = $txtVncPass.Text
    if (-not $host) { Show-Message "Enter VNC host." "Input required"; return }
    if (-not $port) { $port = "5900" }
    Log "Attempting VNC connect to $host:$port"
    Launch-VNC -exePath $exe -host $host -port $port -password $pass
})

$btnSend.Add_Click({
    $apiUrl = $txtApiUrl.Text.Trim()
    $apiKey = $txtApiKey.Text.Trim()
    $model = $cbModel.Text.Trim()
    $prompt = $txtPrompt.Text.Trim()
    $systemPrompt = $txtSystem.Text.Trim()
    if (-not $prompt) { Show-Message "Enter a prompt to send to the LLM." "Input required"; return }
    $lblStatus.Text = "Sending prompt..."
    $txtResponse.Text = ""
    try {
        $result = Invoke-LLM -apiUrl $apiUrl -apiKey $apiKey -model $model -prompt $prompt -systemPrompt $systemPrompt
        $txtResponse.Text = $result
        $txtConsole.AppendText("LLM response:`r`n$result`r`n`r`n")
        Log "LLM response received"
        $lblStatus.Text = "LLM response received"
    } catch {
        $err = $_.Exception.Message
        Show-Message "LLM request failed: $err" "LLM Error"
        Log "LLM error: $err"
        $lblStatus.Text = "LLM error"
    }
})

$btnClear.Add_Click({
    $txtPrompt.Clear()
})

$btnTestApi.Add_Click({
    $apiUrl = $txtApiUrl.Text.Trim()
    $apiKey = $txtApiKey.Text.Trim()
    if (-not $apiUrl -or -not $apiKey) { Show-Message "Set API URL and API Key first." "Input required"; return }
    $lblStatus.Text = "Testing API..."
    try {
        # Minimal test: send a tiny prompt
        $test = Invoke-LLM -apiUrl $apiUrl -apiKey $apiKey -model $cbModel.Text -prompt "Say hello in one word."
        Show-Message "API test succeeded. Sample response:`r`n$test" "API Test"
        Log "API test succeeded"
        $lblStatus.Text = "API OK"
    } catch {
        Show-Message "API test failed: $($_.Exception.Message)" "API Test"
        Log "API test failed: $($_.Exception.Message)"
        $lblStatus.Text = "API error"
    }
})

# ---------- Finalize and show ----------
$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
