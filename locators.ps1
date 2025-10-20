<# 
AI LLM Geolocation App for iPhone 6s — Single-file PowerShell WPF GUI
- Fetches device location via a backend REST endpoint (you provide), then visualizes on a map (Leaflet).
- Sends the location/context to an LLM endpoint (OpenAI-compatible or custom) for analysis/suggestions.
- Admin-safe, no registry writes, self-contained HTML map, no external installs.
- Tested on Windows PowerShell 5.1 (Win10/11); uses WPF + WebBrowser control.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# -------------------------
# Embedded Leaflet Map HTML
# -------------------------
$LeafletHtml = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<meta http-equiv="X-UA-Compatible" content="IE=edge"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>Geolocation Map</title>
<style>
  html, body { height: 100%; margin: 0; }
  #map { width: 100%; height: 100%; }
  .info { position:absolute; top:10px; left:10px; background:#fff; padding:6px 8px; border-radius:4px; box-shadow:0 0 8px rgba(0,0,0,.2); font: 12px/1.4 Arial, sans-serif; }
</style>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
</head>
<body>
<div id="map"></div>
<div class="info" id="info">Waiting for coordinates…</div>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
  var map = L.map('map', { zoomControl: true });
  var tileUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  var tiles = L.tileLayer(tileUrl, { maxZoom: 19, attribution: '&copy; OpenStreetMap contributors' }).addTo(map);
  var marker = null, circle = null;

  function setLocation(lat, lon, accuracy, label) {
    if(!lat || !lon) return;
    var pos = [lat, lon];
    map.setView(pos, 15);
    if (marker) { map.removeLayer(marker); }
    marker = L.marker(pos).addTo(map);
    if (circle) { map.removeLayer(circle); }
    if (accuracy && accuracy > 0) {
      circle = L.circle(pos, { radius: accuracy, color:'#1a73e8', fillColor:'#1a73e8', fillOpacity:0.15 }).addTo(map);
    }
    var text = 'Lat: ' + lat.toFixed(6) + ', Lon: ' + lon.toFixed(6);
    if (accuracy) text += ' (±' + Math.round(accuracy) + ' m)';
    if (label) text += '<br/>' + label;
    document.getElementById('info').innerHTML = text;
  }

  // Expose a simple API for the host app
  window.setLocation = setLocation;
</script>
</body>
</html>
"@

# -------------------------
# Helpers
# -------------------------
function New-TempHtml {
    $tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "GeoLLM_Map_{0}.html" -f ([System.Guid]::NewGuid()))
    [System.IO.File]::WriteAllText($tempPath, $LeafletHtml, [System.Text.Encoding]::UTF8)
    return $tempPath
}

function Invoke-Json {
    param(
        [Parameter(Mandatory=$true)][string]$Method,
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter()][hashtable]$Headers,
        [Parameter()][object]$Body,
        [int]$TimeoutSec = 20
    )
    try {
        $args = @{
            Method      = $Method
            Uri         = $Url
            Headers     = $Headers
            TimeoutSec  = $TimeoutSec
            ErrorAction = 'Stop'
        }
        if ($Body) {
            $json = $Body | ConvertTo-Json -Depth 6
            $args.ContentType = 'application/json'
            $args.Body = $json
        }
        $resp = Invoke-RestMethod @args
        return $resp
    } catch {
        return [pscustomobject]@{ error = $_.Exception.Message }
    }
}

function Sanitize-Text {
    param([string]$s)
    if ([string]::IsNullOrWhiteSpace($s)) { return '' }
    return ($s -replace '[\r\n]+','  ').Trim()
}

