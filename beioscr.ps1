# ParentControlGUI.ps1
# Windows WPF GUI to manage policies for an iOS parental control app via backend APIs.
# Run: powershell -ExecutionPolicy Bypass -File .\ParentControlGUI.ps1

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type -AssemblyName System.Web

# Config (replace with your backend details)
$ApiBase  = "https://parental-backend.example.com"
$AuthToken = $env:PARENTAL_API_TOKEN # or hardcode for testing
$ParentId  = $env:PARENT_ID

function Invoke-Api {
    param(
        [string]$Method, [string]$Path, [hashtable]$Body = $null
    )
    $uri = "$ApiBase$Path"
    $headers = @{
        "Authorization" = "Bearer $AuthToken"
        "X-Parent-Id"   = $ParentId
        "Content-Type"  = "application/json"
    }
    try {
        if ($Body) {
            $json = ($Body | ConvertTo-Json -Depth 6)
            $resp = Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body $json
        } else {
            $resp = Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
        }
        return $resp
    } catch {
        [System.Windows.MessageBox]::Show("API error: $($_.Exception.Message)","Error","OK","Error") | Out-Null
        return $null
    }
}

# XAML UI
$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Title='AI Parental Control (iOS)' Height='640' Width='980' WindowStartupLocation='CenterScreen' Background='#0F1115' Foreground='#EDEFF5'>
    <Grid Margin='10'>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width='260'/>
            <ColumnDefinition Width='*'/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height='40'/>
            <RowDefinition Height='*'/>
            <RowDefinition Height='40'/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Orientation='Horizontal' Grid.ColumnSpan='2' Grid.Row='0' VerticalAlignment='Center'>
            <TextBlock Text='AI Parental Control' FontSize='18' FontWeight='Bold' Margin='0,0,12,0'/>
            <TextBlock Text='for iOS via FamilyControls' Opacity='0.8'/>
            <Button x:Name='RefreshBtn' Content='Refresh' Margin='20,0,0,0' Width='90' Height='24'/>
            <Button x:Name='AuthorizeBtn' Content='Request Authorization' Margin='6,0,0,0' Width='150' Height='24'/>
            <TextBlock x:Name='StatusTxt' Text='Idle' Margin='12,0,0,0' Opacity='0.7'/>
        </StackPanel>

        <!-- Devices -->
        <GroupBox Header='Child devices' Grid.Row='1' Grid.Column='0' Margin='0,8,8,8'>
            <DockPanel>
                <ListBox x:Name='DeviceList' MinHeight='300' />
            </DockPanel>
        </GroupBox>

        <!-- Main tabs -->
        <TabControl Grid.Row='1' Grid.Column='1' Margin='0,8,0,8'>
            <TabItem Header='Apps / Limits'>
                <Grid Margin='8'>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width='*'/>
                        <ColumnDefinition Width='*'/>
                    </Grid.ColumnDefinitions>
                    <Grid.RowDefinitions>
                        <RowDefinition Height='*'/>
                        <RowDefinition Height='Auto'/>
                    </Grid.RowDefinitions>

                    <GroupBox Header='Installed apps'>
                        <DockPanel>
                            <TextBox x:Name='AppSearch' Margin='0,0,0,6' Height='24' PlaceholderText='Search apps...' />
                            <ListView x:Name='AppsView' MinHeight='260'>
                                <ListView.View>
                                    <GridView>
                                        <GridViewColumn Header='App' DisplayMemberBinding='{Binding name}' Width='180'/>
                                        <GridViewColumn Header='Bundle ID' DisplayMemberBinding='{Binding id}' Width='240'/>
                                        <GridViewColumn Header='Category' DisplayMemberBinding='{Binding category}' Width='140'/>
                                        <GridViewColumn Header='Blocked'>
                                            <GridViewColumn.CellTemplate>
                                                <DataTemplate>
                                                    <CheckBox IsChecked='{Binding blocked}'/>
                                                </DataTemplate>
                                            </GridViewColumn.CellTemplate>
                                        </GridViewColumn>
                                        <GridViewColumn Header='Daily limit (min)'>
                                            <GridViewColumn.CellTemplate>
                                                <DataTemplate>
                                                    <TextBox Text='{Binding dailyLimit}' Width='60'/>
                                                </DataTemplate>
                                            </GridViewColumn.CellTemplate>
                                        </GridViewColumn>
                                    </GridView>
                                </ListView.View>
                            </ListView>
                        </DockPanel>
                    </GroupBox>

                    <GroupBox Header='Categories' Grid.Column='1'>
                        <StackPanel>
                            <ListView x:Name='CategoriesView' MinHeight='260'>
                                <ListView.View>
                                    <GridView>
                                        <GridViewColumn Header='Category' DisplayMemberBinding='{Binding name}' Width='200'/>
                                        <GridViewColumn Header='Blocked'>
                                            <GridViewColumn.CellTemplate>
                                                <DataTemplate>
                                                    <CheckBox IsChecked='{Binding blocked}'/>
                                                </DataTemplate>
                                            </GridViewColumn.CellTemplate>
                                        </GridViewColumn>
                                    </GridView>
                                </ListView.View>
                            </ListView>
                            <TextBlock Text='Emergency whitelist (bundle IDs, comma-separated)' Margin='0,6,0,2'/>
                            <TextBox x:Name='WhitelistTxt' Height='24'/>
                        </StackPanel>
                    </GroupBox>

                    <StackPanel Grid.Row='1' Grid.ColumnSpan='2' Orientation='Horizontal' HorizontalAlignment='Right' Margin='0,8,0,0'>
                        <Button x:Name='SavePolicyBtn' Content='Save policy' Width='110' Height='28' Margin='6,0,0,0'/>
                        <Button x:Name='LoadPolicyBtn' Content='Load policy' Width='110' Height='28' Margin='6,0,0,0'/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header='Schedules'>
                <Grid Margin='8'>
                    <Grid.RowDefinitions>
                        <RowDefinition Height='*'/>
                        <RowDefinition Height='Auto'/>
                    </Grid.RowDefinitions>
                    <DataGrid x:Name='ScheduleGrid' AutoGenerateColumns='False' MinHeight='320'>
                        <DataGrid.Columns>
                            <DataGridTextColumn Header='Start (HH:mm)' Binding='{Binding start}' Width='120'/>
                            <DataGridTextColumn Header='End (HH:mm)' Binding='{Binding end}' Width='120'/>
                            <DataGridTextColumn Header='Days (e.g., Mon,Tue,Wed)' Binding='{Binding days}' Width='220'/>
                        </DataGrid.Columns>
                    </DataGrid>
                    <StackPanel Grid.Row='1' Orientation='Horizontal' HorizontalAlignment='Right' Margin='0,8,0,0'>
                        <Button x:Name='AddScheduleBtn' Content='Add' Width='80' Height='26'/>
                        <Button x:Name='RemoveScheduleBtn' Content='Remove' Width='80' Height='26' Margin='6,0,0,0'/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header='Device status'>
                <Grid Margin='8'>
                    <TextBox x:Name='StatusBox' IsReadOnly='True' TextWrapping='Wrap' VerticalScrollBarVisibility='Auto'/>
                </Grid>
            </TabItem>
        </TabControl>

        <!-- Footer -->
        <StackPanel Grid.Row='2' Grid.ColumnSpan='2' Orientation='Horizontal' HorizontalAlignment='Right'>
            <Button x:Name='ExitBtn' Content='Exit' Width='80' Height='26'/>
        </StackPanel>
    </Grid>
