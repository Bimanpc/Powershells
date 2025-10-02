Add-Type -AssemblyName PresentationFramework

# XAML layout
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="CSV Viewer" Height="400" Width="600">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Button Name="LoadButton" Content="Load CSV" Width="100" Height="30" Margin="0,0,0,10"/>
        <DataGrid Name="CsvGrid" Grid.Row="1" AutoGenerateColumns="True" IsReadOnly="True"/>
    </Grid>
</Window>
"@

# Load XAML
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$XAML)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$LoadButton = $window.FindName("LoadButton")
$CsvGrid = $window.FindName("CsvGrid")

# Load CSV handler
$LoadButton.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = "CSV files (*.csv)|*.csv"
    if ($dialog.ShowDialog() -eq $true) {
        $csvPath = $dialog.FileName
        $csvData = Import-Csv -Path $csvPath
        $CsvGrid.ItemsSource = $csvData
    }
})

# Run the GUI
$window.ShowDialog() | Out-Null
