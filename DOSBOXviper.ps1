<# 
    AI LLM DOSBox App - Single-file WPF GUI
    Save as: AiDosbox.ps1
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

#-------------------------
# Helpers
#-------------------------
function New-LogLine {
    param([string]$Text)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    return "[${ts}] $Text"
}

function Show-Error {
    param([string]$Msg)
    $global:TxtLog.AppendText((New-LogLine "ERROR: $Msg") + "`r`n")
    $global:TxtLog.ScrollToEnd()
}

function Show-Info {
    param([string]$Msg)
    $global:TxtLog.AppendText((New-LogLine "$Msg") + "`r`n")
    $global:TxtLog.ScrollToEnd()
}

#-------------------------
# XAML
#-------------------------
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI LLM DOSBox App" Height="700" Width="1000"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResize">
    <Grid Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="2*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- DOSBox Settings -->
        <GroupBox Header="DOSBox settings" Grid.Row="0" Margin="0,0,0,10">
            <Grid Margin="8">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="150"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Grid.Column="0" Text="DOSBox executable:" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBox   Grid.Row="0" Grid.Column="1" Name="TxtDosboxPath" Margin="0,0,8,0"/>
                <Button    Grid.Row="0" Grid.Column="2" Name="BtnBrowseDosbox" Content="Browse..." Padding="10,4" Margin="0,0,0,0"/>

                <TextBlock Grid.Row="1" Grid.Column="0" Text="Mount folder:" VerticalAlignment="Center" Margin="0,8,8,0"/>
                <TextBox   Grid.Row="1" Grid.Column="1" Name="TxtMountPath" Margin="0,8,8,0"/>
                <Button    Grid.Row="1" Grid.Column="2" Name="BtnBrowseMount" Content="Browse..." Padding="10,4" Margin="0,8,0,0"/>

                <TextBlock Grid.Row="2" Grid.Column="0" Text="Drive letter to mount:" VerticalAlignment="Center" Margin="0,8,8,0"/>
                <TextBox   Grid.Row="2" Grid.Column="1" Name="TxtDriveLetter" Margin="0,8,8,0" Text="C"/>

                <TextBlock Grid.Row="3" Grid.Column="0" Text="Autoexec commands (one per line):" VerticalAlignment="Center" Margin="0,8,8,0"/>
                <TextBox   Grid.Row="3" Grid.Column="1" Name="TxtAutoexec" Margin="0,8,8,0" AcceptsReturn="True" Height="90" VerticalScrollBarVisibility="Auto"/>
            </Grid>
        </GroupBox>

        <!-- Controls -->
        <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Left">
            <Button Name="BtnStart" Content="Start DOSBox" Padding="12,6" Margin="0,0,8,10"/>
            <Button Name="BtnStop"  Content="Stop DOSBox"  Padding="12,6" Margin="0,0,8,10" IsEnabled="False"/>
            <Button Name="BtnClear" Content="Clear Log"     Padding="12,6" Margin="0,0,8,10"/>
        </StackPanel>

        <!-- Log -->
        <GroupBox Header="Log" Grid.Row="2" Margin="0,0,0,10">
            <Grid Margin="8">
                <TextBox Name="TxtLog" IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" AcceptsReturn="True"/>
            </Grid>
        </GroupBox>

        <!-- LLM Panel -->
        <GroupBox Header="LLM assistant" Grid.Row="3" Margin="0,0,0,10">
            <Grid Margin="8">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Grid.Column="0" Text="Endpoint URL:" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBox   Grid.Row="0" Grid.Column="0" Name="TxtEndpoint" Margin="100,0,8,0" Text="http://localhost:8080/v1/chat/completions"/>
                <TextBlock Grid.Row="0" Grid.Column="1" Text="API key:" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <PasswordBox Grid.Row="0" Grid.Column="1" Name="PwdApiKey" Margin="60,0,0,0"/>

                <TextBlock Grid.Row="1" Grid.Column="0" Text="Model:" VerticalAlignment="Center" Margin="0,8,8,0"/>
                <TextBox   Grid.Row="1" Grid.Column="0" Name="TxtModel" Margin="60,8,8,0" Text="gpt-4.1-mini"/>
                <TextBlock Grid.Row="1" Grid.Column="1" Text="Temperature:" VerticalAlignment="Center" Margin="0,8,8,0"/>
                <TextBox   Grid.Row="1" Grid.Column="1" Name="TxtTemp" Margin="95,8,0,0" Text="0.2"/>

                <TextBlock Grid.Row="2" Grid.Column="0" Text="System prompt:" VerticalAlignment="Center" Margin="0,8,8,0"/>
                <TextBox   Grid.Row="2" Grid.Column="0" Name="TxtSystem" Margin="100,8,8,0" Text="You are a concise DOSBox assistant. Return exact commands and short notes."/>
                <TextBlock Grid.Row="2" Grid.Column="1" Text="User prompt:" VerticalAlignment="Center" Margin="0,8,8,0"/>
                <TextBox   Grid.Row="2" Grid.Column="1" Name="TxtUser" Margin="80,8,0,0" AcceptsReturn="True" Height="80" Text="Mount my game folder and run SETUP.EXE with Sound Blaster defaults."/>

                <TextBlock Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="2" Text="Response:" Margin="0,8,0,4"/>
                <TextBox   Grid.Row="4" Grid.Column="0" Grid.ColumnSpan="2" Name="TxtResponse" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" Height="140" TextWrapping="Wrap"/>

                <StackPanel Grid.Row="5" Grid.Column="0" Orientation="Horizontal" HorizontalAlignment="Left" Margin="0,8,0,0">
                    <Button Name="BtnSend" Content="Ask LLM" Padding="12,6" Margin="0,0,8,0"/>
                    <Button Name="BtnCopyToAutoexec" Content="Append to autoexec" Padding="12,6"/>
                </StackPanel>
            </Grid>
        </GroupBox>

        <!-- Footer -->
        <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button Name="BtnExit" Content="Exit" Padding="12,6"/>
        </StackPanel>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader([xml]$Xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

#-------------------------
# Control refs
#-------------------------
$global:TxtDosboxPath   = $Window.FindName('TxtDosboxPath')
$global:BtnBrowseDosbox = $Window.FindName('BtnBrowseDosbox')
$global:TxtMountPath    = $Window.FindName('TxtMountPath')
$global:BtnBrowseMount  = $Window.FindName('BtnBrowseMount')
$global:TxtDriveLetter  = $Window.FindName('TxtDriveLetter')
$global:TxtAutoexec     = $Window.FindName('TxtAutoexec')

$global:BtnStart        = $Window.FindName('BtnStart')
$global:BtnStop         = $Window.FindName('BtnStop')
$global:BtnClear        = $Window.FindName('BtnClear')

$global:TxtLog          = $Window.FindName('TxtLog')

$global:TxtEndpoint     = $Window.FindName('TxtEndpoint')
$global:PwdApiKey       = $Window.FindName('PwdApiKey')
$global:TxtModel        = $Window.FindName('TxtModel')
$global:TxtTemp         = $Window.FindName('TxtTemp')
$global:TxtSystem       = $Window.FindName('TxtSystem')
$global:TxtUser         = $Window.FindName('TxtUser')
$global:TxtResponse     = $Window.FindName('TxtResponse')
$global:BtnSend         = $Window.FindName('BtnSend')
$global:BtnCopyToAutoexec = $Window.FindName('BtnCopyToAutoexec')

$global:BtnExit         = $Window.FindName('BtnExit')

#-------------------------
# State
#-------------------------
$global:DosboxProc = $null
$global:TempConfPath = $null

#-------------------------
# File dialogs
#-------------------------
$BtnBrowseDosbox.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Executables (*.exe)|*.exe|All files (*.*)|*.*"
    $ofd.Title = "Select DOSBox executable"
    if ($ofd.ShowDialog() -eq 'OK') {
        $TxtDosboxPath.Text = $ofd.FileName
        Show-Info "Selected DOSBox: $($ofd.FileName)"
    }
})

