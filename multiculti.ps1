Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Batch Rename App"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"

# Folder
$lblFolder = New-Object System.Windows.Forms.Label
$lblFolder.Text = "Folder:"
$lblFolder.Location = New-Object System.Drawing.Point(10,15)
$form.Controls.Add($lblFolder)

$txtFolder = New-Object System.Windows.Forms.TextBox
$txtFolder.Location = New-Object System.Drawing.Point(70,10)
$txtFolder.Size = New-Object System.Drawing.Size(550,25)
$form.Controls.Add($txtFolder)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse"
$btnBrowse.Location = New-Object System.Drawing.Point(630,8)
$form.Controls.Add($btnBrowse)

# Find
$lblFind = New-Object System.Windows.Forms.Label
$lblFind.Text = "Find:"
$lblFind.Location = New-Object System.Drawing.Point(10,50)
$form.Controls.Add($lblFind)

$txtFind = New-Object System.Windows.Forms.TextBox
$txtFind.Location = New-Object System.Drawing.Point(70,45)
$txtFind.Size = New-Object System.Drawing.Size(150,25)
$form.Controls.Add($txtFind)

# Replace
$lblReplace = New-Object System.Windows.Forms.Label
$lblReplace.Text = "Replace:"
$lblReplace.Location = New-Object System.Drawing.Point(240,50)
$form.Controls.Add($lblReplace)

$txtReplace = New-Object System.Windows.Forms.TextBox
$txtReplace.Location = New-Object System.Drawing.Point(310,45)
$txtReplace.Size = New-Object System.Drawing.Size(150,25)
$form.Controls.Add($txtReplace)

# Prefix
$lblPrefix = New-Object System.Windows.Forms.Label
$lblPrefix.Text = "Prefix:"
$lblPrefix.Location = New-Object System.Drawing.Point(480,50)
$form.Controls.Add($lblPrefix)

$txtPrefix = New-Object System.Windows.Forms.TextBox
$txtPrefix.Location = New-Object System.Drawing.Point(530,45)
$txtPrefix.Size = New-Object System.Drawing.Size(100,25)
$form.Controls.Add($txtPrefix)

# Suffix
$lblSuffix = New-Object System.Windows.Forms.Label
$lblSuffix.Text = "Suffix:"
$lblSuffix.Location = New-Object System.Drawing.Point(640,50)
$form.Controls.Add($lblSuffix)

$txtSuffix = New-Object System.Windows.Forms.TextBox
$txtSuffix.Location = New-Object System.Drawing.Point(690,45)
$txtSuffix.Size = New-Object System.Drawing.Size(80,25)
$form.Controls.Add($txtSuffix)

# File List
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(10,90)
$listView.Size = New-Object System.Drawing.Size(760,350)
$listView.View = 'Details'
$listView.FullRowSelect = $true
$listView.GridLines = $true

$listView.Columns.Add("Current Name",350) | Out-Null
$listView.Columns.Add("Preview New Name",390) | Out-Null

$form.Controls.Add($listView)

# Buttons
$btnPreview = New-Object System.Windows.Forms.Button
$btnPreview.Text = "Preview"
$btnPreview.Location = New-Object System.Drawing.Point(10,460)
$btnPreview.Size = New-Object System.Drawing.Size(120,40)
$form.Controls.Add($btnPreview)

$btnRename = New-Object System.Windows.Forms.Button
$btnRename.Text = "Rename Files"
$btnRename.Location = New-Object System.Drawing.Point(150,460)
$btnRename.Size = New-Object System.Drawing.Size(120,40)
$form.Controls.Add($btnRename)

# Log
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(10,515)
$txtLog.Size = New-Object System.Drawing.Size(760,40)
$txtLog.Multiline = $true
$form.Controls.Add($txtLog)

# Browse Event
$btnBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog

    if($folderBrowser.ShowDialog() -eq "OK")
    {
        $txtFolder.Text = $folderBrowser.SelectedPath
    }
})

# Preview Event
$btnPreview.Add_Click({

    $listView.Items.Clear()

    if(!(Test-Path $txtFolder.Text))
    {
        [System.Windows.Forms.MessageBox]::Show("Select a valid folder.")
        return
    }

    $files = Get-ChildItem $txtFolder.Text -File

    foreach($file in $files)
    {
        $nameOnly = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

        $newName = $nameOnly.Replace(
            $txtFind.Text,
            $txtReplace.Text
        )

        $newName = $txtPrefix.Text + $newName + $txtSuffix.Text + $file.Extension

        $item = New-Object System.Windows.Forms.ListViewItem($file.Name)
        $item.SubItems.Add($newName) | Out-Null

        $listView.Items.Add($item) | Out-Null
    }

    $txtLog.Text = "Preview generated."
})

# Rename Event
$btnRename.Add_Click({

    foreach($item in $listView.Items)
    {
        try
        {
            Rename-Item `
                -Path (Join-Path $txtFolder.Text $item.Text) `
                -NewName $item.SubItems[1].Text `
                -ErrorAction Stop

            $txtLog.AppendText("Renamed: $($item.Text)`r`n")
        }
        catch
        {
            $txtLog.AppendText("Error: $($_.Exception.Message)`r`n")
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Rename Complete!")
})

[void]$form.ShowDialog()
