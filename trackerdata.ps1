#requires -version 5.1
<#
Starlink Satellite Tracker - Single-file PowerShell WPF GUI
- Set your location (lat, lon, altitude).
- Browse Starlink satellites from CelesTrak TLE feed.
- Select a satellite to preview current orbit params and query next passes via N2YO (optional API key).
- Live position estimates require orbital propagation; this script focuses on pass prediction via API and displays TLE/derived info.
- Admin-safe, no external installs. Extensible: add SGP4 via Add-Type (C#) or offload to a backend.

Notes:
- N2YO Passes API (optional): https://www.n2yo.com/api/ (get an API key). Without it, you can still fetch TLEs and view orbital data.
- CelesTrak Starlink TLEs: https://celestrak.org/NORAD/elements/starlink.txt
- This is a practical GUI scaffold with clean wiring and error handling.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing

function New-Window {
param(
  [string]$Title = "Starlink Satellite Tracker",
  [int]$Width = 980,
  [int]$Height = 720
)
@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$Title" Width="$Width" Height="$Height" WindowStartupLocation="CenterScreen"
        Background="#121212" Foreground="#EAEAEA" FontFamily="Segoe UI" FontSize="12">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Top controls -->
    <DockPanel Grid.Row="0" LastChildFill="False" Margin="0,0,0,10">
      <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" Margin="0,0,16,0">
        <TextBlock Text="Lat:" VerticalAlignment="Center" Margin="0,0,6,0"/>
        <TextBox x:Name="LatBox" Width="90" Text="36.683" Margin="0,0,10,0"/>
        <TextBlock Text="Lon:" VerticalAlignment="Center" Margin="0,0,6,0"/>
        <TextBox x:Name="LonBox" Width="90" Text="23.045" Margin="0,0,10,0"/>
        <TextBlock Text="Alt (m):" VerticalAlignment="Center" Margin="0,0,6,0"/>
        <TextBox x:Name="AltBox" Width="90" Text="10" Margin="0,0,10,0"/>
        <Button x:Name="UseIPBtn" Content="Use IP location" Padding="10,4" Margin="0,0,10,0"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" Margin="0,0,16,0">
        <Button x:Name="LoadTLEBtn" Content="Load Starlink TLEs" Padding="10,4" Margin="0,0,10,0"/>
        <TextBlock Text="Filter:" VerticalAlignment="Center" Margin="0,0,6,0"/>
        <TextBox x:Name="FilterBox" Width="140" Margin="0,0,10,0"/>
        <Button x:Name="ClearFilterBtn" Content="Clear" Padding="10,4"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
        <TextBlock Text="N2YO API Key:" VerticalAlignment="Center" Margin="0,0,6,0"/>
        <PasswordBox x:Name="ApiKeyBox" Width="180" Margin="0,0,10,0"/>
        <TextBlock Text="Days:" VerticalAlignment="Center" Margin="0,0,6,0"/>
        <TextBox x:Name="DaysBox" Width="50" Text="2" Margin="0,0,10,0"/>
        <TextBlock Text="Min Elev (deg):" VerticalAlignment="Center" Margin="0,0,6,0"/>
        <TextBox x:Name="MinElBox" Width="50" Text="10"/>
      </StackPanel>
    </DockPanel>

    <!-- Main content split -->
    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="2*"/>
        <ColumnDefinition Width="3*"/>
      </Grid.ColumnDefinitions>

      <!-- Left: satellite list -->
      <Grid Grid.Column="0">
        <Grid.RowDefinitions>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <DataGrid x:Name="SatGrid" Grid.Row="0" AutoGenerateColumns="False" CanUserAddRows="False" IsReadOnly="True"
                  Background="#1E1E1E" Foreground="#EAEAEA" HeadersVisibility="Column" SelectionMode="Single">
          <DataGrid.Columns>
            <DataGridTextColumn Header="Name" Binding="{Binding Name}" Width="*"/>
            <DataGridTextColumn Header="NORAD" Binding="{Binding NoradId}" Width="80"/>
            <DataGridTextColumn Header="Epoch (UTC)" Binding="{Binding Epoch}" Width="140"/>
            <DataGridTextColumn Header="Incl (°)" Binding="{Binding Inclination}" Width="80"/>
            <DataGridTextColumn Header="Ecc" Binding="{Binding Eccentricity}" Width="80"/>
            <DataGridTextColumn Header="MeanMo (rev/day)" Binding="{Binding MeanMotion}" Width="120"/>
          </DataGrid.Columns>
        </DataGrid>

        <StackPanel Orientation="Horizontal" Grid.Row="1" Margin="0,8,0,0">
          <Button x:Name="RefreshPassesBtn" Content="Get next passes" Padding="10,6" Margin="0,0,10,0"/>
          <Button x:Name="OpenN2YOBtn" Content="Open on N2YO" Padding="10,6" Margin="0,0,10,0"/>
          <Button x:Name="OpenCelesTrakBtn" Content="Open CelesTrak" Padding="10,6"/>
        </StackPanel>
      </Grid>

      <!-- Right: details and passes -->
      <Grid Grid.Column="1">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="2*"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <GroupBox Header="Satellite details" Grid.Row="0" Padding="8" Background="#1E1E1E">
          <StackPanel>
            <TextBlock x:Name="SelName" Text="Name: -" Margin="0,2,0,0"/>
            <TextBlock x:Name="SelNorad" Text="NORAD: -" Margin="0,2,0,0"/>
            <TextBlock x:Name="SelEpoch" Text="Epoch: -" Margin="0,2,0,0"/>
            <TextBlock x:Name="SelTLE1" Text="TLE Line 1: -" Margin="0,6,0,0" TextWrapping="Wrap"/>
            <TextBlock x:Name="SelTLE2" Text="TLE Line 2: -" Margin="0,2,0,0" TextWrapping="Wrap"/>
          </StackPanel>
        </GroupBox>

        <GroupBox Header="Predicted passes (N2YO)" Grid.Row="1" Padding="8" Background="#1E1E1E">
          <DataGrid x:Name="PassGrid" AutoGenerateColumns="False" CanUserAddRows="False" IsReadOnly="True"
                    Background="#1E1E1E" Foreground="#EAEAEA">
            <DataGrid.Columns>
              <DataGridTextColumn Header="Start (UTC)" Binding="{Binding startUTC}" Width="150"/>
              <DataGridTextColumn Header="Max (UTC)" Binding="{Binding maxUTC}" Width="150"/>
              <DataGridTextColumn Header="End (UTC)" Binding="{Binding endUTC}" Width="150"/>
              <DataGridTextColumn Header="Max Elev (°)" Binding="{Binding maxEl}" Width="100"/>
              <DataGridTextColumn Header="Duration (min)" Binding="{Binding durationMin}" Width="100"/>
              <DataGridTextColumn Header="Az Start" Binding="{Binding azStart}" Width="80"/>
              <DataGridTextColumn Header="Az End" Binding="{Binding azEnd}" Width="80"/>
            </DataGrid.Columns>
          </DataGrid>
        </GroupBox>

        <GroupBox Header="Log" Grid.Row="2" Padding="8" Background="#1E1E1E">
          <ScrollViewer VerticalScrollBarVisibility="Auto">
            <TextBox x:Name="LogBox" IsReadOnly="True" TextWrapping="Wrap" Background="#111111" Foreground="#EAEAEA"/>
          </ScrollViewer>
        </GroupBox>
      </Grid>
    </Grid>

    <!-- Footer -->
    <DockPanel Grid.Row="2" Margin="0,10,0,0">
      <TextBlock DockPanel.Dock="Left" Text="Tip: Without an N2YO API key, you can still load Starlink TLEs and inspect satellite data."/>
      <TextBlock DockPanel.Dock="Right" Text="© Starlink Tracker (PowerShell)" />
    </DockPanel>
  </Grid>
</Window>
"@
}

function Write-Log {
  param([string]$Message, [System.Windows.Controls.TextBox]$Box)
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $Box.AppendText("[${ts}] $Message`r`n")
  $Box.ScrollToEnd()
}

function Fetch-CelesTrakStarlink {
  param([System.Windows.Controls.TextBox]$LogBox)
  try {
    Write-Log "Downloading Starlink TLEs from CelesTrak..." $LogBox
    $url = "https://celestrak.org/NORAD/elements/starlink.txt"
    $raw = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20
    $lines = $raw.Content -split "`r?`n" | Where-Object { $_.Trim().Length -gt 0 }
    $sats = @()
    for ($i=0; $i -lt $lines.Count; $i+=3) {
      $name = $lines[$i].Trim()
      $l1 = $lines[$i+1].Trim()
      $l2 = $lines[$i+2].Trim()
      # NORAD from line2 (cols 3-7) or line1
      $norad = ($l2.Substring(2,5)).Trim()
      # basic params
      $incl = [double]::Parse($l2.Substring(8,8).Trim(), [Globalization.CultureInfo]::InvariantCulture)
      $ecc = ("0." + $l2.Substring(26,7).Trim())
      $mm  = [double]::Parse($l2.Substring(52,11).Trim(), [Globalization.CultureInfo]::InvariantCulture)
      $epochYY = [int]$l1.Substring(18,2)
      $epochDay = [double]::Parse($l1.Substring(20,12).Trim(), [Globalization.CultureInfo]::InvariantCulture)
      $epochYear = if ($epochYY -ge 57) { 1900 + $epochYY } else { 2000 + $epochYY }
      # Convert epoch day-of-year to UTC
      $epoch = (Get-Date -Year $epochYear -Day 1).AddDays($epochDay - 1).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
      $sats += [pscustomobject]@{
        Name        = $name
        NoradId     = $norad
        Line1       = $l1
        Line2       = $l2
        Inclination = "{0:N3}" -f $incl
        Eccentricity= $ecc
        MeanMotion  = "{0:N6}" -f $mm
        Epoch       = $epoch
      }
    }
    Write-Log "Loaded $($sats.Count) Starlink satellites." $LogBox
    return $sats
  } catch {
    Write-Log "Error loading TLEs: $($_.Exception.Message)" $LogBox
    return @()
  }
}

function Get-IPLocation {
  param([System.Windows.Controls.TextBox]$LogBox)
  try {
    Write-Log "Resolving location from IP..." $LogBox
    # Free IP geolocation endpoint (anonymous), may rate-limit. Replace with your preferred provider if needed.
    $resp = Invoke-RestMethod -Uri "https://ipapi.co/json" -TimeoutSec 12
    $lat = [string]$resp.latitude
    $lon = [string]$resp.longitude
    $city = [string]$resp.city
    Write-Log "IP location: $city (lat $lat, lon $lon)" $LogBox
    return @{ lat=$lat; lon=$lon }
  } catch {
    Write-Log "IP location failed: $($_.Exception.Message)" $LogBox
    return $null
  }
}

function Get-N2YOPasses {
param(
  [string]$ApiKey,
  [int]$NoradId,
  [double]$Lat,
  [double]$Lon,
  [double]$AltMeters,
  [int]$Days = 2,
  [int]$MinElevationDeg = 10,
  [System.Windows.Controls.TextBox]$LogBox
)
  if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Log "N2YO API key missing. Enter a key to query passes." $LogBox
    return @()
  }
  try {
    Write-Log "Querying N2YO passes for NORAD $NoradId (days=$Days, minEl=$MinElevationDeg)..." $LogBox
    $altKm = [math]::Round($AltMeters / 1000.0, 3)
    $url = "https://api.n2yo.com/rest/v1/satellite/visualpasses/$NoradId/$Lat/$Lon/$altKm/$Days/$MinElevationDeg/&apiKey=$ApiKey"
    $resp = Invoke-RestMethod -Uri $url -TimeoutSec 20
    if (-not $resp.passes) {
      Write-Log "No passes found." $LogBox
      return @()
    }
    $passes = foreach ($p in $resp.passes) {
      $startUTC = ([DateTimeOffset]::FromUnixTimeSeconds([int64]$p.startUTC)).UtcDateTime.ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
      $maxUTC   = ([DateTimeOffset]::FromUnixTimeSeconds([int64]$p.maxUTC)).UtcDateTime.ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
      $endUTC   = ([DateTimeOffset]::FromUnixTimeSeconds([int64]$p.endUTC)).UtcDateTime.ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
      [pscustomobject]@{
        startUTC    = $startUTC
        maxUTC      = $maxUTC
        endUTC      = $endUTC
        durationMin = [int]$p.duration
        maxEl       = [int]$p.maxEl
        azStart     = [int]$p.azStart
        azEnd       = [int]$p.azEnd
      }
    }
    Write-Log "Found $($passes.Count) passes." $LogBox
    return $passes
  } catch {
    Write-Log "N2YO query failed: $($_.Exception.Message)" $LogBox
    return @()
  }
}

