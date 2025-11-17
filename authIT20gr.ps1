<# 
  Ελληνική Εφαρμογή 2FA/MFA (TOTP) σε PowerShell WPF
  - Φιλική σε διαχειριστές: αποθήκευση μυστικών με DPAPI (Export-Clixml SecureString)
  - Συμβατό με otpauth:// URIs ή Base32 μυστικά
  - Μία μόνο .ps1, χωρίς εξαρτήσεις

  Εκτέλεση:
    powershell -ExecutionPolicy Bypass -File .\Greek-2FA.ps1
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

#region Helpers: Base32, TOTP, Storage

function Convert-Base32ToBytes {
    param(
        [Parameter(Mandatory)]
        [string]$Base32
    )
    # Καθαρισμός: Αφαίρεση κενών, ίσων, κλπ.
    $clean = ($Base32 -replace '\s','').ToUpper()
    $clean = $clean -replace '[=]+$',''
    $alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    $bits = New-Object System.Text.StringBuilder
    foreach ($ch in $clean.ToCharArray()) {
        $idx = $alphabet.IndexOf($ch)
        if ($idx -lt 0) { throw "Μη έγκυρος χαρακτήρας Base32: '$ch'" }
        # 5 bits per char
        [void]$bits.Append(("{0}" -f [Convert]::ToString($idx,2).PadLeft(5,'0')))
    }
    # Ομαδοποίηση σε bytes
    $byteList = New-Object System.Collections.Generic.List[byte]
    for ($i=0; $i -le ($bits.Length - 8); $i += 8) {
        $chunk = $bits.ToString().Substring($i,8)
        $byteList.Add([byte]([Convert]::ToInt32($chunk,2)))
    }
    return ,$byteList.ToArray()
}

function Parse-OtpAuthUri {
    param(
        [Parameter(Mandatory)]
        [string]$Uri
    )
    # Υποστήριξη: otpauth://totp/Label?secret=XXXX&issuer=YYY&period=30&digits=6&algorithm=SHA1
    if ($Uri -notmatch '^otpauth://totp/') {
        throw "Μη έγκυρο otpauth URI."
    }
    $u = [Uri]$Uri.Replace('otpauth://totp/','http://dummy/') # trick για εύκολη parse
    $label = [System.Web.HttpUtility]::UrlDecode($u.AbsolutePath.TrimStart('/'))
    $qs = [System.Web.HttpUtility]::ParseQueryString($u.Query)
    $secret = $qs['secret']
    if (-not $secret) { throw "Το URI δεν περιέχει 'secret'." }
    $issuer = $qs['issuer']
    $period = [int]($qs['period'] ?? 30)
    $digits = [int]($qs['digits'] ?? 6)
    $algo = ($qs['algorithm'] ?? 'SHA1').ToUpper()
    return [pscustomobject]@{
        Label   = $label
        Issuer  = $issuer
        Secret  = $secret
        Period  = $period
        Digits  = $digits
        Algo    = $algo
    }
}

function Get-TotpCode {
    param(
        [Parameter(Mandatory)]
        [string]$Base32Secret,
        [int]$Period = 30,
        [int]$Digits = 6,
        [ValidateSet('SHA1','SHA256','SHA512')]
        [string]$Algorithm = 'SHA1',
        [Nullable[DateTime]]$Time = $null
    )
    if (-not $Time) { $Time = [DateTime]::UtcNow }
    $counter = [Math]::Floor(($Time - [DateTime]::UnixEpoch).TotalSeconds / $Period)
    $secretBytes = Convert-Base32ToBytes -Base32 $Base32Secret
    # Move counter to 8-byte big-endian
    $counterBytes = [BitConverter]::GetBytes([Int64]$counter)
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($counterBytes) }

    switch ($Algorithm) {
        'SHA1'   { $hmac = New-Object System.Security.Cryptography.HMACSHA1($secretBytes) }
        'SHA256' { $hmac = New-Object System.Security.Cryptography.HMACSHA256($secretBytes) }
        'SHA512' { $hmac = New-Object System.Security.Cryptography.HMACSHA512($secretBytes) }
    }
    $hash = $hmac.ComputeHash($counterBytes)
    $offset = $hash[$hash.Length-1] -band 0x0F
    $binaryCode = ((($hash[$offset] -band 0x7F) -shl 24) -bor ($hash[$offset+1] -shl 16) -bor ($hash[$offset+2] -shl 8) -bor $hash[$offset+3])
    $otp = $binaryCode % [int][Math]::Pow(10, $Digits)
    $code = $otp.ToString().PadLeft($Digits, '0')
    $hmac.Dispose()
    return $code
}

