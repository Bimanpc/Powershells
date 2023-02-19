### Computer Name(s) example of how to utilize the GUI_TextBox function
###############################################################################
$Computers = GUI_TextBox "Computer Names(s):" ### Calls the text box function with a parameter and puts returned input in variable
$Computer_Count = $Computers | Measure-Object | % {$_.Count} ### Measures how many objects were inputted
  
If ($Computer_Count -eq 0){ ### If the count returns 0 it will throw and error
    Write-Host "Nothing was inputed..." -BackgroundColor Red -ForegroundColor White
    Return
}
Else { ### If there was actual data returned in the input, the script will continue
    Write-Host "Number of computers entered:" $Computer_Count -BackgroundColor Cyan -ForegroundColor Black
    $Computers
    ### Here is where you would put your specific code to take action on those computers inputted
}
### Adding an OK button to the text box window
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(155,550) ### Location of where the button will be
$OKButton.Size = New-Object System.Drawing.Size(75,23) ### Size of the button
$OKButton.Text = 'OK' ### Text inside the button
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)