Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ================== CRYPTO CORE (AES) ==================
function New-AesKeyPair {
    param(
        [int]$KeySize = 256
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.KeySize = $KeySize
    $aes.GenerateKey()
    $aes.GenerateIV()
    [PSCustomObject]@{
        Key = $aes.Key
        IV  = $aes.IV
    }
}

function Protect-Text {
    param(
        [Parameter(Mandatory)][string]$PlainText,
        [byte[]]$Key,
        [byte[]]$IV
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    $aes.IV  = $IV

    $enc = $aes.CreateEncryptor()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    $cipherBytes = $enc.TransformFinalBlock($bytes, 0, $bytes.Length)
    [Convert]::ToBase64String($cipherBytes)
}

function Unprotect-Text {
    param(
        [Parameter(Mandatory)][string]$CipherText,
        [byte[]]$Key,
        [byte[]]$IV
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    $aes.IV  = $IV

    $dec = $aes.CreateDecryptor()
    $cipherBytes = [Convert]::FromBase64String($CipherText)
    $plainBytes = $dec.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
    [System.Text.Encoding]::UTF8.GetString($plainBytes)
}

# Single shared key for demo – in real app, per-conversation/session keys, key exchange, etc.
$Global:Crypto = New-AesKeyPair

# ================== XAML UI ==================
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Viber-like Secure Chat" Height="600" Width="900"
        WindowStartupLocation="CenterScreen"
        Background="#FF20232A">
    <Grid Margin="0">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="220"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- LEFT: CONTACTS / CHATS LIST -->
        <Border Grid.Column="0" Background="#FF1E1E1E">
            <DockPanel>
                <TextBlock Text="Chats"
                           DockPanel.Dock="Top"
                           Margin="10"
                           Foreground="White"
                           FontSize="18"
                           FontWeight="Bold"/>
                <ListBox x:Name="ChatsList"
                         Margin="5"
                         Background="#FF252525"
                         Foreground="White"
                         BorderThickness="0"
                         SelectionMode="Single">
                    <ListBox.ItemTemplate>
                        <DataTemplate>
                            <StackPanel Orientation="Vertical" Margin="5">
                                <TextBlock Text="{Binding Name}" FontWeight="Bold"/>
                                <TextBlock Text="{Binding LastMessage}" FontSize="11" Foreground="#FFAAAAAA"/>
                            </StackPanel>
                        </DataTemplate>
                    </ListBox.ItemTemplate>
                </ListBox>
            </DockPanel>
        </Border>

        <!-- RIGHT: CONVERSATION -->
        <Grid Grid.Column="1" Margin="0">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- HEADER -->
            <Border Grid.Row="0" Background="#FF262626" Padding="10">
                <StackPanel Orientation="Horizontal">
                    <TextBlock x:Name="ChatTitle"
                               Text="Select a chat"
                               Foreground="White"
                               FontSize="18"
                               FontWeight="Bold"/>
                    <TextBlock Text="  •  End-to-end encrypted (demo)"
                               Foreground="#FF7ED957"
                               Margin="10,0,0,0"
                               VerticalAlignment="Center"/>
                </StackPanel>
            </Border>

            <!-- MESSAGES -->
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Background="#FF20232A">
                <ItemsControl x:Name="MessagesPanel">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <Border Margin="10"
                                    Padding="8"
                                    CornerRadius="8"
                                    Background="{Binding BubbleColor}"
                                    HorizontalAlignment="{Binding Align}">
                                <StackPanel>
                                    <TextBlock Text="{Binding Text}"
                                               Foreground="White"
                                               TextWrapping="Wrap"
                                               MaxWidth="450"/>
                                    <TextBlock Text="{Binding Time}"
                                               Foreground="#FFAAAAAA"
                                               FontSize="10"
                                               HorizontalAlignment="Right"/>
                                </StackPanel>
                            </Border>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>
            </ScrollViewer>

            <!-- INPUT -->
            <Border Grid.Row="2" Background="#FF262626" Padding="8">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox x:Name="InputBox"
                             Grid.Column="0"
                             Margin="0,0,8,0"
                             Height="60"
                             TextWrapping="Wrap"
                             AcceptsReturn="True"
                             VerticalScrollBarVisibility="Auto"
                             Background="#FF1E1E1E"
                             Foreground="White"
                             BorderBrush="#FF444444"/>
                    <Button x:Name="SendButton"
                            Grid.Column="1"
                            Content="Send"
                            Width="80"
                            Height="60"
                            Background="#FF7F5AF0"
                            Foreground="White"
                            FontWeight="Bold"
                            BorderThickness="0"
                            Cursor="Hand"/>
                </Grid>
            </Border>
        </Grid>
    </Grid>
</Window>
"@

# ================== LOAD XAML ==================
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$ChatsList    = $window.FindName("ChatsList")
$MessagesPanel = $window.FindName("MessagesPanel")
$ChatTitle    = $window.FindName("ChatTitle")
$InputBox     = $window.FindName("InputBox")
$SendButton   = $window.FindName("SendButton")

# Simple in-memory model
$Global:Chats = @(
    [PSCustomObject]@{ Name = "Alice"; LastMessage = "Hey, how are you?"; Id = 1 },
    [PSCustomObject]@{ Name = "Bob";   LastMessage = "Ping me later";     Id = 2 }
)

$ChatsList.ItemsSource = $Global:Chats

$Global:CurrentChatId = $null
$Global:Messages = @{} # ChatId -> list of messages

function Add-Message {
    param(
        [int]$ChatId,
        [string]$Text,
        [bool]$IsOutgoing
    )

    if (-not $Global:Messages.ContainsKey($ChatId)) {
        $Global:Messages[$ChatId] = New-Object System.Collections.ObjectModel.ObservableCollection[object]
    }

    $align = if ($IsOutgoing) { "Right" } else { "Left" }
    $color = if ($IsOutgoing) { "#FF7F5AF0" } else { "#FF333842" }

    $msg = [PSCustomObject]@{
        Text        = $Text
        Time        = (Get-Date).ToString("HH:mm")
        Align       = $align
        BubbleColor = $color
    }

    $Global:Messages[$ChatId].Add($msg)

    if ($Global:CurrentChatId -eq $ChatId) {
        $MessagesPanel.ItemsSource = $Global:Messages[$ChatId]
    }
}

# Demo: simulate remote incoming message (local only)
function Simulate-IncomingMessage {
    param(
        [int]$ChatId,
        [string]$PlainText
    )
    # In a real app, you'd receive CipherText from network and call Unprotect-Text
    Add-Message -ChatId $ChatId -Text $PlainText -IsOutgoing:$false
}

# ================== EVENTS ==================
$ChatsList.Add_SelectionChanged({
    if ($ChatsList.SelectedItem -ne $null) {
        $chat = $ChatsList.SelectedItem
        $Global:CurrentChatId = $chat.Id
        $ChatTitle.Text = $chat.Name

        if (-not $Global:Messages.ContainsKey($chat.Id)) {
            $Global:Messages[$chat.Id] = New-Object System.Collections.ObjectModel.ObservableCollection[object]
        }
        $MessagesPanel.ItemsSource = $Global:Messages[$chat.Id]
    }
})

$SendHandler = {
    if (-not $Global:CurrentChatId) { return }
    $text = $InputBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($text)) { return }

    # Encrypt before "sending"
    $cipher = Protect-Text -PlainText $text -Key $Global:Crypto.Key -IV $Global:Crypto.IV

    # In a real client: send $cipher over network to server/peer here

    # Locally show outgoing (plaintext)
    Add-Message -ChatId $Global:CurrentChatId -Text $text -IsOutgoing:$true

    # Demo: echo back decrypted as if from remote
    $plainBack = Unprotect-Text -CipherText $cipher -Key $Global:Crypto.Key -IV $Global:Crypto.IV
    Simulate-IncomingMessage -ChatId $Global:CurrentChatId -PlainText ("Echo: " + $plainBack)

    $InputBox.Clear()
}

$SendButton.Add_Click($SendHandler)

$InputBox.Add_KeyDown({
    param($sender, $e)
    if ($e.Key -eq "Enter" -and -not $e.KeyboardDevice.Modifiers.HasFlag([System.Windows.Input.ModifierKeys]::Shift)) {
        $e.Handled = $true
        & $SendHandler
    }
})

# ================== RUN ==================
$window.ShowDialog() | Out-Null
