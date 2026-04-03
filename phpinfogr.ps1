# PHP Info Viewer - PowerShell GUI Application
# Creates a Windows Forms interface to display PHP configuration information

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PHP Information Viewer"
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Create panel for controls
$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = "Top"
$panel.Height = 60
$panel.BackColor = [System.Drawing.Color]::LightGray

# PHP Path label and textbox
$labelPath = New-Object System.Windows.Forms.Label
$labelPath.Text = "PHP Executable Path:"
$labelPath.Location = New-Object System.Drawing.Point(10, 10)
$labelPath.Size = New-Object System.Drawing.Size(150, 25)

$pathTextBox = New-Object System.Windows.Forms.TextBox
$pathTextBox.Location = New-Object System.Drawing.Point(160, 10)
$pathTextBox.Size = New-Object System.Drawing.Size(400, 25)
$pathTextBox.Text = "php.exe"

# Browse button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = New-Object System.Drawing.Point(570, 10)
$browseButton.Size = New-Object System.Drawing.Size(80, 25)

# Load button
$loadButton = New-Object System.Windows.Forms.Button
$loadButton.Text = "Load PHP Info"
$loadButton.Location = New-Object System.Drawing.Point(660, 10)
$loadButton.Size = New-Object System.Drawing.Size(120, 25)
$loadButton.BackColor = [System.Drawing.Color]::LightBlue

# Create output textbox (multiline)
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Dock = "Fill"
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputBox.ReadOnly = $true
$outputBox.ScrollBars = "Both"
$outputBox.BackColor = [System.Drawing.Color]::White

# Status bar
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready"
$$statusBar.Items.Add($$statusLabel)

# Add controls to form
$$panel.Controls.Add($$labelPath)
$$panel.Controls.Add($$pathTextBox)
$$panel.Controls.Add($$browseButton)
$$panel.Controls.Add($$loadButton)

$$form.Controls.Add($$panel)
$$form.Controls.Add($$outputBox)
$$form.Controls.Add($$statusBar)

# Browse button click event
$browseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "PHP Executable|*.exe|All Files|*.*"
    $dialog.Title = "Select PHP Executable"
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathTextBox.Text = $dialog.FileName
    }
})

# Load button click event
$loadButton.Add_Click({
    $phpPath = $pathTextBox.Text
    $statusLabel.Text = "Loading PHP information..."
    
    try {
        # Get PHP version
        $phpVersion = & $phpPath -v 2>&1 | Out-String
        
        # Get phpinfo() HTML output
        $phpInfo = & $phpPath -r "echo phpinfo();" 2>&1 | Out-String
        
        # Display version info
        $outputBox.Clear()
        $outputBox.AppendText("=== PHP VERSION INFORMATION ===`n")
        $$outputBox.AppendText($$phpVersion)
        $outputBox.AppendText("`n`n")
        
        $outputBox.AppendText("=== PHP CONFIGURATION INFO ===`n")
        $$outputBox.AppendText($$phpInfo)
        
        $statusLabel.Text = "PHP information loaded successfully"
    }
    catch {
        $outputBox.AppendText("Error: $_`n")
        $outputBox.AppendText("Make sure PHP is installed and the path is correct.`n")
        $outputLabel.Text = "Error loading PHP information"
    }
})

# Show the form
$form.ShowDialog()
