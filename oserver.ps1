<# 
    AI LLM MEDIA SERVER APP
    Single-file PowerShell WPF GUI
    - Media list (local or server-side)
    - Prompt box + LLM response
    - Endpoint + API key config
    - Extensible backend contract via Invoke-RestMethod
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

#--------------------------- XAML UI ---------------------------#
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI LLM Media Server" Height="600" Width="950"
        WindowStartupLocation="CenterScreen"
        Background="#1E1E1E" Foreground="#F0F0F0">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="2*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="2*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="2*"/>
            <ColumnDefinition Width="3*"/>
        </Grid.ColumnDefinitions>

        <!-- Header -->
        <TextBlock Grid.Row="0" Grid.ColumnSpan="2"
                   Text="AI LLM Media Server"
                   FontSize="20" FontWeight="Bold"
                   Margin="0,0,0,8"/>

        <!-- Media list + controls -->
        <GroupBox Grid.Row="1" Grid.Column="0" Header="Media Library" Margin="0,0,8,8">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <ListView x:Name="MediaList" Grid.Row="0" Margin="4">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="Name" DisplayMemberBinding="{Binding Name}" Width="160"/>
                            <GridViewColumn Header="Path / URL" DisplayMemberBinding="{Binding Path}" Width="220"/>
                            <GridViewColumn Header="Type" DisplayMemberBinding="{Binding Type}" Width="80"/>
                        </GridView>
                    </ListView.View>
                </ListView>

                <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="4">
                    <Button x:Name="BtnAddLocal" Content="Add Local" Width="90" Margin="4"/>
                    <Button x:Name="BtnAddUrl" Content="Add URL" Width="90" Margin="4"/>
                    <Button x:Name="BtnRemove" Content="Remove" Width="90" Margin="4"/>
                    <Button x:Name="BtnRefreshServer" Content="Refresh Server" Width="110" Margin="4"/>
                </StackPanel>
            </Grid>
        </GroupBox>

        <!-- LLM prompt + controls -->
        <GroupBox Grid.Row="1" Grid.Column="1" Header="LLM Prompt" Margin="8,0,0,8">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBox x:Name="TxtPrompt"
                         Grid.Row="0"
                         Margin="4"
                         AcceptsReturn="True"
                         VerticalScrollBarVisibility="Auto"
                         TextWrapping="Wrap"
                         Background="#252526" Foreground="#F0F0F0"/>

                <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="4">
                    <CheckBox x:Name="ChkIncludeMediaContext" Content="Include selected media context" Margin="4,0"/>
                    <Button x:Name="BtnAnalyze" Content="Send to LLM" Width="120" Margin="4"/>
                </StackPanel>
            </Grid>
        </GroupBox>

        <!-- Settings -->
        <GroupBox Grid.Row="2" Grid.ColumnSpan="2" Header="Backend Settings" Margin="0,0,0,8">
            <Grid Margin="4">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="2*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <TextBlock Text="Endpoint:" VerticalAlignment="Center" Margin="0,0,4,0"/>
                <TextBox x:Name="TxtEndpoint" Grid.Column="1" Margin="0,0,8,0"
                         Text="http://localhost:8000/api/llm/media"/>

                <TextBlock Grid.Column="2" Text="API Key:" VerticalAlignment="Center" Margin="0,0,4,0"/>
                <PasswordBox x:Name="TxtApiKey" Grid.Column="3" Margin="0,0,0,0"/>
            </Grid>
        </GroupBox>

        <!-- LLM response -->
        <GroupBox Grid.Row="3" Grid.ColumnSpan="2" Header="LLM Response" Margin="0,0,0,8">
            <Grid>
                <TextBox x:Name="TxtResponse"
                         Margin="4"
                         IsReadOnly="True"
                         AcceptsReturn="True"
                         VerticalScrollBarVisibility="Auto"
                         TextWrapping="Wrap"
                         Background="#252526" Foreground="#F0F0F0"/>
            </Grid>
        </GroupBox>

        <!-- Status bar -->
        <StatusBar Grid.Row="4" Grid.ColumnSpan="2">
            <StatusBarItem>
                <TextBlock x:Name="LblStatus" Text="Ready."/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

#--------------------------- Load XAML ---------------------------#
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Control bindings
$MediaList            = $window.FindName("MediaList")
$BtnAddLocal          = $window.FindName("BtnAddLocal")
$BtnAddUrl            = $window.FindName("BtnAddUrl")
$BtnRemove            = $window.FindName("BtnRemove")
$BtnRefreshServer     = $window.FindName("BtnRefreshServer")
$TxtPrompt            = $window.FindName("TxtPrompt")
$ChkIncludeMediaContext = $window.FindName("ChkIncludeMediaContext")
$BtnAnalyze           = $window.FindName("BtnAnalyze")
$TxtEndpoint          = $window.FindName("TxtEndpoint")
$TxtApiKey            = $window.FindName("TxtApiKey")
$TxtResponse          = $window.FindName("TxtResponse")
$LblStatus            = $window.FindName("LblStatus")

#--------------------------- Data model ---------------------------#
$MediaItems = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$MediaList.ItemsSource = $MediaItems

