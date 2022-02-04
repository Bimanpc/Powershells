$Author = "Vasilis PS."
$AuthorDate = "20221."
$Version = "2022"
<#Description: GUI Template

Changelog
===
Hash table working.
RunspacePool working.
GUI Working.
Functions working.
#>
#Suppress Errors
$script:ErrorActionPreference = 'SilentlyContinue'
$script:ProgressPreference = 'SilentlyContinue'
#Set-ExecutionPolicy unrestricted
$getPowerShellVersion = $PSVersionTable.PSVersion

#Hash table for runspaces
$hash = [hashtable]::Synchronized(@{})


#Desktop path
$DesktopPath = [Environment]::GetFolderPath("Desktop")

#Working Path
$script:workingPath = Get-Location

#Date
$script:datestring = (Get-Date).ToString("s").Replace(":","-")


#FUNCIONS

#Append output to browse box display.
Function Add-BrowseBoxLine 
{
    Param ($Message)
    $browseBox.AppendText("`r`n$Message")
    $browseBox.Refresh()
    $script:browseBox.ScrollToCaret()
    $hash.Form.Refresh()
}

#Append output to text box display.
Function Add-OutputBoxLine 
{
    Param ($Message)
    $hash.outputBox.AppendText("$Message")
    $hash.outputBox.Refresh()
    $script:hash.OutputBox.ScrollToCaret()
    $script:hash.OutputBox.SelectionStart = $hash.outputBox.Text.Length
    $hash.outputBox.Selectioncolor = "WindowText"
    $hash.Form.Refresh()
}

#File browse function.
Function fileBrowser
{
    try {
        
        $lineList = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
        $lineList.Title = "Select a TEXT file."
        $lineList.filter = "Txt (*.txt)| *.txt|Csv (*.csv)| *.csv"
        $script:inputfile = $lineList.ShowDialog()
        $script:lineList = Get-Content -Path $lineList.FileName
        $hash.lineList = $script:lineList
        $totalServers = Get-Content $lineList.FileName | Measure-Object
        $totalServers = $totalServers.Count
        
            #Empty browse box when we get file, then append file path from our selection.
            $browseBox.Text = ""
            $browseBox.ForeColor = "WindowText"
            Add-BrowseBoxLine -Message $lineList.FileName

            #Check to ensure more than 0 computer objects in text file.
            If($totalServers -le 0)
            {
                $hash.outputBox.Selectioncolor = "Red"
                Add-OutputBoxLine -Message "`r`nMust select a valid input file containing at least one line. Click Browse and select a text/csv file containing a valid list."
            }
            else
            {
            $hash.outputBox.Selectioncolor = "Green"
            Add-OutputBoxLine -Message "`r`nTotal lines in file: $totalServers"
            $hash.outputBox.Selectioncolor = "Green"
            Add-OutputBoxLine -Message "`r`nFile loaded. Click RUN to begin."
            }

    }
    catch {
        $hash.outputBox.Selectioncolor = "Red"
        Add-OutputBoxLine -Message "`r`nMust enter info in first textbox OR select a valid input file. Click Browse and select a text/csv file containing your list."

        }
    $hash.Form.Refresh()
}


Function RunAppCode{

    $scriptRun = {
        #Suppress Errors as to not interrupt the GUI experience. Comment these out when debugging.
        $script:ErrorActionPreference = 'SilentlyContinue'
        $script:ProgressPreference = 'SilentlyContinue'

        $hash.OutputBox.Selectioncolor = "Green"
        $hash.OutputBox.AppendText("`r`nRunning from runspace pool!")



    } #Close the $scriptRun brackets for the runspace
    
    #Configure max thread count for RunspacePool.
    $maxthreads = [int]$env:NUMBER_OF_PROCESSORS
    
    #Create a new session state for parsing variables ie hashtable into our runspace.
    $hashVars = New-object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'hash',$hash,$Null
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    
    #Add the variable to the RunspacePool sessionstate
    $InitialSessionState.Variables.Add($hashVars)

    #Create our runspace pool. We are entering three parameters here min thread count, max thread count and host machine of where these runspaces should be made.
    $script:runspace = [runspacefactory]::CreateRunspacePool(1,$maxthreads,$InitialSessionState, $Host)

    
    #Crate a PowerShell instance.
    $script:powershell = [powershell]::Create()
    
    #Open a RunspacePool instance.
    $script:runspace.Open()
            
        
        #Add our main code to be run via $scriptRun within our RunspacePool.
        $script:powershell.AddScript($scriptRun)
        $script:powershell.RunspacePool = $script:runspace
        
        #Run our RunspacePool.
        $script:handle = $script:powershell.BeginInvoke()

        #Cleanup our RunspacePool threads when they are complete ie. GC.
        if ($script:handle.IsCompleted)
        {
            $script:powershell.EndInvoke($script:handle)
            $script:powershell.Dispose()
            $script:runspace.Dispose()
            $script:runspace.Close()
            [System.GC]::Collect()
        }
        
        

 } #Closing the function.


