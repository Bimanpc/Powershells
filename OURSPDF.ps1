<# 
    File: PdfAI.ps1
    Run:  powershell.exe -ExecutionPolicy Bypass -File .\PdfAI.ps1

    What it does:
    - WPF GUI to load and view a PDF (via WebBrowser navigation).
    - Extracts text using pdftotext.exe if available.
    - Sends a condensed context + your question to an LLM endpoint.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

# -------------------------------
# App configuration (edit these)
# -------------------------------
$Global:LLM_Endpoint = "https://your-llm-endpoint/v1/chat/completions" # e.g., your gateway
$Global:LLM_ApiKey   = "YOUR_API_KEY_HERE"
$Global:LLM_Model    = "your-model-name" # adjust to your provider
$Global:MaxContextChars = 15000          # keep prompt payload reasonable
$Global:MaxAnswerTokens = 512
$Global:Temperature = 0.2

# --------------------------------
# Helpers: Toast + small utilities
# --------------------------------
function Show-Toast {
    param([string]$message)
    [System.Windows.MessageBox]::Show($message, "PDF AI", "OK", "Information") | Out-Null
}

function Test-ExeInPath {
    param([string]$exeName)
    $paths = $env:PATH -split ';'
    foreach ($p in $paths) {
        $candidate = Join-Path $p $exeName
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

# ------------------------------------------------------
# PDF text extraction: prefers local pdftotext.exe
# ------------------------------------------------------
function Get-PdfText {
    param(
        [Parameter(Mandatory=$true)][string]$PdfPath
    )
    if (-not (Test-Path $PdfPath)) {
        throw "PDF not found: $PdfPath"
    }

    $exeLocal = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "pdftotext.exe"
    $exePath  = if (Test-Path $exeLocal) { $exeLocal } else { Test-ExeInPath -exeName "pdftotext.exe" }

    if ($exePath) {
        $tmpTxt = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.txt'
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $exePath
        $psi.Arguments = "`"$PdfPath`" `"$tmpTxt`" -layout -enc UTF-8"
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        $p.WaitForExit()
        if ((Test-Path $tmpTxt) -and ((Get-Item $tmpTxt).Length -gt 0)) {
            try {
                $text = Get-Content -Raw -Path $tmpTxt -Encoding UTF8
                Remove-Item $tmpTxt -ErrorAction SilentlyContinue
                return $text
            } catch {
                Remove-Item $tmpTxt -ErrorAction SilentlyContinue
                throw "Failed to read extracted text."
            }
        } else {
            throw "pdftotext produced no output."
        }
    } else {
        throw "pdftotext.exe not found. Install Poppler or Xpdf tools and ensure pdftotext.exe is in PATH or alongside this script."
    }
}

# ------------------------------------------------------
# Summarize long PDF text to fit within prompt budget
# ------------------------------------------------------
function Compress-Context {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [int]$MaxChars = 15000
    )
    # Simple heuristic: if text is too long, keep head + tail, add marker.
    if ($Text.Length -le $MaxChars) { return $Text }

    $head = [Math]::Floor($MaxChars * 0.6)
    $tail = [Math]::Floor($MaxChars * 0.35)
    $middleNote = "`n...[Content truncated for brevity]...`n"
    if ($head + $tail + $middleNote.Length -gt $MaxChars) {
        $tail = $MaxChars - $head - $middleNote.Length
        if ($tail -lt 0) { $tail = 0 }
    }
    $start = $Text.Substring(0, [Math]::Min($head, $Text.Length))
    $ending = if ($tail -gt 0 -and $tail -lt $Text.Length) { $Text.Substring($Text.Length - $tail) } else { "" }
    return $start + $middleNote + $ending
}

# ------------------------------------------------------
# Call LLM API (generic JSON schema similar to Chat APIs)
# ------------------------------------------------------
function Invoke-LLM {
    param(
        [Parameter(Mandatory=$true)][string]$Context,
        [Parameter(Mandatory=$true)][string]$Question
    )

    $systemPrompt = @"
You are a careful assistant answering questions about a PDF. 
- Cite page numbers if the context includes them.
- If information is missing, say so briefly.
- Be concise and precise.
"@

    $userPrompt = @"
PDF Context:
---
$Context
---

User Question:
$Question
"@

    $body = @{
        model = $Global:LLM_Model
        messages = @(
            @{ role = "system"; content = $systemPrompt },
            @{ role = "user";   content = $userPrompt }
        )
        max_tokens = $Global:MaxAnswerTokens
        temperature = $Global:Temperature
    } | ConvertTo-Json -Depth 6

    $headers = @{
        "Authorization" = "Bearer $($Global:LLM_ApiKey)"
        "Content-Type"  = "application/json"
    }

    try {
        $resp = Invoke-RestMethod -Method Post -Uri $Global:LLM_Endpoint -Headers $headers -Body $body -TimeoutSec 120
        # Try common response shapes
        if ($resp.choices && $resp.choices[0].message.content) {
            return $resp.choices[0].message.content
        } elseif ($resp.choices && $resp.choices[0].text) {
            return $resp.choices[0].text
        } elseif ($resp.output && $resp.output.text) {
            return $resp.output.text
        } else {
            return ($resp | ConvertTo-Json -Depth 10)
        }
    } catch {
        throw "LLM call failed: $($_.Exception.Message)"
    }
}

# -------------------------------
# XAML UI
# -------------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PDF + AI" Height="800" Width="1200" WindowStartupLocation="CenterScreen"
        Background="#111319" Foreground="#EAEAF0">
    <Grid Margin="10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="3*"/>
            <ColumnDefinition Width="2*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Top bar -->
        <DockPanel Grid.ColumnSpan="2" Grid.Row="0" Margin="0,0,0,10">
            <Button x:Name="BtnOpen" Content="Open PDF" Width="120" Height="32" Margin="0,0,10,0"/>
            <TextBlock Text="PDF:" VerticalAlignment="Center" Margin="10,0,5,0"/>
            <TextBox x:Name="TxtPdfPath" IsReadOnly="True" Height="32" VerticalContentAlignment="Center"/>
        </DockPanel>

        <!-- PDF viewer (left) -->
        <Border Grid.Column="0" Grid.Row="1" Margin="0,0,10,10" Background="#1A1C24" CornerRadius="6">
            <Grid>
                <WindowsFormsHost x:Name="WFHost">
                    <System_Windows_Forms:WebBrowser x:Name="Browser" ScriptErrorsSuppressed="True" />
                </WindowsFormsHost>
            </Grid>
        </Border>

        <!-- Right panel (ask AI) -->
        <Border Grid.Column="1" Grid.Row="1" Margin="0,0,0,10" Background="#1A1C24" CornerRadius="6" Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="2*"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
                    <TextBlock Text="Question:" Margin="0,0,8,0" VerticalAlignment="Center"/>
                </StackPanel>

                <TextBox x:Name="TxtQuestion" Grid.Row="1" Height="80" TextWrapping="Wrap" AcceptsReturn="True"/>

                <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,10">
                    <TextBlock Text="Context limit (chars):" VerticalAlignment="Center" Margin="0,0,6,0"/>
                    <TextBox x:Name="TxtMaxChars" Width="100" Text="15000" Margin="6,0,20,0"/>
                    <TextBlock Text="Max answer tokens:" VerticalAlignment="Center" Margin="0,0,6,0"/>
                    <TextBox x:Name="TxtMaxTokens" Width="100" Text="512" Margin="6,0,20,0"/>
                    <TextBlock Text="Temp:" VerticalAlignment="Center" Margin="0,0,6,0"/>
                    <TextBox x:Name="TxtTemp" Width="60" Text="0.2"/>
                </StackPanel>

                <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Left">
                    <Button x:Name="BtnAsk" Content="Ask AI" Width="140" Height="34" Margin="0,0,10,0"/>
                    <ProgressBar x:Name="Prog" Width="140" Height="10" Visibility="Collapsed"/>
                </StackPanel>

                <Grid Grid.Row="4">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Text="Answer:" Margin="0,10,0,6"/>
                    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Background="#101219">
                        <TextBox x:Name="TxtAnswer" IsReadOnly="True" TextWrapping="Wrap" AcceptsReturn="True" Background="#101219" BorderThickness="0"/>
                    </ScrollViewer>
                </Grid>
            </Grid>
        </Border>

        <!-- Status bar -->
        <StatusBar Grid.Row="2" Grid.ColumnSpan="2" Background="#0D0F14">
            <StatusBarItem>
                <TextBlock x:Name="TxtStatus" Text="Ready."/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

# Needed for WindowsFormsHost
Add-Type -AssemblyName WindowsFormsIntegration
$ns = New-Object System.Xml.XmlNamespaceManager($xaml.NameTable)
$ns.AddNamespace("x", "http://schemas.microsoft.com/winfx/2006/xaml")
$ns.AddNamespace("System_Windows_Forms", "clr-namespace:System.Windows.Forms;assembly=System.Windows.Forms")

# Load XAML
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Find named controls
$BtnOpen     = $window.FindName("BtnOpen")
$TxtPdfPath  = $window.FindName("TxtPdfPath")
$WFHost      = $window.FindName("WFHost")
$Browser     = $window.FindName("Browser")
$TxtQuestion = $window.FindName("TxtQuestion")
$TxtAnswer   = $window.FindName("TxtAnswer")
$TxtStatus   = $window.FindName("TxtStatus")
$BtnAsk      = $window.FindName("BtnAsk")
$Prog        = $window.FindName("Prog")
$TxtMaxChars = $window.FindName("TxtMaxChars")
$TxtMaxTokens= $window.FindName("TxtMaxTokens")
$TxtTemp     = $window.FindName("TxtTemp")

# Track current PDF
$Global:CurrentPdf = $null
$ofd = New-Object System.Windows.Forms.OpenFileDialog
$ofd.Filter = "PDF files (*.pdf)|*.pdf|All files (*.*)|*.*"
$ofd.Title = "Open PDF"

# Wire up Open
$BtnOpen.Add_Click({
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $path = $ofd.FileName
        $TxtPdfPath.Text = $path
        $Global:CurrentPdf = $path
        try {
            # Use WinForms WebBrowser control to navigate to local PDF
            $Browser.Navigate($path)
            $TxtStatus.Text = "Loaded: $path"
        } catch {
            $TxtStatus.Text = "Viewer failed to load the PDF."
        }
    }
})

