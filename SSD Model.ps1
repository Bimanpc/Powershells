#Ask for SSD Model 
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

$title = 'Enter SSD Model '
$msg   = 'Enter the SSD Model] of the Item:'

$upc = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)