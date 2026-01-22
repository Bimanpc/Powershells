Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="AI LLM Notepad"
        Height="600"
        Width="900"
        WindowStartupLocation="CenterScreen"
        Background="#1e1e1e">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Toolbar -->
        <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
            <Button Name="BtnNew" Content="New" Width="70" Margin="5"/>
            <Button Name="BtnOpen" Content="Open" Width="70" Margin="5"/>
            <Button Name="BtnSave" Content="Save" Width="70" Margin="5"/>
            <Button Name="BtnCopy" Content="Copy" Width="70" Margin="5"/>
            <Button Name="BtnClear" Content="Clear" Width="70" Margin="5"/>
        </StackPanel>

        <!-- Editor -->
        <TextBox Name="Editor"
                 Grid.Row="1"
                 AcceptsReturn="True"
                 AcceptsTab="True"
                 VerticalScrollBarVisibility="Auto"
                 HorizontalScrollBarVisibility="Auto"
                 FontFamily="Consolas"
                 FontSize="14"
                 Foreground="#d4d4d4"
                 Background="#252526"
                 CaretBrush="White"
                 TextWrapping="Wrap"/>

        <!-- Status Bar -->
        <TextBlock Name="Status"
                   Grid.Row="2"
                   Margin="5"
                   Foreground="#9cdcfe"
                   Text="Ready"/>
    </Grid>
</Window>
"@

$Reader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Controls
$Editor = $Window.FindName("Editor")
$Status = $Window.FindName("Status")

$BtnNew   = $Window.FindName("BtnNew")
$BtnOpen  = $Window.FindName("BtnOpen")
$BtnSave  = $Window.FindName("BtnSave")
$BtnCopy  = $Window.FindName("BtnCopy")
$BtnClear = $Window.FindName("BtnClear")

# Functions
function Update-Status {
    $words = ($Editor.Text -split '\s+' | Where-Object { $_ }).Count
    $Status.Text = "Words: $words"
}

# Events
$Editor.Add_TextChanged({ Update-Status })

$BtnNew.Add_Click({
    $Editor.Clear()
    $Status.Text = "New document"
})

$BtnClear.Add_Click({
    $Editor.Clear()
    $Status.Text = "Cleared"
})

$BtnCopy.Add_Click({
    [System.Windows.Clipboard]::SetText($Editor.Text)
    $Status.Text = "Copied to clipboard"
})

$BtnOpen.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Text Files (*.txt)|*.txt"
    if ($dialog.ShowDialog() -eq "OK") {
        $Editor.Text = Get-Content $dialog.FileName -Raw
        $Status.Text = "Opened: $($dialog.FileName)"
    }
})

$BtnSave.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "Text Files (*.txt)|*.txt"
    if ($dialog.ShowDialog() -eq "OK") {
        Set-Content -Path $dialog.FileName -Value $Editor.Text -Encoding UTF8
        $Status.Text = "Saved: $($dialog.FileName)"
    }
})

# Show Window
$Window.ShowDialog() | Out-Null
