<# 
.SYNOPSIS
  SSD Trim GUI with AI Assistant (single-file .ps1)

.NOTES
  - Admin-aware: auto-elevates if needed
  - Lists NTFS volumes, detects SSDs, runs ReTrim, and reports results
  - Optional AI assistant: send system status to an LLM endpoint for maintenance tips
  - No external modules required (Windows PowerShell 5.1+)
#>

#region Admin check & prerequisites
function Ensure-Admin {
    $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
    if (-not $prp.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Elevation required. Relaunching as Administrator..."
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}
Ensure-Admin

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

#endregion

#region XAML UI
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSD Trim & AI Assistant" Height="680" Width="1000"
        WindowStartupLocation="CenterScreen" Background="#1e1e1e" Foreground="#e6e6e6">
  <Grid Margin="16">
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="2*"/>
      <ColumnDefinition Width="3*"/>
    </Grid.ColumnDefinitions>
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <StackPanel Grid.ColumnSpan="2" Orientation="Horizontal" Margin="0,0,0,12">
      <TextBlock Text="SSD Trim & AI Assistant" FontSize="20" FontWeight="Bold"/>
      <TextBlock Text="  —  Admin mode" Margin="8,0,0,0" Opacity="0.7"/>
    </StackPanel>

    <!-- Left: Volumes -->
    <GroupBox Grid.Row="1" Grid.Column="0" Header="Volumes" Margin="0,0,12,0">
      <DockPanel>
        <StackPanel Orientation="Horizontal" DockPanel.Dock="Top" Margin="0,0,0,8">
          <Button x:Name="BtnRefresh" Content="Refresh" Width="100" Margin="0,0,8,0"/>
          <Button x:Name="BtnTrimSelected" Content="ReTrim selected" Width="140" Margin="0,0,8,0"/>
          <Button x:Name="BtnTrimAll" Content="ReTrim all SSD NTFS" Width="160"/>
        </StackPanel>
        <DataGrid x:Name="GridVolumes" AutoGenerateColumns="False" IsReadOnly="True"
                  CanUserAddRows="False" CanUserDeleteRows="False"
                  HeadersVisibility="Column" GridLinesVisibility="Horizontal"
                  AlternationCount="2" AlternatingRowBackground="#222"
                  RowBackground="#1a1a1a">
          <DataGrid.Columns>
            <DataGridTextColumn Header="Drive" Binding="{Binding DriveLetter}" Width="60"/>
            <DataGridTextColumn Header="Label" Binding="{Binding FileSystemLabel}" Width="120"/>
            <DataGridTextColumn Header="FS" Binding="{Binding FileSystem}" Width="60"/>
            <DataGridTextColumn Header="Type" Binding="{Binding MediaType}" Width="80"/>
            <DataGridTextColumn Header="Health" Binding="{Binding HealthStatus}" Width="90"/>
            <DataGridTextColumn Header="Size (GB)" Binding="{Binding SizeGB}" Width="90"/>
            <DataGridTextColumn Header="Free (GB)" Binding="{Binding FreeGB}" Width="90"/>
            <DataGridTextColumn Header="Trim Supported" Binding="{Binding TrimSupported}" Width="110"/>
          </DataGrid.Columns>
        </DataGrid>
      </DockPanel>
    </GroupBox>

    <!-- Right: Logs + AI -->
    <GroupBox Grid.Row="1" Grid.Column="1" Header="Logs and AI Assistant">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="2*"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Logs -->
        <TextBox x:Name="TxtLog" Grid.Row="0" TextWrapping="Wrap" AcceptsReturn="True"
                 VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                 FontFamily="Consolas" FontSize="12" Background="#0f0f0f"/>

        <!-- AI Config -->
        <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,8,0,8">
          <TextBlock Text="LLM Endpoint:" Width="100" VerticalAlignment="Center"/>
          <TextBox x:Name="TxtEndpoint" Width="280" Margin="8,0,8,0" Text="https://api.example.com/v1/chat"/>
          <TextBlock Text="API Key:" Width="70" VerticalAlignment="Center"/>
          <PasswordBox x:Name="TxtApiKey" Width="200" Margin="8,0,8,0"/>
          <TextBlock Text="Model:" Width="60" VerticalAlignment="Center"/>
          <TextBox x:Name="TxtModel" Width="160" Text="my-llm-model"/>
        </StackPanel>

        <!-- AI Prompt -->
        <StackPanel Grid.Row="2">
          <TextBlock Text="AI Prompt (maintenance tips):" Margin="0,0,0,4"/>
          <TextBox x:Name="TxtPrompt" Height="120" TextWrapping="Wrap" AcceptsReturn="True"
                   VerticalScrollBarVisibility="Auto" Background="#0f0f0f">
SSD TRIM status report attached. Suggest safe maintenance steps for SSDs and NTFS volumes. Prioritize admin-safe, reversible actions.
          </TextBox>
        </StackPanel>

        <!-- AI Actions -->
        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,8,0,0">
          <Button x:Name="BtnBuildContext" Content="Build system context" Width="160" Margin="0,0,8,0"/>
          <Button x:Name="BtnAskAI" Content="Ask AI" Width="100"/>
        </StackPanel>
      </Grid>
    </GroupBox>

    <!-- Footer -->
    <StackPanel Grid.Row="2" Grid.ColumnSpan="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
      <TextBlock x:Name="TxtStatus" Text="Ready." VerticalAlignment="Center" Margin="0,0,12,0"/>
      <Button x:Name="BtnExportLog" Content="Export log" Width="100"/>
      <Button x:Name="BtnSchedule" Content="Schedule weekly TRIM" Margin="8,0,0,0" Width="160"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader ([xml]$Xaml))
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Controls
$GridVolumes   = $Window.FindName('GridVolumes')
$BtnRefresh    = $Window.FindName('BtnRefresh')
$BtnTrimSelected = $Window.FindName('BtnTrimSelected')
$BtnTrimAll    = $Window.FindName('BtnTrimAll')
$TxtLog        = $Window.FindName('TxtLog')
$TxtStatus     = $Window.FindName('TxtStatus')
$BtnExportLog  = $Window.FindName('BtnExportLog')
$BtnSchedule   = $Window.FindName('BtnSchedule')
$TxtEndpoint   = $Window.FindName('TxtEndpoint')
$TxtApiKey     = $Window.FindName('TxtApiKey')
$TxtModel      = $Window.FindName('TxtModel')
$TxtPrompt     = $Window.FindName('TxtPrompt')
$BtnAskAI      = $Window.FindName('BtnAskAI')
$BtnBuildContext = $Window.FindName('BtnBuildContext')

