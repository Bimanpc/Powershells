Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object Windows.Forms.Form
$form.Text = "AI Photo Editor"
$form.Size = New-Object Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"

# Create a menu strip
$menuStrip = New-Object Windows.Forms.MenuStrip

# File menu
$fileMenu = New-Object Windows.Forms.ToolStripMenuItem("File")
$openMenuItem = New-Object Windows.Forms.ToolStripMenuItem("Open")
$saveMenuItem = New-Object Windows.Forms.ToolStripMenuItem("Save")
$exitMenuItem = New-Object Windows.Forms.ToolStripMenuItem("Exit")

$fileMenu.DropDownItems.AddRange(@($openMenuItem, $saveMenuItem, $exitMenuItem))

# Edit menu
$editMenu = New-Object Windows.Forms.ToolStripMenuItem("Edit")
$undoMenuItem = New-Object Windows.Forms.ToolStripMenuItem("Undo")
$redoMenuItem = New-Object Windows.Forms.ToolStripMenuItem("Redo")

$editMenu.DropDownItems.AddRange(@($undoMenuItem, $redoMenuItem))

# Add menus to the menu strip
$menuStrip.Items.AddRange(@($fileMenu, $editMenu))

# Add the menu strip to the form
$form.Controls.Add($menuStrip)

# Create a picture box to display the photo
$pictureBox = New-Object Windows.Forms.PictureBox
$pictureBox.Size = New-Object Drawing.Size(780, 500)
$pictureBox.Location = New-Object Drawing.Point(10, 50)
$pictureBox.BorderStyle = [Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($pictureBox)

# Event handlers
$exitMenuItem.Add_Click({ $form.Close() })

# Show the form
$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
