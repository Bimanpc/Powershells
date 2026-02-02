Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase

# =========================
# CONFIG: LLM API SETTINGS
# =========================
$Global:LLM_ApiKey   = "<YOUR_API_KEY_HERE>"
$Global:LLM_Endpoint = "https://your-llm-endpoint/v1/chat/completions"
$Global:LLM_Model    = "your-model-name"

function Invoke-LLMRequest {
    param(
        [string]$Prompt
    )

    if ([string]::IsNullOrWhiteSpace($Prompt)) {
        return ""
    }

    # Example JSON body for a chat-style LLM (adjust to your provider)
    $body = @{
        model    = $Global:LLM_Model
        messages = @(
            @{
                role    = "user"
                content = $Prompt
            }
        )
    } | ConvertTo-Json -Depth 5

    try {
        $headers = @{
            "Authorization" = "Bearer $($Global:LLM_ApiKey)"
            "Content-Type"  = "application/json"
        }

        $response = Invoke-RestMethod -Uri $Global:LLM_Endpoint -Method Post -Headers $headers -Body $body
        # Adjust parsing according to your provider’s response schema
        $reply = $response.choices[0].message.content
        return $reply
    }
    catch {
        return "Error contacting AI: $($_.Exception.Message)"
    }
}

# =========================
# XAML LAYOUT
# =========================
# Large buttons, high contrast, visual-only interaction
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AI LLM Keyboard (Deaf-Friendly)" Height="600" Width="900"
        WindowStartupLocation="CenterScreen"
        Background="#111111">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="2*"/>
            <RowDefinition Height="2*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Title -->
        <TextBlock Grid.Row="0" Text="AI LLM Keyboard"
                   Foreground="White" FontSize="26"
                   HorizontalAlignment="Center" Margin="0,0,0,10"/>

        <!-- Input Text -->
        <TextBox x:Name="InputBox"
                 Grid.Row="1"
                 FontSize="20"
                 TextWrapping="Wrap"
                 AcceptsReturn="True"
                 VerticalScrollBarVisibility="Auto"
                 Background="#222222"
                 Foreground="White"
                 BorderBrush="#555555"
                 Margin="0,0,0,10"/>

        <!-- On-screen keyboard -->
        <UniformGrid Grid.Row="2" Rows="4" Columns="8" Margin="0,0,0,10">
            <!-- Row 1 -->
            <Button Content="Q" FontSize="20" Margin="3" Tag="Q"/>
            <Button Content="W" FontSize="20" Margin="3" Tag="W"/>
            <Button Content="E" FontSize="20" Margin="3" Tag="E"/>
            <Button Content="R" FontSize="20" Margin="3" Tag="R"/>
            <Button Content="T" FontSize="20" Margin="3" Tag="T"/>
            <Button Content="Y" FontSize="20" Margin="3" Tag="Y"/>
            <Button Content="U" FontSize="20" Margin="3" Tag="U"/>
            <Button Content="I" FontSize="20" Margin="3" Tag="I"/>

            <!-- Row 2 -->
            <Button Content="O" FontSize="20" Margin="3" Tag="O"/>
            <Button Content="P" FontSize="20" Margin="3" Tag="P"/>
            <Button Content="A" FontSize="20" Margin="3" Tag="A"/>
            <Button Content="S" FontSize="20" Margin="3" Tag="S"/>
            <Button Content="D" FontSize="20" Margin="3" Tag="D"/>
            <Button Content="F" FontSize="20" Margin="3" Tag="F"/>
            <Button Content="G" FontSize="20" Margin="3" Tag="G"/>
            <Button Content="H" FontSize="20" Margin="3" Tag="H"/>

            <!-- Row 3 -->
            <Button Content="J" FontSize="20" Margin="3" Tag="J"/>
            <Button Content="K" FontSize="20" Margin="3" Tag="K"/>
            <Button Content="L" FontSize="20" Margin="3" Tag="L"/>
            <Button Content="Z" FontSize="20" Margin="3" Tag="Z"/>
            <Button Content="X" FontSize="20" Margin="3" Tag="X"/>
            <Button Content="C" FontSize="20" Margin="3" Tag="C"/>
            <Button Content="V" FontSize="20" Margin="3" Tag="V"/>
            <Button Content="B" FontSize="20" Margin="3" Tag="B"/>

            <!-- Row 4 -->
            <Button Content="N" FontSize="20" Margin="3" Tag="N"/>
            <Button Content="M" FontSize="20" Margin="3" Tag="M"/>
            <Button Content="Space" FontSize="20" Margin="3" Tag="SPACE"/>
            <Button Content="Back" FontSize="20" Margin="3" Tag="BACK"/>
            <Button Content="Clear" FontSize="20" Margin="3" Tag="CLEAR"/>
            <Button Content="." FontSize="20" Margin="3" Tag="."/>
            <Button Content="?" FontSize="20" Margin="3" Tag="?"/>
            <Button Content="!" FontSize="20" Margin="3" Tag="!"/>
        </UniformGrid>

        <!-- AI Controls + Output -->
        <DockPanel Grid.Row="3">
            <Button x:Name="AskButton"
                    Content="Ask AI"
                    Width="120"
                    Height="40"
                    Margin="0,0,10,0"
                    DockPanel.Dock="Left"
                    Background="#3A7BD5"
                    Foreground="White"
                    FontSize="18"/>

            <TextBlock x:Name="StatusText"
                       DockPanel.Dock="Left"
                       Foreground="LightGray"
                       VerticalAlignment="Center"
                       Margin="0,0,10,0"
                       FontSize="14"/>

            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="OutputBox"
                           Text=""
                           TextWrapping="Wrap"
                           Foreground="White"
                           FontSize="18"/>
            </ScrollViewer>
        </DockPanel>
    </Grid>
