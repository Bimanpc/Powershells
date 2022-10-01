Write-Host "Vasiliy write host cmdlet" -ForegroundColor Green
$test= Get-Process
Write-Host "Print a variable" -ForegroundColor Green
Write-Output $test
Write-Host "Passing output to another cmdlet through pipeline" -ForegroundColor Green
Write-Output "GeekITt" | Get-Member
Write-Host "Vasiya enumerate and no enumerate" -ForegroundColor Green
Write-Output 10,20,30 | Measure-Object
Write-Output 10,20,30 -NoEnumerate | Measure-Object