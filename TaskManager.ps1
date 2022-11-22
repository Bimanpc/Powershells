Write-Host "Dispalying out grid in a GUI with search" -ForegroundColor Green
$pro_arry = @()
$processes = Get-Process | Select Name, Id, CPU, SI
Foreach ($process in $processes){
$pro_arry += New-Object PSObject -Property @{
Process_Name = $process.Nameofservice
Process_CPU = $process.CPUs
Process_Id = $process.IDs
Process_SI = $process.SIt
}
}
$op = $pro_arry | Out-GridView -Title "Grid with Filters" -OutputMode Multiple