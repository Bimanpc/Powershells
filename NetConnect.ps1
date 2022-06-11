Write-Host "Welcome to Test-netconnection" -ForegroundColor Green
Write-Host "Runnss the command with informational level"
$infolevel=Read-Host "specify the information level"
Write-Host "The speified info level is" $infolevel -ForegroundColor Green
Test-NetConnection -InformationLevel $infolevel
$infolevel=Read-Host "specify the info level"
Write-Host "The speified info level is" $infolevel -ForegroundColor Green
Test-NetConnection -InformationLevel $infolevel