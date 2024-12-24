Add-Type -AssemblyName PresentationFramework

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

function Show-ISO-Mounter {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ISO Mounter" Height="200" Width="400">
    <Grid>
        <Label Content="ISO Path:" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,10,0,0"/>
        <TextBox Name="isoPath" HorizontalAlignment="Left" VerticalAlignment="Top" Width="300" Margin="80,10,0,0"/>
        <Button Content="Browse" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="320,10,0,0" Name="browseButton"/>
        <Button Content="Mount" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="100,50,0,0" Name="mountButton"/>
        <Button Content="Unmount" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="200,50,0,0" Name="unmountButton"/>
    </Grid>
</Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    $window.FindName("browseButton").Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "ISO Files (*.iso)|*.iso"
        if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $window.FindName("isoPath").Text = $fileDialog.FileName
        }
    })

    $window.FindName("mountButton").Add_Click({
        $isoPath = $window.FindName("isoPath").Text
        if (-not [string]::IsNullOrWhiteSpace($isoPath) -and (Test-Path $isoPath)) {
            Mount-DiskImage -ImagePath $isoPath
            [System.Windows.MessageBox]::Show("ISO mounted successfully.", "Success")
        } else {
            [System.Windows.MessageBox]::Show("Please select a valid ISO file.", "Error")
        }
    })

    $window.FindName("unmountButton").Add_Click({
        $isoPath = $window.FindName("isoPath").Text
        if (-not [string]::IsNullOrWhiteSpace($isoPath) -and (Test-Path $isoPath)) {
            Dismount-DiskImage -ImagePath $isoPath
            [System.Windows.MessageBox]::Show("ISO unmounted successfully.", "Success")
        } else {
            [System.Windows.MessageBox]::Show("Please select a valid ISO file.", "Error")
        }
    })

    $window.ShowDialog()
}

Show-ISO-Mounter
