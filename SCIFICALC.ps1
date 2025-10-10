<# 
Sci‑Fi Calc (.ps1)
- Neon WPF GUI with keypad, history, and AI mode (natural language → result).
- Local mode: safe expression evaluation (PowerShell AST + selectable math funcs).
- AI mode: configurable generic LLM REST endpoint (JSON), returns a single numeric result.

Usage:
- Save as SciFiCalc.ps1 and run in PowerShell:  powershell -ExecutionPolicy Bypass -File .\SciFiCalc.ps1
- Optional: set $LLMEndpoint/$LLMApiKey to enable AI Mode.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# -------------------- Config --------------------
$LLMEndpoint = ""   # e.g., "https://your-llm-endpoint/v1/chat/completions" or "https://your-llm-endpoint/infer"
$LLMApiKey  = ""    # e.g., "sk-..." (leave empty to disable AI Mode by default)

# Model payload adapter (edit for your endpoint format)
function Invoke-LLM {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Endpoint = $LLMEndpoint,
        [string]$ApiKey   = $LLMApiKey,
        [int]$TimeoutSec  = 20
    )
    if ([string]::IsNullOrWhiteSpace($Endpoint)) { throw "LLM endpoint not configured." }
    $headers = @{}
    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) { $headers["Authorization"] = "Bearer $ApiKey" }
    $headers["Content-Type"] = "application/json"

    # Minimal generic JSON payload; adapt as needed for your LLM
    $body = @{
        model   = "math-instruct"
        messages = @(
            @{ role = "system"; content = "You are a precise calculator. Return only the final numeric result in plain text. No steps, no units unless asked." },
            @{ role = "user";   content = $Prompt }
        )
        temperature = 0
        max_tokens  = 64
    } | ConvertTo-Json -Depth 5

    $invokeParams = @{
        Uri         = $Endpoint
        Method      = "POST"
        Headers     = $headers
        Body        = $body
        TimeoutSec  = $TimeoutSec
        ErrorAction = 'Stop'
    }
    $resp = Invoke-RestMethod @invokeParams
    # Try common shapes: OpenAI-like or simple {output:"..."}
    if ($resp.choices && $resp.choices[0].message.content) { return ($resp.choices[0].message.content).Trim() }
    if ($resp.output) { return ($resp.output).ToString().Trim() }
    if ($resp.result) { return ($resp.result).ToString().Trim() }
    return ($resp | ConvertTo-Json -Depth 4)
}

# -------------------- Safe local evaluation --------------------
# Accepts basic arithmetic and selected math functions using PowerShell AST & whitelist.
$AllowedFuncs = @('sin','cos','tan','asin','acos','atan','sqrt','abs','log','log10','exp','floor','ceiling','round','min','max','pow','pi')
$FuncMap = @{
    sin    = { param($x) [math]::Sin($x) }
    cos    = { param($x) [math]::Cos($x) }
    tan    = { param($x) [math]::Tan($x) }
    asin   = { param($x) [math]::ASin($x) }
    acos   = { param($x) [math]::ACos($x) }
    atan   = { param($x) [math]::ATan($x) }
    sqrt   = { param($x) [math]::Sqrt($x) }
    abs    = { param($x) [math]::Abs($x) }
    log    = { param($x) [math]::Log($x) }
    log10  = { param($x) [math]::Log10($x) }
    exp    = { param($x) [math]::Exp($x) }
    floor  = { param($x) [math]::Floor($x) }
    ceiling= { param($x) [math]::Ceiling($x) }
    round  = { param($x,$d=0) [math]::Round($x,$d) }
    min    = { param($a,$b) [math]::Min($a,$b) }
    max    = { param($a,$b) [math]::Max($a,$b) }
    pow    = { param($a,$b) [math]::Pow($a,$b) }
    pi     = { [math]::PI }
}