#Menu GUI begins.

# Install .Net Assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
 
# Enable Visual Styles
[Windows.Forms.Application]::EnableVisualStyles()


#Main Form
$hash.Form = New-Object system.Windows.Forms.Form
$FormWidth = '500'
$FormHeight = '690'
$hash.Form.Size = "$FormWidth,$FormHeight"
$hash.Form.StartPosition = 'CenterScreen'
$hash.Form.text = "GUI Template by VASILIS PCTECHGREU PS $Version"
$hash.Form.Icon = [System.Drawing.SystemIcons]::Shield
$hash.Form.BackColor = 'CornflowerBlue'
$hash.Form.Refresh()
#Disable windows maximize feature.
$hash.Form.MaximizeBox = $False
$hash.Form.FormBorderStyle='FixedDialog'

#Xmas easter egg
$date = (get-date)
$year = (get-date).Year
$newYear = (get-date).AddYears(1).Year
$xmas = Get-Date -Month 12 -Day 25 -Year $year
$nye = Get-Date -Month 01 -Day 02 -Year $newYear
If(($date -ge $xmas) -and ($date -le $nye))
{
    $hash.Form.text = "GUI Template by PCTECHGREU  $Version - GUI Template by VASILIS PCTECHGREU PS!"
    $hash.Form.BackColor = 'FireBrick'
    $hash.Form.Refresh()
}


$Description = New-Object system.Windows.Forms.Label
$Description.text = "GUI Template by Hugo Gungormez"
$Description.AutoSize = $false
$Description.width = 450
$Description.height = 30
$Description.location = New-Object System.Drawing.Point(20,40)
$Description.Font = 'Verdana,13'
$Description.Anchor = 'top, left'

$moto = New-Object system.Windows.Forms.Label
$moto.text = "A brief synopsis about your app."
$moto.AutoSize = $false
$moto.width = 450
$moto.height = 50
$moto.location = New-Object System.Drawing.Point(20,70)
$moto.Font = 'Verdana,10'

#Input single computer or FQDN textbox
$hash.serverBox = New-Object System.Windows.Forms.TextBox 
$hash.serverBox.Location = New-Object System.Drawing.Size(90,110) 
$hash.serverBox.Size = New-Object System.Drawing.Size(300,40)
$hash.serverBox.Font = 'Verdana,9'
$hash.serverBox.ReadOnly = $False
$WatermarkText = "Watermark."
$hash.serverBox.ForeColor = 'Gray'
$hash.serverBox.Anchor = 'top, left'
$hash.serverBox.Text = $WatermarkText
#If we have focus then clear out the text
$hash.serverBox.Add_GotFocus(
    {
        If($hash.serverBox.Text -eq $WatermarkText)
        {
            $hash.serverBox.Text = ''
            $hash.serverBox.ForeColor = 'WindowText'
        }
    }
)
#If we have lost focus and the field is empty, reset back to watermark.
$hash.serverBox.Add_LostFocus(
    {
        If($hash.serverBox.Text -eq '')
        {
            $hash.serverBox.Text = $WatermarkText
            $hash.serverBox.ForeColor = 'Gray'
        }
    }
)

$hash.serverBox.Add_KeyDown({
    if ($_.KeyCode -eq "Enter") {
        runAppCode
    }
})

#Browse text box displaying file path.
$browseBox = New-Object System.Windows.Forms.TextBox 
$browseBox.Location = New-Object System.Drawing.Size(89,152) 
$browseBox.Size = New-Object System.Drawing.Size(192,50)
$browseBox.Font = "Verdana, 9"
$browseBox.Anchor = 'top, left'
#Must configure BackColor in a ReadOnly textbox in order for ForeColor to work.
$browseBox.BackColor = 'White'
$browseBox.ForeColor = 'Gray'
$browseBox.ReadOnly = $True
$browseWatermark = "Click Browse to select file."
$browseBox.Text = $browseWatermark



<# Output Box which is below all other buttons and displays PS Output #>
$hash.outputBox = New-Object System.Windows.Forms.RichTextBox 
$hash.outputBox.Location = New-Object System.Drawing.Size(65,350) 
$hash.outputBox.Size = New-Object System.Drawing.Size(350,180)
$hash.outputBox.Font = "Verdana, 8"
$hash.outputBox.ReadOnly = $True
$hash.outputBox.MultiLine = $True
$hash.outputBox.ScrollBars = "Vertical"
$hash.outputBox.Anchor = 'top, left'
#$hash.outputBox.AppendText("KVT Tool ready.")
#$hash.Form.Controls.Add($hash.outputBox)

