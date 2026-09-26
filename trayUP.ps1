Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Tray Cleanup Utility"
$form.Size = New-Object System.Drawing.Size(600,450)
$form.StartPosition = "CenterScreen"
$form.BackColor = "#202020"
$form.ForeColor = "White"

# NotifyIcon
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons\]::Information
$notify.Text = "Tray Cleanup Utility"
$notify.Visible = $true

# Context Menu
$menu = New-Object System.Windows.Forms.ContextMenuStrip

$openItem = $menu.Items.Add("Open")
$exitItem = $menu.Items.Add("Exit")

$notify.ContextMenuStrip = $menu

$openItem.Add_Click({
    $form.Show()
    $form.WindowState = "Normal"
})

$exitItem.Add_Click({
    $notify.Dispose()
    $form.Close()
})

$notify.Add_DoubleClick({
    $form.Show()
    $form.WindowState = "Normal"
})

# Title
$title = New-Object System.Windows.Forms.Label
$title.Text = "Tray Cleanup App"
$title.Font = New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle\]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($title)

# Status Box
$output = New-Object System.Windows.Forms.TextBox
$output.Multiline = $true
$output.ScrollBars = "Vertical"
$output.Size = New-Object System.Drawing.Size(540,220)
$output.Location = New-Object System.Drawing.Point(20,70)
$output.BackColor = "#101010"
$output.ForeColor = "Lime"
$form.Controls.Add($output)

# Scan Button
$scanBtn = New-Object System.Windows.Forms.Button
$scanBtn.Text = "Scan System"
$scanBtn.Size = New-Object System.Drawing.Size(150,40)
$scanBtn.Location = New-Object System.Drawing.Point(20,320)
$form.Controls.Add($scanBtn)

# Cleanup Button
$cleanBtn = New-Object System.Windows.Forms.Button
$cleanBtn.Text = "Clean Temp Files"
$cleanBtn.Size = New-Object System.Drawing.Size(150,40)
$cleanBtn.Location = New-Object System.Drawing.Point(190,320)
$form.Controls.Add($cleanBtn)

# Startup Button
$startupBtn = New-Object System.Windows.Forms.Button
$startupBtn.Text = "View Startup"
$startupBtn.Size = New-Object System.Drawing.Size(150,40)
$startupBtn.Location = New-Object System.Drawing.Point(360,320)
$form.Controls.Add($startupBtn)

# Scan Action
$scanBtn.Add_Click({

    $temp = (Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum

    $tempMB = [math\]::Round($temp / 1MB,2)

    $output.Text = @"
System Scan Complete

Computer: $env:COMPUTERNAME
User: $env:USERNAME

Temp Files Size:
$tempMB MB

Free Disk Space:
$([