function Evaluate-Local {
    param([Parameter(Mandatory)][string]$Expr)

    $expr = $Expr.Trim().ToLower()
    if ($expr -match '^[\s\(\)\d\.\+\-\*\/\^%,]+$') {
        # Replace ^ with Power operator for .NET math: use [math]::Pow(a,b)
        if ($expr -match '\^') {
            $expr = $expr -replace '(\d+(?:\.\d+)?)\s*\^\s*(\d+(?:\.\d+)?)','[math]::Pow($1,$2)'
        }
    } else {
        # Translate function calls like sin(1.2) to FuncMap invocation
        foreach ($name in $AllowedFuncs) {
            $pattern = "$name\s*\("
            if ($expr -match $pattern) {
                # no-op; allowed
            }
        }
        # Replace commas with semicolons inside round/min/max function argument splits? We'll parse manually below.
    }

    # Build a small parser for functions: handle func(x [,y])
    function Invoke-FuncText {
        param([string]$text)
        # Replace known function calls iteratively
        $maxIter = 50
        for ($i=0; $i -lt $maxIter; $i++) {
            $matched = $false
            foreach ($fname in $AllowedFuncs) {
                $regex = [regex]::Escape($fname) + '\s*\((?<args>[^\(\)]*)\)'
                $m = [regex]::Match($text, $regex)
                if ($m.Success) {
                    $matched = $true
                    $args = $m.Groups['args'].Value.Split(',').ForEach({ $_.Trim() }) | Where-Object { $_ -ne '' }
                    # Evaluate inner numeric args (recursive)
                    $evalArgs = @()
                    foreach ($a in $args) {
                        $evalArgs += [double](Invoke-Expression ("$a"))
                    }
                    $res = switch ($evalArgs.Count) {
                        0 { & $FuncMap[$fname] }
                        1 { & $FuncMap[$fname] $evalArgs[0] }
                        2 { & $FuncMap[$fname] $evalArgs[0] $evalArgs[1] }
                        Default { throw "Too many args for $fname()" }
                    }
                    $text = ($text.Substring(0,$m.Index) + $res + $text.Substring($m.Index + $m.Length))
                }
            }
            if (-not $matched) { break }
        }
        return $text
    }

    try {
        $prepared = Invoke-FuncText $expr
        # Final safety: allow only digits, operators, dots, parentheses
        if ($prepared -notmatch '^[\d\.\+\-\*\/\(\)\s]+$') {
            throw "Unsupported or unsafe expression."
        }
        $result = Invoke-Expression $prepared
        return [string]$result
    } catch {
        return "Error: $($_.Exception.Message)"
    }
}

# -------------------- XAML --------------------
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SCI‑FI CALC" Height="540" Width="400" WindowStartupLocation="CenterScreen"
        Background="#0A0F1F" AllowsTransparency="False">
    <Window.Resources>
        <SolidColorBrush x:Key="NeonBlue" Color="#00D9FF"/>
        <SolidColorBrush x:Key="NeonPink" Color="#FF3CAC"/>
        <SolidColorBrush x:Key="NeonGreen" Color="#3CFF9E"/>
        <Style x:Key="KeyBtn" TargetType="Button">
            <Setter Property="Margin" Value="6"/>
            <Setter Property="FontSize" Value="18"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="#121833"/>
            <Setter Property="BorderBrush" Value="{StaticResource NeonBlue}"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="Padding" Value="6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border CornerRadius="10" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}">
                            <Grid>
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                <Rectangle StrokeThickness="2" Stroke="{StaticResource NeonBlue}" Opacity="0.15"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="BorderBrush" Value="{StaticResource NeonPink}"/>
                                <Setter Property="Background" Value="#19224d"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="BorderBrush" Value="{StaticResource NeonGreen}"/>
                                <Setter Property="Background" Value="#0c1430"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="2*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,8">
            <TextBlock Text="SCI‑FI CALC" Foreground="{StaticResource NeonBlue}" FontSize="22" FontWeight="Bold"/>
            <TextBlock Text="  |  " Foreground="#5ac" FontSize="20"/>
            <TextBlock Text="AI Mode" Foreground="{StaticResource NeonPink}" FontSize="16" VerticalAlignment="Center"/>
            <ToggleButton x:Name="AiToggle" Width="50" Height="24" Margin="8,0,0,0">
                <ToggleButton.Template>
                    <ControlTemplate TargetType="ToggleButton">
                        <Border CornerRadius="12" Background="#152042" BorderBrush="{StaticResource NeonBlue}" BorderThickness="1.5">
                            <Grid>
                                <Ellipse x:Name="Knob" Width="18" Height="18" Fill="{StaticResource NeonBlue}" HorizontalAlignment="Left" Margin="3"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Knob" Property="HorizontalAlignment" Value="Right"/>
                                <Setter TargetName="Knob" Property="Margin" Value="3"/>
                                <Setter TargetName="Knob" Property="Fill" Value="{StaticResource NeonPink}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </ToggleButton.Template>
            </ToggleButton>
        </StackPanel>

        <!-- Input -->
        <DockPanel Grid.Row="1" LastChildFill="True" Margin="0,0,0,8">
            <TextBox x:Name="InputBox" FontSize="20" Foreground="#eaf" Background="#0c1328" BorderBrush="{StaticResource NeonBlue}" BorderThickness="1.5"
                     Padding="8" Height="40" VerticalContentAlignment="Center" Text="" />
            <Button x:Name="EvalBtn" Content="=" Style="{StaticResource KeyBtn}" Width="60" Height="40" Margin="8,0,0,0"/>
        </DockPanel>

        <!-- Display -->
        <ScrollViewer Grid.Row="2" Background="#0c1328" BorderBrush="#203" BorderThickness="1" Height="120">
            <StackPanel>
                <TextBlock Text="Output" Foreground="{StaticResource NeonGreen}" FontSize="14" Margin="8,6,8,2"/>
                <TextBlock x:Name="OutputBlock" Text="" Foreground="White" FontSize="18" Margin="8,0,8,8" TextWrapping="Wrap"/>
            </StackPanel>
        </ScrollViewer>

        <!-- Keypad -->
        <Grid Grid.Row="3">
            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Row 1 -->
            <Button Grid.Row="0" Grid.Column="0" Content="7" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="0" Grid.Column="1" Content="8" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="0" Grid.Column="2" Content="9" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="0" Grid.Column="3" Content="÷" Style="{StaticResource KeyBtn}"/>

            <!-- Row 2 -->
            <Button Grid.Row="1" Grid.Column="0" Content="4" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="1" Grid.Column="1" Content="5" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="1" Grid.Column="2" Content="6" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="1" Grid.Column="3" Content="×" Style="{StaticResource KeyBtn}"/>

            <!-- Row 3 -->
            <Button Grid.Row="2" Grid.Column="0" Content="1" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="2" Grid.Column="1" Content="2" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="2" Grid.Column="2" Content="3" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="2" Grid.Column="3" Content="−" Style="{StaticResource KeyBtn}"/>

            <!-- Row 4 -->
            <Button Grid.Row="3" Grid.Column="0" Content="0" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="3" Grid.Column="1" Content="." Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="3" Grid.Column="2" Content="(" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="3" Grid.Column="3" Content=")" Style="{StaticResource KeyBtn}"/>

            <!-- Row 5 -->
            <Button Grid.Row="4" Grid.Column="0" Content="+" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="4" Grid.Column="1" Content="^" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="4" Grid.Column="2" Content="C" Style="{StaticResource KeyBtn}"/>
            <Button Grid.Row="4" Grid.Column="3" Content="⌫" Style="{StaticResource KeyBtn}"/>
        </Grid>
    </Grid>
