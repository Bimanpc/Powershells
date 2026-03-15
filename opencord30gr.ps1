<# 
    Discord-like Client UI (WPF, Single-File .ps1)
    - Left:   Servers list
    - Middle: Channels list
    - Right:  Messages + input box
    - No network logic included; add your own REST/WebSocket layer where marked.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

#---------------------------
# XAML LAYOUT
#---------------------------
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Discord-like Client" Height="600" Width="1000"
        WindowStartupLocation="CenterScreen"
        Background="#202225">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#FFFFFF"/>
        </Style>
        <Style TargetType="ListBox">
            <Setter Property="Background" Value="#2F3136"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#40444B"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#202225"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#5865F2"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#5865F2"/>
            <Setter Property="Padding" Value="6,2"/>
        </Style>
    </Window.Resources>

    <Grid Margin="0">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="70"/>    <!-- Servers -->
            <ColumnDefinition Width="200"/>   <!-- Channels -->
            <ColumnDefinition Width="*"/>     <!-- Chat -->
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Servers panel -->
        <Border Grid.Column="0" Background="#202225">
            <StackPanel>
                <TextBlock Text="Servers" Margin="10" FontWeight="Bold" />
                <ListBox x:Name="ServerList" Margin="5" />
            </StackPanel>
        </Border>

        <!-- Channels panel -->
        <Border Grid.Column="1" Background="#2F3136">
            <DockPanel>
                <TextBlock Text="Channels" Margin="10" FontWeight="Bold" DockPanel.Dock="Top" />
                <ListBox x:Name="ChannelList" Margin="5" />
            </DockPanel>
        </Border>

        <!-- Chat panel -->
        <Border Grid.Column="2" Background="#36393F">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>   <!-- Header -->
                    <RowDefinition Height="*"/>      <!-- Messages -->
                    <RowDefinition Height="Auto"/>   <!-- Input -->
                </Grid.RowDefinitions>

                <!-- Channel header -->
                <Border Grid.Row="0" Background="#2F3136" Padding="10">
                    <TextBlock x:Name="ChannelHeader" Text="#general" FontWeight="Bold" />
                </Border>

                <!-- Messages -->
                <ScrollViewer Grid.Row="1" Margin="10" VerticalScrollBarVisibility="Auto">
                    <StackPanel x:Name="MessagesPanel" />
                </ScrollViewer>

                <!-- Input area -->
                <DockPanel Grid.Row="2" Margin="10">
                    <TextBox x:Name="MessageInput" Height="40" VerticalAlignment="Center" 
                             TextWrapping="Wrap" AcceptsReturn="True" />
                    <Button x:Name="SendButton" Content="Send" Margin="10,0,0,0" Width="80" />
                </DockPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

#---------------------------
# PARSE XAML
#---------------------------
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

#---------------------------
# GET CONTROLS
#---------------------------
$ServerList    = $window.FindName("ServerList")
$ChannelList   = $window.FindName("ChannelList")
$MessagesPanel = $window.FindName("MessagesPanel")
$MessageInput  = $window.FindName("MessageInput")
$SendButton    = $window.FindName("SendButton")
$ChannelHeader = $window.FindName("ChannelHeader")

#---------------------------
# MOCK DATA
#---------------------------
$servers = @(
    @{ Name = "Dev Hub";   Id = "srv-dev"   },
    @{ Name = "Friends";   Id = "srv-friends" },
    @{ Name = "Gaming";    Id = "srv-gaming" }
)

$channelsByServer = @{
    "srv-dev"     = @("#general", "#builds", "#infra")
    "srv-friends" = @("#chat", "#memes")
    "srv-gaming"  = @("#lobby", "#raids", "#pvp")
}

# In-memory messages:  [serverId][channelName] -> list of messages
$messages = @{}

