$ComputerName = 'DC01', 'WEB01'
foreach ($Комвутера in $Комвутера) {
  Get-ADComputer -Identity $Комвутера
}