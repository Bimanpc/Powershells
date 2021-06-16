#Variables
$script:GUIElements = @(
    [pscustomobject]@{
        script=".\parameter.ps1";parameters="-Option -nochEineOption";text="ninite.com"
    },
    [pscustomobject]@{
        script=".\parameter.ps1";parameters="-nochEineOption";text="softpedia.com"
    },
    [pscustomobject]@{
        script=".\Skript2.ps1";parameters="";text="freewarefilles.com"
    }
)

#Lyout:XAML Code kann zwischen @" und "@ ersetzt werden:
[xml]$XAML = @"
<Window x:Class="WpfApplication.MainWindow"
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
xmlns:local="clr-namespace:WpfApplication"
mc:Ignorable="d"
Title="Select an Item" Height="768" Width="1024" Background="#cccccc">
    <Window.Resources>
      <Style TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="border" BorderThickness="1" BorderBrush="Black" CornerRadius="7" Padding="7" Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Opacity" Value="0.3" />
                                <Setter Property="Foreground" Value="#ffffff"/>
                                <Setter Property="Background" Value="#000000"/>
                                <Setter Property="BorderBrush" Value="#ffffff"/>
                        </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
      </Style>
    </Window.Resources>
        <StackPanel x:Name="StackPanel" Margin = "50,50,50,50">   
        <Label x:Name="label" Content="Sites:" HorizontalAlignment="Left"/>                                        
        </StackPanel>
</Window>
"@ -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window' #-replace wird benötigt, wenn XAML aus Visual Studio kopiert wird.
#XAML laden
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
try{$Form=[Windows.Markup.XamlReader]::Load( (New-Object System.Xml.XmlNodeReader $XAML) )}
catch{Write-Host "Windows.Markup.XamlReader konnte nicht geladen werden. Mögliche Ursache: ungültige Syntax oder fehlendes .net"}
$StackPanel = $Form.FindName("StackPanel")

function add_button($strLabel) {
        $objButton = New-Object System.Windows.Controls.Button
        $objButton.Content = $strLabel
        $objButton.margin = '5'
        $objButton.height = '40'
        $objButton.Name = $(($strLabel) -replace "[^a-zA-Z1-9]")
        $objButton.Add_Click({
                write-host "$($this.content) pressed"
                $Form.FindName("label").Content= "$($this.content) gestartet"

                foreach ($Element in $script:GUIElements) {
                    if ($($Element.text) -eq $($this.content)){
                    $command= "$($Element.script) $($Element.parameters)"
                    write-host "starting command $command"
                    $Form.Close()
                    invoke-expression -Command $command
                    }
                }

        }) 
        #insert it into the StackPanel
        $StackPanel.Children.Insert(($StackPanel.Children.count),$objButton)   

} 

foreach ($Element in $script:GUIElements) {
add_button $Element.text
}

#Fenster anzeigen:
$Form.ShowDialog()