#Requires -RunAsAdministrator
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

function Test-IsAdmin {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    [System.Windows.MessageBox]::Show("Please run this script as Administrator.", "ISO Mounter", 'OK', 'Warning') | Out-Null
    return
}

# XAML for UI
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ISO File Mounter" Height="420" Width="700" WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="8"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="8"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <!-- ISO picker -->
        <TextBox x:Name="IsoPath" Grid.Row="0" Grid.Column="0" Height="28" Margin="0,0,8,0" />
        <StackPanel Grid.Row="0" Grid.Column="1" Orientation="Horizontal" >
            <Button x:Name="BrowseBtn" Content="Browse..." Width="90" Margin="0,0,8,0" />
            <Button x:Name="MountBtn" Content="Mount" Width="90" />
        </StackPanel>

        <!-- Spacer -->
        <Border Grid.Row="1"/>

        <!-- Mounted list -->
        <GroupBox Grid.Row="2" Grid.ColumnSpan="2" Header="Mounted ISOs">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <ListView x:Name="IsoList" Grid.Row="0">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="ISO path" Width="440" DisplayMemberBinding="{Binding IsoPath}" />
                            <GridViewColumn Header="Drive letter(s)" Width="120" DisplayMemberBinding="{Binding DriveLetters}" />
                            <GridViewColumn Header="Attached" Width="80" DisplayMemberBinding="{Binding Attached}" />
                        </GridView>
                    </ListView.View>
                </ListView>
                <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,6,0,0">
                    <Button x:Name="RefreshBtn" Content="Refresh" Width="90" Margin="0,0,8,0"/>
                    <Button x:Name="DismountBtn" Content="Dismount selected" Width="140"/>
                </StackPanel>
            </Grid>
        </GroupBox>

        <!-- Spacer -->
        <Border Grid.Row="3"/>

        <!-- Status -->
        <TextBlock x:Name="StatusText" Grid.Row="4" Grid.ColumnSpan="2" Foreground="DimGray" />
    </Grid>
</Window>
"@

# Load XAML
$reader = New-Object System.Xml.XmlNodeReader ([xml]$Xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$IsoPathTb   = $window.FindName('IsoPath')
$BrowseBtn   = $window.FindName('BrowseBtn')
$MountBtn    = $window.FindName('MountBtn')
$IsoList     = $window.FindName('IsoList')
$RefreshBtn  = $window.FindName('RefreshBtn')
$DismountBtn = $window.FindName('DismountBtn')
$StatusText  = $window.FindName('StatusText')

# Helpers
function Set-Status($msg, [System.Windows.Media.Brush]$color = [System.Windows.Media.Brushes]::DimGray) {
    $StatusText.Text = $msg
    $StatusText.Foreground = $color
}

function Get-MountedIsoInfo {
    # Returns objects with IsoPath, DriveLetters, Attached
    $images = Get-DiskImage | Where-Object { $_.ImagePath -and $_.ImagePath.ToLower().EndsWith('.iso') }
    foreach ($img in $images) {
        $letters = @()
        try {
            $vols = Get-Volume -DiskImage $img -ErrorAction Stop
            foreach ($v in $vols) {
                if ($v.DriveLetter) { $letters += ($v.DriveLetter + ':') }
            }
        } catch {
            # Fallback: look for CD-ROM volumes if needed (may include physical drives)
            $letters = @()
        }
        [PSCustomObject]@{
            IsoPath      = $img.ImagePath
            DriveLetters = ($letters -join ', ')
            Attached     = [string]$img.Attached
        }
    }
}

function Refresh-List {
    $IsoList.Items.Clear()
    $items = Get-MountedIsoInfo | Where-Object { $_.Attached -eq 'True' }
    foreach ($i in $items) { [void]$IsoList.Items.Add($i) }
    if ($IsoList.Items.Count -eq 0) {
        Set-Status "No ISOs are currently mounted."
    } else {
        Set-Status "Found $($IsoList.Items.Count) mounted ISO(s)."
    }
}

function Browse-Iso {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "ISO files (*.iso)|*.iso|All files (*.*)|*.*"
    $dlg.Multiselect = $false
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $IsoPathTb.Text = $dlg.FileName
        Set-Status "Selected: $($dlg.FileName)"
    }
}

function Mount-Iso($path) {
    if (-not $path -or -not (Test-Path -LiteralPath $path)) {
        Set-Status "Please select a valid ISO file.", [System.Windows.Media.Brushes]::Tomato
        return
    }
    try {
        Set-Status "Mounting ISO..."
        $img = Mount-DiskImage -ImagePath $path -PassThru -ErrorAction Stop
        Start-Sleep -Milliseconds 800
        $vols = Get-Volume -DiskImage $img -ErrorAction SilentlyContinue
        $letters = $null
        if ($vols) { $letters = ($vols | Where-Object DriveLetter | ForEach-Object { "$($_.DriveLetter):" }) -join ', ' }
        Refresh-List
        if ($letters) {
            Set-Status "Mounted: $path  ->  $letters", [System.Windows.Media.Brushes]::ForestGreen
        } else {
            Set-Status "Mounted: $path (no letter yet — refresh if needed)", [System.Windows.Media.Brushes]::ForestGreen
        }
    } catch {
        Set-Status "Mount failed: $($_.Exception.Message)", [System.Windows.Media.Brushes]::Tomato
    }
}

function Dismount-Selected {
    $sel = $IsoList.SelectedItem
    if (-not $sel) {
        Set-Status "Select a mounted ISO from the list to dismount.", [System.Windows.Media.Brushes]::Tomato
        return
    }
    try {
        Set-Status "Dismounting..."
        Dismount-DiskImage -ImagePath $sel.IsoPath -ErrorAction Stop
        Start-Sleep -Milliseconds 400
        Refresh-List
        Set-Status "Dismounted: $($sel.IsoPath)", [System.Windows.Media.Brushes]::ForestGreen
    } catch {
        Set-Status "Dismount failed: $($_.Exception.Message)", [System.Windows.Media.Brushes]::Tomato
    }
}

# Wire events
$BrowseBtn.Add_Click({ Browse-Iso })
$MountBtn.Add_Click({ Mount-Iso -path $IsoPathTb.Text })
$RefreshBtn.Add_Click({ Refresh-List })
$DismountBtn.Add_Click({ Dismount-Selected })

# Initial load
Refresh-List

# Show window
$window.Topmost = $false
[void]$window.ShowDialog()