#PowerShell version check.
If($getPowerShellVersion -ge "4.0")
{
        $hash.outputBox.AppendText("Your PowerShell version is $getPowerShellVersion. `nGUI Template is ready.")
}
else
{
        $hash.outputBox.Selectioncolor = "Red"
        $hash.outputBox.AppendText("Your PowerShell version is $getPowerShellVersion. `nGUI Template may not run correctly on your computer.")
}

#Browse Button
$hash.buttonBrowse = New-Object System.Windows.Forms.Button
$hash.buttonBrowse.text = "Browse"
$hash.buttonBrowse.Size = '80,30'
$hash.buttonBrowse.location = '310, 147'
$hash.buttonBrowse.Font = 'Verdana,9'
$hash.buttonBrowse.Anchor = 'top, left'
$hash.buttonBrowse.Add_Click({fileBrowser})


$hash.buttonRun = New-Object System.Windows.Forms.Button
$hash.buttonRun.text = "RUN"
$hash.buttonRun.Size = '300,40'
$hash.buttonRun.location = '90, 200'
$hash.buttonRun.Font = 'Verdana,11'
$hash.buttonRun.BackColor = "CornflowerBlue"
$hash.buttonRun.Cursor = [System.Windows.Forms.Cursors]::Hand
$hash.buttonRun.Anchor = 'top, left'
$hash.buttonRun.Add_Click({RunAppCode})

#Close button
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Location = '190,270'
$exitButton.Size = '100,40'
$exitButton.FlatStyle = 'Flat'
$exitButton.BackColor = 'Brown'
$exitButton.Font = 'Verdana, 9'
$exitButton.Anchor = 'top, left'

# Font styles are: Regular, Bold, Italic, Underline, Strikeout
#$exitButton.Font = $cancelFont
$hash.Form.Controls.Add($exitButton)
$exitButton.Text = 'Exit'
$exitButton.tabindex = 0
$exitButton.Add_Click({
    $hash.Form.Tag = $hash.Form.close()
    $script:powershell.EndInvoke($script:handle)
    #$script:powershell.Close()
    $script:powershell.Dispose()
    $script:runspace.Close()
    $script:runspace.Dispose()
    [System.GC]::Collect()
    })
$hash.Form.CancelButton = $exitButton


#Progress status Heading
$StatusHeading = New-Object system.Windows.Forms.Label
$StatusHeading.text = "Progress: "
$StatusHeading.AutoSize = $false
$StatusHeading.width = 80
$StatusHeading.height = 20
$StatusHeading.location = New-Object System.Drawing.Point(70,558)
$StatusHeading.Anchor = 'bottom, left'
$StatusHeading.Font = 'Verdana,10'

#Progress bar.
$hash.progressBar1 = New-Object System.Windows.Forms.ProgressBar
$hash.progressBar1.Name = 'progressBar1'
$hash.progressBar1.Value = 0
$hash.progressBar1.Style="Blocks"
$hash.progressBar1.Size = "254, 30"
$hash.progressBar1.location = '160, 550'
$hash.progressBar1.Anchor = 'bottom, left'



#File Menu
$menuClose = New-Object System.Windows.Forms.ToolStripMenuItem
$menuClose.Name = "Close"
$menuClose.Text = "Close"
$menuClose.Add_Click({$hash.Form.Close()
    $script:powershell.EndInvoke($script:handle)
    #$script:powershell.Close()
    $script:powershell.Dispose()
    $script:runspace.Dispose()
    $script:runspace.Close()
    [System.GC]::Collect()})

#File Menu continued
$menuFile = New-Object System.Windows.Forms.ToolStripMenuItem
$menuFile.Name = "File"
$menuFile.Text = "File"
$menuFile.DropDownItems.AddRange(@($menuClose))


