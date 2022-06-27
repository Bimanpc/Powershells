Get-Service |
  Where-Object CanPauseAndContinue -eq $true |
    Select-Object -Property *