</Window>
"@

# =========================
# BUILD WINDOW
# =========================
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$InputBox   = $window.FindName("InputBox")
$OutputBox  = $window.FindName("OutputBox")
$AskButton  = $window.FindName("AskButton")
$StatusText = $window.FindName("StatusText")

# Attach handlers to all keyboard buttons
$buttons = $window.FindName("InputBox").Parent.FindName("InputBox") # dummy to keep reference
# Better: walk visual tree for all Buttons in the UniformGrid
function Get-VisualChildrenButtons {
    param([System.Windows.DependencyObject]$parent)

    $count = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($parent)
    for ($i = 0; $i -lt $count; $i++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($parent, $i)
        if ($child -is [System.Windows.Controls.Button]) {
            $child
        }
        Get-VisualChildrenButtons -parent $child
    }
}

$allButtons = Get-VisualChildrenButtons -parent $window | Where-Object { $_ -is [System.Windows.Controls.Button] }

foreach ($btn in $allButtons) {
    if ($btn.Name -eq "AskButton") { continue }

    $btn.Add_Click({
        param($sender, $e)
        $tag = $sender.Tag

        switch ($tag) {
            "SPACE" {
                $InputBox.Text += " "
            }
            "BACK" {
                if ($InputBox.Text.Length -gt 0) {
                    $InputBox.Text = $InputBox.Text.Substring(0, $InputBox.Text.Length - 1)
                }
            }
            "CLEAR" {
                $InputBox.Clear()
            }
            default {
                $InputBox.Text += $tag
            }
        }

        # Move caret to end for better visual feedback
        $InputBox.CaretIndex = $InputBox.Text.Length
        $InputBox.Focus() | Out-Null
    })
}

# Ask AI button
$AskButton.Add_Click({
    $prompt = $InputBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($prompt)) {
        $StatusText.Text = "Type something first."
        return
    }

    $StatusText.Text = "Thinking..."
    $OutputBox.Text  = ""

    # Run LLM call in background to keep UI responsive
    $job = Start-Job -ScriptBlock {
        param($p, $apiKey, $endpoint, $model)

        # Rebuild function in job scope
        $body = @{
            model    = $model
            messages = @(
                @{
                    role    = "user"
                    content = $p
                }
            )
        } | ConvertTo-Json -Depth 5

        $headers = @{
            "Authorization" = "Bearer $apiKey"
            "Content-Type"  = "application/json"
        }

        try {
            $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
            $reply = $response.choices[0].message.content
            return $reply
        }
        catch {
            return "Error contacting AI: $($_.Exception.Message)"
        }
    } -ArgumentList $prompt, $Global:LLM_ApiKey, $Global:LLM_Endpoint, $Global:LLM_Model

    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        if ($EventArgs.JobStateInfo.State -eq "Completed") {
            $result = Receive-Job -Job $Event.Sender
            $window.Dispatcher.Invoke({
                $OutputBox.Text  = $result
                $StatusText.Text = "Done."
            })
            Unregister-Event -SourceIdentifier $Event.SourceIdentifier
            Remove-Job -Job $Event.Sender
        }
        elseif ($EventArgs.JobStateInfo.State -eq "Failed") {
            $window.Dispatcher.Invoke({
                $OutputBox.Text  = "Job failed."
                $StatusText.Text = "Error."
            })
            Unregister-Event -SourceIdentifier $Event.SourceIdentifier
            Remove-Job -Job $Event.Sender
        }
    } | Out-Null
})

# Show window
$window.Topmost = $true   # stays visible, useful in noisy / multi-window environments
$window.ShowDialog() | Out-Null
