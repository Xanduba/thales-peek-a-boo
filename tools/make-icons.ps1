<#
  Generates the app icons in icons/ as a 2x2 collage of the four photos
  (same look as the app itself). Re-run after changing the photos:
      powershell -ExecutionPolicy Bypass -File tools\make-icons.ps1
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$photos = 'mamae', 'papai', 'thales', 'vovo' | ForEach-Object { Join-Path $root "Assets\images\$_.png" }
$outDir = Join-Path $root 'icons'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$background = [System.Drawing.Color]::FromArgb(245, 245, 244)   # Tailwind stone-100 (#f5f5f4)

function New-RoundedRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure()
  return $p
}

# $safeFraction: share of the icon used by the collage (smaller = more padding,
# needed for "maskable" icons that Android crops into circles/squircles).
function New-Icon([int]$size, [string]$fileName, [double]$safeFraction) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.PixelOffsetMode = 'HighQuality'
  $g.Clear($background)

  $area = $size * $safeFraction
  $offset = ($size - $area) / 2
  $gap = $area * 0.05
  $tile = ($area - $gap) / 2
  $radius = $tile * 0.16

  for ($i = 0; $i -lt 4; $i++) {
    $x = $offset + ($i % 2) * ($tile + $gap)
    $y = $offset + [math]::Floor($i / 2) * ($tile + $gap)

    $img = [System.Drawing.Image]::FromFile($photos[$i])
    # "object-cover": crop the photo to a centered square
    $side = [math]::Min($img.Width, $img.Height)
    $src = New-Object System.Drawing.RectangleF (($img.Width - $side) / 2), (($img.Height - $side) / 2), $side, $side
    $dst = New-Object System.Drawing.RectangleF $x, $y, $tile, $tile

    $path = New-RoundedRect $x $y $tile $tile $radius
    $g.SetClip($path)
    $g.DrawImage($img, $dst, $src, [System.Drawing.GraphicsUnit]::Pixel)
    $g.ResetClip()
    $path.Dispose()
    $img.Dispose()
  }

  $bmp.Save((Join-Path $outDir $fileName), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
  Write-Output "icons/$fileName ($size x $size)"
}

New-Icon 192 'icon-192.png'          0.92
New-Icon 512 'icon-512.png'          0.92
New-Icon 512 'icon-maskable-512.png' 0.72   # keeps the photos inside Android's safe zone
New-Icon 180 'apple-touch-icon.png'  0.92   # iOS rounds the corners itself
