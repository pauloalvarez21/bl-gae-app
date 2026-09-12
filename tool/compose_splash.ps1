Add-Type -AssemblyName System.Drawing

# Compose assets/splash_full.png (1024x1024): logo + institutional credit
# with content filling most of the canvas. flutter_native_splash downscales
# this to mdpi=256 (a 600px-wide mdpi tablet draws it 1:1), so relative
# sizes are what matter: logo ~55% of width, text >=44px on canvas.

$logoPath = "assets\splash.png"
$outPath = "assets\splash_full.png"

$canvas = New-Object System.Drawing.Bitmap(1024, 1024)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

$g.Clear([System.Drawing.Color]::White)

# Logo: 560px (55% of canvas), centered
$logo = [System.Drawing.Image]::FromFile($logoPath)
$logoSize = 560
$logoX = [int]((1024 - $logoSize) / 2)
$logoY = 70
$g.DrawImage($logo, $logoX, $logoY, $logoSize, $logoSize)
$logo.Dispose()

function DrawCentered($text, $y, $sizePx, $bold, $hexColor) {
  $font = New-Object System.Drawing.Font("Arial", $sizePx, $(if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }), [System.Drawing.GraphicsUnit]::Pixel)
  $color = [System.Drawing.ColorTranslator]::FromHtml($hexColor)
  $brush = New-Object System.Drawing.SolidBrush($color)
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Center
  $rect = [System.Drawing.RectangleF]::new([float]30, [float]$y, [float]964, [float]($sizePx * 3))
  $g.DrawString($text, $font, $brush, $rect, $fmt)
  $brush.Dispose(); $font.Dispose(); $fmt.Dispose()
}

DrawCentered "© 2026 Gaelectronica." 680 60 $true "#0D1430"
DrawCentered "Todos los derechos reservados." 756 48 $false "#0D1430"
DrawCentered "Desarrollada por el Gaelectronica." 830 44 $false "#5A648C"
DrawCentered "v1.0.0" 908 48 $true "#4F7CFF"

$g.Dispose()
$canvas.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()
Write-Output "OK -> $outPath"
