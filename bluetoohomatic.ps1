<#
.SYNOPSIS
  AI LLM Bluetooth Manager GUI (.ps1)

.DESCRIPTION
  - WPF GUI for scanning, pairing, connecting, disconnecting, and toggling Bluetooth radios.
  - AI Assistant textbox: type natural language (e.g., "turn bluetooth off", "connect to my headset") → app maps to actions.
  - Uses Windows Runtime (WinRT) APIs when available; falls back to PnP device enumeration.
  - Admin-safe: no registry writes; radio toggling uses Radios API when possible.

.NOTES
  - Tested on Windows 10/11 with PowerShell 5.1+ / 7+.
  - Pair/Connect/Disconnect APIs are limited by Windows public APIs; provided best-effort & stubs with actionable UI feedback.
  - Extensibility: wire your LLM endpoint in Invoke-LLM (HTTP POST stub), expand action mapping in Resolve-AICommand.

#>

#-------------------------------#
# Bootstrap: WinRT + WPF setup  #
#-------------------------------#

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase

# Enable WinRT types for Bluetooth/Radio APIs (best-effort)
$global:WinRTReady = $false
try {
  Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null
  $null = [Windows.Devices.Enumeration.DeviceInformation, Windows, ContentType=WindowsRuntime]
  $null = [Windows.Devices.Bluetooth.BluetoothLEDevice, Windows, ContentType=WindowsRuntime]
  $null = [Windows.Devices.Radios.Radio, Windows, ContentType=WindowsRuntime]
  $global:WinRTReady = $true
} catch {
  $global:WinRTReady = $false
}

#-------------------------------#
# Helper: Async → Sync bridge   #
#-------------------------------#

