﻿Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$window = New-Object System.Windows.Forms.Form
$window.Width = 1000
$window.Height = 1000
[void]$window.ShowDialog()