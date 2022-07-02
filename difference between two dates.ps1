$dateA= Get-Date
$dateB= Get-Date "1/1/1968"
$difference= $dateA- $dateB
$difference|Format-List