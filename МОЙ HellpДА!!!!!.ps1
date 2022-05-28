#Generated Form Function
function GenerateForm {
#region Import the Assemblies
[reflection.assembly]::loadwithpartialname(“System.Windows.Forms”) | Out-Null
[reflection.assembly]::loadwithpartialname(“System.Drawing”) | Out-Null
#endregion

#region Generated Form Objects
$HelpDeskForm = New-Object System.Windows.Forms.Form
$UnlockAccountButton = New-Object System.Windows.Forms.Button
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#———————————————-
#Generated Event Script Blocks
#———————————————-
#Provide Custom Code for events specified in PrimalForms.
$handler_UnlockAccountButton_Click=
{
#TODO: Place custom script here

}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
$HelpDeskForm.WindowState = $InitialFormWindowState
}

#———————————————-
#region Generated Form Code
$HelpDeskForm.Text = “МОЙ  Help Desk”
$HelpDeskForm.Name = “МОЙ HelpDeskForm”
$HelpDeskForm.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 265
$System_Drawing_Size.Height = 55
$HelpDeskForm.ClientSize = $System_Drawing_Size

$UnlockAccountButton.TabIndex = 0
$UnlockAccountButton.Name = “МОЙ UnlockAccountButton”
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 240
$System_Drawing_Size.Height = 23
$UnlockAccountButton.Size = $System_Drawing_Size
$UnlockAccountButton.UseVisualStyleBackColor = $True

$UnlockAccountButton.Text = “МОЙ UNLOCK Account”

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 13
$System_Drawing_Point.Y = 13
$UnlockAccountButton.Location = $System_Drawing_Point
$UnlockAccountButton.DataBindings.DefaultDataSourceUpdateMode = 0
$UnlockAccountButton.add_Click($handler_UnlockAccountButton_Click)

$HelpDeskForm.Controls.Add($UnlockAccountButton)

#endregion Generated Form Code

#Save the initial state of the form
$InitialFormWindowState = $HelpDeskForm.WindowState
#Init the OnLoad event to correct the initial state of the form
$HelpDeskForm.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$HelpDeskForm.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm