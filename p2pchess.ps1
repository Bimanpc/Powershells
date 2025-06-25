Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net.Sockets
Add-Type -AssemblyName System.IO

# Create a basic chess board state
$board = @{}
for ($r = 0; $r -lt 8; $r++) {
    for ($c = 0; $c -lt 8; $c++) {
        $board["$r$c"] = ""
    }
}
$turn = "white"
$myColor = "white"
$opponentIP = "127.0.0.1"
$listener = $null

# Basic AI - random move
function Get-RandomMove {
    $from = ($board.GetEnumerator() | Where-Object { $_.Value -ne "" -and $_.Value -like "$myColor*" } | Get-Random).Key
    $to = ($board.Keys | Get-Random)
    return "$from-$to"
}

# Networking - Send Move
function Send-Move($move) {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect($opponentIP, 8888)
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.WriteLine($move)
    $writer.Flush()
    $writer.Close()
    $client.Close()
}

# Networking - Start listener for opponent move
function Start-Listener {
    $listener = [System.Net.Sockets.TcpListener]8888
    $listener.Start()

    Start-Job {
        while ($true) {
            $client = $using:listener.AcceptTcpClient()
            $reader = New-Object System.IO.StreamReader($client.GetStream())
            $move = $reader.ReadLine()
            $reader.Close()
            $client.Close()
            [System.Windows.Forms.MessageBox]::Show("Opponent move: $move")
        }
    }
}

# GUI setup
$form = New-Object System.Windows.Forms.Form
$form.Text = "P2P Chess (PowerShell)"
$form.Size = New-Object System.Drawing.Size(400, 450)

# Chessboard Panel
$boardPanel = New-Object System.Windows.Forms.Panel
$boardPanel.Size = New-Object System.Drawing.Size(320, 320)
$boardPanel.Location = New-Object System.Drawing.Point(40, 20)
$form.Controls.Add($boardPanel)

# Draw buttons as chess squares
$squareSize = 40
$buttons = @{}
for ($r = 0; $r -lt 8; $r++) {
    for ($c = 0; $c -lt 8; $c++) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Size = New-Object System.Drawing.Size($squareSize, $squareSize)
        $btn.Location = New-Object System.Drawing.Point($c * $squareSize, $r * $squareSize)
        $btn.BackColor = if (($r + $c) % 2 -eq 0) { [System.Drawing.Color]::Beige } else { [System.Drawing.Color]::Brown }
        $btn.Text = ""
        $btn.Tag = "$r$c"
        $btn.Add_Click({
            $coord = $_.Source.Tag
            [System.Windows.Forms.MessageBox]::Show("You clicked $coord")
            # Here: add move logic, update board
            $move = Get-RandomMove
            Send-Move -move $move
        })
        $boardPanel.Controls.Add($btn)
        $buttons["$r$c"] = $btn
    }
}

# Start Button
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start Game"
$btnStart.Size = New-Object System.Drawing.Size(100, 30)
$btnStart.Location = New-Object System.Drawing.Point(150, 360)
$btnStart.Add_Click({ Start-Listener })
$form.Controls.Add($btnStart)

[void]$form.ShowDialog()
