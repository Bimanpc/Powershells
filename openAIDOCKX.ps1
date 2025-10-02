Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Load Word Interop for reading DOCX
Add-Type -AssemblyName Microsoft.Office.Interop.Word

# XAML layout
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="AI Word File Viewer" Height="500" Width="700">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
            <Button Name="LoadButton" Content="Open Word File" Width="120" Margin="0,0,10,0"/>
            <Button Name="AnalyzeButton" Content="AI Analyze" Width="120"/>
        </StackPanel>

        <ScrollViewer Grid.Row="1">
            <TextBox Name="DocText" TextWrapping="Wrap" AcceptsReturn="True" 
                     VerticalScrollBarVisibility="Auto" IsReadOnly="True"/>
        </ScrollViewer>

        <TextBlock Grid.Row="2" Name="StatusBar" Text="Ready." 
                   HorizontalAlignment="Left" VerticalAlignment="Center"/>
    </Grid>
</Window>
"@

# Load XAML
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$XAML)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Controls
$LoadButton   = $window.FindName("LoadButton")
$AnalyzeButton= $window.FindName("AnalyzeButton")
$DocText      = $window.FindName("DocText")
$StatusBar    = $window.FindName("StatusBar")

# Load Word file
$LoadButton.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = "Word Documents (*.docx)|*.docx"
    if ($dialog.ShowDialog() -eq $true) {
        $filePath = $dialog.FileName
        $StatusBar.Text = "Loading $filePath ..."

        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $doc = $word.Documents.Open($filePath)
        $text = $doc.Content.Text
        $doc.Close()
        $word.Quit()

        $DocText.Text = $text
        $StatusBar.Text = "Loaded: $filePath"
    }
})

# AI Analyze (placeholder hook)
$AnalyzeButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($DocText.Text)) {
        $StatusBar.Text = "No document loaded."
        return
    }

    # Here you would call your AI/LLM API with $DocText.Text
    # Example placeholder:
    $StatusBar.Text = "Sending text to AI..."
    Start-Sleep -Seconds 1
    [System.Windows.MessageBox]::Show("AI Summary (placeholder):`n`n" + 
        $DocText.Text.Substring(0, [Math]::Min(500, $DocText.Text.Length)) + "...",
        "AI Analysis")
    $StatusBar.Text = "AI analysis complete."
})

# Run GUI
$window.ShowDialog() | Out-Null
