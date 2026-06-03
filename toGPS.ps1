Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

#-------------------------#
#  XAML UI LAYOUT         #
#-------------------------#
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Ham Radio AI + GPS Console"
        Height="600" Width="1000"
        WindowStartupLocation="CenterScreen"
        Background="#111111"
        Foreground="#EEEEEE">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="2*"/>
            <RowDefinition Height="2*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="2*"/>
            <ColumnDefinition Width="3*"/>
        </Grid.ColumnDefinitions>

        <!-- HEADER -->
        <StackPanel Grid.Row="0" Grid.ColumnSpan="2" Orientation="Horizontal" Margin="0,0,0,10">
            <TextBlock Text="Ham Radio AI + GPS" FontSize="20" FontWeight="Bold" Margin="0,0,20,0"/>
            <TextBlock Text="Local, script-based control" FontSize="12" Opacity="0.7" VerticalAlignment="Bottom"/>
        </StackPanel>

        <!-- HAM RADIO PANEL -->
        <GroupBox Grid.Row="1" Grid.Column="0" Header="Ham Radio" Margin="0,0,10,10">
            <Grid Margin="5">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <TextBlock Grid.Row="0" Grid.Column="0" Text="Frequency (MHz):" Margin="0,0,5,5" VerticalAlignment="Center"/>
                <TextBox   Grid.Row="0" Grid.Column="1" Name="txtFreq" Text="145.500" Margin="0,0,5,5"/>

                <TextBlock Grid.Row="1" Grid.Column="0" Text="Mode:" Margin="0,0,5,5" VerticalAlignment="Center"/>
                <ComboBox Grid.Row="1" Grid.Column="1" Name="cmbMode" Margin="0,0,5,5">
                    <ComboBoxItem Content="FM" IsSelected="True"/>
                    <ComboBoxItem Content="SSB"/>
                    <ComboBoxItem Content="AM"/>
                    <ComboBoxItem Content="CW"/>
                    <ComboBoxItem Content="DIGI"/>
                </ComboBox>

                <StackPanel Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,5,0,5">
                    <Button Name="btnSetFreq" Content="Set Freq" Width="80" Margin="0,0,5,0"/>
                    <Button Name="btnPTTOn"   Content="PTT ON"  Width="80" Margin="0,0,5,0" Background="#552222"/>
                    <Button Name="btnPTTOff"  Content="PTT OFF" Width="80" Margin="0,0,5,0" Background="#225522"/>
                    <Button Name="btnLogQSO"  Content="Log QSO" Width="80" Margin="0,0,5,0"/>
                </StackPanel>

                <TextBox Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="3"
                         Name="txtRadioLog"
                         Margin="0,5,0,0"
                         AcceptsReturn="True"
                         VerticalScrollBarVisibility="Auto"
                         TextWrapping="Wrap"
                         Background="#222222"
                         Foreground="#DDDDDD"/>
            </Grid>
        </GroupBox>

        <!-- GPS PANEL -->
        <GroupBox Grid.Row="1" Grid.Column="1" Header="GPS" Margin="0,0,0,10">
            <Grid Margin="5">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <TextBlock Grid.Row="0" Grid.Column="0" Text="GPS COM Port:" Margin="0,0,5,5" VerticalAlignment="Center"/>
                <TextBox   Grid.Row="0" Grid.Column="1" Name="txtGpsPort" Text="COM3" Margin="0,0,5,5"/>
                <Button    Grid.Row="0" Grid.Column="2" Name="btnGpsConnect" Content="Connect" Width="80" Margin="0,0,0,5"/>

                <TextBlock Grid.Row="1" Grid.Column="0" Text="Latitude:" Margin="0,0,5,5" VerticalAlignment="Center"/>
                <TextBox   Grid.Row="1" Grid.Column="1" Name="txtLat" IsReadOnly="True" Margin="0,0,5,5"/>

                <TextBlock Grid.Row="2" Grid.Column="0" Text="Longitude:" Margin="0,0,5,5" VerticalAlignment="Center"/>
                <TextBox   Grid.Row="2" Grid.Column="1" Name="txtLon" IsReadOnly="True" Margin="0,0,5,5"/>
                <Button    Grid.Row="2" Grid.Column="2" Name="btnOpenMap" Content="Map" Width="80" Margin="0,0,0,5"/>

                <TextBox Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="3"
                         Name="txtGpsRaw"
                         Margin="0,5,0,0"
                         AcceptsReturn="True"
                         VerticalScrollBarVisibility="Auto"
                         TextWrapping="Wrap"
                         Background="#222222"
                         Foreground="#DDDDDD"/>
            </Grid>
        </GroupBox>

        <!-- AI PANEL -->
        <GroupBox Grid.Row="2" Grid.ColumnSpan="2" Header="AI Assistant (LLM)" Margin="0,0,0,0">
            <Grid Margin="5">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="3*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="4*"/>
                </Grid.ColumnDefinitions>

                <TextBox Grid.Row="0" Grid.Column="0"
                         Name="txtPrompt"
                         Margin="0,0,5,5"
                         Height="60"
                         AcceptsReturn="True"
                         TextWrapping="Wrap"
                         Background="#222222"
                         Foreground="#DDDDDD"
                         Text="Ask AI about propagation, antenna ideas, or QSO text..."/>
                <StackPanel Grid.Row="0" Grid.Column="1" Orientation="Vertical" Margin="0,0,5,5">
                    <Button Name="btnAskAI" Content="Ask AI" Width="100" Margin="0,0,0,5"/>
                    <TextBlock Text="LLM endpoint is local/scripted" FontSize="10" Opacity="0.7" TextWrapping="Wrap" Width="100"/>
                </StackPanel>
                <TextBox Grid.Row="0" Grid.RowSpan="2" Grid.Column="2"
                         Name="txtAIResponse"
                         Margin="0,0,0,0"
                         AcceptsReturn="True"
                         VerticalScrollBarVisibility="Auto"
                         TextWrapping="Wrap"
                         Background="#222222"
                         Foreground="#DDDDDD"/>

                <TextBox Grid.Row="1" Grid.Column="0"
                         Name="txtAIStatus"
                         Margin="0,5,5,0"
                         Height="40"
                         IsReadOnly="True"
                         Background="#222222"
                         Foreground="#AAAAAA"
                         Text="Status: Idle"/>
            </Grid>
        </GroupBox>
    </Grid>
</Window>
"@

#-------------------------#
#  PARSE XAML             #
#-------------------------#
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Grab controls
$txtFreq       = $window.FindName("txtFreq")
$cmbMode       = $window.FindName("cmbMode")
$btnSetFreq    = $window.FindName("btnSetFreq")
$btnPTTOn      = $window.FindName("btnPTTOn")
$btnPTTOff     = $window.FindName("btnPTTOff")
$btnLogQSO     = $window.FindName("btnLogQSO")
$txtRadioLog   = $window.FindName("txtRadioLog")

$txtGpsPort    = $window.FindName("txtGpsPort")
$btnGpsConnect = $window.FindName("btnGpsConnect")
$txtLat        = $window.FindName("txtLat")
$txtLon        = $window.FindName("txtLon")
$btnOpenMap    = $window.FindName("btnOpenMap")
$txtGpsRaw     = $window.FindName("txtGpsRaw")

$txtPrompt     = $window.FindName("txtPrompt")
$btnAskAI      = $window.FindName("btnAskAI")
$txtAIResponse = $window.FindName("txtAIResponse")
$txtAIStatus   = $window.FindName("txtAIStatus")

#-------------------------#
#  GLOBAL STATE           #
#-------------------------#
$global:GpsPort = $null
$global:GpsTimer = $null

#-------------------------#
#  HELPER: LOGGING        #
#-------------------------#
function Add-RadioLog {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $txtRadioLog.AppendText("[$timestamp] $Message`r`n")
    $txtRadioLog.ScrollToEnd()
}

function Set-AIStatus {
    param([string]$Message)
    $txtAIStatus.Text = "Status: $Message"
}

#-------------------------#
#  HAM RADIO HOOKS        #
#-------------------------#
function Set-RadioFrequency {
    param(
        [double]$FrequencyMHz,
        [string]$Mode
    )
    # TODO: Implement your CAT / rig control here.
    # Example: send CAT commands over serial or TCP to your radio.
    Add-RadioLog "Set frequency to $FrequencyMHz MHz, mode $Mode (stub)."
}

function Set-PTT {
    param([bool]$On)
    # TODO: Implement PTT control (serial line, GPIO, etc.)
    if ($On) {
        Add-RadioLog "PTT ON (stub)."
    } else {
        Add-RadioLog "PTT OFF (stub)."
    }
}

function Log-QSO {
    # TODO: Extend with callsign, RST, etc.
    Add-RadioLog "QSO logged (stub)."
}

#-------------------------#
#  GPS HANDLING           #
#-------------------------#
function Open-GpsPort {
    param([string]$PortName)

    if ($global:GpsPort -and $global:GpsPort.IsOpen) {
        $global:GpsPort.Close()
        $global:GpsPort.Dispose()
        $global:GpsPort = $null
    }

    try {
        $port = New-Object System.IO.Ports.SerialPort $PortName,4800,'None',8,1
        $port.NewLine = "`r`n"
        $port.Open()
        $global:GpsPort = $port
        $txtGpsRaw.AppendText("Opened GPS port $PortName`r`n")
        $txtGpsRaw.ScrollToEnd()
        return $true
    } catch {
        $txtGpsRaw.AppendText("Failed to open $PortName: $($_.Exception.Message)`r`n")
        $txtGpsRaw.ScrollToEnd()
        return $false
    }
}

