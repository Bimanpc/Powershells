<#
.SYNOPSIS
  Simple GUI tool for "Cache / Memory cleanup" with Greek cache‑memory notes.

.NOTES
  Save as: CacheMemoryCleanup.ps1
  Run:  powershell.exe -ExecutionPolicy Bypass -File .\CacheMemoryCleanup.ps1
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#-----------------------------#
# Helper functions (no admin) #
#-----------------------------#

function Clear-TempFiles {
    try {
        $paths = @(
            $env:TEMP,
            "$env:WINDIR\Temp"
        )

        foreach ($p in $paths) {
            if (Test-Path $p) {
                Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        [System.Windows.Forms.MessageBox]::Show("Temp αρχεία καθαρίστηκαν (όσο ήταν δυνατόν).","Ολοκλήρωση")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Σφάλμα στο καθάρισμα Temp: $($_.Exception.Message)","Σφάλμα")
    }
}

function Clear-DnsCache {
    try {
        ipconfig /flushdns | Out-Null
        [System.Windows.Forms.MessageBox]::Show("DNS cache καθαρίστηκε.","Ολοκλήρωση")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Σφάλμα στο DNS flush: $($_.Exception.Message)","Σφάλμα")
    }
}

function Clear-ExplorerCache {
    try {
        $paths = @(
            "$env:LOCALAPPDATA\Microsoft\Windows\Explorer",
            "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
            "$env:LOCALAPPDATA\Microsoft\Windows\History"
        )

        foreach ($p in $paths) {
            if (Test-Path $p) {
                Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        [System.Windows.Forms.MessageBox]::Show("Explorer / Browser cache καθαρίστηκε (όσο ήταν δυνατόν).","Ολοκλήρωση")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Σφάλμα στο καθάρισμα Explorer cache: $($_.Exception.Message)","Σφάλμα")
    }
}

function Show-MemoryInfo {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $total = [math]::Round($os.TotalVisibleMemorySize / 1MB,2)
        $free  = [math]::Round($os.FreePhysicalMemory      / 1MB,2)
        $used  = [math]::Round($total - $free,2)

        $msg = @"
Σύνολο RAM: $total GB
Σε χρήση:   $used GB
Ελεύθερη:   $free GB

Σημείωση:
Η cache μνήμη συνεργάζεται στενά με τη RAM.
Όσο αποτελεσματικότερα γίνεται η αλληλοενημέρωση RAM και Cache,
τόσο πιο γρήγορη είναι η εκτέλεση των προγραμμάτων.
"@

        [System.Windows.Forms.MessageBox]::Show($msg,"Πληροφορίες Μνήμης")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Σφάλμα στην ανάγνωση πληροφοριών RAM: $($_.Exception.Message)","Σφάλμα")
    }
}

#-----------------------------#
# Form                        #
#-----------------------------#

$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Cache / Memory Cleanup"
$form.Size          = New-Object System.Drawing.Size(680,420)
$form.StartPosition = "CenterScreen"
$form.Topmost       = $false

# Label: Greek theory about cache memory
$labelInfo                  = New-Object System.Windows.Forms.Label
$labelInfo.AutoSize         = $false
$labelInfo.Size             = New-Object System.Drawing.Size(640,120)
$labelInfo.Location         = New-Object System.Drawing.Point(10,10)
$labelInfo.Font             = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Regular)
$labelInfo.Text =
@"
Cache Μνήμη:

• Μνήμη αρκετά μεγάλης ταχύτητας
• Γρηγορότερη από την κύρια μνήμη (RAM)
• Μικρή χωρητικότητα
• Επικοινωνεί απευθείας με την CPU
• Ένα πρόγραμμα φορτώνεται στην cache μνήμη, γιατί έτσι αυξάνεται η ταχύτητα εκτέλεσής του
• Αλληλοενημέρωση RAM και Cache για καλύτερη απόδοση
"
$form.Controls.Add($labelInfo)

# GroupBox for actions
$groupActions              = New-Object System.Windows.Forms.GroupBox
$groupActions.Text         = "Ενέργειες καθαρισμού"
$groupActions.Size         = New-Object System.Drawing.Size(640,190)
$groupActions.Location     = New-Object System.Drawing.Point(10,140)
$form.Controls.Add($groupActions)

# Buttons
$btnTemp                   = New-Object System.Windows.Forms.Button
$btnTemp.Text              = "Καθαρισμός Temp φακέλων"
$btnTemp.Size              = New-Object System.Drawing.Size(190,40)
$btnTemp.Location          = New-Object System.Drawing.Point(20,30)
$btnTemp.Add_Click({ Clear-TempFiles })
$groupActions.Controls.Add($btnTemp)

$btnDns                    = New-Object System.Windows.Forms.Button
$btnDns.Text               = "Καθαρισμός DNS cache"
$btnDns.Size               = New-Object System.Drawing.Size(190,40)
$btnDns.Location           = New-Object System.Drawing.Point(230,30)
$btnDns.Add_Click({ Clear-DnsCache })
$groupActions.Controls.Add($btnDns)

$btnExplorer               = New-Object System.Windows.Forms.Button
$btnExplorer.Text          = "Καθαρισμός Explorer/Browser cache"
$btnExplorer.Size          = New-Object System.Drawing.Size(230,40)
$btnExplorer.Location      = New-Object System.Drawing.Point(20,90)
$btnExplorer.Add_Click({ Clear-ExplorerCache })
$groupActions.Controls.Add($btnExplorer)

$btnMemInfo                = New-Object System.Windows.Forms.Button
$btnMemInfo.Text           = "Πληροφορίες RAM και Cache (θεωρία)"
$btnMemInfo.Size           = New-Object System.Drawing.Size(300,40)
$btnMemInfo.Location       = New-Object System.Drawing.Point(270,90)
$btnMemInfo.Add_Click({ Show-MemoryInfo })
$groupActions.Controls.Add($btnMemInfo)

# Close button
$btnClose                  = New-Object System.Windows.Forms.Button
$btnClose.Text             = "Κλείσιμο"
$btnClose.Size             = New-Object System.Drawing.Size(100,35)
$btnClose.Location         = New-Object System.Drawing.Point(550,340)
$btnClose.Add_Click({ $form.Close() })
$form.Controls.Add($btnClose)

#-----------------------------#
# Show form                   #
#-----------------------------#

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.Add_Shown({ $form.Activate() })
[System.Windows.Forms.Application]::Run($form)
