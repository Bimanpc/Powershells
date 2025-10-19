Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object Windows.Forms.Form
$form.Text = "AI Parental Control for Android"
$form.Size = '500,400'
$form.StartPosition = "CenterScreen"

# Device ID Input
$deviceLabel = New-Object Windows.Forms.Label
$deviceLabel.Text = "Android Device ID:"
$deviceLabel.Location = '20,20'
$deviceLabel.Size = '120,20'
$form.Controls.Add($deviceLabel)

$deviceBox = New-Object Windows.Forms.TextBox
$deviceBox.Location = '150,20'
$deviceBox.Size = '300,20'
$form.Controls.Add($deviceBox)

# LLM Query Box
$queryLabel = New-Object Windows.Forms.Label
$queryLabel.Text = "Ask AI (e.g. 'Block TikTok'):"
$queryLabel.Location = '20,60'
$queryLabel.Size = '200,20'
$form.Controls.Add($queryLabel)

$queryBox = New-Object Windows.Forms.TextBox
$queryBox.Location = '20,90'
$queryBox.Size = '430,80'
$queryBox.Multiline = $true
$form.Controls.Add($queryBox)

# Output Box
$outputBox = New-Object Windows.Forms.TextBox
$outputBox.Location = '20,180'
$outputBox.Size = '430,120'
$outputBox.Multiline = $true
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

# Run Button
$runButton = New-Object Windows.Forms.Button
$runButton.Text = "Run AI Command"
$runButton.Location = '180,320'
$runButton.Size = '120,30'
$form.Controls.Add($runButton)

# AI + ADB Logic
$runButton.Add_Click({
    $device = $deviceBox.Text
    $query = $queryBox.Text

    if (-not $device -or -not $query) {
        $outputBox.Text = "Please enter both device ID and query."
        return
    }

    # Simulated AI response (replace with real API call)
    $aiResponse = switch -Regex ($query.ToLower()) {
        "block tiktok" { "adb -s $device shell pm disable-user com.zhiliaoapp.musically" }
        "limit youtube" { "adb -s $device shell am start -a android.intent.action.VIEW -d 'https://www.youtube.com/parental'" }
        "lock screen" { "adb -s $device shell input keyevent 26" }
        default { "No known command. AI needs training." }
    }

    $outputBox.Text = "AI Response:`n$aiResponse"

    # Optional: Execute ADB command
    # & adb $aiResponse
})

# Show GUI
[void]$form.ShowDialog()
