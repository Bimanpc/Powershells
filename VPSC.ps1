#requires -version 5.1
<# 
AI LLM Video Player GUI (PowerShell + WPF)
- Media playback: Open, Play/Pause, Stop, Seek, Volume, Mute, Speed
- Playlist: Add/Remove, Double-click to play
- Subtitles: Load external .srt (basic overlay)
- AI Panel: Send prompt with video context (filename, duration, position) to an LLM endpoint and show response
- Admin-safe: no elevation required, no external modules
#>

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, System.Xaml

#-------------------------
# Helper: Simple SRT parser
#-------------------------
function Parse-Srt {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return @() }
    $entries = @()
    $lines = Get-Content -Path $Path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Delimiter "`n`n"
    foreach ($chunk in $lines) {
        $parts = ($chunk -split "`r?`n").Where({ $_ -ne '' })
        if ($parts.Count -ge 2) {
            # Expected format:
            # index
            # hh:mm:ss,ms --> hh:mm:ss,ms
            # text...
            $time = $parts[1]
            $m = [regex]::Match($time, '(\d{2}:\d{2}:\d{2},\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2},\d{3})')
            if ($m.Success) {
                $start = $m.Groups[1].Value
                $end   = $m.Groups[2].Value
                $text  = ($parts[2..($parts.Count-1)]) -join [Environment]::NewLine
                $entries += [pscustomobject]@{
                    Start = [TimeSpan]::ParseExact($start.Replace(',', '.'), 'hh\:mm\:ss\.fff', $null)
                    End   = [TimeSpan]::ParseExact($end.Replace(',', '.'), 'hh\:mm\:ss\.fff', $null)
                    Text  = $text
                }
            }
        }
    }
    return $entries
}

#-------------------------
# Helper: HTTP POST to LLM
#-------------------------
function Invoke-LLM {
    param(
        [string]$Endpoint,
        [hashtable]$Headers,
        [object]$Body
    )
    try {
        $json = $Body | ConvertTo-Json -Depth 8
        $resp = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $Headers -Body $json -ContentType 'application/json'
        return $resp
    } catch {
        return [pscustomobject]@{ error = $_.Exception.Message }
    }
}

#-------------------------
# XAML UI
#-------------------------
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI LLM Video Player" Height="720" Width="1200" Background="#121212" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Margin" Value="6"/>
            <Setter Property="Padding" Value="8,4"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Margin" Value="6"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Margin" Value="6"/>
        </Style>
        <Style TargetType="Slider">
            <Setter Property="Margin" Value="6"/>
        </Style>
        <Style TargetType="ListBox">
            <Setter Property="Margin" Value="6"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="#e0e0e0"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="3*"/>
            <ColumnDefinition Width="2*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Top controls -->
        <DockPanel Grid.Row="0" Grid.Column="0" LastChildFill="False" Margin="8">
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Left">
                <Button x:Name="BtnOpen">Open</Button>
                <Button x:Name="BtnPlay">Play</Button>
                <Button x:Name="BtnPause">Pause</Button>
                <Button x:Name="BtnStop">Stop</Button>
                <Button x:Name="BtnSubtitles">Load SRT</Button>
            </StackPanel>
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
                <Label Content="Speed" VerticalAlignment="Center" />
                <ComboBox x:Name="CmbSpeed" Width="80">
                    <ComboBoxItem Content="0.5x"/>
                    <ComboBoxItem Content="0.75x"/>
                    <ComboBoxItem Content="1.0x"/>
                    <ComboBoxItem Content="1.25x"/>
                    <ComboBoxItem Content="1.5x"/>
                    <ComboBoxItem Content="2.0x"/>
                </ComboBox>
                <Label Content="Volume" VerticalAlignment="Center" />
                <Slider x:Name="SldVolume" Minimum="0" Maximum="1" Value="0.7" Width="120"/>
                <CheckBox x:Name="ChkMute" Content="Mute" Margin="6" Foreground="#e0e0e0"/>
            </StackPanel>
        </DockPanel>

        <!-- Video area -->
        <Grid Grid.Row="1" Grid.Column="0" Margin="8">
            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Border Background="#000000" CornerRadius="6">
                <Grid>
                    <MediaElement x:Name="Player" LoadedBehavior="Manual" UnloadedBehavior="Manual" Stretch="Uniform" />
                    <!-- Subtitle overlay -->
                    <Border VerticalAlignment="Bottom" Background="#00000000" Margin="12">
                        <TextBlock x:Name="TxtSubtitle" Text="" Foreground="White" FontSize="20" TextAlignment="Center" TextWrapping="Wrap" />
                    </Border>
                </Grid>
            </Border>

            <!-- Seek bar -->
            <DockPanel Grid.Row="1" Margin="4,8,4,0">
                <Label x:Name="LblPos" Content="00:00:00" Width="80" />
                <Slider x:Name="SldSeek" Minimum="0" Maximum="100" Value="0" Margin="10,0" />
                <Label x:Name="LblDur" Content="00:00:00" Width="80" />
            </DockPanel>
        </Grid>

        <!-- Right side: Playlist + AI -->
        <Grid Grid.Row="1" Grid.Column="1" Margin="8">
            <Grid.RowDefinitions>
                <RowDefinition Height="2*"/>
                <RowDefinition Height="3*"/>
            </Grid.RowDefinitions>

            <!-- Playlist -->
            <GroupBox Header="Playlist" Margin="0,0,0,8">
                <DockPanel>
                    <StackPanel Orientation="Horizontal" DockPanel.Dock="Top">
                        <Button x:Name="BtnAddToList">Add</Button>
                        <Button x:Name="BtnRemoveFromList">Remove</Button>
                        <Button x:Name="BtnClearList">Clear</Button>
                    </StackPanel>
                    <ListBox x:Name="LstPlaylist" />
                </DockPanel>
            </GroupBox>

            <!-- AI LLM Panel -->
            <GroupBox Header="AI assistant">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <StackPanel Orientation="Horizontal" Grid.Row="0">
                        <Label Content="Endpoint" Width="70"/>
                        <TextBox x:Name="TxtEndpoint" Text="https://api.example.com/v1/chat/completions"/>
                    </StackPanel>

                    <StackPanel Orientation="Horizontal" Grid.Row="1">
                        <Label Content="API key" Width="70"/>
                        <PasswordBox x:Name="TxtApiKey"/>
                    </StackPanel>

                    <TextBox x:Name="TxtPrompt" Grid.Row="2" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" Height="160"
                             Text="Describe the current scene and suggest highlights. Consider timeline position and file name." />

                    <StackPanel Orientation="Horizontal" Grid.Row="3">
                        <Button x:Name="BtnAskAI">Ask AI</Button>
                        <Button x:Name="BtnCopyAI">Copy</Button>
                    </StackPanel>
                </Grid>
            </GroupBox>
        </Grid>

        <!-- AI output -->
        <Grid Grid.Row="2" Grid.ColumnSpan="2" Margin="8">
            <GroupBox Header="AI response">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Height="140">
                    <TextBox x:Name="TxtAIOut" IsReadOnly="True" AcceptsReturn="True" TextWrapping="Wrap" Background="#1e1e1e" Foreground="#e0e0e0"/>
                </ScrollViewer>
            </GroupBox>
        </Grid>
    </Grid>
