<# 
AI Printer Manager App (.ps1)
- Windows 10/11 compatible
- WPF GUI for managing printers and queues
- "AI Diagnose" offers human-friendly, heuristic suggestions based on live status and queue
#>

#region Prereqs (STA + Assemblies)
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Warning "Restarting PowerShell in STA mode..."
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName  = (Get-Process -Id $PID).Path
    $psi.Arguments = "-STA -NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    exit
}

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
Add-Type -AssemblyName System.Printing
#endregion

#region Helpers: Models & Utils
class PrinterItem {
    [string]$Name
    [string]$ShareName
    [string]$PortName
    [string]$Location
    [bool]  $IsDefault
    [string]$Status
    [int]   $QueueLength
    [string]$DriverName
    [string]$Comment
    [string]$HostAddress
}

function Get-PrinterList {
    $server = New-Object System.Printing.LocalPrintServer
    $queues = $server.GetPrintQueues([System.Printing.EnumeratedPrintQueueTypes]::Local,[System.Printing.EnumeratedPrintQueueTypes]::Connections)
    $items = @()

    foreach ($q in $queues) {
        try {
            $q.Refresh()
            $jobs = $q.GetPrintJobInfoCollection()
            $isDefault = $q.Default
            $statusFlags = @()
            foreach ($flag in [enum]::GetValues([System.Printing.PrintQueueStatus])) {
                if ($q.QueueStatus.HasFlag([System.Printing.PrintQueueStatus]$flag) -and $flag -ne [System.Printing.PrintQueueStatus]::None) {
                    $statusFlags += $flag.ToString()
                }
            }
            $statusText = if ($statusFlags) { ($statusFlags -join ", ") } else { "Ready" }

            # Attempt to derive host address from port if possible (best-effort for TCP/IP ports)
            $host = $null
            try {
                $wmi = Get-CimInstance -ClassName Win32_Printer -Filter "Name='$($q.FullName.Replace("'","''"))'"
                $host = $wmi.PortName
                if ($host -and $host -match '(\d{1,3}\.){3}\d{1,3}') { $host = $Matches[0] }
            } catch {}

            $items += [PrinterItem]@{
                Name        = $q.FullName
                ShareName   = $q.ShareName
                PortName    = $q.QueuePort.Name
                Location    = $q.Location
                IsDefault   = $isDefault
                Status      = $statusText
                QueueLength = ($jobs | Measure-Object).Count
                DriverName  = $q.QueueDriver.Name
                Comment     = $q.Comment
                HostAddress = $host
            }
        } catch {
            Write-Verbose "Failed to read queue $($q.FullName): $_"
        }
    }
    return $items
}

function Set-DefaultPrinter($printerName) {
    if (-not $printerName) { return $false }
    try {
        (Get-WmiObject -Query "SELECT * FROM Win32_Printer WHERE Name='$($printerName.Replace('\','\\'))'").SetDefaultPrinter() | Out-Null
        return $true
    } catch { return $false }
}

function Pause-Printer($printerName) {
    try {
        $q = (New-Object System.Printing.LocalPrintServer).GetPrintQueue($printerName)
        $q.Pause()
        return $true
    } catch { return $false }
}

function Resume-Printer($printerName) {
    try {
        $q = (New-Object System.Printing.LocalPrintServer).GetPrintQueue($printerName)
        $q.Resume()
        return $true
    } catch { return $false }
}

function Print-TestPage($printerName) {
    try {
        $printer = Get-CimInstance Win32_Printer -Filter "Name='$($printerName.Replace("'","''"))'"
        if ($printer) {
            $printer.PrintTestPage() | Out-Null
            return $true
        }
        return $false
    } catch { return $false }
}

