# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Function to get the Windows product key from the registry
function Get-WindowsKey {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $digitalProductId = (Get-ItemProperty -Path $regPath).DigitalProductId
    $key = ""
    $chars = "BCDFGHJKMPQRTVWXY2346789"
    $keyStartIndex = 52
    $keyEndIndex = 67
    $isN = ($digitalProductId[66] / 6) -shr 1 -band 1
    $startIndex = 24
    $partKey = New-Object byte[] 15
    $partKey[0..14] = $digitalProductId[$keyStartIndex..$keyEndIndex]

    for ($i = 24; $i -ge 0; $i--) {
        $current = 0
        for ($j = 14; $j -ge 0; $j--) {
            $current = $current * 256 -bxor $partKey[$j]
            $partKey[$j] = [math]::Floor($current / 24)
            $current = $current % 24
        }
        $key = $chars[$current] + $key
        if ((($i % 5) -eq 0) -and ($i -ne 0)) {
            $key = "-" + $key
        }
    }

    return $key
}

# Create the GUI form
$form = New-Object system.Windows.Forms.Form
$form.Text = "Windows Product Key Finder"
$form.Width = 400
$form.Height = 150
$form.StartPosition = 'CenterScreen'

# Label for displaying the product key
$keyLabel = New-Object system.Windows.Forms.Label
$keyLabel.AutoSize = $true
$keyLabel.Location = New-Object System.Drawing.Point(20, 30)
$keyLabel.Font = New-Object System.Drawing.Font("Arial", 10)
$form.Controls.Add($keyLabel)

# Button to find and display the product key
$button = New-Object System.Windows.Forms.Button
$button.Text = "Find Windows Key"
$button.Location = New-Object System.Drawing.Point(140, 70)
$button.Width = 120
$button.Height = 30
$button.Add_Click({
    $keyLabel.Text = "Windows Key: " + (Get-WindowsKey)
})

$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
