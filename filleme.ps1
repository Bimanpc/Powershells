Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell File Manager"
$form.Size = New-Object System.Drawing.Size(900,600)
$form.StartPosition = "CenterScreen"

# --- Split Container ---
$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = "Fill"
$split.SplitterDistance = 250
$form.Controls.Add($split)

# --- TreeView (Folders) ---
$tree = New-Object System.Windows.Forms.TreeView
$tree.Dock = "Fill"
$split.Panel1.Controls.Add($tree)

# --- ListView (Files) ---
$list = New-Object System.Windows.Forms.ListView
$list.Dock = "Fill"
$list.View = "Details"
$list.FullRowSelect = $true
$list.Columns.Add("Name",300)
$list.Columns.Add("Size",100)
$list.Columns.Add("Type",120)
$list.Columns.Add("Modified",150)
$split.Panel2.Controls.Add($list)

# --- Load Drives ---
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $node = New-Object System.Windows.Forms.TreeNode($_.Root)
    $node.Tag = $_.Root
    $node.Nodes.Add("Loading...")
    $tree.Nodes.Add($node)
}

# --- Expand Folder ---
$tree.add_BeforeExpand({
    $node = $_.Node
    $node.Nodes.Clear()
    try {
        Get-ChildItem -Directory $node.Tag -ErrorAction SilentlyContinue | ForEach-Object {
            $child = New-Object System.Windows.Forms.TreeNode($_.Name)
            $child.Tag = $_.FullName
            $child.Nodes.Add("Loading...")
            $node.Nodes.Add($child)
        }
    } catch {}
})

# --- Select Folder ---
$tree.add_AfterSelect({
    $list.Items.Clear()
    $path = $_.Node.Tag

    Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object {
        $item = New-Object System.Windows.Forms.ListViewItem($_.Name)
        $item.Tag = $_.FullName

        if ($_.PSIsContainer) {
            $item.SubItems.Add("")
            $item.SubItems.Add("Folder")
        } else {
            $item.SubItems.Add([math]::Round($_.Length/1KB,2).ToString() + " KB")
            $item.SubItems.Add($_.Extension)
        }

        $item.SubItems.Add($_.LastWriteTime)
        $list.Items.Add($item)
    }
})

# --- Double-Click Navigation ---
$list.add_DoubleClick({
    if ($list.SelectedItems.Count -eq 1) {
        $path = $list.SelectedItems[0].Tag
        if (Test-Path $path -PathType Container) {
            $tree.SelectedNode.Nodes.Clear()
            $tree.SelectedNode.Tag = $path
            $tree.SelectedNode.Text = Split-Path $path -Leaf
            $tree.SelectedNode.Expand()
        }
    }
})

# --- Context Menu (Delete) ---
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$delete = $menu.Items.Add("Delete")
$delete.add_Click({
    foreach ($item in $list.SelectedItems) {
        Remove-Item $item.Tag -Recurse -Force -Confirm
    }
    $tree.SelectedNode = $tree.SelectedNode
})
$list.ContextMenuStrip = $menu

# --- Run ---
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