</Window>
"@

# Load XAML
$reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Control bindings
$DeviceList         = $Window.FindName("DeviceList")
$AppsView           = $Window.FindName("AppsView")
$CategoriesView     = $Window.FindName("CategoriesView")
$WhitelistTxt       = $Window.FindName("WhitelistTxt")
$ScheduleGrid       = $Window.FindName("ScheduleGrid")
$StatusBox          = $Window.FindName("StatusBox")
$StatusTxt          = $Window.FindName("StatusTxt")

$RefreshBtn         = $Window.FindName("RefreshBtn")
$AuthorizeBtn       = $Window.FindName("AuthorizeBtn")
$SavePolicyBtn      = $Window.FindName("SavePolicyBtn")
$LoadPolicyBtn      = $Window.FindName("LoadPolicyBtn")
$AddScheduleBtn     = $Window.FindName("AddScheduleBtn")
$RemoveScheduleBtn  = $Window.FindName("RemoveScheduleBtn")
$ExitBtn            = $Window.FindName("ExitBtn")
$AppSearch          = $Window.FindName("AppSearch")

# State
$global:Devices = @()
$global:Apps    = @()
$global:Categories = @(
    @{ name="Social"; blocked=$false }
    @{ name="Games"; blocked=$false }
    @{ name="Entertainment"; blocked=$false }
    @{ name="Education"; blocked=$false }
    @{ name="Productivity"; blocked=$false }
)