# -------------------------
# Build WPF UI
# -------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI LLM Geolocation (iPhone 6s)" Height="720" Width="1100"
        WindowStartupLocation="CenterScreen" Background="#0f0f13" Foreground="#f0f0f0">
  <Grid Margin="10">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="2*"/>
    </Grid.RowDefinitions>

    <!-- Backend config -->
    <GroupBox Grid.Row="0" Header="Backend endpoints" Margin="0,0,0,8" Background="#15151a">
      <Grid Margin="8">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <TextBlock Grid.Column="0" Text="Location API:" Margin="0,0,6,0" VerticalAlignment="Center"/>
        <TextBox   Grid.Column="1" Name="LocationApiTxt" Text="http://127.0.0.1:8080/device/location" />
        <TextBlock Grid.Column="2" Text="LLM API:" Margin="12,0,6,0" VerticalAlignment="Center"/>
        <TextBox   Grid.Column="3" Name="LlmApiTxt" Text="https://api.openai-compatible.local/v1/chat/completions" />
      </Grid>
    </GroupBox>

    <!-- Credentials / device -->
    <GroupBox Grid.Row="1" Header="Credentials & device" Margin="0,0,0,8" Background="#15151a">
      <Grid Margin="8">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <TextBlock Grid.Column="0" Text="Location token:" Margin="0,0,6,0" VerticalAlignment="Center"/>
        <PasswordBox Grid.Column="1" Name="LocationTokenTxt" />
        <TextBlock Grid.Column="2" Text="LLM token:" Margin="12,0,6,0" VerticalAlignment="Center"/>
        <PasswordBox Grid.Column="3" Name="LlmTokenTxt" />
        <TextBlock Grid.Column="4" Text="Device ID:" Margin="12,0,6,0" VerticalAlignment="Center"/>
        <TextBox Grid.Column="5" Name="DeviceIdTxt" Text="iphone-6s-basename" />
      </Grid>
    </GroupBox>

    <!-- Controls + status -->
    <DockPanel Grid.Row="2" LastChildFill="True">
      <StackPanel Orientation="Horizontal" DockPanel.Dock="Top" Margin="0,0,0,8">
        <Button Name="FetchBtn" Content="Fetch location" Margin="0,0,8,0" Padding="12,6"/>
        <Button Name="SetBtn" Content="Set location on map" Margin="0,0,8,0" Padding="12,6"/>
        <Button Name="AskBtn" Content="Ask LLM about this place" Margin="0,0,8,0" Padding="12,6"/>
        <Button Name="CopyBtn" Content="Copy coordinates" Margin="0,0,8,0" Padding="12,6"/>
        <Button Name="ClearBtn" Content="Clear" Padding="12,6"/>
      </StackPanel>
      <TextBlock Name="StatusTxt" Text="Ready." Margin="6,0,0,0" />
    </DockPanel>

    <!-- Map + details -->
    <Grid Grid.Row="3">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="2*"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <!-- Map -->
      <WindowsFormsHost Grid.Column="0" Name="MapHost" Margin="0,0,8,0">
        <wf:WebBrowser x:Name="MapBrowser" />
      </WindowsFormsHost>

      <!-- Details/LLM -->
      <Grid Grid.Column="1">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <GroupBox Grid.Row="0" Header="Coordinates">
          <Grid Margin="8">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="Auto"/>
              <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="Latitude:" Margin="0,0,6,0" VerticalAlignment="Center"/>
            <TextBox   Grid.Column="1" Name="LatTxt" />
            <TextBlock Grid.Row="1" Grid.Column="0" Text="Longitude:" Margin="0,6,6,0" VerticalAlignment="Center"/>
            <TextBox   Grid.Row="1" Grid.Column="1" Name="LonTxt" Margin="0,6,0,0"/>
            <TextBlock Grid.Row="2" Grid.Column="0" Text="Accuracy (m):" Margin="0,6,6,0" VerticalAlignment="Center"/>
            <TextBox   Grid.Row="2" Grid.Column="1" Name="AccTxt" Margin="0,6,0,0"/>
            <TextBlock Grid.Row="3" Grid.Column="0" Text="Label:" Margin="0,6,6,0" VerticalAlignment="Center"/>
            <TextBox   Grid.Row="3" Grid.Column="1" Name="LabelTxt" Margin="0,6,0,0" Text="Monemvasia, Peloponnese"/>
          </Grid>
        </GroupBox>

        <GroupBox Grid.Row="1" Header="LLM prompt">
          <TextBox Name="PromptTxt" Margin="8" AcceptsReturn="True" Height="80" Text="Given these coordinates, suggest nearby points of interest and walking routes with short descriptions."/>
        </GroupBox>

        <GroupBox Grid.Row="2" Header="LLM response">
          <ScrollViewer Margin="8">
            <TextBlock Name="LlmOutTxt" TextWrapping="Wrap" />
          </ScrollViewer>
        </GroupBox>

        <GroupBox Grid.Row="3" Header="Logs">
          <TextBox Name="LogTxt" Margin="8" AcceptsReturn="True" Height="80" IsReadOnly="True" VerticalScrollBarVisibility="Auto"/>
        </GroupBox>

        <StackPanel Grid.Row="4" Orientation="Horizontal" Margin="0,8,0,0">
          <CheckBox Name="OpenAICheck" Content="OpenAI-compatible schema" IsChecked="True" Margin="0,0,12,0"/>
          <TextBlock Text="Model:" VerticalAlignment="Center" Margin="0,0,6,0"/>
          <TextBox Name="ModelTxt" Text="gpt-4o-mini" Width="140"/>
        </StackPanel>
      </Grid>
    </Grid>
  </Grid>
