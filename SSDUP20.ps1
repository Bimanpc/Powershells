# AI_SSD_TRIM.ps1
# PowerShell WPF GUI for AI LLM chat + Windows 11 SSD TRIM controls
# Run as Admin for TRIM actions

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# XAML UI
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI + SSD TRIM (Windows 11)" Height="640" Width="980" WindowStartupLocation="CenterScreen">
  <Grid Margin="10">
    <TabControl>
      <TabItem Header="AI Chat">
        <Grid Margin="10">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>

          <!-- Config -->
          <Border Grid.Row="0" Padding="10" Margin="0,0,0,10" BorderBrush="#DDD" BorderThickness="1">
            <Grid>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="200"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="200"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="200"/>
                <ColumnDefinition Width="*"/>
              </Grid.ColumnDefinitions>

              <TextBlock Grid.Column="0" VerticalAlignment="Center" Text="Provider"/>
              <ComboBox x:Name="ProviderBox" Grid.Column="1" Margin="6,0" SelectedIndex="0">
                <ComboBoxItem>OpenAI</ComboBoxItem>
                <ComboBoxItem>AzureOpenAI</ComboBoxItem>
                <ComboBoxItem>Ollama</ComboBoxItem>
              </ComboBox>

              <TextBlock Grid.Column="2" VerticalAlignment="Center" Text="Model"/>
              <TextBox x:Name="ModelBox" Grid.Column="3" Margin="6,0" Text="gpt-4o-mini"/>

              <TextBlock Grid.Column="4" VerticalAlignment="Center" Text="API Key"/>
              <PasswordBox x:Name="ApiKeyBox" Grid.Column="5" Margin="6,0"/>
            </Grid>
          </Border>

          <!-- Endpoint row -->
          <Border Grid.Row="0" Padding="10" Margin="0,60,0,10" BorderBrush="#EEE" BorderThickness="0">
            <Grid>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="200"/>
                <ColumnDefinition Width="*"/>
              </Grid.ColumnDefinitions>
              <TextBlock Grid.Column="0" VerticalAlignment="Center" Text="Endpoint URL"/>
              <TextBox x:Name="EndpointBox" Grid.Column="1" Margin="6,0" Text="https://api.openai.com/v1/chat/completions"/>
            </Grid>
          </Border>

          <!-- Chat -->
          <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
              <RowDefinition Height="*"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
              <TextBox x:Name="ChatOutput" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" AcceptsReturn="True"/>
            </ScrollViewer>

            <DockPanel Grid.Row="1" Margin="0,10,0,0">
              <Button x:Name="ClearChatBtn" Content="Clear" Width="80" Margin="0,0,10,0" DockPanel.Dock="Right"/>
              <Button x:Name="SendBtn" Content="Send" Width="100" Margin="10,0,0,0" DockPanel.Dock="Right"/>
              <TextBox x:Name="PromptBox" AcceptsReturn="True" TextWrapping="Wrap" Height="80"/>
            </DockPanel>
          </Grid>

          <!-- Status -->
          <StatusBar Grid.Row="2">
            <StatusBarItem>
              <TextBlock x:Name="AiStatus" Text="Ready"/>
            </StatusBarItem>
          </StatusBar>
        </Grid>
      </TabItem>

      <TabItem Header="SSD TRIM">
        <Grid Margin="10">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>

          <!-- Controls -->
          <Border Grid.Row="0" Padding="10" Margin="0,0,0,10" BorderBrush="#DDD" BorderThickness="1">
            <StackPanel Orientation="Horizontal" Spacing="10">
              <Button x:Name="CheckTrimBtn" Content="Check TRIM" Width="120"/>
              <Button x:Name="EnableTrimBtn" Content="Enable TRIM" Width="120"/>
              <Button x:Name="DisableTrimBtn" Content="Disable TRIM" Width="120"/>
              <TextBlock VerticalAlignment="Center" Text="Drive Letter:" Margin="20,0,0,0"/>
              <TextBox x:Name="DriveLetterBox" Width="60" Text="C"/>
              <Button x:Name="ReTrimBtn" Content="ReTrim Volume" Width="140"/>
            </StackPanel>
          </Border>

          <!-- Output -->
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <TextBox x:Name="TrimOutput" IsReadOnly="True" TextWrapping="Wrap" AcceptsReturn="True"/>
          </ScrollViewer>

          <!-- Status -->
          <StatusBar Grid.Row="2">
            <StatusBarItem>
              <TextBlock x:Name="TrimStatus" Text="Ready"/>
            </StatusBarItem>
          </StatusBar>
        </Grid>
      </TabItem>
    </TabControl>
  </Grid>
