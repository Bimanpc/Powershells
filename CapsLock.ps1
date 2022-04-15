param (
	[parameter( Mandatory = $False, ValueFromPipeline = $True )]
	[string] $text
)

if ( $text -eq "/?" ) {
	Clear-Host
	Write-Host "`nCapsLockIcon.ps1,  Version 1.01 for Windows"
	Write-Host "CapsLock key indicator in  System tray`n"
	Write-Host "Usage:`t. 'CapsLockIcoN.ps1' [text]`n"
	Write-Host "Where:`ttext`tis the text on the indicator"
	Write-Host "`t`t(default: `"C`"; maximum length: 2)`n"
	exit
} else {
	# Remove whitespace and special characters
	$text = $text -replace '\W', ''
	# Use no more than 2 characters
	if ( $text.Length -gt 2 )
	{
		$text = $text.Substring( 0, 2 )
	}
}
# Use default in case no valid text was supplied
if ( [string]::IsNullOrWhiteSpace( $text ) ) {
	$text = "C"
}

[void] [System.Reflection.Assembly]::LoadWithPartialName( "System.Drawing" )
[void] [System.Reflection.Assembly]::LoadWithPartialName( "System.Windows.Forms" )

# Create bitmap
$bitmap = [System.Drawing.Bitmap]::new( 16, 16 )
# Define font
$fontfamily = [System.Drawing.FontFamily]::GenericSansSerif
$fontstyle = [System.Drawing.FontStyle]::Bold
$font = [System.Drawing.Font]::new( $fontfamily, 8, $fontstyle )
# Create graphic from bitmap
$graphic = [System.Drawing.Graphics]::FromImage( $bitmap )
# Create a circle in the graphic, fill this circle with color
$blackbrush = [System.Drawing.Brushes]::Black
$redbrush = [System.Drawing.Brushes]::Red
$graphic.FillEllipse( $redbrush, 0, 0, 16, 16 )
# Center text in circle
$textsize = $graphic.MeasureString( $text, $font )
# Resize font if text is too large to fit in icon
if ( $textsize.Width -gt 14 ) {
	$font = [System.Drawing.Font]::new( $fontfamily, $font.Size * 0.8, $fontstyle )
	$textsize = $graphic.MeasureString( $text, $font )
}
$x = [Math]::Max( 0, [Math]::Floor( ( $bitmap.Width - $textsize.Width ) / 2 ) )
$y = [Math]::Max( 0, [Math]::Ceiling( ( $bitmap.Height - $textsize.Height ) / 2 ) )
$stringformat = [System.Drawing.StringFormat]::GenericDefault
$graphic.DrawString( $text, $font, $blackbrush, $x, $y, $stringformat )
# Create icon from graphic
$icon = [System.Drawing.Icon]::FromHandle( $bitmap.GetHicon( ) )
# Cleanup
$graphic.Dispose( )
$bitmap.Dispose( )

# Create new System Tray icon
[void] [System.Reflection.Assembly]::LoadWithPartialName( "System.Windows.Forms" )
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = $icon

# Explain how to break free from the endless loop
Write-Host "`nPress any key to stop monitoring CapsLock . . .  " -NoNewline

# Monitor CapsLock until a key is pressed in this console
while ( !$Host.UI.RawUI.KeyAvailable ) {
	Start-Sleep -Seconds 1
	# Show System Tray icon only if CapsLock is ON
	$notifyIcon.Visible = [System.Windows.Forms.Control]::IsKeyLocked( [System.Windows.Forms.Keys]::CapsLock )
}

# Remove the key from the keyboard buffer . . .
[void] $Host.UI.RawUI.ReadKey( )
# . . .  and wipe it from the screen
Write-Host "`b `n"

# Cleanup
$notifyIcon.Visible = $False
# Only if variable "$icon" is of type "Icon" it should be disposed of
if ( $icon.GetType( ) -eq [System.Drawing.Icon] ) {
	$icon.Dispose( )
}
$notifyIcon.Dispose( )