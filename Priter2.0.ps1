# Select printer dialog
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object -TypeName System.Windows.Forms.Form
$form.Text = 'Select a printer'
$form.Size = '400, 200'

$list = @( ( Get-Printer ).Name )
$Script:selectedvalue = ''

$dropdown = New-Object -TypeName System.Windows.Forms.ComboBox
$dropdown.Items.AddRange( $list )
$dropdown.SelectedIndex = 0
$dropdown.Width = '200'
$dropdown.Location = New-Object System.Drawing.Point( [int]( ( $form.Width - $dropdown.Width ) / 2 ), 25 )
$form.Controls.Add( $dropdown )

$buttonOK_Click = {
	$Script:selectedvalue = $dropdown.Text
	$form.DialogResult = 'OK'
	$form.Close( )
}

$buttonOK = New-Object System.Windows.Forms.Button
$buttonOK.Text = 'OK'
$buttonOK.Location = New-Object System.Drawing.Point( [int]( ( $form.Width / 2 ) - 5 - $buttonOK.Width ), 100 )
$buttonOK.Add_Click( $buttonOK_Click )
$form.Controls.Add( $buttonOK )
$form.AcceptButton = $buttonOK # pressing Enter assuming OK

$buttonCancel_Click = {
	$form.DialogResult = 'Cancel'
	$form.Close( )
}

$buttonCancel = New-Object System.Windows.Forms.Button
$buttonCancel.Text = 'Cancel'
$buttonCancel.Location = New-Object System.Drawing.Point( [int]( ( $form.Width / 2 ) + 5 ), 100 )
$buttonCancel.Add_Click( $buttonCancel_Click )
$form.Controls.Add( $buttonCancel )
$form.CancelButton = $buttonCancel # pressing Esc assuming Cancel

$result = $form.ShowDialog( )

if ( $result -eq 'OK' ) {
	$Script:selectedvalue
}