</Window>
"@

#-------------------------
# Build UI
#-------------------------
$reader = New-Object System.Xml.XmlNodeReader([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Element refs
$Player         = $window.FindName('Player')
$BtnOpen        = $window.FindName('BtnOpen')
$BtnPlay        = $window.FindName('BtnPlay')
$BtnPause       = $window.FindName('BtnPause')
$BtnStop        = $window.FindName('BtnStop')
$BtnSubtitles   = $window.FindName('BtnSubtitles')

$SldVolume      = $window.FindName('SldVolume')
$ChkMute        = $window.FindName('ChkMute')
$CmbSpeed       = $window.FindName('CmbSpeed')

$SldSeek        = $window.FindName('SldSeek')
$LblPos         = $window.FindName('LblPos')
$LblDur         = $window.FindName('LblDur')
$TxtSubtitle    = $window.FindName('TxtSubtitle')

$LstPlaylist    = $window.FindName('LstPlaylist')
$BtnAddToList   = $window.FindName('BtnAddToList')
$BtnRemoveFromList = $window.FindName('BtnRemoveFromList')
$BtnClearList   = $window.FindName('BtnClearList')

$TxtEndpoint    = $window.FindName('TxtEndpoint')
$TxtApiKey      = $window.FindName('TxtApiKey')
$TxtPrompt      = $window.FindName('TxtPrompt')
$BtnAskAI       = $window.FindName('BtnAskAI')
$BtnCopyAI      = $window.FindName('BtnCopyAI')
$TxtAIOut       = $window.FindName('TxtAIOut')

# State
$global:Subtitles = @()
$global:Duration = [TimeSpan]::Zero
$global:UpdatingSeek = $false

#-------------------------
# File dialogs
#-------------------------
function Select-Video {
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Video Files|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.m4v|All Files|*.*"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $ofd.FileName }
}
function Select-Srt {
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "SubRip Subtitles|*.srt|All Files|*.*"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $ofd.FileName }
}

Add-Type -AssemblyName System.Windows.Forms

#-------------------------
# Playback handlers
#-------------------------
$BtnOpen.Add_Click({
    $path = Select-Video
    if ($path) {
        $Player.Source = [Uri]$path
        $Player.Volume = $SldVolume.Value
        $Player.Play()
        # Reset subtitles
        $global:Subtitles = @()
    }
})

$BtnPlay.Add_Click({ $Player.Play() })
$BtnPause.Add_Click({ $Player.Pause() })
$BtnStop.Add_Click({ $Player.Stop(); $SldSeek.Value = 0 })

$SldVolume.Add_ValueChanged({
    if (-not $ChkMute.IsChecked) { $Player.Volume = $SldVolume.Value }
})
$ChkMute.Add_Checked({ $Player.IsMuted = $true })
$ChkMute.Add_Unchecked({ $Player.IsMuted = $false; $Player.Volume = $SldVolume.Value })

$CmbSpeed.Add_SelectionChanged({
    $text = ($CmbSpeed.SelectedItem.Content)
    switch ($text) {
        '0.5x'  { $Player.SpeedRatio = 0.5 }
        '0.75x' { $Player.SpeedRatio = 0.75 }
        '1.0x'  { $Player.SpeedRatio = 1.0 }
        '1.25x' { $Player.SpeedRatio = 1.25 }
        '1.5x'  { $Player.SpeedRatio = 1.5 }
        '2.0x'  { $Player.SpeedRatio = 2.0 }
        default { $Player.SpeedRatio = 1.0 }
    }
})

# Media opened: set duration and seek max
$Player.Add_MediaOpened({
    if ($Player.NaturalDuration.HasTimeSpan) {
        $global:Duration = $Player.NaturalDuration.TimeSpan
        $LblDur.Content = $global:Duration.ToString()
        $SldSeek.Maximum = [int]$global:Duration.TotalSeconds
    }
})

# Seek slider drag commit
$SldSeek.Add_PreviewMouseLeftButtonUp({
    $global:UpdatingSeek = $true
    $Player.Position = [TimeSpan]::FromSeconds([int]$SldSeek.Value)
    $LblPos.Content = $Player.Position.ToString()
    $global:UpdatingSeek = $false
})

# Timer for updating position and subtitles
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(200)
$timer.Add_Tick({
    if (-not $global:UpdatingSeek) {
        $SldSeek.Value = [int]$Player.Position.TotalSeconds
        $LblPos.Content = $Player.Position.ToString()
    }
    # Subtitle update
    if ($global:Subtitles.Count -gt 0) {
        $now = $Player.Position
        $curr = $global:Subtitles | Where-Object { $now -ge $_.Start -and $now -le $_.End } | Select-Object -First 1
        $TxtSubtitle.Text = if ($curr) { $curr.Text } else { '' }
    }
})
$timer.Start()

#-------------------------
# Playlist
#-------------------------
$BtnAddToList.Add_Click({
    $path = Select-Video
    if ($path) { $LstPlaylist.Items.Add($path) }
})
$BtnRemoveFromList.Add_Click({
    $item = $LstPlaylist.SelectedItem
    if ($item) { $LstPlaylist.Items.Remove($item) }
})
$BtnClearList.Add_Click({ $LstPlaylist.Items.Clear() })
$LstPlaylist.Add_MouseDoubleClick({
    if ($LstPlaylist.SelectedItem) {
        $Player.Source = [Uri]$LstPlaylist.SelectedItem
        $Player.Play()
        $global:Subtitles = @()
    }
})

#-------------------------
# Subtitles
#-------------------------
$BtnSubtitles.Add_Click({
    $srt = Select-Srt
    if ($srt) { $global:Subtitles = Parse-Srt -Path $srt }
})

#-------------------------
# AI integration
#-------------------------
$BtnAskAI.Add_Click({
    $endpoint = $TxtEndpoint.Text.Trim()
    $key = $TxtApiKey.Password.Trim()
    if ([string]::IsNullOrWhiteSpace($endpoint)) { $TxtAIOut.Text = "Endpoint required."; return }
    if ([string]::IsNullOrWhiteSpace($key)) { $TxtAIOut.Text = "API key required."; return }

    $fileName = if ($Player.Source) { [System.IO.Path]::GetFileName($Player.Source.LocalPath) } else { '' }
    $position = $Player.Position.ToString()
    $duration = $global:Duration.ToString()

    $prompt = $TxtPrompt.Text
    $system = "You are a helpful video assistant. Provide concise, actionable insights."
    $userContent = @"
Video file: $fileName
Position: $position
Duration: $duration

Request:
$prompt
"@

    # Example body for OpenAI-style chat completions; adjust "model" to your provider
    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "system"; content = $system },
            @{ role = "user"; content = $userContent }
        )
        temperature = 0.7
    }

    $headers = @{
        "Authorization" = "Bearer $key"
        "Accept"        = "application/json"
    }

    $TxtAIOut.Text = "Thinking..."
    Start-Job -ScriptBlock {
        param($endpoint,$headers,$body)
        $ProgressPreference = 'SilentlyContinue'
        try {
            $json = $body | ConvertTo-Json -Depth 8
            $resp = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $json -ContentType 'application/json'
            if ($resp.choices) {
                return ($resp.choices[0].message.content)
            } elseif ($resp.content) {
                return $resp.content
            } else {
                return ($resp | ConvertTo-Json -Depth 8)
            }
        } catch {
            return "Error: $($_.Exception.Message)"
        }
    } -ArgumentList $endpoint,$headers,$body | ForEach-Object {
        $_ | Wait-Job | Receive-Job | ForEach-Object {
            # Back to UI thread
            [void]$window.Dispatcher.Invoke([action]{ $TxtAIOut.Text = $_ })
        }
        Remove-Job $_
    }
})

$BtnCopyAI.Add_Click({
    [System.Windows.Clipboard]::SetText($TxtAIOut.Text)
})

#-------------------------
# Run app
#-------------------------
$window.Add_Closed({ $timer.Stop() })
$window.ShowDialog() | Out-Null