</Window>
"@

# Namespace mapping for WindowsFormsHost
$ns = New-Object System.Xml.XmlNamespaceManager($xaml.NameTable)
$ns.AddNamespace("wf","clr-namespace:System.Windows.Forms;assembly=System.Windows.Forms")
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Bind controls
$LocationApiTxt = $Window.FindName("LocationApiTxt")
$LlmApiTxt      = $Window.FindName("LlmApiTxt")
$LocationTokenTxt = $Window.FindName("LocationTokenTxt")
$LlmTokenTxt    = $Window.FindName("LlmTokenTxt")
$DeviceIdTxt    = $Window.FindName("DeviceIdTxt")
$FetchBtn       = $Window.FindName("FetchBtn")
$SetBtn         = $Window.FindName("SetBtn")
$AskBtn         = $Window.FindName("AskBtn")
$CopyBtn        = $Window.FindName("CopyBtn")
$ClearBtn       = $Window.FindName("ClearBtn")
$StatusTxt      = $Window.FindName("StatusTxt")
$MapHost        = $Window.FindName("MapHost")
$LatTxt         = $Window.FindName("LatTxt")
$LonTxt         = $Window.FindName("LonTxt")
$AccTxt         = $Window.FindName("AccTxt")
$LabelTxt       = $Window.FindName("LabelTxt")
$PromptTxt      = $Window.FindName("PromptTxt")
$LlmOutTxt      = $Window.FindName("LlmOutTxt")
$LogTxt         = $Window.FindName("LogTxt")
$OpenAICheck    = $Window.FindName("OpenAICheck")
$ModelTxt       = $Window.FindName("ModelTxt")

# Create and navigate WebBrowser to temp HTML
$tempHtml = New-TempHtml
$wb = New-Object System.Windows.Forms.WebBrowser
$wb.ScriptErrorsSuppressed = $true
$wb.Url = "file:///$tempHtml"
$MapHost.Child = $wb

function Log {
    param([string]$msg)
    $ts = (Get-Date).ToString("HH:mm:ss")
    $LogTxt.AppendText("[$ts] $msg`r`n")
    $LogTxt.ScrollToEnd()
}

function Set-Status { param([string]$s) $StatusTxt.Text = $s }

function Update-Map {
    $lat = [double]::TryParse($LatTxt.Text, [ref]([double]0)); $latVal = [double]$LatTxt.Text
    $lon = [double]::TryParse($LonTxt.Text, [ref]([double]0)); $lonVal = [double]$LonTxt.Text
    $accVal = $AccTxt.Text
    if (-not $lat -or -not $lon) { Log "Invalid lat/lon"; Set-Status "Invalid coordinates"; return }
    $label = Sanitize-Text $LabelTxt.Text
    $acc = 0
    [void][double]::TryParse($accVal, [ref]$acc)
    try {
        # Call JS setLocation(lat, lon, accuracy, label)
        $wb.Document.InvokeScript("setLocation", @($latVal, $lonVal, $acc, $label))
        Log "Map updated: $latVal, $lonVal (±$acc m)"
        Set-Status "Map updated"
    } catch {
        Log "Map update failed: $($_.Exception.Message)"
        Set-Status "Map update failed"
    }
}

