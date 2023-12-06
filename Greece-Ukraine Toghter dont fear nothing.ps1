Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Flags Display" Height="300" Width="400">
    <Grid>
        <Image HorizontalAlignment="Left" VerticalAlignment="Top" Width="200" Height="150" Margin="10">
            <Image.Source>
                <BitmapImage UriSource="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAACXBIWXMAAB7CAAAewgFu0HU+AAEAAElEQVR4nOzdeXQTZfv/8WcNpEFCEihWYVUUFEii0iJEBEFEVEUUEUERFRQhRFRFERURRQREFRFVEIURRFRFEVEUUREURUUiRFRRFRFRFFUiIVEVUIiJRFRRFRFFUiIgVEVSIiJRFRRFEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVUQiIVEVEVEUiIgVEVUiJRFRRFEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiJRFRRFEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiJRFRRFEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiJRFRRFEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiIiIVEVUiIVEVEVEUUiI