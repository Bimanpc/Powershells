Write-Host "Demo of dispalying out grid in a GUI with search" -ForegroundColor Green
$pro_arry = @()
$processes = Get-Process | Select Name, Id, CPU, SI
Foreach ($process in $processes){
$pro_arry += New-Object PSObject -Property @{
Process_Name = $process.Name
Process_CPU = $process.CPU
Process_Id = $process.ID
Process_SI = $process.SI
}
}
$op = $pro_arry | Out-GridView -Title "Custome grid with Filters" -OutputMode Multiple