#endregion

#region Helpers
function Log {
    param([string]$Message)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $TxtLog.AppendText("[$ts] $Message`r`n")
    $TxtLog.ScrollToEnd()
    $TxtStatus.Text = $Message
}

function Get-VolumeData {
    # Map volumes to physical disks to detect SSD and TRIM support
    $vols = Get-Volume | Where-Object { $_.FileSystem -eq 'NTFS' -and $_.DriveLetter } | Sort-Object DriveLetter
    $disks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, DeviceId
    $parts = Get-Partition | Select-Object DiskNumber, DriveLetter

    $rows = foreach ($v in $vols) {
        $diskNum = ($parts | Where-Object { $_.DriveLetter -eq $v.DriveLetter }).DiskNumber
        $phy = $null
        if ($diskNum -ne $null) {
            # Try match via DeviceId==DiskNumber when available, fallback by index
            $phy = $disks | Where-Object { $_.DeviceId -eq $diskNum } | Select-Object -First 1
            if (-not $phy) { $phy = $disks | Select-Object -Index $diskNum -ErrorAction Ignore }
        }
        $mediaType = if ($phy) { $phy.MediaType } else { 'Unknown' }
        $health = if ($phy) { $phy.HealthStatus } else { $v.HealthStatus }

        # Check TRIM support via fsutil (NTFS DisableDeleteNotify==0 indicates TRIM enabled)
        $trimSupported = $false
        try {
            $out = (fsutil behavior query DisableDeleteNotify 2>$null)
            # Expected lines:
            #   NTFS DisableDeleteNotify = 0 (Disabled=1, Enabled=0)
            if ($out -match 'NTFS DisableDeleteNotify\s*=\s*0') { $trimSupported = $true }
        } catch { $trimSupported = $false }

        [PSCustomObject]@{
            DriveLetter    = "$($v.DriveLetter):"
            FileSystemLabel= $v.FileSystemLabel
            FileSystem     = $v.FileSystem
            MediaType      = $mediaType
            HealthStatus   = $health
            SizeGB         = [math]::Round($v.Size/1GB,2)
            FreeGB         = [math]::Round($v.SizeRemaining/1GB,2)
            TrimSupported  = $trimSupported
        }
    }
    return ,$rows
}

function Refresh-Volumes {
    try {
        $data = Get-VolumeData
        $GridVolumes.ItemsSource = $data
        Log "Refreshed volumes. Found $($data.Count) NTFS volumes."
    } catch {
        Log "Failed to refresh volumes: $($_.Exception.Message)"
    }
}

function Optimize-Target {
    param(
        [Parameter(Mandatory=$true)][string]$DriveLetter
    )
    try {
        Log "Starting ReTrim on $DriveLetter ..."
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Optimize-Volume -DriveLetter $DriveLetter.TrimEnd(':') -ReTrim -Verbose -ErrorAction Stop
        $sw.Stop()
        Log "Completed ReTrim on $DriveLetter in $([math]::Round($sw.Elapsed.TotalSeconds,2))s."
        Log ($result | Out-String).Trim()
    } catch {
        Log "ReTrim failed on $DriveLetter: $($_.Exception.Message)"
    }
}

function Optimize-AllSSD {
    try {
        $rows = $GridVolumes.ItemsSource
        $targets = $rows | Where-Object { $_.FileSystem -eq 'NTFS' -and $_.TrimSupported -eq $true -and $_.MediaType -match 'SSD|SolidState' }
        if (-not $targets -or $targets.Count -eq 0) {
            Log "No SSD NTFS volumes with TRIM enabled found."
            return
        }
        foreach ($t in $targets) {
            Optimize-Target -DriveLetter $t.DriveLetter
        }
        Log "All eligible SSD volumes retrimmed."
    } catch {
        Log "Batch ReTrim failed: $($_.Exception.Message)"
    }
}

