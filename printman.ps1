Add-Type -AssemblyName System.Windows.Forms

$Form = New-Object System.Windows.Forms.Form
$Form.Size = New-Object System.Drawing.Size(600, 400)

# ... Other form elements (DropdownBoxes, Buttons, OutputBox) ...

# Example site names
$Sites = @( 'Site 1', 'Site 2', 'Site 3', 'Site 4', 'Site 5', 'Site 6', 'Site 7' )

# DropdownBox1 event handler
$Global:DropDownBox1_SelectedIndexChanged = {
    Switch ($DropDownBox1.Text) {
        'Site 1' { $Global:PrintServer = '\\Printserver1' }
        'Site 2' { $Global:PrintServer = '\\Printserver2' }
        # ... Add other cases for different sites
    }
}

# Button2 event handler (FetchPrinters)
$Button2.Add_Click({
    FetchPrinters
})

# Button1 event handler (procInfo)
$Button.Add_Click({
    procInfo
})

# Show the form
[void] $Form.ShowDialog()
Exit

# FetchPrinters function
function FetchPrinters {
    # Fetch printers based on $Global:PrintServer
    # Populate DropdownBox2 with printer names
}

# procInfo function
function procInfo {
    # Install the selected printer using PrintUIEntry
    # Display success message in the output box
}
