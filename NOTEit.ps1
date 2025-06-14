Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# XAML for the WPF Window
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI Tabbed Notepad" Height="350" Width="500">
    <Grid>
        <TabControl Name="tabControl">
            <TabItem Header="New Tab">
                <TextBox AcceptsReturn="True" Name="textBox" />
            </TabItem>
        </TabControl>
        <Button Content="New Tab" HorizontalAlignment="Left" Margin="10" VerticalAlignment="Top" Width="80" Height="30" Name="newTabButton"/>
    </Grid>
</Window>
"@

# Create a reader to load the XAML
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Connect the button to an event handler
$newTabButton = $window.FindName("newTabButton")
$tabControl = $window.FindName("tabControl")

$newTabButton.Add_Click({
    $newTabItem = New-Object Windows.Controls.TabItem
    $newTabItem.Header = "New Tab"
    $newTextBox = New-Object Windows.Controls.TextBox
    $newTextBox.AcceptsReturn = $true
    $newTabItem.Content = $newTextBox
    $tabControl.Items.Add($newTabItem)
})

# Show the window
$window.ShowDialog()
