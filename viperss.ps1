Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Morse dictionary
$morseDict = @{
    "A"=".-"; "B"="-..."; "C"="-.-."; "D"="-.."; "E"=".";
    "F"="..-."; "G"="--."; "H"="...."; "I"=".."; "J"=".---";
    "K"="-.-"; "L"=".-.."; "M"="--"; "N"="-."; "O"="---";
    "P"=".--."; "Q"="--.-"; "R"=".-."; "S"="..."; "T"="-";
    "U"="..-"; "V"="...-"; "W"=".--"; "X"="-..-"; "Y"="-.--";
    "Z"="--..";
    "1"=".----"; "2"="..---"; "3"="...--"; "4"="....-";
    "5"="....."; "6"="-...."; "7"="--..."; "8"="---..";
    "9"="----."; "0"="-----";
    " "="/"
}

# Reverse dictionary
$reverseDict = @{}
foreach ($key in $morseDict.Keys) {
    $reverseDict[$morseDict[$key]] = $key
}

# Functions
function Convert-ToMorse($text) {
    $result = ""
    foreach ($char in $text.ToUpper().ToCharArray()) {
        if ($morseDict.ContainsKey($char)) {
            $result += $morseDict[$char] + " "
        }
    }
    return $result.Trim()
}

function Convert-ToText($morse) {
    $result = ""
    foreach ($code in $morse.Split(" ")) {
        if ($reverseDict.ContainsKey($code)) {
            $result += $reverseDict[$code]
        } elseif ($code -eq "/") {
            $result += " "
        }
    }
    return $result
}

# GUI Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI Morse Code Converter"
$form.Size = New-Object System.Drawing.Size(500,350)

# Input Box
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Multiline = $true
$inputBox.Size = New-Object System.Drawing.Size(450,80)
$inputBox.Location = New-Object System.Drawing.Point(20,20)

# Output Box
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.Size = New-Object System.Drawing.Size(450,80)
$outputBox.Location = New-Object System.Drawing.Point(20,200)

# Buttons
$btnToMorse = New-Object System.Windows.Forms.Button
$btnToMorse.Text = "Text → Morse"
$btnToMorse.Location = New-Object System.Drawing.Point(50,120)

$btnToText = New-Object System.Windows.Forms.Button
$btnToText.Text = "Morse → Text"
$btnToText.Location = New-Object System.Drawing.Point(250,120)

# Button Events
$btnToMorse.Add_Click({
    $outputBox.Text = Convert-ToMorse $inputBox.Text
})

$btnToText.Add_Click({
    $outputBox.Text = Convert-ToText $inputBox.Text
})

# Add Controls
$form.Controls.Add($inputBox)
$form.Controls.Add($outputBox)
$form.Controls.Add($btnToMorse)
$form.Controls.Add($btnToText)

# Run App
$form.ShowDialog()
