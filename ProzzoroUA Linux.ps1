$Question = $host.ui.PromptForChoice(
    "Window Title", "Prozzorro is written in open source code?",(
        [System.Management.Automation.Host.ChoiceDescription[]](
            (New-Object System.Management.Automation.Host.ChoiceDescription "&YES","Yess"),
            (New-Object System.Management.Automation.Host.ChoiceDescription "&No","No")
        )
    ), 0
) 
switch($Question){
    0 {Write-Host "Yess"}
    1 {Write-Host "Noo"}
}