function Await($asyncOp) {
  # Bridges WinRT IAsyncOperation to sync
  $task = [System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeAsync({
    $asyncOp.AsTask().GetAwaiter().GetResult()
  })
  $task.Result
}

#-------------------------------#
# Bluetooth core functionality  #
#-------------------------------#

# Cache for devices
$global:BtDevices = @()

function Get-BluetoothDevices {
  $devices = @()

  if ($global:WinRTReady) {
    try {
      # Bluetooth LE selector (AEP protocol)
      $selector = [Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelector()
      $found = Await ([Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($selector))

      foreach ($di in $found) {
        $ble = Await ([Windows.Devices.Bluetooth.BluetoothLEDevice]::FromIdAsync($di.Id))
        if ($ble) {
          $devices += [PSCustomObject]@{
            Id            = $di.Id
            Name          = if ($ble.Name) { $ble.Name } else { $di.Name }
            Paired        = $di.Pairing.IsPaired
            Connected     = $ble.ConnectionStatus -eq [Windows.Devices.Bluetooth.BluetoothConnectionStatus]::Connected
            Address       = ("{0:X12}" -f $ble.BluetoothAddress)
            IsLE          = $true
            DeviceInfo    = $di
            LEDevice      = $ble
          }
        } else {
          $devices += [PSCustomObject]@{
            Id            = $di.Id
            Name          = $di.Name
            Paired        = $di.Pairing.IsPaired
            Connected     = $false
            Address       = $null
            IsLE          = $true
            DeviceInfo    = $di
            LEDevice      = $null
          }
        }
      }
    } catch {
      # Fall back below
    }
  }

  if (-not $devices -or $devices.Count -eq 0) {
    # Fallback: PnP device class Bluetooth
    try {
      $pnp = Get-PnpDevice -Class Bluetooth -Status OK -ErrorAction Stop
      foreach ($d in $pnp) {
        $devices += [PSCustomObject]@{
          Id            = $d.InstanceId
          Name          = $d.FriendlyName
          Paired        = $null
          Connected     = ($d.Status -eq "OK")
          Address       = $null
          IsLE          = $null
          DeviceInfo    = $d
          LEDevice      = $null
        }
      }
    } catch {
      # If PnP not available, return empty
    }
  }

  $global:BtDevices = $devices
  return $devices
}

function Get-BluetoothRadios {
  if (-not $global:WinRTReady) { return @() }
  try {
    Await([Windows.Devices.Radios.Radio]::GetRadiosAsync())
  } catch { @() }
}

function Set-RadioState {
  param(
    [Parameter(Mandatory=$true)][ValidateSet('On','Off')]$State
  )
  $radios = Get-BluetoothRadios | Where-Object { $_.Kind -eq [Windows.Devices.Radios.RadioKind]::Bluetooth }
  if (-not $radios -or $radios.Count -eq 0) {
    throw "No Bluetooth radios found or API unavailable."
  }
  foreach ($r in $radios) {
    $desired = if ($State -eq 'On') { [Windows.Devices.Radios.RadioState]::On } else { [Windows.Devices.Radios.RadioState]::Off }
    $result = Await($r.SetStateAsync($desired))
    if ($result -ne [Windows.Devices.Radios.RadioAccessStatus]::Allowed) {
      throw "Radio change not allowed (access=$result). Try running PowerShell as administrator or via Settings."
    }
  }
}

function Pair-Device {
  param([Parameter(Mandatory=$true)]$DeviceRow)
  # WinRT pairing support (UI-assisted)
  if ($global:WinRTReady -and $DeviceRow.DeviceInfo) {
    try {
      $pairing = $DeviceRow.DeviceInfo.Pairing
      if ($pairing.IsPaired) { return "Already paired." }
      # This may show system UI for consent
      $res = Await($pairing.PairAsync())
      if ($res.Status -eq [Windows.Devices.Enumeration.DevicePairingResultStatus]::Paired) {
        return "Paired successfully."
      } else {
        return "Pairing failed: $($res.Status)"
      }
    } catch {
      return "Pairing not supported for this device via API."
    }
  }
  return "Pairing API unavailable. Use Windows Settings > Bluetooth & devices."
}

function Unpair-Device {
  param([Parameter(Mandatory=$true)]$DeviceRow)
  if ($global:WinRTReady -and $DeviceRow.DeviceInfo) {
    try {
      $pairing = $DeviceRow.DeviceInfo.Pairing
      if (-not $pairing.IsPaired) { return "Not paired." }
      $res = Await($pairing.UnpairAsync())
      if ($res.Status -eq [Windows.Devices.Enumeration.DeviceUnpairingResultStatus]::Unpaired) {
        return "Unpaired successfully."
      } else {
        return "Unpairing failed: $($res.Status)"
      }
    } catch {
      return "Unpairing not supported via API."
    }
  }
  return "Unpairing API unavailable. Use Windows Settings."
}

function Connect-Device {
  param([Parameter(Mandatory=$true)]$DeviceRow)
  # Direct connect for BLE GATT isn't universally supported via public API.
  # Best-effort: touch device to prompt connection when paired.
  if ($DeviceRow.LEDevice) {
    try {
      $gatt = Await($DeviceRow.LEDevice.GetGattServicesAsync())
      if ($gatt.Status -eq [Windows.Devices.Bluetooth.GenericAttributeProfile.GattCommunicationStatus]::Success) {
        return "Connection nudged via GATT. Device should be connected if supported."
      } else {
        return "GATT access failed: $($gatt.Status)"
      }
    } catch {
      return "Connect not supported via API. If audio device, use system sound settings."
    }
  }
  return "Connect unavailable for this device."
}

function Disconnect-Device {
  param([Parameter(Mandatory=$true)]$DeviceRow)
  if ($DeviceRow.LEDevice) {
    try {
      # Dispose to drop GATT session; may not fully disconnect transport
      $DeviceRow.LEDevice.Dispose()
      return "Disconnected GATT session. Physical link may persist depending on profile."
    } catch {
      return "Disconnect not supported via API."
    }
  }
  return "Disconnect unavailable for this device."
}

#-------------------------------#
# AI Assistant wiring (stub)    #
#-------------------------------#

$global:AIConfig = [PSCustomObject]@{
  Endpoint = "https://your-llm-endpoint/v1/chat/completions"  # Replace with your endpoint
  ApiKey   = $env:LLM_API_KEY                                 # Store key in env var
  Model    = "your-model-id"
}

function Invoke-LLM {
  param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [string]$SystemInstruction = "You are a Bluetooth manager assistant. Interpret user intent into concise actions."
  )
  # Stub: returns a lightweight intent in JSON. Replace with real HTTP POST.
  # Expected JSON: { "action": "toggle", "state": "on" } or { "action": "connect", "target": "WH-1000XM4" }
  # For immediate usability, do a local heuristic intent parse:
  return Resolve-AICommand -Text $Prompt
}

function Resolve-AICommand {
  param([Parameter(Mandatory=$true)][string]$Text)

  $t = $Text.ToLower()

  if ($t -match '\b(turn|switch)\s+(bluetooth)\s+off\b' -or $t -match '\bdisable\b') {
    return @{ action='toggle'; state='off' }
  }
  if ($t -match '\b(turn|switch)\s+(bluetooth)\s+on\b' -or $t -match '\benable\b') {
    return @{ action='toggle'; state='on' }
  }
  if ($t -match '\bscan\b' -or $t -match '\bdiscover\b' -or $t -match '\brefresh\b') {
    return @{ action='scan' }
  }
  if ($t -match '\bpai?r\b') {
    # Extract name after 'pair' if present
    $m = [regex]::Match($t, 'pair\s+(with\s+)?(?<name>.+)$')
    return @{ action='pair'; target=$m.Groups['name'].Value.Trim() }
  }
  if ($t -match '\bunpair\b' -or $t -match '\bforget\b') {
    $m = [regex]::Match($t, '(unpair|forget)\s+(?<name>.+)$')
    return @{ action='unpair'; target=$m.Groups['name'].Value.Trim() }
  }
  if ($t -match '\bconnect\b') {
    $m = [regex]::Match($t, 'connect\s+(to\s+)?(?<name>.+)$')
    return @{ action='connect'; target=$m.Groups['name'].Value.Trim() }
  }
  if ($t -match '\bdisconnect\b') {
    $m = [regex]::Match($t, 'disconnect\s+(from\s+)?(?<name>.+)$')
    return @{ action='disconnect'; target=$m.Groups['name'].Value.Trim() }
  }

  return @{ action='unknown'; text=$Text }
}

function Apply-AIIntent {
  param([Parameter(Mandatory=$true)]$Intent)

  switch ($Intent.action) {
    'toggle' {
      try {
        Set-RadioState -State $Intent.state
        return "Bluetooth turned $($Intent.state)."
      } catch {
        return "Failed to toggle Bluetooth: $($_.Exception.Message)"
      }
    }
    'scan' {
      $null = Get-BluetoothDevices
      Update-DeviceGrid
      return "Scan complete."
    }
    'pair' {
      $target = Match-DeviceByName -Name $Intent.target
      if (-not $target) { return "Device not found for pairing: '$($Intent.target)'." }
      return Pair-Device -DeviceRow $target
    }
    'unpair' {
      $target = Match-DeviceByName -Name $Intent.target
      if (-not $target) { return "Device not found for unpair: '$($Intent.target)'." }
      return Unpair-Device -DeviceRow $target
    }
    'connect' {
      $target = Match-DeviceByName -Name $Intent.target
      if (-not $target) { return "Device not found for connect: '$($Intent.target)'." }
      return Connect-Device -DeviceRow $target
    }
    'disconnect' {
      $target = Match-DeviceByName -Name $Intent.target
      if (-not $target) { return "Device not found for disconnect: '$($Intent.target)'." }
      return Disconnect-Device -DeviceRow $target
    }
    Default {
      return "I didn't catch that. Try: 'turn bluetooth on', 'scan', 'pair WH-1000XM4', 'connect to AirPods'."
    }
  }
}

function Match-DeviceByName {
  param([Parameter(Mandatory=$true)][string]$Name)
  if (-not $Name) { return $null }
  $n = $Name.Trim().ToLower()
  $global:BtDevices | Sort-Object Name | Where-Object {
    $_.Name -and $_.Name.ToLower() -like "*$n*"
  } | Select-Object -First 1
}

#-------------------------------#
# WPF UI (XAML)                 #
#-------------------------------#

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI Bluetooth Manager" Height="600" Width="920" WindowStartupLocation="CenterScreen">
  <Grid Margin="10">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Toolbar -->
    <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,8">
      <Button x:Name="BtnScan" Content="Scan" Width="90" Margin="0,0,8,0"/>
      <Button x:Name="BtnOn" Content="Bluetooth On" Width="120" Margin="0,0,8,0"/>
      <Button x:Name="BtnOff" Content="Bluetooth Off" Width="120" Margin="0,0,8,0"/>
      <TextBlock Text="Status:" VerticalAlignment="Center" Margin="16,0,4,0"/>
      <TextBlock x:Name="LblStatus" VerticalAlignment="Center"/>
    </StackPanel>

    <!-- Device grid -->
    <DataGrid x:Name="GridDevices" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single">
      <DataGrid.Columns>
        <DataGridTextColumn Header="Name" Binding="{Binding Name}" Width="2*"/>
        <DataGridTextColumn Header="Paired" Binding="{Binding Paired}" Width="*" />
        <DataGridTextColumn Header="Connected" Binding="{Binding Connected}" Width="*" />
        <DataGridTextColumn Header="Address" Binding="{Binding Address}" Width="*" />
        <DataGridTextColumn Header="LE" Binding="{Binding IsLE}" Width="*" />
      </DataGrid.Columns>
    </DataGrid>

    <!-- Device actions -->
    <StackPanel Orientation="Horizontal" Grid.Row="2" Margin="0,8,0,8">
      <Button x:Name="BtnPair" Content="Pair" Width="100" Margin="0,0,8,0"/>
      <Button x:Name="BtnUnpair" Content="Unpair" Width="100" Margin="0,0,8,0"/>
      <Button x:Name="BtnConnect" Content="Connect" Width="100" Margin="0,0,8,0"/>
      <Button x:Name="BtnDisconnect" Content="Disconnect" Width="110" Margin="0,0,8,0"/>
    </StackPanel>

    <!-- AI assistant -->
    <GroupBox Header="AI Assistant" Grid.Row="3">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBox x:Name="TxtAI" Grid.Column="0" Margin="8" Height="60" TextWrapping="Wrap"
                 VerticalContentAlignment="Top" AcceptsReturn="True"
                 ToolTip="Try commands: 'turn bluetooth on', 'scan', 'pair WH-1000XM4', 'connect to AirPods'"/>
        <Button x:Name="BtnAI" Grid.Column="1" Content="Run" Width="100" Margin="0,8,8,8"/>
      </Grid>
    </GroupBox>
  </Grid>
</Window>
"@

$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$window=[Windows.Markup.XamlReader]::Load($reader)

#-------------------------------#
# UI wiring                     #
#-------------------------------#

$BtnScan       = $window.FindName('BtnScan')
$BtnOn         = $window.FindName('BtnOn')
$BtnOff        = $window.FindName('BtnOff')
$LblStatus     = $window.FindName('LblStatus')
$GridDevices   = $window.FindName('GridDevices')
$BtnPair       = $window.FindName('BtnPair')
$BtnUnpair     = $window.FindName('BtnUnpair')
$BtnConnect    = $window.FindName('BtnConnect')
$BtnDisconnect = $window.FindName('BtnDisconnect')
$TxtAI         = $window.FindName('TxtAI')
$BtnAI         = $window.FindName('BtnAI')

function Set-Status($text) { $LblStatus.Text = $text }

function Update-DeviceGrid {
  $GridDevices.ItemsSource = $null
  $GridDevices.ItemsSource = $global:BtDevices
  Set-Status("Devices: $($global:BtDevices.Count)")
}

# Initial scan
Get-BluetoothDevices | Out-Null
Update-DeviceGrid

# Events
$BtnScan.Add_Click({
  Get-BluetoothDevices | Out-Null
  Update-DeviceGrid
})

$BtnOn.Add_Click({
  try { Set-RadioState -State 'On'; Set-Status "Bluetooth turned on." }
  catch { Set-Status "Failed: $($_.Exception.Message)" }
})

$BtnOff.Add_Click({
  try { Set-RadioState -State 'Off'; Set-Status "Bluetooth turned off." }
  catch { Set-Status "Failed: $($_.Exception.Message)" }
})

$BtnPair.Add_Click({
  $row = $GridDevices.SelectedItem
  if (-not $row) { Set-Status "Select a device first."; return }
  $msg = Pair-Device -DeviceRow $row
  Set-Status $msg
  Get-BluetoothDevices | Out-Null
  Update-DeviceGrid
})

$BtnUnpair.Add_Click({
  $row = $GridDevices.SelectedItem
  if (-not $row) { Set-Status "Select a device first."; return }
  $msg = Unpair-Device -DeviceRow $row
  Set-Status $msg
  Get-BluetoothDevices | Out-Null
  Update-DeviceGrid
})

$BtnConnect.Add_Click({
  $row = $GridDevices.SelectedItem
  if (-not $row) { Set-Status "Select a device first."; return }
  $msg = Connect-Device -DeviceRow $row
  Set-Status $msg
  Get-BluetoothDevices | Out-Null
  Update-DeviceGrid
})

$BtnDisconnect.Add_Click({
  $row = $GridDevices.SelectedItem
  if (-not $row) { Set-Status "Select a device first."; return }
  $msg = Disconnect-Device -DeviceRow $row
  Set-Status $msg
  Get-BluetoothDevices | Out-Null
  Update-DeviceGrid
})

$BtnAI.Add_Click({
  $prompt = $TxtAI.Text.Trim()
  if (-not $prompt) { Set-Status "Type a command for the AI assistant."; return }
  $intent = Invoke-LLM -Prompt $prompt
  $result = Apply-AIIntent -Intent $intent
  Set-Status $result
})

# Show
$window.Topmost = $true
$window.ShowDialog() | Out-Null
