# Button click event handler
$buttonRunBenchmark_Click = {
    $scriptPath = "C:\Path\To\Your\BenchmarkScript.ps1"
    
    # Run the benchmark script
    Start-Process powershell -ArgumentList "-File $scriptPath"
    
    # Display a message to the user
    $labelStatus.Text = "Benchmarking completed."
}
# Label to display benchmark results
$labelResults = New-Object System.Windows.Forms.Label
$labelResults.Location = New-Object System.Drawing.Point(10, 100)
$labelResults.Size = New-Object System.Drawing.Size(400, 50)
$form.Controls.Add($labelResults)
# Label to display benchmark results
$labelResults = New-Object System.Windows.Forms.Label
$labelResults.Location = New-Object System.Drawing.Point(10, 100)
$labelResults.Size = New-Object System.Drawing.Size(400, 50)
$form.Controls.Add($labelResults)