</Window>
"@

# Build UI
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Find controls
$ProviderBox  = $window.FindName('ProviderBox')
$ModelBox     = $window.FindName('ModelBox')
$ApiKeyBox    = $window.FindName('ApiKeyBox')
$EndpointBox  = $window.FindName('EndpointBox')
$ChatOutput   = $window.FindName('ChatOutput')
$PromptBox    = $window.FindName('PromptBox')
$SendBtn      = $window.FindName('SendBtn')
$ClearChatBtn = $window.FindName('ClearChatBtn')
$AiStatus     = $window.FindName('AiStatus')

$CheckTrimBtn   = $window.FindName('CheckTrimBtn')
$EnableTrimBtn  = $window.FindName('EnableTrimBtn')
$DisableTrimBtn = $window.FindName('DisableTrimBtn')
$DriveLetterBox = $window.FindName('DriveLetterBox')
$ReTrimBtn      = $window.FindName('ReTrimBtn')
$TrimOutput     = $window.FindName('TrimOutput')
$TrimStatus     = $window.FindName('TrimStatus')

# Helpers
function Show-Info {
  param($box, $msg, $statusControl)
  $box.AppendText("$msg`r`n")
  $box.ScrollToEnd()
  if ($statusControl) { $statusControl.Text = $msg }
}

function Require-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $pr = New-Object Security.Principal.WindowsPrincipal($id)
  return $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# AI: Build request payloads
function Invoke-LLM {
  param(
    [string]$Provider,
    [string]$Endpoint,
    [string]$ApiKey,
    [string]$Model,
    [string]$Prompt
  )

  try {
    $AiStatus.Text = "Sending..."
    if ($Provider -eq 'OpenAI') {
      $headers = @{ 'Authorization' = "Bearer $ApiKey"; 'Content-Type' = 'application/json' }
      $body = @{
        model = $Model
        messages = @(@{ role = 'user'; content = $Prompt })
        temperature = 0.2
      } | ConvertTo-Json -Depth 5
      $resp = Invoke-RestMethod -Method Post -Uri $Endpoint -Headers $headers -Body $body
      $text = $resp.choices[0].message.content
    }
    elseif ($Provider -eq 'AzureOpenAI') {
      # Example: https://YOUR-RESOURCE.openai.azure.com/openai/deployments/YOUR-DEPLOYMENT/chat/completions?api-version=2024-02-15-preview
      $headers = @{ 'api-key' = $ApiKey; 'Content-Type' = 'application/json' }
      $body = @{
        messages = @(@{ role = 'user'; content = $Prompt })
        temperature = 0.2
      } | ConvertTo-Json -Depth 5
      $resp = Invoke-RestMethod -Method Post -Uri $Endpoint -Headers $headers -Body $body
      $text = $resp.choices[0].message.content
    }
    elseif ($Provider -eq 'Ollama') {
      # Endpoint typically: http://localhost:11434/api/generate
      $headers = @{ 'Content-Type' = 'application/json' }
      $body = @{
        model = $Model
        prompt = $Prompt
        stream = $false
      } | ConvertTo-Json -Depth 5
      $resp = Invoke-RestMethod -Method Post -Uri $Endpoint -Headers $headers -Body $body
      # Ollama returns { response: "...", ... }
      $text = $resp.response
    }
    else {
      throw "Unsupported provider: $Provider"
    }

    if (-not $text) { $text = "[No response]" }
    $AiStatus.Text = "Done"
    return $text
  }
  catch {
    $AiStatus.Text = "Error"
    return "Error: $($_.Exception.Message)"
  }
}

