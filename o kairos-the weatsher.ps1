# Weather Forecast GUI using OpenWeatherMap API

# Define your OpenWeatherMap API key
$api_key = "YOUR_API_KEY_HERE"

# Create a GUI window
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object Windows.Forms.Form
$form.Text = "Weather Forecast"
$form.Width = 400
$form.Height = 300

# Add a label for city input
$label = New-Object Windows.Forms.Label
$label.Text = "Enter City Name:"
$label.Location = New-Object Drawing.Point(20, 20)
$form.Controls.Add($label)

# Add a text box for city input
$cityTextBox = New-Object Windows.Forms.TextBox
$cityTextBox.Location = New-Object Drawing.Point(20, 40)
$form.Controls.Add($cityTextBox)

# Add a button to fetch weather data
$fetchButton = New-Object Windows.Forms.Button
$fetchButton.Text = "Get Weather"
$fetchButton.Location = New-Object Drawing.Point(20, 70)
$form.Controls.Add($fetchButton)

# Event handler for button click
$fetchButton.Add_Click({
    $city = $cityTextBox.Text
    $url = "https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$api_key"
    $response = Invoke-RestMethod -Uri $url
    $temp = $response.main.temp
    $humidity = $response.main.humidity
    $description = $response.weather[0].description

    # Display weather information
    [Windows.Forms.MessageBox]::Show("City: $city`r`nTemperature: $temp°C`r`nHumidity: $humidity%`r`nCondition: $description")
})

# Show the form
$form.ShowDialog()
