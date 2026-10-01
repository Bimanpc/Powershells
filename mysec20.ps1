Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "AI LLM Anti-Ransomware File Scanner"
$form.Size = New-Object System.Drawing.Size(900,600)
$form.StartPosition = "CenterScreen"

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Select Folder"
$btnBrowse.Location = New-Object System.Drawing.Point(10,10)
$btnBrowse.Size = New-Object System.Drawing.Size(120,35)

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "Scan"
$btnScan.Location = New-Object System.Drawing.Point(140,10)
$btnScan.Size = New-Object System.Drawing.Size(120,35)

$txtFolder = New-Object System.Windows.Forms.TextBox
$txtFolder.Location = New-Object System.Drawing.Point(10,55)
$txtFolder.Size = New-Object System.Drawing.Size(850,25)

$listResults = New-Object System.Windows.Forms.ListView
$listResults.Location = New-Object System.Drawing.Point(10,90)
$listResults.Size = New-Object System.Drawing.Size(860,420)
$listResults.View = "Details"
$listResults.FullRowSelect = $true

$listResults.Columns.Add("File",500)
$listResults.Columns.Add("Status",150)
$listResults.Columns.Add("Reason",180)

$status = New-Object System.Windows.Forms.Label
$status.Location = New-Object System.Drawing.Point(10,525)
$status.Size = New-Object System.Drawing.Size(850,25)
$status.Text = "Ready"

$form.Controls.AddRange(@(
    $btnBrowse,
    $btnScan,
    $txtFolder,
    $listResults,
    $status
))

$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog

$btnBrowse.Add_Click({
    if($folderDialog.ShowDialog() -eq "OK"){
        $txtFolder.Text = $folderDialog.SelectedPath
    }
})

function Test-SuspiciousFile {
    param($File)

    $suspiciousExt = @(
        ".locked",".crypt",".encrypted",
        ".locky",".zepto",".cerber",
        ".cryptolocker",".wncry",
        ".ryk",".ryuk"
    )

    $reason = ""

    if($suspiciousExt -contains $File.Extension.ToLower()){
        $reason += "Known ransomware extension "
    }

    if($File.Name.Length -gt 40){
        $reason += "Long filename "
    }

    if($File.LastWriteTime -gt (Get-Date).AddDays(-2)){
        $reason += "Recently modified "
    }

    if($reason -eq ""){
        return @{
            Status="Clean"
            Reason="No indicators"
        }
    }
    else{
        return @{
            Status="Suspicious"
            Reason=$reason
        }
    }
}

$btnScan.Add_Click({

    $listResults.Items.Clear()

    if(-not (Test-Path $txtFolder.Text)){
        [System.Windows.Forms.MessageBox]::Show(
            "Select a valid folder."
        )
        return
    }

    $status.Text = "Scanning..."

    Get-ChildItem $txtFolder.Text -File -Recurse -ErrorAction SilentlyContinue |
    ForEach-Object {

        $result = Test-SuspiciousFile $_

        $item = New-Object System.Windows.Forms.ListViewItem($_.FullName)
        $item.SubItems.Add($result.Status)
        $item.SubItems.Add($result.Reason)

        if($result.Status -eq "Suspicious"){
            $item.BackColor = "LightCoral"
        }

        $listResults.Items.Add($item) | Out-Null
    }

    $status.Text = "Scan completed. Files checked: $($listResults.Items.Count)"
})

[void]$form.ShowDialog()
