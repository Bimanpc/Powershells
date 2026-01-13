# ==========================================
# AI WiFi Security Analysis Tool (GUI)
# Ethical / Defensive Use Only
# ==========================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# --------------------------
# XAML UI
# --------------------------
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="AI Wi-Fi Security Analysis Tool"
        Height="520"
        Width="820"
        WindowStartupLocation="CenterScreen">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Authorized Wi-Fi Security Assessment (AI-Assisted)"
                   FontSize="18"
                   FontWeight="Bold"
                   Margin="0,0,0,10"/>

        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="2*"/>
                <ColumnDefinition Width="3*"/>
            </Grid.ColumnDefinitions>

            <!-- Left Panel -->
            <StackPanel Grid.Column="0" Margin="5">
                <Button Name="BtnLoad"
                        Content="Load Scan Results"
                        Height="35"
                        Margin="0,0,0,10"/>

                <TextBlock Text="Scan Data Preview:" FontWeight="Bold"/>
                <TextBox Name="TxtScanData"
                         Height="300"
                         AcceptsReturn="True"
                         VerticalScrollBarVisibility="Auto"
                         TextWrapping="Wrap"/>
            </StackPanel>

            <!-- Right Panel -->
            <StackPanel Grid.Column="1" Margin="5">
                <Button Name="BtnAnalyze"
                        Content="Analyze with AI"
                        Height="35"
                        Margin="0,0,0,10"/>

                <TextBlock Text="AI Security Analysis & Recommendations:"
                           FontWeight="Bold"/>

                <TextBox Name="TxtAIOutput"
                         Height="300"
                         AcceptsReturn="True"
                         VerticalScrollBarVisibility="Auto"
                         TextWrapping="Wrap"
                         IsReadOnly="True"/>
            </StackPanel>
        </Grid>

        <TextBlock Grid.Row="2"
                   Text="⚠ Use only on networks you own or have written authorization to test."
                   Foreground="DarkRed"
                   Margin="0,10,0,0"/>
    </Grid>
</Window>
"@

# --------------------------
# Load UI
# --------------------------
$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$BtnLoad     = $Window.FindName("BtnLoad")
$BtnAnalyze  = $Window.FindName("BtnAnalyze")
$TxtScanData = $Window.FindName("TxtScanData")
$TxtAIOutput = $Window.FindName("TxtAIOutput")

# --------------------------
# Load Scan Results
# --------------------------
$BtnLoad.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = "Text Files (*.txt)|*.txt|CSV Files (*.csv)|*.csv|JSON Files (*.json)|*.json"

    if ($dialog.ShowDialog()) {
        $TxtScanData.Text = Get-Content $dialog.FileName -Raw
    }
})

# --------------------------
# AI Analysis (Mock / Placeholder)
# Replace with approved LLM API
# --------------------------
function Invoke-AISecurityAnalysis {
    param($ScanData)

    return @"
AI SECURITY REVIEW SUMMARY
--------------------------
• Detected legacy encryption (WEP/WPA): HIGH RISK
• Weak passphrase indicators: MEDIUM RISK
• Hidden SSID usage: LOW SECURITY BENEFIT
• Missing WPA3 support

RECOMMENDATIONS
---------------
✔ Enforce WPA3 or WPA2-AES only
✔ Disable WPS
✔ Implement strong passphrase policy
✔ Enable network segmentation
✔ Monitor for rogue APs

NOTE
----
This analysis is advisory and does not perform exploitation.
"@
}

# --------------------------
# Analyze Button
# --------------------------
$BtnAnalyze.Add_Click({
    if ([string]::IsNullOrWhiteSpace($TxtScanData.Text)) {
        [System.Windows.MessageBox]::Show(
            "Please load scan data first.",
            "No Data",
            "OK",
            "Warning"
        )
        return
    }

    $TxtAIOutput.Text = "Analyzing..."
    Start-Sleep -Milliseconds 800

    $result = Invoke-AISecurityAnalysis -ScanData $TxtScanData.Text
    $TxtAIOutput.Text = $result
})

# --------------------------
# Show Window
# --------------------------
$Window.ShowDialog() | Out-Null
