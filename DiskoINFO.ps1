$inputXML = @"
<Window x:Class="FoxDeploy.Window1" 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008" 
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" 
    xmlns:local="clr-namespace:Azure" 
    mc:Ignorable="d" 
    Title="FoxDeploy Awesome GUI" Height="350" Width="600">    
    <Grid Margin="0,0,45,0">        
        <TextBlock x:Name="textBlock" HorizontalAlignment="Left" Height="100" Margin="174,28,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="282" FontSize="16"><Run GeekIT!!="Use the  tool to find out useful disk info, and also to get rich input from your scripts and tools"/><InlineUIContainer>
                <TextBlock x:Name="textBlock1" TextWrapping="Wrap" Text="TextBlock"/>
            </InlineUIContainer></TextBlock>
        <Button x:Name="button" Content="OK" HorizontalAlignment="Left" Height="55" Margin="370,235,0,0" VerticalAlignment="Top" Width="102" FontSize="18.667"/>
        <TextBox x:Name="textBox" HorizontalAlignment="Left" Height="35" Margin="221,166,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="168" FontSize="16"/>
        <Label x:Name="label" Content="UPC" HorizontalAlignment="Left" Height="46" Margin="56,162,0,0" VerticalAlignment="Top" Width="138" FontSize="16"/>
</Grid>
</Window>
"@

$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
try{
    $Form=[Windows.Markup.XamlReader]::Load( $reader )
}
catch{
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}
 
#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
  
$xaml.SelectNodes("//*[@Name]") | %{"trying item $($_.Name)";
    try {Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop}
    catch{throw}
    }

$Form.ShowDialog()