$Schedule = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$ScheduleGrid.ItemsSource = $Schedule

function RenderDevices {
    $DeviceList.Items.Clear()
    foreach ($d in $global:Devices) {
        $DeviceList.Items.Add("$($d.name)  [$($d.id)]  status: $($d.status)")
    }
}

function RenderApps {
    $AppsView.Items.Clear()
    foreach ($a in $global:Apps) { $AppsView.Items.Add($a) }
}

function RenderCategories {
    $CategoriesView.Items.Clear()
    foreach ($c in $global:Categories) { $CategoriesView.Items.Add($c) }
}

function LoadDevices {
    $StatusTxt.Text = "Loading devices..."
    $resp = Invoke-Api -Method GET -Path "/devices"
    if ($resp -and $resp.devices) {
        $global:Devices = $resp.devices
        RenderDevices
        $StatusTxt.Text = "Loaded devices: $($global:Devices.Count)"
    } else {
        $StatusTxt.Text = "No devices"
    }
}

function LoadApps {
    if (-not $DeviceList.SelectedIndex -ge 0) { return }
    $devLine = $DeviceList.SelectedItem
    if (-not $devLine) { return }
    $devId = ($devLine -split '\[|\]')[1]
    $StatusTxt.Text = "Loading apps for $devId..."
    $resp = Invoke-Api -Method GET -Path "/apps?deviceId=$devId"
    if ($resp -and $resp.apps) {
        # normalize app data
        $global:Apps = @()
        foreach ($a in $resp.apps) {
            $global:Apps += [pscustomobject]@{
                name = $a.name
                id   = $a.id
                category = $a.category
                blocked  = [bool]$a.blocked
                dailyLimit = [int]($a.dailyLimit ?? 0)
            }
        }
        RenderApps
        $StatusTxt.Text = "Loaded apps: $($global:Apps.Count)"
    } else {
        $global:Apps = @()
        RenderApps
        $StatusTxt.Text = "No apps returned"
    }
}

function LoadPolicy {
    if (-not $DeviceList.SelectedIndex -ge 0) { return }
    $devLine = $DeviceList.SelectedItem
    $devId = ($devLine -split '\[|\]')[1]
    $resp = Invoke-Api -Method GET -Path "/policy?deviceId=$devId"
    if ($resp) {
        # Apply policy into UI
        $WhitelistTxt.Text = ($resp.emergencyWhitelist -join ",")
        # Blocks and limits
        $idToPolicy = @{}
        foreach ($b in ($resp.blocks ?? @())) { $idToPolicy[$b] = @{ blocked=$true } }
        $limits = $resp.dailyLimits ?? @{}
        for ($i=0; $i -lt $global:Apps.Count; $i++) {
            $app = $global:Apps[$i]
            $app.blocked = $idToPolicy.ContainsKey($app.id)
            if ($limits.ContainsKey($app.id)) { $app.dailyLimit = [int]$limits[$app.id] } else { $app.dailyLimit = 0 }
        }
        RenderApps
        # Categories
        $blockedCats = $resp.categoriesBlocked ?? @()
        for ($i=0; $i -lt $global:Categories.Count; $i++) {
            $cat = $global:Categories[$i]
            $cat.blocked = $blockedCats -contains $cat.name
        }
        RenderCategories
        # Schedule
        $Schedule.Clear()
        foreach ($s in ($resp.screenTimeSchedule ?? @())) {
            $Schedule.Add([pscustomobject]@{
                start = $s.startLocal
                end   = $s.endLocal
                days  = ($s.days -join ",")
            })
        }
        $StatusTxt.Text = "Policy loaded"
    } else {
        $StatusTxt.Text = "No policy"
    }
}