function Parse-Nmea-GGA {
    param([string]$Sentence)

    # Very minimal NMEA GGA parser for lat/lon
    # Example: $GPGGA,123519,4807.038,N,01131.000,E,1,...
    $parts = $Sentence.Split(',')
    if ($parts.Count -lt 6) { return $null }

    $latRaw = $parts[2]
    $latHem = $parts[3]
    $lonRaw = $parts[4]
    $lonHem = $parts[5]

    if (-not $latRaw -or -not $lonRaw) { return $null }

    # Convert ddmm.mmmm to decimal degrees
    function Convert-NmeaCoord {
        param([string]$raw, [string]$hem, [int]$degLen)

        if ($raw.Length -lt $degLen) { return $null }
        $deg = [double]$raw.Substring(0,$degLen)
        $min = [double]$raw.Substring($degLen)
        $dec = $deg + ($min / 60.0)
        if ($hem -eq 'S' -or $hem -eq 'W') { $dec = -$dec }
        return $dec
    }

    $lat = Convert-NmeaCoord -raw $latRaw -hem $latHem -degLen 2
    $lon = Convert-NmeaCoord -raw $lonRaw -hem $lonHem -degLen 3

    if ($lat -and $lon) {
        return [PSCustomObject]@{
            Lat = [math]::Round($lat, 6)
            Lon = [math]::Round($lon, 6)
        }
    }
    return $null
}

function Start-GpsTimer {
    if ($global:GpsTimer) {
        $global:GpsTimer.Stop()
        $global:GpsTimer = $null
    }

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Add_Tick({
        if (-not $global:GpsPort -or -not $global:GpsPort.IsOpen) { return }

        try {
            while ($global:GpsPort.BytesToRead -gt 0) {
                $line = $global:GpsPort.ReadLine().Trim()
                if (-not $line) { continue }

                $txtGpsRaw.AppendText("$line`r`n")
                $txtGpsRaw.ScrollToEnd()

                if ($line.StartsWith('$GPGGA') -or $line.StartsWith('$GNGGA')) {
                    $pos = Parse-Nmea-GGA -Sentence $line
                    if ($pos) {
                        $txtLat.Text = $pos.Lat.ToString()
                        $txtLon.Text = $pos.Lon.ToString()
                    }
                }
            }
        } catch {
            $txtGpsRaw.AppendText("GPS read error: $($_.Exception.Message)`r`n")
            $txtGpsRaw.ScrollToEnd()
        }
    })
    $timer.Start()
    $global:GpsTimer = $timer
}

#-------------------------#
#  AI LLM HOOK            #
#-------------------------#
function Invoke-LocalLLM {
    param(
        [string]$Prompt,
        [string]$Lat,
        [string]$Lon
    )

    # TODO: Replace this stub with your local LLM call.
    # Example patterns:
    # - Call a local HTTP endpoint (Ollama, LM Studio, custom FastAPI, etc.)
    # - Call a local CLI and capture stdout.
    #
    # This stub just echoes context.

    $context = ""
    if ($Lat -and $Lon) {
        $context = "Current GPS: lat=$Lat, lon=$Lon. "
    }

    $response = @"
[Stub LLM]
Context: $context
Prompt: $Prompt

Here you would see the real LLM answer (propagation tips, antenna ideas, QSO text, etc.).
"@
    return $response
}

#-------------------------#
#  EVENT HANDLERS         #
#-------------------------#

# Set frequency
$btnSetFreq.Add_Click({
    try {
        $freq = [double]$txtFreq.Text
        $modeItem = $cmbMode.SelectedItem
        $mode = if ($modeItem -and $modeItem.Content) { $modeItem.Content.ToString() } else { "FM" }
        Set-RadioFrequency -FrequencyMHz $freq -Mode $mode
    } catch {
        Add-RadioLog "Invalid frequency: $($_.Exception.Message)"
    }
})

# PTT ON/OFF
$btnPTTOn.Add_Click({
    Set-PTT -On $true
})
$btnPTTOff.Add_Click({
    Set-PTT -On $false
})

# Log QSO
$btnLogQSO.Add_Click({
    Log-QSO
})

# GPS Connect
$btnGpsConnect.Add_Click({
    $portName = $txtGpsPort.Text
    if ([string]::IsNullOrWhiteSpace($portName)) { return }

    if (Open-GpsPort -PortName $portName) {
        Start-GpsTimer
    }
})

# Open map
$btnOpenMap.Add_Click({
    $lat = $txtLat.Text
    $lon = $txtLon.Text
    if (-not $lat -or -not $lon) { return }
    $url = "https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=15/$lat/$lon"
    Start-Process $url
})

# Ask AI
$btnAskAI.Add_Click({
    $prompt = $txtPrompt.Text.Trim()
    if (-not $prompt) { return }

    Set-AIStatus "Querying LLM (stub)..."
    $txtAIResponse.Text = ""

    # In a real app, you might run this in a background job/thread.
    $lat = $txtLat.Text
    $lon = $txtLon.Text

    $response = Invoke-LocalLLM -Prompt $prompt -Lat $lat -Lon $lon
    $txtAIResponse.Text = $response
    Set-AIStatus "Idle"
})

#-------------------------#
#  SHOW WINDOW            #
#-------------------------#
$window.Add_Closed({
    if ($global:GpsTimer) { $global:GpsTimer.Stop() }
    if ($global:GpsPort -and $global:GpsPort.IsOpen) {
        $global:GpsPort.Close()
        $global:GpsPort.Dispose()
    }
})

[void]$window.ShowDialog()