# AI: Events
$SendBtn.Add_Click({
  $provider = ($ProviderBox.SelectedItem.Content)
  $endpoint = $EndpointBox.Text.Trim()
  $apikey   = $ApiKeyBox.Password.Trim()
  $model    = $ModelBox.Text.Trim()
  $prompt   = $PromptBox.Text.Trim()

  if ([string]::IsNullOrWhiteSpace($prompt)) { return }
  Show-Info -box $ChatOutput -msg "You: $prompt" -statusControl $AiStatus

  $response = Invoke-LLM -Provider $provider -Endpoint $endpoint -ApiKey $apikey -Model $model -Prompt $prompt
  Show-Info -box $ChatOutput -msg "AI: $response" -statusControl $AiStatus
  $PromptBox.Clear()
})

$ClearChatBtn.Add_Click({
  $ChatOutput.Clear()
  $AiStatus.Text = "Ready"
})

# SSD TRIM: functions
function Get-TrimState {
  try {
    $out = & fsutil behavior query DisableDeleteNotify 2>&1
    # Possible outputs can include both NTFS and ReFS lines on newer builds.
    # We'll parse for a zero meaning enabled.
    $lines = $out -split "`r?`n" | Where-Object { $_ -match 'DisableDeleteNotify' }
    $enabled = $false
    foreach ($l in $lines) {
      if ($l -match '0') { $enabled = $true }
    }
    return [pscustomobject]@{
      RawOutput = $out
      Enabled   = $enabled
    }
  }
  catch {
    return [pscustomobject]@{
      RawOutput = $_.Exception.Message
      Enabled   = $null
    }
  }
}

function Set-TrimState {
  param([bool]$Enable)
  if (-not (Require-Admin)) { throw "Administrator privileges required." }
  $val = if ($Enable) { 0 } else { 1 }
  & fsutil behavior set DisableDeleteNotify $val
}

function Invoke-ReTrim {
  param([string]$DriveLetter)
  if (-not (Require-Admin)) { throw "Administrator privileges required." }
  $dl = $DriveLetter.TrimEnd(':')
  # Use Optimize-Volume with ReTrim for SSDs
  Optimize-Volume -DriveLetter $dl -ReTrim -Verbose
}

# SSD TRIM: events
$CheckTrimBtn.Add_Click({
  $TrimStatus.Text = "Checking..."
  $state = Get-TrimState
  Show-Info -box $TrimOutput -msg ("--- TRIM Status ---`r`n" + $state.RawOutput) -statusControl $TrimStatus
  if ($state.Enabled -eq $true) { Show-Info -box $TrimOutput -msg "TRIM is ENABLED." }
  elseif ($state.Enabled -eq $false) { Show-Info -box $TrimOutput -msg "TRIM is DISABLED." }
  else { Show-Info -box $TrimOutput -msg "Unable to determine TRIM state." }
})

$EnableTrimBtn.Add_Click({
  try {
    $TrimStatus.Text = "Enabling TRIM..."
    Set-TrimState -Enable:$true | Out-String | % { Show-Info -box $TrimOutput -msg $_ }
    Show-Info -box $TrimOutput -msg "TRIM enabled."
    $TrimStatus.Text = "Enabled"
  }
  catch {
    Show-Info -box $TrimOutput -msg "Error: $($_.Exception.Message)" -statusControl $TrimStatus
  }
})

$DisableTrimBtn.Add_Click({
  try {
    $TrimStatus.Text = "Disabling TRIM..."
    Set-TrimState -Enable:$false | Out-String | % { Show-Info -box $TrimOutput -msg $_ }
    Show-Info -box $TrimOutput -msg "TRIM disabled."
    $TrimStatus.Text = "Disabled"
  }
  catch {
    Show-Info -box $TrimOutput -msg "Error: $($_.Exception.Message)" -statusControl $TrimStatus
  }
})

$ReTrimBtn.Add_Click({
  try {
    $dl = $DriveLetterBox.Text
    if ([string]::IsNullOrWhiteSpace($dl)) { throw "Specify a drive letter (e.g., C)." }
    $TrimStatus.Text = "ReTrimming..."
    Invoke-ReTrim -DriveLetter $dl | Out-String | % { Show-Info -box $TrimOutput -msg $_ }
    Show-Info -box $TrimOutput -msg "ReTrim complete for $dl."
    $TrimStatus.Text = "Done"
  }
  catch {
    Show-Info -box $TrimOutput -msg "Error: $($_.Exception.Message)" -statusControl $TrimStatus
  }
})

# Start
$window.ShowDialog() | Out-Null