function Add-MediaItem {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Type
    )
    $obj = [PSCustomObject]@{
        Name = $Name
        Path = $Path
        Type = $Type
    }
    $MediaItems.Add($obj) | Out-Null
}

#--------------------------- Backend contract ---------------------------#
function Invoke-LLMMediaRequest {
    param(
        [string]$Endpoint,
        [string]$ApiKey,
        [string]$Prompt,
        [object[]]$MediaContext
    )

    $body = @{
        prompt       = $Prompt
        mediaContext = $MediaContext
    } | ConvertTo-Json -Depth 6

    $headers = @{}
    if ($ApiKey) {
        $headers["Authorization"] = "Bearer $ApiKey"
    }

    try {
        $LblStatus.Text = "Calling LLM backend..."
        $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $body -ContentType "application/json"
        return $response
    }
    catch {
        return [PSCustomObject]@{
            error = $_.Exception.Message
        }
    }
}

#--------------------------- Event handlers ---------------------------#

# Add local media
$BtnAddLocal.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Multiselect = $true
    $ofd.Filter = "Media Files|*.mp4;*.mp3;*.wav;*.mkv;*.avi;*.flac;*.jpg;*.png;*.gif;*.webm|All Files|*.*"
    [void][System.Windows.Forms.DialogResult]$result = $ofd.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($file in $ofd.FileNames) {
            $name = [System.IO.Path]::GetFileName($file)
            $ext  = [System.IO.Path]::GetExtension($file).TrimStart('.').ToUpperInvariant()
            Add-MediaItem -Name $name -Path $file -Type $ext
        }
        $LblStatus.Text = "Added local media."
    }
})

# Add URL media
$BtnAddUrl.Add_Click({
    $url = [System.Windows.MessageBox]::Show("Paste URL in clipboard and press OK.`n(Or Cancel to abort.)","Add Media URL","OKCancel","Information")
    if ($url -eq [System.Windows.MessageBoxResult]::OK) {
        $clip = [System.Windows.Clipboard]::GetText()
        if ($clip) {
            Add-MediaItem -Name $clip -Path $clip -Type "URL"
            $LblStatus.Text = "Added URL media."
        }
        else {
            $LblStatus.Text = "Clipboard empty; no URL added."
        }
    }
})

# Remove selected media
$BtnRemove.Add_Click({
    $selected = @($MediaList.SelectedItems)
    if (-not $selected -or $selected.Count -eq 0) {
        $LblStatus.Text = "No media selected to remove."
        return
    }
    foreach ($item in $selected) {
        [void]$MediaItems.Remove($item)
    }
    $LblStatus.Text = "Removed selected media."
})

# Refresh from server (placeholder)
$BtnRefreshServer.Add_Click({
    # TODO: Wire to your media server listing endpoint
    # Example contract:
    # GET $TxtEndpoint.Text + "/media" -> returns list of { name, path, type }
    $LblStatus.Text = "Server refresh not implemented. Wire your media listing endpoint here."
})

# Analyze with LLM
$BtnAnalyze.Add_Click({
    $prompt = $TxtPrompt.Text.Trim()
    if (-not $prompt) {
        $LblStatus.Text = "Prompt is empty."
        return
    }

    $endpoint = $TxtEndpoint.Text.Trim()
    if (-not $endpoint) {
        $LblStatus.Text = "Endpoint is empty."
        return
    }

    $apiKey = $TxtApiKey.Password

    $mediaContext = @()
    if ($ChkIncludeMediaContext.IsChecked -eq $true) {
        $mediaContext = @($MediaList.SelectedItems | ForEach-Object {
            @{
                name = $_.Name
                path = $_.Path
                type = $_.Type
            }
        })
    }

    $LblStatus.Text = "Sending request..."
    $TxtResponse.Text = ""

    $job = [System.ComponentModel.BackgroundWorker]::new()
    $job.WorkerSupportsCancellation = $false

    $job.DoWork += {
        param($sender, $e)
        $e.Result = Invoke-LLMMediaRequest -Endpoint $endpoint -ApiKey $apiKey -Prompt $prompt -MediaContext $mediaContext
    }

    $job.RunWorkerCompleted += {
        param($sender, $e)
        if ($e.Error) {
            $TxtResponse.Text = "Error: " + $e.Error.Message
            $LblStatus.Text = "Error."
        }
        else {
            $result = $e.Result
            if ($result -and $result.error) {
                $TxtResponse.Text = "Backend error: " + $result.error
                $LblStatus.Text = "Backend error."
            }
            else {
                # Expecting JSON like { responseText: "...", ... }
                if ($result.PSObject.Properties.Name -contains "responseText") {
                    $TxtResponse.Text = $result.responseText
                }
                else {
                    $TxtResponse.Text = ($result | ConvertTo-Json -Depth 8)
                }
                $LblStatus.Text = "Done."
            }
        }
    }

    $job.RunWorkerAsync()
})

#--------------------------- Run window ---------------------------#
$window.Add_Closed({ $window.Dispatcher.InvokeShutdown() }) | Out-Null
[System.Windows.Threading.Dispatcher]::Run()