# Build UI
$xaml = New-Window
$reader = New-Object System.Xml.XmlNodeReader([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Resolve controls
$LatBox          = $window.FindName("LatBox")
$LonBox          = $window.FindName("LonBox")
$AltBox          = $window.FindName("AltBox")
$UseIPBtn        = $window.FindName("UseIPBtn")
$LoadTLEBtn      = $window.FindName("LoadTLEBtn")
$FilterBox       = $window.FindName("FilterBox")
$ClearFilterBtn  = $window.FindName("ClearFilterBtn")
$SatGrid         = $window.FindName("SatGrid")
$RefreshPassesBtn= $window.FindName("RefreshPassesBtn")
$OpenN2YOBtn     = $window.FindName("OpenN2YOBtn")
$OpenCelesTrakBtn= $window.FindName("OpenCelesTrakBtn")
$ApiKeyBox       = $window.FindName("ApiKeyBox")
$DaysBox         = $window.FindName("DaysBox")
$MinElBox        = $window.FindName("MinElBox")
$PassGrid        = $window.FindName("PassGrid")
$LogBox          = $window.FindName("LogBox")
$SelName         = $window.FindName("SelName")
$SelNorad        = $window.FindName("SelNorad")
$SelEpoch        = $window.FindName("SelEpoch")
$SelTLE1         = $window.FindName("SelTLE1")
$SelTLE2         = $window.FindName("SelTLE2")

$global:Sats = @()
$global:View = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$SatGrid.ItemsSource = $global:View

$global:PassesView = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$PassGrid.ItemsSource = $global:PassesView

# Events
$UseIPBtn.Add_Click({
  $loc = Get-IPLocation -LogBox $LogBox
  if ($loc) {
    $LatBox.Text = "{0}" -f $loc.lat
    $LonBox.Text = "{0}" -f $loc.lon
  }
})

$LoadTLEBtn.Add_Click({
  $global:Sats = Fetch-CelesTrakStarlink -LogBox $LogBox
  $global:View.Clear()
  foreach ($s in $global:Sats) { $global:View.Add($s) }
})

$ClearFilterBtn.Add_Click({
  $FilterBox.Text = ""
  $global:View.Clear()
  foreach ($s in $global:Sats) { $global:View.Add($s) }
})

$FilterBox.Add_TextChanged({
  $term = $FilterBox.Text.Trim()
  if ($global:Sats.Count -eq 0) { return }
  if ([string]::IsNullOrWhiteSpace($term)) {
    $global:View.Clear(); foreach ($s in $global:Sats) { $global:View.Add($s) }; return
  }
  $filtered = $global:Sats | Where-Object {
    $_.Name -like "*$term*" -or $_.NoradId -like "*$term*"
  }
  $global:View.Clear(); foreach ($s in $filtered) { $global:View.Add($s) }
})

$SatGrid.Add_SelectionChanged({
  $sel = $SatGrid.SelectedItem
  if (-not $sel) { return }
  $SelName.Text = "Name: " + $sel.Name
  $SelNorad.Text = "NORAD: " + $sel.NoradId
  $SelEpoch.Text = "Epoch: " + $sel.Epoch
  $SelTLE1.Text = "TLE Line 1: " + $sel.Line1
  $SelTLE2.Text = "TLE Line 2: " + $sel.Line2
})

$RefreshPassesBtn.Add_Click({
  $sel = $SatGrid.SelectedItem
  if (-not $sel) { Write-Log "Select a satellite first." $LogBox; return }
  try {
    $lat = [double]::Parse($LatBox.Text, [Globalization.CultureInfo]::InvariantCulture)
    $lon = [double]::Parse($LonBox.Text, [Globalization.CultureInfo]::InvariantCulture)
    $alt = [double]::Parse($AltBox.Text, [Globalization.CultureInfo]::InvariantCulture)
    $days = [int]::Parse($DaysBox.Text)
    $minEl = [int]::Parse($MinElBox.Text)
  } catch {
    Write-Log "Invalid location or pass parameters." $LogBox; return
  }
  $key = $ApiKeyBox.Password
  $passes = Get-N2YOPasses -ApiKey $key -NoradId ([int]$sel.NoradId) -Lat $lat -Lon $lon -AltMeters $alt -Days $days -MinElevationDeg $minEl -LogBox $LogBox
  $global:PassesView.Clear()
  foreach ($p in $passes) { $global:PassesView.Add($p) }
})

$OpenN2YOBtn.Add_Click({
  $sel = $SatGrid.SelectedItem
  if (-not $sel) { Write-Log "Select a satellite first." $LogBox; return }
  Start-Process "https://www.n2yo.com/satellite/?s=$($sel.NoradId)"
})

$OpenCelesTrakBtn.Add_Click({
  Start-Process "https://celestrak.org/NORAD/elements/starlink.php"
})

# Show window
$window.Topmost = $false
$null = $window.ShowDialog()
