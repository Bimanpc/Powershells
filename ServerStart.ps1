[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @"

<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"


        Title="Start" Height="350" Width="525">
    <Grid>
        <Label Name="label" Content="Hostname" HorizontalAlignment="Left" Margin="38,84,0,0" VerticalAlignment="Top" Width="132"/>
        <Label Name="label1" Content="User" HorizontalAlignment="Left" Margin="38,115,0,0" VerticalAlignment="Top" Width="132"/>
        <Label Name="label1_Copy" Content="Domain" HorizontalAlignment="Left" Margin="38,146,0,0" VerticalAlignment="Top" Width="132"/>
        <Label Name="label2" Content="Headline" HorizontalAlignment="Left" Margin="38,51,0,0" VerticalAlignment="Top" Width="132" FontWeight="Bold"/>
        <TextBox Name="textBox" HorizontalAlignment="Left" Height="23" Margin="170,87,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="120"/>
        <TextBox Name="textBox1" HorizontalAlignment="Left" Height="23" Margin="170,118,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="120"/>
        <TextBox Name="textBox2" HorizontalAlignment="Left" Height="23" Margin="170,148,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="120"/>
        <Button Name="button" Content="Close" HorizontalAlignment="Left" Margin="38,197,0,0" VerticalAlignment="Top" Width="75"/>
    </Grid>
</Window>


"@
#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader"; exit}

# Store Form Objects In PowerShell
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

#Show Form
$Form.ShowDialog() | out-null