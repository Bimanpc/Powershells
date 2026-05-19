<# 
ZTE H600P Router Info GUI + AI LLM helper
Single-file, no telemetry. 
- Basic HTTP calls to router (default 192.168.1.1)
- Simple WPF GUI
- LLM call is a stub: wire it to your local/private endpoint.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

#---------------- CONFIG ----------------#
$Global:RouterDefaultIP   = "192.168.1.1"
$Global:LLM_Endpoint      = "http://127.0.0.1:11434/api/generate"  # change to your local LLM
$Global:LLM_Model         = "local-llm"                             # model name if needed

#------------- CORE FUNCTIONS -----------#
function Invoke-RouterApi {
    param(
        [string]$RouterIP,
        [string]$Path,
        [string]$User,
        [string]$Pass,
        [string]$Method = "GET",
        [string]$Body   = $null
    )

    $uri = "http://$RouterIP/$Path"

    $headers = @{
        Authorization = "Basic " + [Convert]::ToBase64String(
            [Text.Encoding]::ASCII.GetBytes("$User`:$Pass")
        )
    }

    $params = @{
        Uri         = $uri
        Method      = $Method
        Headers     = $headers
        ErrorAction = 'Stop'
    }
    if ($Body) {
        $params.ContentType = "application/json"
        $params.Body        = $Body
    }

    try {
        $resp = Invoke-WebRequest @params
        if ($resp.Content) {
            return $resp.Content
        } else {
            return ""
        }
    } catch {
        return "ERROR: $($_.Exception.Message)"
    }
}

function Get-RouterStatusJson {
    param(
        [string]$RouterIP,
        [string]$User,
        [string]$Pass
    )
    # Adjust path to actual ZTE H600P status API or page
    # Example: "status.asp" or "api/status" etc.
    $path = "status.asp"
    Invoke-RouterApi -RouterIP $RouterIP -Path $path -User $User -Pass $Pass
}

function Get-RouterWifiJson {
    param(
        [string]$RouterIP,
        [string]$User,
        [string]$Pass
    )
    # Adjust path to actual WiFi config endpoint
    $path = "wifi.asp"
    Invoke-RouterApi -RouterIP $RouterIP -Path $path -User $User -Pass $Pass
}

function Reboot-Router {
    param(
        [string]$RouterIP,
        [string]$User,
        [string]$Pass
    )
    # Adjust path/body to actual reboot endpoint
    $path = "reboot.asp"
    Invoke-RouterApi -RouterIP $RouterIP -Path $path -User $User -Pass $Pass -Method "POST"
}

function Invoke-LLM {
    param(
        [string]$RouterData,
        [string]$Question
    )

    # Stub for local/private LLM HTTP API
    # Example: simple JSON POST to your endpoint
    $bodyObj = @{
        model   = $Global:LLM_Model
        prompt  = "Router data:`n$RouterData`n`nUser question: $Question`n`nExplain clearly:"
        stream  = $false
    }

    try {
        $resp = Invoke-WebRequest -Uri $Global:LLM_Endpoint `
                                  -Method POST `
                                  -ContentType "application/json" `
                                  -Body (ConvertTo-Json $bodyObj -Depth 5) `
                                  -ErrorAction Stop
        if ($resp.Content) {
            return $resp.Content
        } else {
            return "No response from LLM."
        }
    } catch {
        return "LLM ERROR: $($_.Exception.Message)"
    }
}

#------------- XAML UI ------------------#
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="ZTE H600P Router Info + AI" Height="520" Width="900"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResize">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="2*"/>
        </Grid.RowDefinitions>

        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,5">
            <Label Content="Router IP:" VerticalAlignment="Center"/>
            <TextBox x:Name="txtRouterIP" Width="120" Margin="5,0,15,0"/>
            <Label Content="User:" VerticalAlignment="Center"/>
            <TextBox x:Name="txtUser" Width="100" Margin="5,0,15,0"/>
            <Label Content="Password:" VerticalAlignment="Center"/>
            <PasswordBox x:Name="txtPass" Width="120" Margin="5,0,15,0"/>
            <Button x:Name="btnStatus" Content="Get Status" Width="90" Margin="5,0"/>
            <Button x:Name="btnWifi" Content="Get WiFi" Width="90" Margin="5,0"/>
            <Button x:Name="btnReboot" Content="Reboot" Width="90" Margin="5,0"/>
        </StackPanel>

        <StackPanel Orientation="Horizontal" Grid.Row="1" Margin="0,0,0,5">
            <Label Content="LLM Endpoint:" VerticalAlignment="Center"/>
            <TextBox x:Name="txtLLMEndpoint" Width="260" Margin="5,0,15,0"/>
            <Label Content="Model:" VerticalAlignment="Center"/>
            <TextBox x:Name="txtLLMModel" Width="120" Margin="5,0,15,0"/>
            <Label Content="AI Question:" VerticalAlignment="Center"/>
            <TextBox x:Name="txtQuestion" Width="260" Margin="5,0,5,0"/>
            <Button x:Name="btnAskAI" Content="Ask AI" Width="80" Margin="5,0"/>
        </StackPanel>

        <GroupBox Header="Router Raw Data" Grid.Row="2" Margin="0,0,0,5">
            <Grid>
                <TextBox x:Name="txtRouterData"
                         TextWrapping="Wrap"
                         VerticalScrollBarVisibility="Auto"
                         HorizontalScrollBarVisibility="Auto"
                         AcceptsReturn="True"/>
            </Grid>
        </GroupBox>

        <GroupBox Header="AI Answer" Grid.Row="3">
            <Grid>
                <TextBox x:Name="txtAIAnswer"
                         TextWrapping="Wrap"
                         VerticalScrollBarVisibility="Auto"
                         HorizontalScrollBarVisibility="Auto"
                         AcceptsReturn="True"/>
            </Grid>
        </GroupBox>
    </Grid>
