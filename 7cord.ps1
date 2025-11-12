#requires -version 2.0
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# App state
$AppState = New-Object PSObject -Property @{
    CurrentChannel = 'general'
    Channels       = @('general','dev','random','support')
    Users          = @('Vasilis','Anna','Nikos','Bot')
    Messages       = @{
        'general' = New-Object System.Collections.ArrayList
        'dev'     = New-Object System.Collections.ArrayList
        'random'  = New-Object System.Collections.ArrayList
        'support' = New-Object System.Collections.ArrayList
    }
    Me             = 'Vasilis'
}

# Helper: append message to channel
function Add-Message {
    param(
        [string]$channel,
        [string]$author,
        [string]$text
    )
    if (-not $AppState.Messages.ContainsKey($channel)) {
        $AppState.Messages[$channel] = New-Object System.Collections.ArrayList
    }
    $null = $AppState.Messages[$channel].Add([PSCustomObject]@{
        Timestamp = (Get-Date)
        Author    = $author
        Text      = $text
    })
}

# Seed demo messages
Add-Message 'general' 'Anna'   'Καλώς ήρθες! Αυτό είναι ένα demo UI.'
Add-Message 'general' 'Vasilis' 'Δουλεύει καλά σε Windows 7.'
Add-Message 'dev'     'Nikos'  'Push the build after lunch.'
Add-Message 'random'  'Bot'    'Tip: Press Enter to send.'
Add-Message 'support' 'Anna'   'Ping me if you need help.'

# UI colors (Discord-ish dark)
$colors = @{
    Bg          = [System.Drawing.Color]::FromArgb(54,57,63)
    Sidebar     = [System.Drawing.Color]::FromArgb(47,49,54)
    Header      = [System.Drawing.Color]::FromArgb(32,34,37)
    ChatBg      = [System.Drawing.Color]::FromArgb(64,68,75)
    ChatText    = [System.Drawing.Color]::White
    MutedText   = [System.Drawing.Color]::FromArgb(170,170,170)
    Accent      = [System.Drawing.Color]::FromArgb(114,137,218)
    InputBg     = [System.Drawing.Color]::FromArgb(69,72,78)
}

# Fonts
$fonts = @{
    Ui      = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Regular)
    UiBold  = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
    Mono    = New-Object System.Drawing.Font('Consolas', 9, [System.Drawing.FontStyle]::Regular)
}

# Main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Discord-like Client (PowerShell)'
$form.StartPosition = 'CenterScreen'
$form.BackColor = $colors.Bg
$form.Width  = 980
$form.Height = 640

# Sidebar (channels + user list)
$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Dock = 'Left'
$sidebar.Width = 200
$sidebar.BackColor = $colors.Sidebar

# Header bar
$header = New-Object System.Windows.Forms.Panel
$header.Dock = 'Top'
$header.Height = 40
$header.BackColor = $colors.Header

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "# $($AppState.CurrentChannel)"
$lblTitle.ForeColor = $colors.ChatText
$lblTitle.Font = $fonts.UiBold
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(12, 11)
$header.Controls.Add($lblTitle)

# Channel list
$lblChannels = New-Object System.Windows.Forms.Label
$lblChannels.Text = 'Channels'
$lblChannels.ForeColor = $colors.MutedText
$lblChannels.Font = $fonts.UiBold
$lblChannels.AutoSize = $true
$lblChannels.Location = New-Object System.Drawing.Point(12, 10)

$listChannels = New-Object System.Windows.Forms.ListBox
$listChannels.Font = $fonts.Ui
$listChannels.ForeColor = $colors.ChatText
$listChannels.BackColor = $colors.Sidebar
$listChannels.BorderStyle = 'None'
$listChannels.Location = New-Object System.Drawing.Point(12, 30)
$listChannels.Size = New-Object System.Drawing.Size(176, 200)
$AppState.Channels | ForEach-Object { [void]$listChannels.Items.Add($_) }
$listChannels.SelectedItem = $AppState.CurrentChannel

# Users list
$lblUsers = New-Object System.Windows.Forms.Label
$lblUsers.Text = 'Users'
$lblUsers.ForeColor = $colors.MutedText
$lblUsers.Font = $fonts.UiBold
$lblUsers.AutoSize = $true
$lblUsers.Location = New-Object System.Drawing.Point(12, 250)

$listUsers = New-Object System.Windows.Forms.ListBox
$listUsers.Font = $fonts.Ui
$listUsers.ForeColor = $colors.ChatText
$listUsers.BackColor = $colors.Sidebar
$listUsers.BorderStyle = 'None'
$listUsers.Location = New-Object System.Drawing.Point(12, 270)
$listUsers.Size = New-Object System.Drawing.Size(176, 280)
$AppState.Users | ForEach-Object { [void]$listUsers.Items.Add($_) }