# Αποθήκευση λογαριασμών με DPAPI μέσω SecureString + Export-Clixml
$AppDir = Join-Path $env:APPDATA 'Greek2FA'
$StorePath = Join-Path $AppDir 'accounts.xml'
if (-not (Test-Path $AppDir)) { New-Item -ItemType Directory -Path $AppDir | Out-Null }

function Load-Accounts {
    if (Test-Path $StorePath) {
        try {
            $data = Import-Clixml -Path $StorePath
            # Εξασφάλιση τύπων
            return @($data | ForEach-Object {
                [pscustomobject]@{
                    Name     = $_.Name
                    Issuer   = $_.Issuer
                    Secret   = $_.Secret # SecureString
                    Period   = [int]($_.Period)
                    Digits   = [int]($_.Digits)
                    Algorithm= $_.Algorithm
                }
            })
        } catch {
            [System.Windows.MessageBox]::Show("Σφάλμα φόρτωσης αποθήκης: $($_.Exception.Message)","Σφάλμα",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
            return @()
        }
    } else {
        return @()
    }
}

function Save-Accounts($accounts) {
    try {
        $accounts | Export-Clixml -Path $StorePath
        return $true
    } catch {
        [System.Windows.MessageBox]::Show("Σφάλμα αποθήκευσης: $($_.Exception.Message)","Σφάλμα",
            [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
        return $false
    }
}

function SecureString-ToPlain([SecureString]$s) {
    if (-not $s) { return "" }
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        if ($ptr -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    }
}

#endregion

#region XAML UI (Greek)
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Εφαρμογή 2FA / MFA (TOTP)" Height="520" Width="820" WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize">
  <Grid Margin="10">
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="2*"/>
      <ColumnDefinition Width="3*"/>
    </Grid.ColumnDefinitions>
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <TextBlock Grid.ColumnSpan="2" Text="Διαχείριση Λογαριασμών TOTP" FontSize="18" FontWeight="Bold" Margin="0,0,0,10"/>

    <!-- Left: Accounts -->
    <GroupBox Header="Λογαριασμοί" Grid.Row="1" Grid.Column="0" Margin="0,0,10,0">
      <DockPanel>
        <StackPanel DockPanel.Dock="Bottom" Orientation="Horizontal" Margin="0,10,0,0">
          <Button x:Name="btnAdd" Content="Προσθήκη" Width="90" Margin="0,0,8,0"/>
          <Button x:Name="btnEdit" Content="Επεξεργασία" Width="90" Margin="0,0,8,0"/>
          <Button x:Name="btnDelete" Content="Διαγραφή" Width="90"/>
        </StackPanel>
        <ListBox x:Name="lstAccounts" DisplayMemberPath="Name" />
      </DockPanel>
    </GroupBox>

    <!-- Right: Details & Code -->
    <GroupBox Header="Λεπτομέρειες & Κωδικός" Grid.Row="1" Grid.Column="1">
      <Grid Margin="10">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="10"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Row="0" Grid.Column="0" Text="Όνομα:" VerticalAlignment="Center"/>
        <TextBox x:Name="txtName" Grid.Row="0" Grid.Column="1" Margin="8,0"/>

        <TextBlock Grid.Row="1" Grid.Column="0" Text="Έκδοτης (Issuer):" VerticalAlignment="Center"/>
        <TextBox x:Name="txtIssuer" Grid.Row="1" Grid.Column="1" Margin="8,0"/>

        <TextBlock Grid.Row="2" Grid.Column="0" Text="Μυστικό (Base32 ή otpauth URI):" VerticalAlignment="Center"/>
        <TextBox x:Name="txtSecret" Grid.Row="2" Grid.Column="1" Margin="8,0"/>

        <StackPanel Grid.Row="3" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,6,0,0">
          <TextBlock Text="Διάστημα (sec):" VerticalAlignment="Center"/>
          <TextBox x:Name="txtPeriod" Width="60" Margin="8,0" Text="30"/>
          <TextBlock Text="Ψηφία:" VerticalAlignment="Center" Margin="18,0,0,0"/>
          <TextBox x:Name="txtDigits" Width="60" Margin="8,0" Text="6"/>
          <TextBlock Text="Αλγόριθμος:" VerticalAlignment="Center" Margin="18,0,0,0"/>
          <ComboBox x:Name="cmbAlgo" Width="100" Margin="8,0">
            <ComboBoxItem Content="SHA1" IsSelected="True"/>
            <ComboBoxItem Content="SHA256"/>
            <ComboBoxItem Content="SHA512"/>
          </ComboBox>
          <Button x:Name="btnSave" Content="Αποθήκευση" Width="100" Margin="18,0,0,0"/>
        </StackPanel>

        <Separator Grid.Row="4" Grid.ColumnSpan="3" Margin="0,10,0,10"/>

        <TextBlock Grid.Row="5" Grid.Column="0" Text="Τρέχων κωδικός:" VerticalAlignment="Center"/>
        <TextBlock x:Name="lblCode" Grid.Row="5" Grid.Column="1" FontSize="24" FontWeight="Bold" Margin="8,0" Text="------"/>

        <ProgressBar x:Name="barTime" Grid.Row="6" Grid.ColumnSpan="3" Height="18" Minimum="0" Maximum="30" Margin="0,4,0,0"/>
        <TextBlock x:Name="lblExpires" Grid.Row="6" Grid.Column="2" HorizontalAlignment="Right" Text="Λήγει σε: 30s"/>

        <StackPanel Grid.Row="7" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,8,0,0">
          <Button x:Name="btnCopy" Content="Αντιγραφή" Width="100"/>
          <TextBox x:Name="txtVerify" Width="120" Margin="12,0" PlaceholderText="Επαλήθευση"/>
          <Button x:Name="btnVerify" Content="Έλεγχος" Width="100" Margin="8,0"/>
        </StackPanel>
      </Grid>
    </GroupBox>

    <!-- Footer -->
    <StackPanel Grid.Row="2" Grid.ColumnSpan="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button x:Name="btnExport" Content="Εξαγωγή" Width="100" Margin="0,0,8,0"/>
      <Button x:Name="btnImport" Content="Εισαγωγή" Width="100"/>
    </StackPanel>

  </Grid>
</Window>
"@

[xml]$x = $xaml
$reader = (New-Object System.Xml.XmlNodeReader $x)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Find controls
$lstAccounts = $window.FindName('lstAccounts')
$btnAdd      = $window.FindName('btnAdd')
$btnEdit     = $window.FindName('btnEdit')
$btnDelete   = $window.FindName('btnDelete')

$txtName     = $window.FindName('txtName')
$txtIssuer   = $window.FindName('txtIssuer')
$txtSecret   = $window.FindName('txtSecret')
$txtPeriod   = $window.FindName('txtPeriod')
$txtDigits   = $window.FindName('txtDigits')
$cmbAlgo     = $window.FindName('cmbAlgo')
$btnSave     = $window.FindName('btnSave')

$lblCode     = $window.FindName('lblCode')
$barTime     = $window.FindName('barTime')
$lblExpires  = $window.FindName('lblExpires')
$btnCopy     = $window.FindName('btnCopy')
$txtVerify   = $window.FindName('txtVerify')
$btnVerify   = $window.FindName('btnVerify')

$btnExport   = $window.FindName('btnExport')
$btnImport   = $window.FindName('btnImport')

# Data
$Accounts = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$loaded = Load-Accounts
$loaded | ForEach-Object { $Accounts.Add($_) }
$lstAccounts.ItemsSource = $Accounts

function Refresh-Details {
    $sel = $lstAccounts.SelectedItem
    if ($sel) {
        $txtName.Text   = $sel.Name
        $txtIssuer.Text = $sel.Issuer
        $txtPeriod.Text = [string]$sel.Period
        $txtDigits.Text = [string]$sel.Digits
        # Secret και αλγόριθμος
        $txtSecret.Text = SecureString-ToPlain $sel.Secret
        foreach ($item in $cmbAlgo.Items) {
            if ($item.Content -eq $sel.Algorithm) { $cmbAlgo.SelectedItem = $item; break }
        }
    } else {
        $txtName.Text   = ""
        $txtIssuer.Text = ""
        $txtPeriod.Text = "30"
        $txtDigits.Text = "6"
        $txtSecret.Text = ""
        $cmbAlgo.SelectedIndex = 0
    }
}

# Timer για ενημέρωση κωδικού
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(250)
$timer.Add_Tick({
    $sel = $lstAccounts.SelectedItem
    if (-not $sel) {
        $lblCode.Text = "------"
        $barTime.Value = 0
        $lblExpires.Text = "Λήγει σε: --s"
        return
    }
    # Υπολογισμός υπολοίπου χρόνου
    $period = [int]$sel.Period
    $now = [DateTime]::UtcNow
    $elapsed = [int]([Math]::Floor(($now - [DateTime]::UnixEpoch).TotalSeconds) % $period)
    $remaining = $period - $elapsed
    $barTime.Maximum = $period
    $barTime.Value = $remaining
    $lblExpires.Text = "Λήγει σε: $remaining s"
    try {
        $secretPlain = SecureString-ToPlain $sel.Secret
        $code = Get-TotpCode -Base32Secret $secretPlain -Period $sel.Period -Digits $sel.Digits -Algorithm $sel.Algorithm -Time $now
        $lblCode.Text = $code
    } catch {
        $lblCode.Text = "Σφάλμα"
    }
})

# Events
$lstAccounts.Add_SelectionChanged({ Refresh-Details })

$btnAdd.Add_Click({
    $txtName.Text   = ""
    $txtIssuer.Text = ""
    $txtSecret.Text = ""
    $txtPeriod.Text = "30"
    $txtDigits.Text = "6"
    $cmbAlgo.SelectedIndex = 0
    $txtName.Focus()
})

$btnEdit.Add_Click({
    if (-not $lstAccounts.SelectedItem) {
        [System.Windows.MessageBox]::Show("Επιλέξτε λογαριασμό για επεξεργασία.","Προειδοποίηση",
            [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    $txtName.Focus()
})

$btnDelete.Add_Click({
    $sel = $lstAccounts.SelectedItem
    if ($sel) {
        $res = [System.Windows.MessageBox]::Show("Διαγραφή του '${($sel.Name)}';","Επιβεβαίωση",
            [System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
        if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
            $Accounts.Remove($sel) | Out-Null
            Save-Accounts $Accounts | Out-Null
            Refresh-Details
        }
    }
})

$btnSave.Add_Click({
    $name = $txtName.Text.Trim()
    $issuer = $txtIssuer.Text.Trim()
    $secretInput = $txtSecret.Text.Trim()
    if (-not $name) { [System.Windows.MessageBox]::Show("Το 'Όνομα' είναι υποχρεωτικό.","Σφάλμα") | Out-Null; return }
    if (-not $secretInput) { [System.Windows.MessageBox]::Show("Το 'Μυστικό' είναι υποχρεωτικό.","Σφάλμα") | Out-Null; return }

    # Αν είναι otpauth URI, parse και αντικατάσταση πεδίων
    if ($secretInput -like 'otpauth://totp/*') {
        try {
            $parsed = Parse-OtpAuthUri -Uri $secretInput
            if (-not $issuer) { $issuer = $parsed.Issuer }
            if (-not $name)   { $name   = $parsed.Label }
            $secretInput = $parsed.Secret
            $txtPeriod.Text = [string]$parsed.Period
            $txtDigits.Text = [string]$parsed.Digits
            foreach ($item in $cmbAlgo.Items) {
                if ($item.Content -eq $parsed.Algo) { $cmbAlgo.SelectedItem = $item; break }
            }
        } catch {
            [System.Windows.MessageBox]::Show("Σφάλμα απο το otpauth URI: $($_.Exception.Message)","Σφάλμα") | Out-Null
            return
        }
    }

    # Επιβεβαίωση Base32 μυστικού
    try { [void](Convert-Base32ToBytes -Base32 $secretInput) } catch {
        [System.Windows.MessageBox]::Show("Μυστικό (Base32) μη έγκυρο: $($_.Exception.Message)","Σφάλμα") | Out-Null
        return
    }

    $period = [int]$txtPeriod.Text
    $digits = [int]$txtDigits.Text
    $algo = ($cmbAlgo.SelectedItem.Content).ToString()
    $secureSecret = ConvertTo-SecureString -String $secretInput -AsPlainText -Force

    $existing = $Accounts | Where-Object { $_.Name -eq $name }
    if ($existing) {
        $existing.Issuer    = $issuer
        $existing.Secret    = $secureSecret
        $existing.Period    = $period
        $existing.Digits    = $digits
        $existing.Algorithm = $algo
    } else {
        $Accounts.Add([pscustomobject]@{
            Name      = $name
            Issuer    = $issuer
            Secret    = $secureSecret
            Period    = $period
            Digits    = $digits
            Algorithm = $algo
        }) | Out-Null
    }
    Save-Accounts $Accounts | Out-Null
    $lstAccounts.Items.Refresh()
    # Επιλογή του αποθηκευμένου
    $lstAccounts.SelectedItem = ($Accounts | Where-Object { $_.Name -eq $name } | Select-Object -First 1)
    [System.Windows.MessageBox]::Show("Αποθηκεύτηκε επιτυχώς.","Εντάξει",
        [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
})

$btnCopy.Add_Click({
    $code = $lblCode.Text
    if ($code -and $code -notlike '---*') {
        [System.Windows.Forms.Clipboard]::SetText($code)
        [System.Windows.MessageBox]::Show("Ο κωδικός αντιγράφηκε στο πρόχειρο.","Εντάξει") | Out-Null
    }
})

$btnVerify.Add_Click({
    $sel = $lstAccounts.SelectedItem
    if (-not $sel) { return }
    $input = $txtVerify.Text.Trim()
    if (-not $input) { return }
    try {
        $secretPlain = SecureString-ToPlain $sel.Secret
        $now = [DateTime]::UtcNow
        $codes = @(
            Get-TotpCode -Base32Secret $secretPlain -Period $sel.Period -Digits $sel.Digits -Algorithm $sel.Algorithm -Time $now
            # Επιτρέπουμε ένα παράθυρο +/- 1 περίοδο για ανοχή
            Get-TotpCode -Base32Secret $secretPlain -Period $sel.Period -Digits $sel.Digits -Algorithm $sel.Algorithm -Time ($now.AddSeconds(-$sel.Period))
            Get-TotpCode -Base32Secret $secretPlain -Period $sel.Period -Digits $sel.Digits -Algorithm $sel.Algorithm -Time ($now.AddSeconds($sel.Period))
        )
        if ($codes -contains $input) {
            [System.Windows.MessageBox]::Show("Έγκυρος κωδικός.","Επιτυχία",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
        } else {
            [System.Windows.MessageBox]::Show("Μη έγκυρος κωδικός.","Αποτυχία",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
        }
    } catch {
        [System.Windows.MessageBox]::Show("Σφάλμα επαλήθευσης: $($_.Exception.Message)","Σφάλμα",
            [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$btnExport.Add_Click({
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Title = "Εξαγωγή αποθήκης"
    $dlg.Filter = "XML αρχεία|*.xml|Όλα τα αρχεία|*.*"
    $dlg.FileName = "Greek2FA-accounts.xml"
    if ($dlg.ShowDialog()) {
        try {
            $Accounts | Export-Clixml -Path $dlg.FileName
            [System.Windows.MessageBox]::Show("Εξαγωγή ολοκληρώθηκε.","Εντάξει") | Out-Null
        } catch {
            [System.Windows.MessageBox]::Show("Σφάλμα εξαγωγής: $($_.Exception.Message)","Σφάλμα") | Out-Null
        }
    }
})

$btnImport.Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Title = "Εισαγωγή αποθήκης"
    $dlg.Filter = "XML αρχεία|*.xml|Όλα τα αρχεία|*.*"
    if ($dlg.ShowDialog()) {
        try {
            $imp = Import-Clixml -Path $dlg.FileName
            # Συγχώνευση/αντικατάσταση βάσει ονόματος
            foreach ($acc in $imp) {
                $existing = $Accounts | Where-Object { $_.Name -eq $acc.Name }
                if ($existing) {
                    $existing.Issuer    = $acc.Issuer
                    $existing.Secret    = $acc.Secret
                    $existing.Period    = [int]$acc.Period
                    $existing.Digits    = [int]$acc.Digits
                    $existing.Algorithm = $acc.Algorithm
                } else {
                    $Accounts.Add($acc) | Out-Null
                }
            }
            Save-Accounts $Accounts | Out-Null
            $lstAccounts.Items.Refresh()
            [System.Windows.MessageBox]::Show("Εισαγωγή ολοκληρώθηκε.","Εντάξει") | Out-Null
        } catch {
            [System.Windows.MessageBox]::Show("Σφάλμα εισαγωγής: $($_.Exception.Message)","Σφάλμα") | Out-Null
        }
    }
})

# Start
$window.Add_SourceInitialized({
    $timer.Start()
})
$window.Add_Closed({
    $timer.Stop()
    $timer = $null
    [GC]::Collect()
})

# Εμφάνιση
$window.ShowDialog() | Out-Null
