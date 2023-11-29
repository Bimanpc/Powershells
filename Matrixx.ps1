Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to create a random matrix-like character
function Get-RandomMatrixChar {
    $matrixChars = @('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F')
    Get-Random -InputObject $matrixChars
}

# Function to update the matrix display
function Update-Matrix {
    $matrixText = @()
    $rowCount = 20
    $colCount = 40

    # Generate matrix-like characters
    for ($row = 0; $row -lt $rowCount; $row++) {
        $matrixRow = ''
        for ($col = 0; $col -lt $colCount; $col++) {
            $matrixRow += Get-RandomMatrixChar
        }
        $matrixText += $matrixRow
    }

    # Update the label text with matrix-like characters
    $labelMatrix.Text = $matrixText -join "`r`n"
}

# Create a form
$formMatrix = New-Object System.Windows.Forms.Form
$formMatrix.Text = "Matrix GUI"
$formMatrix.Size = New-Object System.Drawing.Size(400, 300)
$formMatrix.StartPosition = "CenterScreen"
$formMatrix.FormBorderStyle = "FixedSingle"
$formMatrix.MaximizeBox = $false

# Create a label for displaying the matrix-like characters
$labelMatrix = New-Object System.Windows.Forms.Label
$labelMatrix.Location = New-Object System.Drawing.Point(10, 10)
$labelMatrix.Size = New-Object System.Drawing.Size(380, 280)
$labelMatrix.Font = New-Object System.Drawing.Font("Courier New", 10)
$formMatrix.Controls.Add($labelMatrix)

# Add a timer to periodically update the matrix display
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100
$timer.Add_Tick({
    Update-Matrix
})
$timer.Start()

# Add an event handler to close the form when it is closed
$formMatrix.Add_Closed({
    $timer.Stop()
})

# Show the form
$formMatrix.ShowDialog()
