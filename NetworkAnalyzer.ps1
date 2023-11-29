Add-Type -AssemblyName PresentationFramework

[xml]$xaml = Get-Content -Path "Path\To\NetworkAnalyzer.xaml"
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlLoader]::Load($reader)

$startButton = $window.FindName("StartButton")
$outputTextBox = $window.FindName("OutputTextBox")

$startButton.Add_Click({
    # Your network analysis logic goes here
    $outputTextBox.Text = "Network analysis started..."
    # Add your code to analyze the network and update the $outputTextBox accordingly
})

[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)

[Windows.Markup.XamlLoader]::Load($reader)
[Windows.Markup.XamlLoader]::Load($reader)
$window.ShowDialog() | Out-Null
