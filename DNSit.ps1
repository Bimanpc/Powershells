Add-Type -AssemblyName PresentationFramework

# Load XAML
[xml]$xaml = Get-Content -Path "DNSCheckerGUI.xaml"
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get UI elements
$domainTextBox = $window.FindName("DomainTextBox")
$checkButton = $window.FindName("CheckButton")
$resultTextBlock = $window.FindName("ResultTextBlock")

# Define the button click event
$checkButton.Add_Click({
    $domain = $domainTextBox.Text
    if (-not [string]::IsNullOrWhiteSpace($domain)) {
        try {
            $dnsResult = Resolve-DnsName -Name $domain -ErrorAction Stop
            $resultTextBlock.Text = "DNS Resolution Successful:"
            $resultTextBlock.Text += "`nIP Address: $($dnsResult.IPAddress)"
            $resultTextBlock.Foreground = "Green"
        } catch {
            $resultTextBlock.Text = "DNS Resolution Failed: $_"
            $resultTextBlock.Foreground = "Red"
        }
    } else {
        $resultTextBlock.Text = "Please enter a domain name."
        $resultTextBlock.Foreground = "Red"
    }
})

# Show the window
$window.ShowDialog() | Out-Null
