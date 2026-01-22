Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell DOS Commander"
$form.Size = New-Object System.Drawing.Size(1000,600)
$form.StartPosition = "CenterScreen"

# Function to create a file panel
function Create-Panel($x) {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($x,10)
    $panel.Size = New-Object System.Drawing.Size(470,520)

    $pathBox = New-Object System.Windows.Forms.TextBox
    $pathBox.Dock = "Top"

    $listView = New-Object System.Windows.Forms.ListView
    $listView.View = "Details"
    $listView.FullRowSelect = $true
    $listView.Dock = "Fill"
    $listView.Columns.Add("Name",250)
    $listView.Columns.Add("Size",100)

    $panel.Controls.Add($listView)
    $panel.Controls.Add($pathBox)

    return @{
        Panel = $panel
        PathBox = $pathBox
        ListView = $listView
    }
}

# Load directory contents
function Load-Directory($path, $listView, $pathBox) {
    if (-not (Test-Path $path)) { return }

    $listView.Items.Clear()
    $pathBox.Text = $path

    if ($path -ne (Get-Item $path).Root.FullName) {
        $item = New-Object System.Windows.Forms.ListViewItem("..")
        $item.Tag = "UP"
        $listView.Items.Add($item)
    }

    Get-ChildItem $path | ForEach-Object {
        $item = New-Object System.Windows.Forms.ListViewItem($_.Name)
        $item.Tag = $_.FullName
        if ($_.PSIsContainer) {
            $item.SubItems.Add("<DIR>")
        } else {
            $item.SubItems.Add($_.Length)
        }
        $listView.Items.Add($item)
    }
}

# Create panels
$left = Create-Panel 10
$right = Create-Panel 500

$form.Controls.Add($left.Panel)
$form.Controls.Add($right.Panel)

# Default paths
Load-Directory "C:\" $left.ListView $left.PathBox
Load-Directory "C:\" $right.ListView $right.PathBox

# Double-click navigation
$navHandler = {
    $lv = $_.Sender
    $item = $lv.SelectedItems[0]
    if (-not $item) { return }

    if ($item.Tag -eq "UP") {
        $newPath = Split-Path $lv.Parent.Controls[1].Text -Parent
    } else {
        $newPath = $item.Tag
    }

    if (Test-Path $newPath -PathType Container) {
        Load-Directory $newPath $lv $lv.Parent.Controls[1]
    }
}

$left.ListView.Add_DoubleClick($navHandler)
$right.ListView.Add_DoubleClick($navHandler)

# Run
[void]$form.ShowDialog()