</Window>
"@

#------------- BUILD UI -----------------#
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$txtRouterIP   = $window.FindName("txtRouterIP")
$txtUser       = $window.FindName("txtUser")
$txtPass       = $window.FindName("txtPass")
$btnStatus     = $window.FindName("btnStatus")
$btnWifi       = $window.FindName("btnWifi")
$btnReboot     = $window.FindName("btnReboot")

$txtLLMEndpoint = $window.FindName("txtLLMEndpoint")
$txtLLMModel    = $window.FindName("txtLLMModel")
$txtQuestion    = $window.FindName("txtQuestion")
$btnAskAI       = $window.FindName("btnAskAI")

$txtRouterData = $window.FindName("txtRouterData")
$txtAIAnswer   = $window.FindName("txtAIAnswer")

# Defaults
$txtRouterIP.Text    = $Global:RouterDefaultIP
$txtLLMEndpoint.Text = $Global:LLM_Endpoint
$txtLLMModel.Text    = $Global:LLM_Model
$txtUser.Text        = "admin"

#------------- EVENT HANDLERS -----------#
$btnStatus.Add_Click({
    $ip   = $txtRouterIP.Text.Trim()
    $user = $txtUser.Text.Trim()
    $pass = $txtPass.Password

    if (-not $ip -or -not $user) { 
        [System.Windows.MessageBox]::Show("Router IP and User are required.","Error","OK","Error") | Out-Null
        return
    }

    $txtRouterData.Text = "Querying router status..."
    $data = Get-RouterStatusJson -RouterIP $ip -User $user -Pass $pass
    $txtRouterData.Text = $data
})

$btnWifi.Add_Click({
    $ip   = $txtRouterIP.Text.Trim()
    $user = $txtUser.Text.Trim()
    $pass = $txtPass.Password

    if (-not $ip -or -not $user) { 
        [System.Windows.MessageBox]::Show("Router IP and User are required.","Error","OK","Error") | Out-Null
        return
    }

    $txtRouterData.Text = "Querying router WiFi config..."
    $data = Get-RouterWifiJson -RouterIP $ip -User $user -Pass $pass
    $txtRouterData.Text = $data
})

$btnReboot.Add_Click({
    $ip   = $txtRouterIP.Text.Trim()
    $user = $txtUser.Text.Trim()
    $pass = $txtPass.Password

    if (-not $ip -or -not $user) { 
        [System.Windows.MessageBox]::Show("Router IP and User are required.","Error","OK","Error") | Out-Null
        return
    }

    $confirm = [System.Windows.MessageBox]::Show("Reboot router $ip ?","Confirm","YesNo","Warning")
    if ($confirm -ne "Yes") { return }

    $txtRouterData.Text = "Sending reboot command..."
    $data = Reboot-Router -RouterIP $ip -User $user -Pass $pass
    $txtRouterData.Text = $data
})

$btnAskAI.Add_Click({
    $Global:LLM_Endpoint = $txtLLMEndpoint.Text.Trim()
    $Global:LLM_Model    = $txtLLMModel.Text.Trim()

    $routerData = $txtRouterData.Text
    $question   = $txtQuestion.Text.Trim()

    if (-not $routerData) {
        [System.Windows.MessageBox]::Show("No router data to analyze. Get Status/WiFi first.","Info","OK","Information") | Out-Null
        return
    }
    if (-not $question) {
        [System.Windows.MessageBox]::Show("Enter a question for the AI.","Info","OK","Information") | Out-Null
        return
    }

    $txtAIAnswer.Text = "Asking LLM..."
    $answer = Invoke-LLM -RouterData $routerData -Question $question
    $txtAIAnswer.Text = $answer
})

#------------- RUN ----------------------#
$window.Topmost = $false
$null = $window.ShowDialog()
