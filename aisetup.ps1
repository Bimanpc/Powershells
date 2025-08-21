# Load required assembly for WPF
Add-Type -AssemblyName PresentationFramework

# Create XAML for GUI
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="AI SFX Setup App Maker"
        Height="400" Width="600"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,10">
            <Label Content="SFX Name:" Width="80"/>
            <TextBox Name="txtSFXName" Width="300" Margin="5,0,0,0"/>
            <Button Name="btnBrowse" Content="Browse..." Width="80" Margin="5,0,0,0"/>
        </StackPanel>
        
        <TextBox Name="txtLog" Grid.Row="1" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"
                 AcceptsReturn="True" IsReadOnly="True" Background="#FF1E1E1E" Foreground="White"/>
        
        <StackPanel Orientation="Horizontal" Grid.Row="2" HorizontalAlignment="Right" Margin="0,10,0,0">
            <Button Name="btnGenerate" Content="Generate SFX" Width="120" Margin="0,0,5,0"/>
            <Button Name="btnExit" Content="Exit" Width="80"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Convert XAML to objects
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Link controls to variables
$txtSFXName = $Window.FindName('txtSFXName')
$txtLog      = $Window.FindName('txtLog')
$btnBrowse   = $Window.FindName('btnBrowse')
$btnGenerate = $Window.FindName('btnGenerate')
$btnExit     = $Window.FindName('btnExit')

# Event: Browse button
$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Audio Files (*.wav;*.mp3)|*.wav;*.mp3"
    if ($dialog.ShowDialog() -eq "OK") {
        $txtSFXName.Text = $dialog.FileName
        $txtLog.AppendText("Selected file: $($dialog.FileName)`r`n")
    }
})

# Event: Generate SFX (placeholder for AI logic)
$btnGenerate.Add_Click({
    $txtLog.AppendText("Processing SFX setup for: $($txtSFXName.Text)`r`n")
    # Placeholder: call your AI sound effect generator here
    Start-Sleep -Seconds 1
    $txtLog.AppendText("SFX generated successfully!`r`n")
})

# Event: Exit button
$btnExit.Add_Click({
    $Window.Close()
})

# Show the window
$Window.ShowDialog() | Out-Null
