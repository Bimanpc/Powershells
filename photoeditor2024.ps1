# Ensure you have the required libraries
# You might need to install ImageMagick or a similar library for image processing

# Load the required assembly
Add-Type -AssemblyName System.Drawing

# Function to load an image
function Load-Image {
    param (
        [string]$path
    )
    return [System.Drawing.Image]::FromFile($path)
}

# Function to save an image
function Save-Image {
    param (
        [System.Drawing.Image]$image,
        [string]$path
    )
    $image.Save($path)
}

# Function to apply grayscale filter
function Apply-Grayscale {
    param (
        [System.Drawing.Image]$image
    )
    $bitmap = New-Object System.Drawing.Bitmap $image
    for ($x = 0; $x -lt $bitmap.Width; $x++) {
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            $color = $bitmap.GetPixel($x, $y)
            $gray = [System.Drawing.Color]::FromArgb($color.A, ($color.R + $color.G + $color.B) / 3, ($color.R + $color.G + $color.B) / 3, ($color.R + $color.G + $color.B) / 3)
            $bitmap.SetPixel($x, $y, $gray)
        }
    }
    return $bitmap
}

# Example usage
$imagePath = "path_to_your_image.jpg"
$outputPath = "path_to_save_edited_image.jpg"

$image = Load-Image -path $imagePath
$grayscaleImage = Apply-Grayscale -image $image
Save-Image -image $grayscaleImage -path $outputPath

Write-Output "Image processing complete. Edited image saved to $outputPath"
