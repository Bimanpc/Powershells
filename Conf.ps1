function Invoke-GUI { #Begin function Invoke-GUI
    [cmdletbinding()]
    Param()

    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

    $inputXML = @"
<Window x:Class="psguiconfig.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:psguiconfig"
        mc:Ignorable="d"
        Title="PCTECHGREU Configuration" Height="281.26" Width="509.864">
    <Grid>
        <Label x:Name="lblWarningMin" Content="Warning Days" HorizontalAlignment="Left" Height="29" Margin="10,6,0,0" VerticalAlignment="Top" Width="86"/>
        <TextBox x:Name="txtBoxWarnLow" HorizontalAlignment="Left" Height="20" Margin="96,6,0,0" TextWrapping="Wrap" Text="0" VerticalAlignment="Top" Width="27"/>
        <Label x:Name="lblDisableMin" Content="Disable Days" HorizontalAlignment="Left" Height="29" Margin="134,6,0,0" VerticalAlignment="Top" Width="86"/>
        <TextBox x:Name="txtBoxDisableLow" HorizontalAlignment="Left" Height="20" Margin="220,6,0,0" TextWrapping="Wrap" Text="0" VerticalAlignment="Top" Width="27"/>
        <TextBox x:Name="txtBoxOUList" HorizontalAlignment="Left" Height="153" Margin="10,54,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="479" AcceptsReturn="True" ScrollViewer.VerticalScrollBarVisibility="Auto"/>
        <Label x:Name="lblOUs" Content="OU,s To Scan" HorizontalAlignment="Left" Height="26" Margin="10,28,0,0" VerticalAlignment="Top" Width="80"/>
        <Button x:Name="btnExceptions" Content="Exceptions" HorizontalAlignment="Left" Height="43" Margin="252,6,0,0" VerticalAlignment="Top" Width="237"/>
        <Button x:Name="btnEdit" Content="Edit" HorizontalAlignment="Left" Height="29" Margin="10,212,0,0" VerticalAlignment="Top" Width="66"/>
        <Button x:Name="btnSave" Content="Save" HorizontalAlignment="Left" Height="29" Margin="423,212,0,0" VerticalAlignment="Top" Width="66"/>
    </Grid>
</Window>
"@  

    [xml]$XAML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window' 
    
    #Read XAML 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
    try {
    
        $Form=[Windows.Markup.XamlReader]::Load( $reader )
        
    }

    catch {
    
        Write-Error "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
        
    }
 
    #Create variables to control form elements as objects in PowerShell
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    
        Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -Scope Global
        
    } 
    
    #Show form
    $form.ShowDialog() | Out-Null

}

#Call function to open the form
Invoke-GUI