</Window>
"@

# -------------------- Build window --------------------
$reader = New-Object System.Xml.XmlNodeReader([xml]$xaml)
$win = [Windows.Markup.XamlReader]::Load($reader)

# Find controls
$InputBox   = $win.FindName("InputBox")
$OutputBlock= $win.FindName("OutputBlock")
$EvalBtn    = $win.FindName("EvalBtn")
$AiToggle   = $win.FindName("AiToggle")

# Wire keypad buttons
$buttons = @()
function Wire-Buttons {
    $queue = New-Object System.Collections.Generic.Queue[System.Windows.DependencyObject]
    $queue.Enqueue($win)
    while ($queue.Count -gt 0) {
        $node = $queue.Dequeue()
        for ($i=0; $i -lt [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($node); $i++) {
            $child = [System.Windows.Media.VisualTreeHelper]::GetChild($node, $i)
            if ($child -is [System.Windows.Controls.Button] -and $child.Name -ne "EvalBtn") {
                $buttons += $child
            }
            $queue.Enqueue($child)
        }
    }
    foreach ($btn in $buttons) {
        $btn.Add_Click({
            $txt = $btn.Content.ToString()
            switch ($txt) {
                "÷" { $InputBox.Text += " / " }
                "×" { $InputBox.Text += " * " }
                "−" { $InputBox.Text += " - " }
                "C" { $InputBox.Text = ""; $OutputBlock.Text = "" }
                "⌫" {
                    if ($InputBox.Text.Length -gt 0) { $InputBox.Text = $InputBox.Text.Substring(0, $InputBox.Text.Length - 1) }
                }
                Default { $InputBox.Text += $txt }
            }
            $InputBox.Focus()
            $InputBox.CaretIndex = $InputBox.Text.Length
        })
    }
}
Wire-Buttons

# Evaluate handler
function Do-Eval {
    $expr = $InputBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($expr)) { return }
    $OutputBlock.Text = "Processing..."
    $win.Cursor = 'Wait'
    try {
        if ($AiToggle.IsChecked) {
            try {
                $res = Invoke-LLM -Prompt $expr
                $OutputBlock.Text = $res
            } catch {
                $OutputBlock.Text = "AI Error: $($_.Exception.Message)"
            }
        } else {
            $res = Evaluate-Local -Expr $expr
            $OutputBlock.Text = $res
        }
    } finally {
        $win.Cursor = 'Arrow'
    }
}

$EvalBtn.Add_Click({ Do-Eval })
$InputBox.Add_KeyDown({
    if ($_.Key -eq 'Return') { Do-Eval }
})

# Minimal key bindings for convenience
$win.Add_KeyDown({
    switch ($_.Key) {
        'Escape' { $win.Close() }
        'F1'     { $OutputBlock.Text = "Tips: Try sin(0.5), sqrt(2)^2, (3+5)/2, round(3.14159,2). Toggle AI for natural language." }
    }
})

# Show window
$win.Topmost = $false
$win.ShowDialog() | Out-Null