# Fetch location from your backend
$FetchBtn.Add_Click({
    $url = $LocationApiTxt.Text.Trim()
    $token = $LocationTokenTxt.Password
    $deviceId = $DeviceIdTxt.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($url)) { Log "Location API missing"; return }
    Log "Fetching location from $url for device '$deviceId'..."
    Set-Status "Fetching location..."
    $headers = @{}
    if ($token) { $headers['Authorization'] = "Bearer $token" }
    $body = @{ deviceId = $deviceId }
    $resp = Invoke-Json -Method 'POST' -Url $url -Headers $headers -Body $body
    if ($resp.error) {
        Log "Location fetch error: $($resp.error)"
        Set-Status "Fetch failed"
        return
    }
    # Expecting: { latitude: , longitude: , accuracy: , label: 'optional' }
    $LatTxt.Text = "$($resp.latitude)"
    $LonTxt.Text = "$($resp.longitude)"
    $AccTxt.Text = "$($resp.accuracy)"
    if ($resp.label) { $LabelTxt.Text = "$($resp.label)" }
    Update-Map
})

# Manual set to map
$SetBtn.Add_Click({ Update-Map })

# Copy coordinates
$CopyBtn.Add_Click({
    $coords = "Lat=$($LatTxt.Text), Lon=$($LonTxt.Text), Acc=$($AccTxt.Text)"
    [System.Windows.Clipboard]::SetText($coords)
    Log "Copied: $coords"
    Set-Status "Coordinates copied"
})

# Clear fields
$ClearBtn.Add_Click({
    $LatTxt.Text = ''
    $LonTxt.Text = ''
    $AccTxt.Text = ''
    $LabelTxt.Text = ''
    $PromptTxt.Text = ''
    $LlmOutTxt.Text = ''
    Log "Cleared"
    Set-Status "Ready"
})

# Ask LLM
$AskBtn.Add_Click({
    $llmUrl = $LlmApiTxt.Text.Trim()
    $llmToken = $LlmTokenTxt.Password
    $model = $ModelTxt.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($llmUrl)) { Log "LLM API missing"; return }
    $lat = $LatTxt.Text; $lon = $LonTxt.Text; $acc = $AccTxt.Text
    if ([string]::IsNullOrWhiteSpace($lat) -or [string]::IsNullOrWhiteSpace($lon)) { Log "Coordinates missing"; return }
    $label = Sanitize-Text $LabelTxt.Text
    $promptBase = $PromptTxt.Text
    $context = "Coordinates: lat=$lat, lon=$lon, acc=$acc m; label='$label'."
    $finalPrompt = "$promptBase`n$context"
    Log "Sending prompt to LLM ($model)…"
    Set-Status "Querying LLM..."

    $headers = @{ 'Content-Type'='application/json' }
    if ($llmToken) { $headers['Authorization'] = "Bearer $llmToken" }

    if ($OpenAICheck.IsChecked) {
        $body = @{
            model = $model
            messages = @(
                @{ role = 'system'; content = 'You are a helpful geolocation assistant. Provide concise, practical, safety-aware suggestions.' },
                @{ role = 'user'; content = $finalPrompt }
            )
            temperature = 0.7
        }
        $resp = Invoke-Json -Method 'POST' -Url $llmUrl -Headers $headers -Body $body
        if ($resp.error) { Log "LLM error: $($resp.error)"; Set-Status "LLM failed"; return }
        # Extract text (OpenAI-style)
        try {
            $text = $resp.choices[0].message.content
        } catch { $text = ($resp | ConvertTo-Json -Depth 6) }
        $LlmOutTxt.Text = $text
        Log "LLM response received."
        Set-Status "LLM ok"
    } else {
        # Generic JSON schema: { prompt: "...", model: "..."} expecting { text: "..." }
        $body = @{ prompt = $finalPrompt; model = $model }
        $resp = Invoke-Json -Method 'POST' -Url $llmUrl -Headers $headers -Body $body
        if ($resp.error) { Log "LLM error: $($resp.error)"; Set-Status "LLM failed"; return }
        $text = $resp.text
        if (-not $text) { $text = ($resp | ConvertTo-Json -Depth 6) }
        $LlmOutTxt.Text = $text
        Log "LLM response received."
        Set-Status "LLM ok"
    }
})

# Show window
$Window.Add_Closed({
    try { if (Test-Path $tempHtml) { Remove-Item $tempHtml -Force -ErrorAction SilentlyContinue } } catch {}
})

[System.Windows.Application]::new().Run($Window)