function Open-QueueWindow($printerName) {
    try {
        Start-Process "rundll32.exe" "printui.dll,PrintUIEntry /o /n `"$printerName`""
        return $true
    } catch { return $false }
}

function Remove-PrinterByName($printerName) {
    try {
        Remove-Printer -Name $printerName -ErrorAction Stop
        return $true
    } catch { return $false }
}

function Add-TcpIpPrinter($name, $ip, $driver, $portName) {
    try {
        if (-not $portName) { $portName = "IP_$ip" }
        # Create TCP/IP port if not exists
        $existingPort = Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue
        if (-not $existingPort) {
            Add-PrinterPort -Name $portName -PrinterHostAddress $ip -ErrorAction Stop
        }
        # Add printer
        Add-Printer -Name $name -DriverName $driver -PortName $portName -ErrorAction Stop
        return $true
    } catch { return $false }
}

function AI-Diagnose($printers) {
    $suggestions = New-Object System.Collections.Generic.List[string]
    if (-not $printers -or $printers.Count -eq 0) {
        $suggestions.Add("No printers found. Check if the Print Spooler service is running and drivers are installed.")
        return $suggestions
    }

    $default = $printers | Where-Object { $_.IsDefault } | Select-Object -First 1
    $busy = $printers | Where-Object { $_.QueueLength -gt 0 }
    $paused = $printers | Where-Object { $_.Status -match 'Paused' }
    $offline = $printers | Where-Object { $_.Status -match 'Offline|Not available' }
    $paper = $printers | Where-Object { $_.Status -match 'OutOfPaper|PaperProblem|PaperOut' }
    $error = $printers | Where-Object { $_.Status -match 'Error|ServerUnknown|DoorOpen|TonerLow|NoToner|OutputBinFull' }

    if ($default -and $default.Status -ne 'Ready') {
        $suggestions.Add("Default printer '$($default.Name)' is not Ready ($($default.Status)). Consider setting a different default or resolving its status.")
    } elseif (-not $default) {
        $suggestions.Add("No default printer set. Choose a reliable printer and set it as default for faster printing.")
    }

    if ($busy.Count -gt 0) {
        $sum = ($busy | Measure-Object QueueLength -Sum).Sum
        $top = ($busy | Sort-Object QueueLength -Descending | Select-Object -First 1)
        $suggestions.Add("There are $sum job(s) in queues. Top queue: '$($top.Name)' with $($top.QueueLength) job(s). If stuck, try Resume or clear failed jobs.")
    }

    foreach ($p in $paused) {
        $suggestions.Add("Printer '$($p.Name)' is Paused. If intentional, keep it paused; otherwise click Resume.")
    }
    foreach ($p in $offline) {
        $suggestions.Add("Printer '$($p.Name)' appears Offline. Check power, network (host $($p.HostAddress)), and cable/Wi‑Fi connection.")
    }
    foreach ($p in $paper) {
        $suggestions.Add("Printer '$($p.Name)' reports a paper issue. Refill paper, clear jams, and verify tray settings.")
    }
    foreach ($p in $error) {
        $suggestions.Add("Printer '$($p.Name)' shows an error ($($p.Status)). Open its queue to inspect job errors or device alerts.")
    }

    if ($suggestions.Count -eq 0) {
        $suggestions.Add("All printers look Ready. If prints are slow, try restarting the Print Spooler: 'services.msc' → Print Spooler → Restart.")
    }
    return $suggestions
}
#endregion

#region XAML
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI Printer Manager" Height="620" Width="1000" WindowStartupLocation="CenterScreen"
        Background="#0f0f13" Foreground="#f5f5f7">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Margin" Value="6"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="Background" Value="#2b2b33"/>
            <Setter Property="Foreground" Value="#f5f5f7"/>
            <Setter Property="BorderBrush" Value="#3c3c46"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Margin" Value="6"/>
            <Setter Property="Padding" Value="6"/>
            <Setter Property="Background" Value="#1a1a20"/>
            <Setter Property="Foreground" Value="#f5f5f7"/>
            <Setter Property="BorderBrush" Value="#3c3c46"/>
        </Style>
        <Style TargetType="DataGrid">
            <Setter Property="Margin" Value="10"/>
            <Setter Property="Background" Value="#1a1a20"/>
            <Setter Property="Foreground" Value="#f5f5f7"/>
            <Setter Property="BorderBrush" Value="#3c3c46"/>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Margin" Value="10"/>
            <Setter Property="Foreground" Value="#f5f5f7"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="220"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Top toolbar -->
        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="10">
            <Button x:Name="RefreshBtn" Content="Refresh"/>
            <Button x:Name="DiagnoseBtn" Content="AI Diagnose"/>
            <Button x:Name="SetDefaultBtn" Content="Set Default"/>
            <Button x:Name="PauseBtn" Content="Pause"/>
            <Button x:Name="ResumeBtn" Content="Resume"/>
            <Button x:Name="TestPageBtn" Content="Print Test Page"/>
            <Button x:Name="OpenQueueBtn" Content="Open Queue"/>
            <Button x:Name="RemoveBtn" Content="Remove"/>
        </StackPanel>

        <!-- Printers grid -->
        <DataGrid x:Name="PrintersGrid" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Name" Binding="{Binding Name}" Width="2*"/>
                <DataGridTextColumn Header="Default" Binding="{Binding IsDefault}" Width="0.8*"/>
                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="1.5*"/>
                <DataGridTextColumn Header="Queue" Binding="{Binding QueueLength}" Width="0.6*"/>
                <DataGridTextColumn Header="Driver" Binding="{Binding DriverName}" Width="1.5*"/>
                <DataGridTextColumn Header="Location" Binding="{Binding Location}" Width="1.2*"/>
                <DataGridTextColumn Header="Port" Binding="{Binding PortName}" Width="1.2*"/>
                <DataGridTextColumn Header="Host" Binding="{Binding HostAddress}" Width="1.0*"/>
            </DataGrid.Columns>
        </DataGrid>

        <!-- Add printer panel -->
        <GroupBox Grid.Row="2" Header="Add TCP/IP Printer">
            <Grid Margin="8">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBox x:Name="AddName" Grid.Column="0" Grid.Row="0" PlaceholderText="Printer name"/>
                <TextBox x:Name="AddIP" Grid.Column="1" Grid.Row="0" PlaceholderText="IP address"/>
                <TextBox x:Name="AddDriver" Grid.Column="2" Grid.Row="0" PlaceholderText="Driver name"/>
                <TextBox x:Name="AddPort" Grid.Column="3" Grid.Row="0" PlaceholderText="Port name (optional)"/>
                <Button x:Name="AddBtn" Grid.Column="4" Grid.Row="0" Content="Add" Margin="6,0,0,0"/>

                <TextBlock Grid.ColumnSpan="5" Grid.Row="1" Margin="4,6,0,0" TextWrapping="Wrap"
                           Text="Tip: Use an installed driver name (e.g., 'Microsoft IPP Class Driver'). If the port doesn't exist, it will be created."/>
            </Grid>
        </GroupBox>

        <!-- Output / AI suggestions -->
        <GroupBox Grid.Row="3" Header="Output">
            <Grid Margin="8">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBox x:Name="OutputBox" Grid.Row="0" Grid.Column="0" Height="120" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" IsReadOnly="True"/>
            </Grid>
        </GroupBox>
    </Grid>
</Window>
"@
#endregion

#region Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$PrintersGrid  = $window.FindName("PrintersGrid")
$RefreshBtn    = $window.FindName("RefreshBtn")
$DiagnoseBtn   = $window.FindName("DiagnoseBtn")
$SetDefaultBtn = $window.FindName("SetDefaultBtn")
$PauseBtn      = $window.FindName("PauseBtn")
$ResumeBtn     = $window.FindName("ResumeBtn")
$TestPageBtn   = $window.FindName("TestPageBtn")
$OpenQueueBtn  = $window.FindName("OpenQueueBtn")
$RemoveBtn     = $window.FindName("RemoveBtn")
$AddName       = $window.FindName("AddName")
$AddIP         = $window.FindName("AddIP")
$AddDriver     = $window.FindName("AddDriver")
$AddPort       = $window.FindName("AddPort")
$AddBtn        = $window.FindName("AddBtn")
$OutputBox     = $window.FindName("OutputBox")
#endregion

#region UI Logic
function Refresh-PrintersUI {
    $PrintersGrid.ItemsSource = $null
    $data = Get-PrinterList
    $PrintersGrid.ItemsSource = $data
    $OutputBox.Text = "Refreshed at $(Get-Date). Found $($data.Count) printer(s)."
}

function Get-SelectedPrinterName {
    $item = $PrintersGrid.SelectedItem
    if ($item -and $item.Name) { return $item.Name }
    return $null
}

$RefreshBtn.Add_Click({
    Refresh-PrintersUI
})

$DiagnoseBtn.Add_Click({
    $items = @($PrintersGrid.ItemsSource)
    if (-not $items -or $items.Count -eq 0) { $items = Get-PrinterList }
    $tips = AI-Diagnose $items
    $OutputBox.Text = ($tips -join [Environment]::NewLine)
})

$SetDefaultBtn.Add_Click({
    $name = Get-SelectedPrinterName
    if (-not $name) { $OutputBox.Text = "Select a printer first."; return }
    if (Set-DefaultPrinter $name) { 
        Refresh-PrintersUI
        $OutputBox.Text = "Default printer set to '$name'."
    } else {
        $OutputBox.Text = "Failed to set default for '$name'."
    }
})

$PauseBtn.Add_Click({
    $name = Get-SelectedPrinterName
    if (-not $name) { $OutputBox.Text = "Select a printer first."; return }
    if (Pause-Printer $name) {
        Refresh-PrintersUI
        $OutputBox.Text = "Paused '$name'."
    } else {
        $OutputBox.Text = "Failed to pause '$name'."
    }
})

$ResumeBtn.Add_Click({
    $name = Get-SelectedPrinterName
    if (-not $name) { $OutputBox.Text = "Select a printer first."; return }
    if (Resume-Printer $name) {
        Refresh-PrintersUI
        $OutputBox.Text = "Resumed '$name'."
    } else {
        $OutputBox.Text = "Failed to resume '$name'."
    }
})

$TestPageBtn.Add_Click({
    $name = Get-SelectedPrinterName
    if (-not $name) { $OutputBox.Text = "Select a printer first."; return }
    if (Print-TestPage $name) {
        $OutputBox.Text = "Test page sent to '$name'."
    } else {
        $OutputBox.Text = "Failed to send test page to '$name'."
    }
})

$OpenQueueBtn.Add_Click({
    $name = Get-SelectedPrinterName
    if (-not $name) { $OutputBox.Text = "Select a printer first."; return }
    if (Open-QueueWindow $name) {
        $OutputBox.Text = "Opened queue for '$name'."
    } else {
        $OutputBox.Text = "Failed to open queue for '$name'."
    }
})

$RemoveBtn.Add_Click({
    $name = Get-SelectedPrinterName
    if (-not $name) { $OutputBox.Text = "Select a printer first."; return }
    $res = [System.Windows.MessageBox]::Show("Remove printer '$name'?", "Confirm", 'YesNo', 'Warning')
    if ($res -eq 'Yes') {
        if (Remove-PrinterByName $name) {
            Refresh-PrintersUI
            $OutputBox.Text = "Removed '$name'."
        } else {
            $OutputBox.Text = "Failed to remove '$name'."
        }
    }
})

$AddBtn.Add_Click({
    $name   = $AddName.Text.Trim()
    $ip     = $AddIP.Text.Trim()
    $driver = $AddDriver.Text.Trim()
    $port   = $AddPort.Text.Trim()

    if (-not $name -or -not $ip -or -not $driver) {
        $OutputBox.Text = "Enter Name, IP, and Driver. Port is optional."
        return
    }

    if (Add-TcpIpPrinter -name $name -ip $ip -driver $driver -portName $port) {
        Refresh-PrintersUI
        $OutputBox.Text = "Added printer '$name' at $ip using driver '$driver'."
    } else {
        $OutputBox.Text = "Failed to add printer '$name'. Check driver name and IP."
    }
})
#endregion

#region Start
Refresh-PrintersUI
$window.Topmost = $false
$null = $window.ShowDialog()
#endregion
