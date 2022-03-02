$Computername = "user"

  $CertStore = New-Object System.Security.Cryptography.X509Certificates.X509Store  -ArgumentList  "\\$($Computername)\My", "LocalMachine"

  $CertStore.Open('ReadOnly')

$certificate  = $CertStore.Certificates[0]