#---------------------------
# HELPER: ADD MESSAGE TO UI
#---------------------------
function Add-MessageToUI {
    param(
        [string]$author,
        [string]$content
    )

    $msgPanel = New-Object System.Windows.Controls.StackPanel
    $msgPanel.Margin = '0,0,0,8'

    $authorBlock = New-Object System.Windows.Controls.TextBlock
    $authorBlock.Text = $author
    $authorBlock.FontWeight = 'Bold'
    $authorBlock.Foreground = [Windows.Media.Brushes]::LightBlue

    $contentBlock = New-Object System.Windows.Controls.TextBlock
    $contentBlock.Text = $content
    $contentBlock.TextWrapping = 'Wrap'

    $msgPanel.Children.Add($authorBlock) | Out-Null
    $msgPanel.Children.Add($contentBlock) | Out-Null

    $MessagesPanel.Children.Add($msgPanel) | Out-Null
}

function Load-MessagesForChannel {
    param(
        [string]$serverId,
        [string]$channelName
    )

    $MessagesPanel.Children.Clear()

    if (-not $messages.ContainsKey($serverId)) { return }
    if (-not $messages[$serverId].ContainsKey($channelName)) { return }

    foreach ($m in $messages[$serverId][$channelName]) {
        Add-MessageToUI -author $m.Author -content $m.Content
    }
}

#---------------------------
# POPULATE SERVERS
#---------------------------
foreach ($s in $servers) {
    $item = New-Object System.Windows.Controls.ListBoxItem
    $item.Content = $s.Name
    $item.Tag     = $s.Id
    $ServerList.Items.Add($item) | Out-Null
}

#---------------------------
# EVENT: SERVER SELECTION
#---------------------------
$ServerList.Add_SelectionChanged({
    $selected = $ServerList.SelectedItem
    if (-not $selected) { return }

    $serverId = $selected.Tag

    $ChannelList.Items.Clear()
    $Channels = $channelsByServer[$serverId]

    foreach ($c in $Channels) {
        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Content = $c
        $ChannelList.Items.Add($item) | Out-Null
    }

    if ($ChannelList.Items.Count -gt 0) {
        $ChannelList.SelectedIndex = 0
    }
})

#---------------------------
# EVENT: CHANNEL SELECTION
#---------------------------
$ChannelList.Add_SelectionChanged({
    $serverItem = $ServerList.SelectedItem
    $channelItem = $ChannelList.SelectedItem
    if (-not $serverItem -or -not $channelItem) { return }

    $serverId    = $serverItem.Tag
    $channelName = $channelItem.Content

    $ChannelHeader.Text = $channelName
    Load-MessagesForChannel -serverId $serverId -channelName $channelName
})

#---------------------------
# EVENT: SEND MESSAGE
#---------------------------
$SendAction = {
    $text = $MessageInput.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($text)) { return }

    $serverItem  = $ServerList.SelectedItem
    $channelItem = $ChannelList.SelectedItem
    if (-not $serverItem -or -not $channelItem) { return }

    $serverId    = $serverItem.Tag
    $channelName = $channelItem.Content

    if (-not $messages.ContainsKey($serverId)) {
        $messages[$serverId] = @{}
    }
    if (-not $messages[$serverId].ContainsKey($channelName)) {
        $messages[$serverId][$channelName] = New-Object System.Collections.ArrayList
    }

    # Local append
    [void]$messages[$serverId][$channelName].Add([pscustomobject]@{
        Author  = "You"
        Content = $text
    })

    # UI append
    Add-MessageToUI -author "You" -content $text
    $MessageInput.Clear()

    # -----------------------------
    # BACKEND HOOK:
    # Here you’d call your REST/WebSocket send function, e.g.:
    # Send-DiscordMessage -ServerId $serverId -Channel $channelName -Content $text
    # -----------------------------
}

$SendButton.Add_Click($SendAction)
$MessageInput.Add_KeyDown({
    param($sender, $e)
    if ($e.Key -eq 'Enter' -and -not $e.KeyboardDevice.Modifiers.HasFlag([System.Windows.Input.ModifierKeys]::Shift)) {
        $e.Handled = $true
        & $SendAction
    }
})

#---------------------------
# INITIAL SELECTION
#---------------------------
if ($ServerList.Items.Count -gt 0) {
    $ServerList.SelectedIndex = 0
}

#---------------------------
# SHOW WINDOW
#---------------------------
$window.ShowDialog() | Out-Null
