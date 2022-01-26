Write-Host "PC TECH GREU SysAnalyzer2022" -ForegroundColor Green
$pro_arry = @()
$processes = Get-Process | Select Name, Id, CPU, SI
Foreach ($process in $processes){
$pro_arry += New-Object PSObject -Property @{
Process_Name = $process.Names
Process_CPU = $process.CPUs
Process_Id = $process.Id
Process_SI = $process.SI
}
}
$op = $pro_arry | Out-GridView -Title "Grid with Filters" -OutputMode Multiple