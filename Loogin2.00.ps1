Write-Host "Welcome to the Geek2.0 of Split a large log file into smaller files"
$lc = 0
$fn = 1
# Getting the source log file
$source = Read-Host "Enter the log file path"
# Getting the destination where the smaller log files will be saved
$destination = Read-Host "Enter the destination path"
Write-Host "The total number of lines is being calculated ..... "
Get-Content $source | Measure-Object | ForEach-Object { $sourcelc = $_.Count }
#total number of lines in source file
Write-Host " total number of lines present is  "  $sourcelc
# size of each destination file
$destfilesize = Read-Host "Number of lines to present in each file"
$maxsize = [int]$destfilesize
Write-Host File is $source - destination is $destination - new file line count will be $destfilesize
$content = get-content $source | % {
Add-Content $destination\splitlog$fn.txt "$_"
$lc ++
If ($lc -eq $maxsize) {
$fn++
$lc = 0
}
}
Write-Host "The new number of smaller files generated is " $fn
Write-Host "Please check the for the files in" $destination