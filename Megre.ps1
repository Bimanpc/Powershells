Write-Host "Welcome to VasiyaLand"
Write-Host "Writing success message to console"
for($i=0; $i -le 10; $i++)
{
Write-Host "the value is "$i
}
Write-Host "Demo of writing log to a text file"
for($i=0; $i -le 10; $i++)
{
$i |Out-File -FilePath C:\VASIYA.txt -Append
}
Write-Host "The logging is done to the file.Please check"