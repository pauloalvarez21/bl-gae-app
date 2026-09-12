Add-Type -AssemblyName System.Drawing

# flutter_native_splash escala la fuente/4 para mdpi. En tablets mdpi de
# 600px (densidad 1.0) esa imagen se dibuja 1:1 y queda diminuta.
# Sobreescribimos mdpi y hdpi con versiones ampliadas (bicúbico):
#   mdpi: 256 -> 512   (Android la pinta a 256dp = 512px en esta tablet)
#   hdpi: 384 -> 640

function Upscale($src, $dst, $target) {
  $img = [System.Drawing.Image]::FromFile($src)
  $bmp = New-Object System.Drawing.Bitmap($target, $target)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.DrawImage($img, 0, 0, $target, $target)
  $g.Dispose()
  $img.Dispose()  # libera el lock del archivo ANTES de guardar sobre él
  $bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Output ("{0} -> {1}x{1}" -f $dst, $target)
}

Upscale "android\app\src\main\res\drawable-mdpi\splash.png" "android\app\src\main\res\drawable-mdpi\splash.png" 512
Upscale "android\app\src\main\res\drawable-hdpi\splash.png" "android\app\src\main\res\drawable-hdpi\splash.png" 640
