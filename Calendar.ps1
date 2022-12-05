[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object Windows.Forms.Form 

$objForm.Text = "Select a Date!" 
$objForm.Size = New-Object Drawing.Size @(500,400) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True

$objForm.Add_KeyDown({
    if ($_.KeyCode -eq "Esc") 
        {
            $objForm.Close()
        }
    })

function btnClick
{
            $dtmDate=$objCalendar.SelectionStart.ToString("yyyyMMdd")

            Write-Host "Date selected: $dtmDate"


        $ps = new-object System.Diagnostics.Process
        $ps.StartInfo.Filename = "cmd.exe"
        $ps.StartInfo.Arguments = " /c echo Date = $dtmDate"
        $ps.StartInfo.RedirectStandardOutput = $True
        $ps.StartInfo.UseShellExecute = $false
        $ps.start()
        $ps.WaitForExit()
        [string] $Out = $ps.StandardOutput.ReadToEnd();

        Write-Host "Output $Out"
        $label.text = "$Out"    
}

$button = New-Object Windows.Forms.Button
$button.text = "RUN"
$button.Location = New-Object Drawing.Point 170,130
$button.add_click({btnClick})
$objForm.controls.add($button)

$label = new-object system.windows.forms.label
$label.text = ""
$label.Location = New-Object Drawing.Point 0, 180
$label.Size = New-Object Drawing.Point 200,30
$objForm.controls.add($label)

$objCalendar = New-Object System.Windows.Forms.MonthCalendar 
$objCalendar.ShowTodayCircle = $False
$objCalendar.MaxSelectionCount = 1
$objForm.Controls.Add($objCalendar) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})  
[void] $objForm.ShowDialog() 