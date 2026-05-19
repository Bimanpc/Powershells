Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase

#---------------- CONFIG ----------------#
# Requires: MySQL .NET Connector or ODBC, or mysql.exe in PATH
# This sample uses mysql.exe CLI for max portability / no extra libs.
#----------------------------------------#

# Create XAML for a simple WPF window
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MySQL Info / Version - LLM Ready" Height="420" Width="720"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResizeWithGrip">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <!-- Connection fields -->
        <TextBlock Grid.Row="0" Grid.Column="0" Margin="0,0,8,4" VerticalAlignment="Center">Host:</TextBlock>
        <TextBox   Grid.Row="0" Grid.Column="1" Margin="0,0,8,4" x:Name="txtHost" Text="127.0.0.1"/>

        <TextBlock Grid.Row="1" Grid.Column="0" Margin="0,0,8,4" VerticalAlignment="Center">Port:</TextBlock>
        <TextBox   Grid.Row="1" Grid.Column="1" Margin="0,0,8,4" x:Name="txtPort" Text="3306"/>

        <TextBlock Grid.Row="2" Grid.Column="0" Margin="0,0,8,4" VerticalAlignment="Center">User:</TextBlock>
        <TextBox   Grid.Row="2" Grid.Column="1" Margin="0,0,8,4" x:Name="txtUser" Text="root"/>

        <TextBlock Grid.Row="3" Grid.Column="0" Margin="0,0,8,4" VerticalAlignment="Center">Password:</TextBlock>
        <PasswordBox Grid.Row="3" Grid.Column="1" Margin="0,0,8,4" x:Name="txtPass"/>

        <TextBlock Grid.Row="4" Grid.Column="0" Margin="0,0,8,4" VerticalAlignment="Center">Database (optional):</TextBlock>
        <TextBox   Grid.Row="4" Grid.Column="1" Margin="0,0,8,4" x:Name="txtDb"/>

        <!-- Buttons -->
        <StackPanel Grid.Row="0" Grid.Column="2" Grid.RowSpan="5" Orientation="Vertical" HorizontalAlignment="Right">
            <Button x:Name="btnVersion" Margin="0,0,0,6" Padding="10,4" Content="Get Version"/>
            <Button x:Name="btnInfo"    Margin="0,0,0,6" Padding="10,4" Content="Server Info"/>
            <Button x:Name="btnLLM"     Margin="0,0,0,6" Padding="10,4" Content="Send to LLM" ToolTip="Placeholder – wire your local LLM here"/>
        </StackPanel>

        <!-- Output -->
        <TextBlock Grid.Row="5" Grid.Column="0" Grid.ColumnSpan="3" Margin="0,4,0,4">Output:</TextBlock>
        <TextBox Grid.Row="5" Grid.Column="0" Grid.ColumnSpan="3" Margin="0,24,0,4"
                 x:Name="txtOutput" VerticalScrollBarVisibility="Auto"
                 HorizontalScrollBarVisibility="Auto" TextWrapping="NoWrap"
                 AcceptsReturn="True" IsReadOnly="True"/>

        <!-- Status bar -->
        <StatusBar Grid.Row="6" Grid.Column="0" Grid.ColumnSpan="3">
            <StatusBarItem>
                <TextBlock x:Name="lblStatus" Text="Ready."/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

# Parse XAML
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$txtHost   = $window.FindName("txtHost")
$txtPort   = $window.FindName("txtPort")
$txtUser   = $window.FindName("txtUser")
$txtPass   = $window.FindName("txtPass")
$txtDb     = $window.FindName("txtDb")
$btnVersion= $window.FindName("btnVersion")
$btnInfo   = $window.FindName("btnInfo")
$btnLLM    = $window.FindName("btnLLM")
$txtOutput = $window.FindName("txtOutput")
$lblStatus = $window.FindName("lblStatus")

function Invoke-MySqlCli {
    param(
        [string]$Host,
        [int]   $Port,
        [string]$User,
        [string]$Password,
        [string]$Database,
        [string]$Query
    )

    # Build mysql.exe command
    $args = @(
        "-h", $Host,
        "-P", $Port,
        "-u", $User,
        "-e", $Query,
        "--batch",
        "--skip-column-names"
    )

    if ($Password -ne "") {
        # Use env var to avoid password in process list
        $env:MYSQL_PWD = $Password
    } else {
        Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
    }

    if ($Database -ne "") {
        $args += $Database
    }

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "mysql"
        $psi.Arguments = ($args -join " ")
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $psi
        [void]$p.Start()
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()

        if ($p.ExitCode -ne 0) {
            throw "mysql exited with code $($p.ExitCode): $stderr"
        }

        return $stdout.Trim()
    }
    catch {
        throw $_
    }
    finally {
        Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
    }
}

function Get-UiConnectionParams {
    return [PSCustomObject]@{
        Host     = $txtHost.Text.Trim()
        Port     = [int]($txtPort.Text.Trim())
        User     = $txtUser.Text.Trim()
        Password = $txtPass.Password
        Database = $txtDb.Text.Trim()
    }
}

# Button: Get Version (SELECT VERSION())
$btnVersion.Add_Click({
    $lblStatus.Text = "Querying MySQL version..."
    $txtOutput.Text = ""
    try {
        $p = Get-UiConnectionParams
        $result = Invoke-MySqlCli -Host $p.Host -Port $p.Port -User $p.User -Password $p.Password -Database $p.Database -Query "SELECT VERSION();"
        $txtOutput.Text = "MySQL VERSION():`r`n$result"
        $lblStatus.Text = "Version retrieved."
    }
    catch {
        $txtOutput.Text = "ERROR:`r`n$($_.Exception.Message)"
        $lblStatus.Text = "Error."
    }
})

# Button: Server Info (SHOW VARIABLES LIKE 'version%'; etc.)
$btnInfo.Add_Click({
    $lblStatus.Text = "Querying MySQL server info..."
    $txtOutput.Text = ""
    try {
        $p = Get-UiConnectionParams
        $query = "SHOW VARIABLES LIKE 'version%';"
        $result = Invoke-MySqlCli -Host $p.Host -Port $p.Port -User $p.User -Password $p.Password -Database $p.Database -Query $query
        $txtOutput.Text = "MySQL Server Info (version% variables):`r`n$result"
        $lblStatus.Text = "Server info retrieved."
    }
    catch {
        $txtOutput.Text = "ERROR:`r`n$($_.Exception.Message)"
        $lblStatus.Text = "Error."
    }
})

# Button: Send to LLM (placeholder – local-only hook)
$btnLLM.Add_Click({
    $lblStatus.Text = "Preparing payload for LLM (no network call in this template)..."
    $currentText = $txtOutput.Text

    # ---- LLM HOOK START ----
    # Here you can wire your local LLM / HTTP endpoint / pipe.
    # Example (pseudo):
    #   $body = @{ prompt = "Explain this MySQL info:`n`n$currentText" } | ConvertTo-Json
    #   Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/generate" -Method POST -Body $body -ContentType "application/json"
    #
    # For now we just show the payload preview:
    $preview = "LLM payload preview (not sent):`r`n" +
               "--------------------------------`r`n" +
               "Explain this MySQL info:`r`n`r`n" +
               $currentText
    $txtOutput.Text = $preview
    $lblStatus.Text = "LLM payload prepared (preview only)."
    # ---- LLM HOOK END ----
})

# Show window
$window.Topmost = $false
$window.ShowDialog() | Out-Null
