Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text ='GUI Billman s PC TECH Lovers'
$main_form.Width = 600
$main_form.Height = 400
$main_form.AutoSize = $true
Now you can display the form on the screen.
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "I LOVE PC AND TECH"
$Label.Location  = New-Object System.Drawing.Point(0,10)
$Label.AutoSize = $true
$main_form.Controls.Add($Label)
$main_form.ShowDialog()