$BtnBrowseMount.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "Select folder to mount in DOSBox"
    if ($fbd.ShowDialog() -eq 'OK') {
        $TxtMountPath.Text = $fbd.SelectedPath
        Show-Info "Selected mount folder: $($fbd.SelectedPath)"
    }
})

#-------------------------
# DOSBox start/stop
#-------------------------
function Build-Autoexec {
    param([string]$MountPath, [string]$DriveLetter, [string[]]$ExtraLines)

    $lines = New-Object System.Collections.Generic.List[string]
    if ($DriveLetter -match '^[A-Z]$') {
        $lines.Add("mount $DriveLetter `"$MountPath`"")
        $lines.Add("$DriveLetter:")
    } else {
        $lines.Add("echo Invalid drive letter; using C")
        $lines.Add("mount C `"$MountPath`"")
        $lines.Add("C:")
    }

    foreach ($l in $ExtraLines) {
        if ([string]::IsNullOrWhiteSpace($l)) { continue }
        $lines.Add($l.Trim())
    }

    # Add a polite note
    $lines.Add("echo --- AI LLM DOSBox session started ---")

    return $lines
}

function New-TempConf {
    param([string[]]$AutoexecLines)

    $conf = @()
    $conf += "[sdl]"
    $conf += "fullscreen=false"
    $conf += "fulldouble=false"
    $conf += "fullresolution=original"
    $conf += ""
    $conf += "[dosbox]"
    $conf += "captures=capture"
    $conf += ""
    $conf += "[autoexec]"
    foreach ($l in $AutoexecLines) { $conf += $l }

    $temp = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ("dosbox_ai_" + [System.Guid]::NewGuid().ToString() + ".conf"))
    [IO.File]::WriteAllLines($temp, $conf)
    return $temp
}

function Start-Dosbox {
    try {
        $exe = $TxtDosboxPath.Text
        $mount = $TxtMountPath.Text
        $drive = $TxtDriveLetter.Text.Trim().ToUpper()

        if (-not (Test-Path $exe)) { throw "DOSBox executable not found: $exe" }
        if (-not (Test-Path $mount)) { throw "Mount folder not found: $mount" }
        if ($drive -notmatch '^[A-Z]$') { throw "Drive letter must be A-Z" }

        $extra = @()
        if (-not [string]::IsNullOrWhiteSpace($TxtAutoexec.Text)) {
            $extra = $TxtAutoexec.Text -split "`r?`n"  # handles windows newlines
        }

        $auto = Build-Autoexec -MountPath $mount -DriveLetter $drive -ExtraLines $extra
        $global:TempConfPath = New-TempConf -AutoexecLines $auto

        Show-Info "Generated temp conf: $global:TempConfPath"
        $args = @("-conf", "`"$global:TempConfPath`"")
        Show-Info "Starting DOSBox..."
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $exe
        $startInfo.Arguments = [string]::Join(' ', $args)
        $startInfo.UseShellExecute = $true
        $startInfo.WorkingDirectory = [System.IO.Path]::GetDirectoryName($exe)

        $global:DosboxProc = [System.Diagnostics.Process]::Start($startInfo)
        if ($global:DosboxProc) {
            Show-Info "DOSBox PID: $($global:DosboxProc.Id)"
            $BtnStart.IsEnabled = $false
            $BtnStop.IsEnabled = $true
        } else {
            throw "Failed to start DOSBox"
        }
    } catch {
        Show-Error $_.Exception.Message
        if ($global:TempConfPath -and (Test-Path $global:TempConfPath)) {
            Remove-Item -Force $global:TempConfPath -ErrorAction SilentlyContinue
            $global:TempConfPath = $null
        }
    }
}

function Stop-Dosbox {
    try {
        if ($global:DosboxProc -and -not $global:DosboxProc.HasExited) {
            Show-Info "Stopping DOSBox..."
            $global:DosboxProc.CloseMainWindow() | Out-Null
            Start-Sleep -Milliseconds 800
            $global:DosboxProc.Refresh()
            if (-not $global:DosboxProc.HasExited) {
                Show-Info "Forcing DOSBox to exit..."
                $global:DosboxProc.Kill()
            }
        }
    } catch {
        Show-Error $_.Exception.Message
    } finally {
        $BtnStart.IsEnabled = $true
        $BtnStop.IsEnabled = $false
        $global:DosboxProc = $null
        if ($global:TempConfPath -and (Test-Path $global:TempConfPath)) {
            Show-Info "Cleaning temp conf: $global:TempConfPath"
            Remove-Item -Force $global:TempConfPath -ErrorAction SilentlyContinue
            $global:TempConfPath = $null
        }
    }
}

#-------------------------
# LLM call
#-------------------------
function Invoke-LLM {
    param(
        [string]$Endpoint,
        [string]$ApiKey,
        [string]$Model,
        [double]$Temperature,
        [string]$SystemMsg,
        [string]$UserMsg
    )
    try {
        if ([string]::IsNullOrWhiteSpace($Endpoint)) { throw "Endpoint URL is required." }
        if ([string]::IsNullOrWhiteSpace($Model)) { throw "Model is required." }
        if ([string]::IsNullOrWhiteSpace($UserMsg)) { throw "User prompt is required." }

        $headers = @{}
        if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
            $headers["Authorization"] = "Bearer $ApiKey"
        }
        $headers["Content-Type"] = "application/json"

        $body = [ordered]@{
            model = $Model
            temperature = $Temperature
            messages = @(
                @{ role = "system"; content = $SystemMsg },
                @{ role = "user";   content = $UserMsg }
            )
        } | ConvertTo-Json -Depth 6

        Show-Info "Sending request to LLM..."
        $resp = Invoke-RestMethod -Method Post -Uri $Endpoint -Headers $headers -Body $body -TimeoutSec 60 -ErrorAction Stop

        # Try common response shapes: OpenAI-compatible
        $text = $null
        if ($resp.choices && $resp.choices[0].message.content) {
            $text = $resp.choices[0].message.content
        } elseif ($resp.output && $resp.output[0].content) {
            $text = $resp.output[0].content
        } elseif ($resp.content) {
            $text = $resp.content
        } else {
            $text = ($resp | ConvertTo-Json -Depth 8)
        }

        return $text
    } catch {
        Show-Error $_.Exception.Message
        return $null
    }
}

#-------------------------
# Wire up buttons
#-------------------------
$BtnStart.Add_Click({ Start-Dosbox })
$BtnStop.Add_Click({ Stop-Dosbox })
$BtnClear.Add_Click({ $TxtLog.Clear() })

$BtnSend.Add_Click({
    $Endpoint = $TxtEndpoint.Text
    $ApiKey   = $PwdApiKey.Password
    $Model    = $TxtModel.Text
    $Temp     = 0.0
    [double]::TryParse($TxtTemp.Text, [ref]$Temp) | Out-Null
    $System   = $TxtSystem.Text
    $User     = $TxtUser.Text

    $TxtResponse.Text = ""
    $txt = Invoke-LLM -Endpoint $Endpoint -ApiKey $ApiKey -Model $Model -Temperature $Temp -SystemMsg $System -UserMsg $User
    if ($txt) {
        $TxtResponse.Text = $txt
        Show-Info "LLM response received."
    } else {
        Show-Error "No response text."
    }
})

$BtnCopyToAutoexec.Add_Click({
    $r = $TxtResponse.Text
    if ([string]::IsNullOrWhiteSpace($r)) { return }
    # Extract lines that look like DOSBox commands; simple heuristic.
    $lines = ($r -split "`r?`n") | ForEach-Object {
        $_.Trim()
    } | Where-Object {
        $_ -and ($_ -match '^(mount\s+[A-Z]\s+)|(^[A-Z]:$)|(\.exe(\s|$))|(^set\s+)|(^cls$)|(^cd\s+)'
    }

    if ($lines.Count -gt 0) {
        $existing = $TxtAutoexec.Text
        if (-not [string]::IsNullOrWhiteSpace($existing)) {
            $TxtAutoexec.Text = $existing + "`r`n" + ($lines -join "`r`n")
        } else {
            $TxtAutoexec.Text = ($lines -join "`r`n")
        }
        Show-Info "Appended $(($lines.Count)) line(s) to autoexec."
    } else {
        Show-Info "No command-like lines detected to append."
    }
})

$BtnExit.Add_Click({
    try { Stop-Dosbox } catch {}
    $Window.Close()
})

# Ensure cleanup if window closes unexpectedly
$Window.Add_Closing({
    try { Stop-Dosbox } catch {}
})

#-------------------------
# Seed defaults
#-------------------------
# Try to find DOSBox in Program Files
$possible = @(
    "$Env:ProgramFiles\DOSBox-0.74-3\DOSBox.exe",
    "$Env:ProgramFiles\DOSBox-0.74\DOSBox.exe",
    "$Env:ProgramFiles\DOSBox\DOSBox.exe",
    "$Env:ProgramFiles\DOSBox-X\dosbox-x.exe",
    "$Env:ProgramFiles(x86)\DOSBox-0.74-3\DOSBox.exe",
    "$Env:ProgramFiles(x86)\DOSBox\DOSBox.exe",
    "$Env:ProgramFiles(x86)\DOSBox-X\dosbox-x.exe"
)
foreach ($p in $possible) {
    if (Test-Path $p) { $TxtDosboxPath.Text = $p; break }
}

$TxtAutoexec.Text = @"
rem Example:
rem mount C "C:\Games\DOS"
rem C:
rem cd GAME
rem SETUP.EXE
rem GAME.EXE
"@

#-------------------------
# Run
#-------------------------
$Window.ShowDialog() | Out-Null
