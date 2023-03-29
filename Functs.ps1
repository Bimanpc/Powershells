Write-Host "~~~~~~~~~~~~~~~~~~ Menu Title ~~~~~~~~~~~~~~~~~~" -ForegroundColor Cyan
Write-Host "1: Enter 1 to execute Function One"
Write-Host "2: Enter 2 to execute Function Two"
Write-Host "Q: Enter Q to quit."
 
$input = (Read-Host "Please make a selection").ToUpper(###############################################
Function Function_One {
    write-host "Function One executed!"
}
###############################################
Function Function_Two {
    write-host "Function Two executed!"

}
###############################################)
 
switch ($input)
{
    '1' {Function_One}    ### Input the name of the function you want to execute when 1 is entered
    '2' {Function_Two}    ### Input the name of the function you want to execute when 2 is entered
    'Q' {Write-Host "The script has been canceled" -BackgroundColor Red -ForegroundColor White}
    Default {Write-Host "Yours selection = $input, isn't valid. Please try again." -BackgroundColor Red -ForegroundColor White}

Write-Host "Press a key to exit.........."
$Readkey = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
