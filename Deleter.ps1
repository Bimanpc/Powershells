#2# Remove Temp files from various locations 
write-Host "Erasing temporary files from various locations" -ForegroundColor Yellow  
# Specify the path where temporary files are stored in the Windows Temp folder
$Path1 = 'C' + ':\Windows\Temp' 
# Remove all items (files and directories) from the Windows Temp folder
Get-ChildItem $Path1 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue  
# Specify the path where temporary files are stored in the Windows Prefetch folder
$Path2 = 'C' + ':\Windows\Prefetch' 
# Remove all items (files and directories) from the Windows Prefetch folder
Get-ChildItem $Path2 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue  
# Specify the path where temporary files are stored in the user's AppData\Local\Temp folder
$Path3 = 'C' + ':\Users\*\AppData\Local\Temp' 
# Remove all items (files and directories) from the specified user's Temp folder
Get-ChildItem $Path4 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
# Display a success message
write-Host "removed all the temp files successfully" -ForegroundColor Green 