function Build-SystemContext {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        $pd = Get-PhysicalDisk | Select FriendlyName, MediaType, HealthStatus, Size
        $vol = Get-Volume | Select DriveLetter, FileSystemLabel, FileSystem, Size, SizeRemaining, HealthStatus

        $trimQuery = (fsutil behavior query DisableDeleteNotify 2>$null)
        $context = [pscustomobject]@{
            Hostname = $env:COMPUTERNAME
            OS       = "$($os.Caption) $($os.Version) $($os.OSArchitecture)"
            MemoryGB = [math]::Round($cs.TotalPhysicalMemory/1GB,2)
            Disks    = ($pd | ConvertTo-Json -Depth 3)
            Volumes  = ($vol | ConvertTo-Json -Depth 3)
            TrimInfo = $trimQuery
            Timestamp= (Get-Date).ToString("o")
        }

        $json = $context | ConvertTo-Json -Depth 5
        $TxtLog.AppendText("---- SYSTEM CONTEXT JSON ----`r`n$json`r`n------------------------------`r`n")
        $TxtLog.ScrollToEnd()
        Log "Built system context for AI."
        return $json
    } catch {
        Log "Failed to build system context: $($_.Exception.Message)"
        return "{}"
    }
}

function Ask-AI {
    param(
        [string]$Endpoint,
        [string]$ApiKey,
        [string]$Model,
        [string]$Prompt,
        [string]$ContextJson
    )
    if ([string]::IsNullOrWhiteSpace($Endpoint)) { Log "LLM endpoint is required."; return }
    if ([string]::IsNullOrWhiteSpace($Model)) { Log "LLM model is required."; return }
    if ([string]::IsNullOrWhiteSpace($Prompt)) { Log "Prompt is required."; return }

    try {
        $body = @{
            model = $Model
            messages = @(
                @{ role="system"; content="You are a cautious Windows storage assistant. Provide admin-safe, reversible SSD maintenance advice." },
                @{ role="user"; content=$Prompt },
                @{ role="user"; content="System context:" },
                @{ role="user"; content=$ContextJson }
            )
            temperature = 0.2
        } | ConvertTo-Json -Depth 6

        $headers = @{}
        if ($ApiKey) { $headers["Authorization"] = "Bearer $ApiKey" }
        $headers["Content-Type"] = "application/json"

        Log "Sending request to LLM..."
        $resp = Invoke-RestMethod -Method Post -Uri $Endpoint -Headers $headers -Body $body -TimeoutSec 60
        # Adapt to common chat completion shape
        $text =
            $resp.choices[0].message.content `
            -or $resp.choices[0].text `
            -or ($resp | ConvertTo-Json -Depth 6)

        $TxtLog.AppendText("---- AI RESPONSE ----`r`n$text`r`n------------------`r`n")
        $TxtLog.ScrollToEnd()
        Log "AI response received."
    } catch {
        Log "AI request failed: $($_.Exception.Message)"
    }
}

function Export-Log {
    try {
        $path = Join-Path $env:TEMP ("SSD-Trim-Log_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".txt")
        Set-Content -Path $path -Value $TxtLog.Text -Encoding UTF8
        Log "Log exported: $path"
    } catch {
        Log "Failed to export log: $($_.Exception.Message)"
    }
}

function Schedule-WeeklyTrim {
    try {
        $taskName = "SSD_ReTrim_Weekly"
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"Optimize-Volume -ReTrim -DriveLetter (Get-Volume | ? FileSystem -eq 'NTFS' | % DriveLetter)`""
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 03:00
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
        Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null
        Log "Scheduled weekly TRIM as task '$taskName' (Sun 03:00, SYSTEM)."
    } catch {
        Log "Failed to schedule TRIM: $($_.Exception.Message)"
    }
}
#endregion

#region Wire up events
$BtnRefresh.Add_Click({ Refresh-Volumes })
$BtnTrimSelected.Add_Click({
    $sel = $GridVolumes.SelectedItem
    if ($sel -and $sel.DriveLetter) { Optimize-Target -DriveLetter $sel.DriveLetter }
    else { Log "Select a volume first." }
})
$BtnTrimAll.Add_Click({ Optimize-AllSSD })
$BtnExportLog.Add_Click({ Export-Log })
$BtnSchedule.Add_Click({ Schedule-WeeklyTrim })

$BtnBuildContext.Add_Click({
    $null = Build-SystemContext
})

$BtnAskAI.Add_Click({
    $ctx = Build-SystemContext
    Ask-AI -Endpoint $TxtEndpoint.Text -ApiKey $TxtApiKey.Password -Model $TxtModel.Text -Prompt $TxtPrompt.Text -ContextJson $ctx
})

#endregion

#region Initial load
Refresh-Volumes
Log "Ready."
#endregion

# Show UI
$Window.Topmost = $false
$Window.ShowDialog() | Out-Null