#ABOUT FORM
 $FormAbout = New-Object system.Windows.Forms.Form
 $FormAboutWidth = '800'
 $FormAboutHeight = '500'
 $FormAbout.MinimumSize = "$FormAboutWidth,$FormAboutHeight"
 $FormAbout.StartPosition = 'CenterScreen'
 $FormAbout.text = "About"
 $FormAbout.Icon = [System.Drawing.SystemIcons]::Shield
 #Autoscaling settings
 $FormAbout.AutoScale = $true
 $FormAbout.AutoScaleMode = "Font"
 $ASsize = New-Object System.Drawing.SizeF(7,15)
 $FormAbout.AutoScaleDimensions = $ASsize
 $FormAbout.BackColor = 'CornflowerBlue'
 $FormAbout.Refresh()
 #Disable windows maximize feature.
 $FormAbout.MaximizeBox = $False
 

 $AboutHeading = New-Object system.Windows.Forms.Label
 $AboutHeading.text = "About"
 $AboutHeading.AutoSize = $false
 $AboutHeading.width = 450
 $AboutHeading.height = 70
 $AboutHeading.location = New-Object System.Drawing.Point(20,20)
 $AboutHeading.Font = 'Verdana,14'
 $AboutHeading.Anchor = 'top, left'

 $AboutDescription = New-Object system.Windows.Forms.Label
 $AboutDescription.text = "Credits.`r`nAuthor: $Author Build date: $AuthorDate Version: $Version"
 $AboutDescription.AutoSize = $false
 $AboutDescription.width = 500
 $AboutDescription.height = 70
 $AboutDescription.location = New-Object System.Drawing.Point(20,410)
 $AboutDescription.Font = 'Verdana,10'
 $AboutDescription.Anchor = 'bottom, left'

 $Description2Heading = New-Object system.Windows.Forms.Label
 $Description2Heading.text = "GUI Template Geeekz."
 $Description2Heading.AutoSize = $false
 $Description2Heading.width = 450
 $Description2Heading.height = 50
 $Description2Heading.location = New-Object System.Drawing.Point(20,100)
 $Description2Heading.Font = 'Verdana,12'

$AboutDescription2 = New-Object system.Windows.Forms.Label
$AboutDescription2.text = "By PCYTEGHREU  AKA Geekz ;)"
$AboutDescription2.AutoSize = $false
$AboutDescription2.width = 620
$AboutDescription2.height = 200
$AboutDescription2.location = New-Object System.Drawing.Point(20,150)
$AboutDescription2.Font = 'Verdana,10'

$AboutLinkLabel = New-Object System.Windows.Forms.LinkLabel
$AboutLinkLabel.Location = New-Object System.Drawing.Size(320,400)
$AboutLinkLabel.Size = New-Object System.Drawing.Size(150,20)
$AboutLinkLabel.LinkColor = "BLUE"
$AboutLinkLabel.ActiveLinkColor = "RED"
$AboutLinkLabel.Text = "https://kamikazeadmin.net"
$AbouLinkLabel.Anchor = 'top, left'
$AboutLinkLabel.add_Click({[system.Diagnostics.Process]::start("https://kamikazeadmin.net")})

#About Close Button
$aboutClose = New-Object System.Windows.Forms.Button
$aboutClose.text = "Close"
#$buttonClose.Size = '80,30'
$aboutClose.Size = '80,30'
$aboutClose.location = '350, 360'
$aboutClose.Font = 'Verdana,9'
$aboutClose.Anchor = 'Bottom,Left'
$aboutClose.Add_Click({$FormAbout.Close()})

#Add our controls ie labels and buttons into our Abou form.
$FormAbout.Controls.AddRange(@($AboutHeading, $AboutDescription, $Description2Heading, $AboutDescription2, $AboutLinkLabel, $aboutClose))

#Help ToolStrip Menu
$helpAbout = New-Object System.Windows.Forms.ToolStripMenuItem
$helpAbout.Name = "About"
$helpAbout.Text = "About"
$helpAbout.Add_Click({$FormAbout.ShowDialog()})

$menuHelp = New-Object System.Windows.Forms.ToolStripMenuItem
$menuHelp.Name = "Help"
$menuHelp.Text = "Help"
$menuHelp.DropDownItems.AddRange(@($helpAbout))

$menuMain = New-Object System.Windows.Forms.MenuStrip
$menuMain.Items.AddRange(@($menuFile, $menuHelp))

#Display form
$hash.Form.Controls.AddRange(@($menuMain, $hash.serverBox, $hash.buttonBrowse, $hash.buttonRun, $Description, $moto, $hash.outputBox, $browseBox, $StatusHeading, $hash.progressBar1))
$result = $hash.Form.ShowDialog()

if($result -eq [System.Windows.Forms.DialogResult]::Cancel)
    {
        Exit
    }

#Ensure a text file containing server list is entered.
while(!$lineList)
{
    $hash.outputBox.Selectioncolor = "Red"
    Add-OutputBoxLine -Message "`r`nMust enter a String in top bar OR select a valid input file. Click Browse and select a text/csv file."
    $hash.buttonBrowse.enabled = $true
    $hash.buttonRun.enabled = $true
}