function SavePolicy {
    if (-not $DeviceList.SelectedIndex -ge 0) { return }
    $devLine = $DeviceList.SelectedItem
    $devId = ($devLine -split '\[|\]')[1]

    $blocks = @()
    $limits = @{}
    foreach ($a in $global:Apps) {
        if ($a.blocked) { $blocks += $a.id }
        if ([int]$a.dailyLimit -gt 0) { $limits[$a.id] = [int]$a.dailyLimit }
    }

    $catBlocked = @()
    foreach ($c in $global:Categories) {
        if ($c.blocked) { $catBlocked += $c.name }
    }

    $sched = @()
    foreach ($row in $Schedule) {
        $sched += @{
            startLocal = $row.start
            endLocal   = $row.end
            days       = ($row.days -split ",\s*")
        }
    }

    $wl = @()
    if ($WhitelistTxt.Text.Trim().Length -gt 0) {
        $wl = $WhitelistTxt.Text.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    }

    $policy = @{
        deviceId           = $devId
        blocks             = $blocks
        categoriesBlocked  = $catBlocked
        dailyLimits        = $limits
        screenTimeSchedule = $sched
        emergencyWhitelist = $wl
        notes              = "Set by Windows GUI $(Get-Date -Format s)"
    }

    $resp = Invoke-Api -Method POST -Path "/policy" -Body $policy
    if ($resp) {
        $StatusTxt.Text = "Policy saved"
        [System.Windows.MessageBox]::Show("Policy saved for $devId","Success","OK","None") | Out-Null
    }
}

function RequestAuthorization {
    if (-not $DeviceList.SelectedIndex -ge 0) { return }
    $devLine = $DeviceList.SelectedItem
    $devId = ($devLine -split '\[|\]')[1]
    $resp = Invoke-Api -Method POST -Path "/authorize" -Body @{ deviceId = $devId }
    if ($resp) {
        [System.Windows.MessageBox]::Show("Authorization request sent. Child device will prompt for approval via Family Sharing.","Info","OK","None") | Out-Null
        $StatusTxt.Text = "Auth request sent"
    }
}

# Events
$RefreshBtn.Add_Click({ LoadDevices })
$AuthorizeBtn.Add_Click({ RequestAuthorization })
$SavePolicyBtn.Add_Click({ SavePolicy })
$LoadPolicyBtn.Add_Click({ LoadPolicy })
$ExitBtn.Add_Click({ $Window.Close() })

$DeviceList.Add_SelectionChanged({
    LoadApps
    LoadPolicy
})

$AddScheduleBtn.Add_Click({
    $Schedule.Add([pscustomobject]@{ start="20:00"; end="07:00"; days="Sun,Mon,Tue,Wed,Thu" })
})

$RemoveScheduleBtn.Add_Click({
    $sel = $ScheduleGrid.SelectedItem
    if ($sel) { $Schedule.Remove($sel) }
})

$AppSearch.Add_TextChanged({
    $query = $AppSearch.Text.Trim().ToLower()
    $AppsView.Items.Clear()
    foreach ($a in $global:Apps) {
        if ($query -eq "" -or $a.name.ToLower().Contains($query) -or $a.id.ToLower().Contains($query)) {
            $AppsView.Items.Add($a)
        }
    }
})

# Startup
LoadDevices
RenderCategories

# Show window
$Window.Topmost = $false
$Window.ShowDialog() | Out-Null
