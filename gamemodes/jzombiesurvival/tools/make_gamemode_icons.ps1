# make_gamemode_icons.ps1 - Icone della gamemode per il menu di GMod
#  logo.png    (288x128) -> banner nel menu di selezione gamemode
#  icon24.png  (24x24)   -> iconcina accanto al nome (lista gamemode)
# Output: gamemodes/jzombiesurvival/
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$outDir = Split-Path -Parent $PSScriptRoot   # .../gamemodes/jzombiesurvival/

$GREEN  = [System.Drawing.Color]::FromArgb(255, 110, 205, 120)
$LGREEN = [System.Drawing.Color]::FromArgb(255, 170, 235, 175)
$DARK   = [System.Drawing.Color]::FromArgb(255, 15, 18, 16)
$BLACK  = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
$BONE   = [System.Drawing.Color]::FromArgb(255, 225, 228, 235)

function Draw-EllipseF([System.Drawing.Graphics]$g, [float]$x, [float]$y, [float]$w, [float]$h, $fill, $pen) {
    if ($fill -ne $null) {
        $b = New-Object System.Drawing.SolidBrush($fill)
        $g.FillEllipse($b, $x, $y, $w, $h); $b.Dispose()
    }
    if ($pen -ne $null) { $g.DrawEllipse($pen, $x, $y, $w, $h) }
}
function Draw-PolyF([System.Drawing.Graphics]$g, $pts, $fill, $pen) {
    $arr = [System.Drawing.PointF[]]::new($pts.Count)
    for ($i = 0; $i -lt $pts.Count; $i++) {
        $arr[$i] = New-Object System.Drawing.PointF([float]$pts[$i][0], [float]$pts[$i][1])
    }
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddPolygon($arr)
    if ($fill -ne $null) {
        $b = New-Object System.Drawing.SolidBrush($fill)
        $g.FillPath($b, $path); $b.Dispose()
    }
    if ($pen -ne $null) { $g.DrawPath($pen, $path) }
    $path.Dispose()
}
function Draw-RectF([System.Drawing.Graphics]$g, [float]$x, [float]$y, [float]$w, [float]$h, $fill) {
    $b = New-Object System.Drawing.SolidBrush($fill)
    $g.FillRectangle($b, $x, $y, $w, $h); $b.Dispose()
}

# Disegna un teschio in un'area quadrata (cx,cy,raggio)
function Draw-Skull([System.Drawing.Graphics]$g, [float]$cx, [float]$cy, [float]$r, $bone, $dark, $penW) {
    $pen = $null
    if ($penW -gt 0) { $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 40, 70, 45), $penW) }
    # cranio
    Draw-EllipseF $g ($cx - $r) ($cy - $r * 1.05) ($r * 2) ($r * 2.1) $bone $pen
    # mascella
    Draw-PolyF $g @(,@($cx - $r*0.62) + @($cy + $r*0.45),
                     @($cx + $r*0.62) + @($cy + $r*0.45),
                     @($cx + $r*0.55) + @($cy + $r*1.02),
                     @($cx - $r*0.55) + @($cy + $r*1.02)) $bone $pen
    # occhi
    Draw-EllipseF $g ($cx - $r*0.62) ($cy - $r*0.38) ($r*0.5) ($r*0.58) $dark $null
    Draw-EllipseF $g ($cx + $r*0.12) ($cy - $r*0.38) ($r*0.5) ($r*0.58) $dark $null
    # naso
    Draw-PolyF $g @(,@($cx - $r*0.10) + @($cy + $r*0.02),
                     @($cx + $r*0.10) + @($cy + $r*0.02),
                     @($cx)            + @($cy + $r*0.26)) $dark $null
    # denti
    $dy = $cy + $r * 0.62
    $dh = $r * 0.32
    Draw-RectF $g ($cx - $r*0.30) $dy ($r*0.11) $dh $dark
    Draw-RectF $g ($cx - $r*0.055) $dy ($r*0.11) $dh $dark
    Draw-RectF $g ($cx + $r*0.19) $dy ($r*0.11) $dh $dark
    if ($pen -ne $null) { $pen.Dispose() }
}

# ============================================================================
# LOGO 288x128
# ============================================================================
$bmp = New-Object System.Drawing.Bitmap(288, 128, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

# sfondo gradiente scuro
$rect = New-Object System.Drawing.Rectangle(0, 0, 288, 128)
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.Color]::FromArgb(255, 16, 22, 18),
    [System.Drawing.Color]::FromArgb(255, 34, 52, 38),
    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$g.FillRectangle($brush, $rect)
$brush.Dispose()
# bordo verde
$bpen = New-Object System.Drawing.Pen($GREEN, 3)
$g.DrawRectangle($bpen, 1, 1, 285, 125)
$bpen.Dispose()

# teschio a sinistra
Draw-Skull $g 62 62 34 $BONE $DARK 2

# testo
$fontBig = New-Object System.Drawing.Font("Impact", 30, [System.Drawing.FontStyle]::Regular)
$fontSm  = New-Object System.Drawing.Font("Impact", 17, [System.Drawing.FontStyle]::Regular)
$fmt = New-Object System.Drawing.StringFormat
$fmt.Alignment = [System.Drawing.StringAlignment]::Near
$tb = New-Object System.Drawing.SolidBrush($LGREEN)
$wb = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 230, 235, 232))
$g.DrawString('JZOMBIE', $fontBig, $wb, 110, 24, $fmt)
$g.DrawString('SURVIVAL', $fontSm, $tb, 112, 66, $fmt)
$tb.Dispose(); $wb.Dispose(); $fontBig.Dispose(); $fontSm.Dispose()

# righe decorative (barre)
Draw-RectF $g 112 96 150 3 ([System.Drawing.Color]::FromArgb(160, 110, 205, 120))
Draw-RectF $g 112 102 110 3 ([System.Drawing.Color]::FromArgb(90, 110, 205, 120))

$g.Dispose()
$bmp.Save((Join-Path $outDir 'logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host 'OK logo.png (288x128)'

# ============================================================================
# ICON24 24x24 (teschio secco su sfondo trasparente)
# ============================================================================
$bmp = New-Object System.Drawing.Bitmap(24, 24, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
Draw-Skull $g 12 10.5 8 $GREEN $DARK 0
$g.Dispose()
$bmp.Save((Join-Path $outDir 'icon24.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host 'OK icon24.png (24x24)'

Write-Host "Output: $outDir"
