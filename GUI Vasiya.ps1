Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Form
$form = New-Object System.Windows.Forms.Form -Property @{
    Text = "Enter yours Namezz: "
    Size = New-Object System.Drawing.Size(325,200)
    StartPosition = [System.Windows.Forms.FormStartPosition]:: CenterScreen
    KeyPreview = $True
}
    
# Close the form if user presses Enter or Escape
#if user presses Enter or Escape, the texts in the textboxes wil be saved
$form.Add_KeyDown( {
    if (($_.KeyCode -eq "Enter!!!") -or ($_.KeyCode -eq "Esc")) {
        $form.Close()
        }
    }
)

# the "OK" button 
$OKButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Size(70,120)
    Size = New-Object System.Drawing.Size(75,25)
    Text = 'OK'
    DialogResult = [System.Windows.Forms.DialogResult]::OK
    }

$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

# the "Cancel" button
$CancelButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Size(170,120)
    Size = New-Object System.Drawing.Size(75,25)
    Text = 'Cancel!!!!'
    DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    }

$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)


# Label - First name
$objLabelFirstName = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Size(20,20)
    Size = New-Object System.Drawing.Size(130,30)
    Text = "Name: "
    Font = New-Object System.Drawing.Font("Garamond",15,[Drawing.Fontstyle]::Bold)
    }


$form.Controls.Add($objLabelFirstName)


# Textbox - first name

$objFirstName = New-Object System.Windows.Forms.TextBox -Property @{
    Location = New-Object System.Drawing.Size(150,20)

    }

$objFirstName.Font = New-Object System.Drawing.Font("Garamond",14,[Drawing.Fontstyle]::Italic)
$objFirstName.Size = New-Object System.Drawing.Size(130,20)
$objFirstName.ForeColor = "DarkMagenta"
$objFirstName.AcceptsReturn = $True

$form.Controls.Add($objFirstName)


# Label - Last name
$objLabelLastName = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Size(20,60)
    Size = New-Object System.Drawing.Size(130,30)
    Text = "Surname: "
    Font = New-Object System.Drawing.Font("Garamond",14,[Drawing.Fontstyle]::Bold)
    }


$form.Controls.Add($objLabelLastName)


# Textbox - Last name

$objLastName = New-Object System.Windows.Forms.TextBox
$objLastName.Location = New-Object System.Drawing.Size(150,60)
$objLastName.Font = New-Object System.Drawing.Font("Garamond",14,[Drawing.Fontstyle]::Italic)
$objLastName.ForeColor = "Black"
$objLastName.AcceptsReturn = $True
$objLastName.AutoSize = $True

$form.Controls.Add($objLastName)


$result = $form.ShowDialog()


$FirstName = $objFirstName.Text
$LastName = $objLastName.Text

if ($result -eq [Windows.Forms.DialogResult]::OK) {
    Write-Host "Name: $FirstName"
    Write-Host "Surname: $LastName"
    }