# Wire up Ask AI
$BtnAsk.Add_Click({
    if (-not $Global:CurrentPdf) { Show-Toast "Open a PDF first."; return }
    $question = ($TxtQuestion.Text ?? "").Trim()
    if (-not $question) { Show-Toast "Type your question."; return }

    # Read UI-configurable params
    $Global:MaxContextChars = [int]($TxtMaxChars.Text)
    $Global:MaxAnswerTokens = [int]($TxtMaxTokens.Text)
    $Global:Temperature     = [double]($TxtTemp.Text)

    $BtnAsk.IsEnabled = $false
    $Prog.Visibility = "Visible"
    $TxtStatus.Text = "Extracting PDF text..."

    Start-Job -ScriptBlock {
        param($pdf, $maxChars)

        # Extract
        $text = Get-PdfText -PdfPath $pdf

        # Compress
        $context = Compress-Context -Text $text -MaxChars $maxChars

        # Return as PSObject
        [PSCustomObject]@{
            Context = $context
        }
    } -ArgumentList $Global:CurrentPdf, $Global:MaxContextChars | Wait-Job | Receive-Job | ForEach-Object {
        $context = $_.Context
        $TxtStatus.Dispatcher.Invoke([action]{ $TxtStatus.Text = "Contacting AI..." })
        try {
            $answer = Invoke-LLM -Context $context -Question $question
            $TxtAnswer.Dispatcher.Invoke([action]{ $TxtAnswer.Text = $answer })
            $TxtStatus.Dispatcher.Invoke([action]{ $TxtStatus.Text = "Done." })
        } catch {
            $msg = $_.Exception.Message
            $TxtAnswer.Dispatcher.Invoke([action]{ $TxtAnswer.Text = "Error: $msg" })
            $TxtStatus.Dispatcher.Invoke([action]{ $TxtStatus.Text = "Error." })
        } finally {
            $BtnAsk.Dispatcher.Invoke([action]{ $BtnAsk.IsEnabled = $true })
            $Prog.Dispatcher.Invoke([action]{ $Prog.Visibility = "Collapsed" })
        }
    } | Out-Null
})

# Show window
$window.Topmost = $false
$window.ShowDialog() | Out-Null