$sidebar.Controls.AddRange(@($lblChannels, $listChannels, $lblUsers, $listUsers))

# Chat area panel
$main = New-Object System.Windows.Forms.Panel
$main.Dock = 'Fill'
$main.BackColor = $colors.ChatBg

# Chat view (RichTextBox)
$chat = New-Object System.Windows.Forms.RichTextBox
$chat.Dock = 'Top'
$chat.Height = 440
$chat.ReadOnly = $true
$chat.BackColor = $colors.ChatBg
$chat.BorderStyle = 'None'
$chat.ForeColor = $colors.ChatText
$chat.Font = $fonts.Ui

# Message input
$inputPanel = New-Object System.Windows.Forms.Panel
$inputPanel.Dock = 'Bottom'
$inputPanel.Height = 100
$inputPanel.BackColor = $colors.ChatBg

$txtMessage = New-Object System.Windows.Forms.TextBox
$txtMessage.Multiline = $true
$txtMessage.Font = $fonts.Ui
$txtMessage.ForeColor = $colors.ChatText
$txtMessage.BackColor = $colors.InputBg
$txtMessage.BorderStyle = 'FixedSingle'
$txtMessage.Location = New-Object System.Drawing.Point(12, 12)
$txtMessage.Size = New-Object System.Drawing.Size(640, 70)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = 'Send'
$btnSend.Font = $fonts.UiBold
$btnSend.ForeColor = [System.Drawing.Color]::White
$btnSend.BackColor = $colors.Accent
$btnSend.FlatStyle = 'Flat'
$btnSend.Location = New-Object System.Drawing.Point(670, 12)
$btnSend.Size = New-Object System.Drawing.Size(90, 30)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = 'Clear'
$btnClear.Font = $fonts.Ui
$btnClear.ForeColor = [System.Drawing.Color]::White
$btnClear.BackColor = [System.Drawing.Color]::FromArgb(79,84,92)
$btnClear.FlatStyle = 'Flat'
$btnClear.Location = New-Object System.Drawing.Point(670, 52)
$btnClear.Size = New-Object System.Drawing.Size(90, 30)

$inputPanel.Controls.AddRange(@($txtMessage, $btnSend, $btnClear))

# Status bar
$status = New-Object System.Windows.Forms.StatusStrip
$status.BackColor = $colors.Header
$status.ForeColor = $colors.MutedText
$lblStatus = New-Object System.Windows.Forms.ToolStripStatusLabel
$lblStatus.Text = "Signed in as $($AppState.Me)"
$null = $status.Items.Add($lblStatus)

# Layout
$form.Controls.AddRange(@($main, $sidebar, $header, $status))
$main.Controls.AddRange(@($chat, $inputPanel))

# Render messages for current channel
function Render-Channel {
    param([string]$channel)
    $chat.Clear()
    $lblTitle.Text = "# $channel"
    $AppState.Messages[$channel] | ForEach-Object {
        $line = "[{0}] {1}: {2}" -f $_.Timestamp.ToString('HH:mm'), $_.Author, $_.Text
        $chat.SelectionColor = $colors.MutedText
        $chat.AppendText("[$($_.Timestamp.ToString('HH:mm'))] ")
        $chat.SelectionColor = [System.Drawing.Color]::White
        $chat.AppendText("$($_.Author): ")
        $chat.SelectionColor = $colors.ChatText
        $chat.AppendText("$($_.Text)`r`n")
    }
    $chat.SelectionStart = $chat.Text.Length
    $chat.ScrollToCaret()
}

# Events
$listChannels.Add_SelectedIndexChanged({
    $AppState.CurrentChannel = $listChannels.SelectedItem
    Render-Channel -channel $AppState.CurrentChannel
})

$btnSend.Add_Click({
    $text = ($txtMessage.Text ?? '').Trim()
    if ($text.Length -gt 0) {
        Add-Message -channel $AppState.CurrentChannel -author $AppState.Me -text $text
        $txtMessage.Clear()
        Render-Channel -channel $AppState.CurrentChannel
        $lblStatus.Text = "Sent to #$($AppState.CurrentChannel) at $(Get-Date -Format 'HH:mm:ss')"
    }
})

$btnClear.Add_Click({
    $AppState.Messages[$AppState.CurrentChannel].Clear()
    Render-Channel -channel $AppState.CurrentChannel
    $lblStatus.Text = "Cleared #$($AppState.CurrentChannel)"
})

$txtMessage.Add_KeyDown({
    param($sender,$e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter -and -not $e.Shift) {
        $e.SuppressKeyPress = $true
        $btnSend.PerformClick()
    }
})

# Initial render
Render-Channel -channel $AppState.CurrentChannel

# Run
$form.Add_Shown({ $form.Activate() })
[void][System.Windows.Forms.Application]::EnableVisualStyles()
[void][System.Windows.Forms.Application]::Run($form)
