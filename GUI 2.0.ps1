### User Name(s) example of how to utilize the GUI_TextBox function
###############################################################################
$Users = GUI_TextBox "User Names:" ### Calls the text box function with a parameter and puts returned input in variable
$User_Count = $Users | Measure-Object | % {$_.Count} ### Measures how many objects were inputted
 
If ($User_Count -eq 0){ ### If the count returns 0 it will throw and error
    Write-Host "Nothing inputed..." -BackgroundColor Red -ForegroundColor White
    Return
}
Else { ### If there was actual data returned in the input, the script will continue
    Write-Host "Number of users entered:" $User_Count -BackgroundColor Cyan -ForegroundColor Black
    $Users
    ### Here is where you would put your specific code to take action on those users inputted
}