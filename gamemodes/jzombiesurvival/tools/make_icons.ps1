# make_icons.ps1 - Genera le icone PNG + VMT per JZombie Survival
# Output: gamemodes/jzombiesurvival/materials/zombiesurvival/icons/
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root   = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root 'gamemodes\jzombiesurvival\materials\zombiesurvival\icons'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$SILVER = [System.Drawing.Color]::FromArgb(255, 210, 213, 222)
$EDGE   = [System.Drawing.Color]::FromArgb(255, 108, 112, 126)
$DARK   = [System.Drawing.Color]::FromArgb(255, 20, 22, 26)
$GREEN  = [System.Drawing.Color]::FromArgb(255, 110, 205, 120)

function New-Canvas([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    return @($bmp, $g)
}

function Clear-G([System.Drawing.Graphics]$g, [System.Drawing.Bitmap]$bmp) {
    $g.Clear([System.Drawing.Color]::Transparent)
}

function Draw-Rect([System.Drawing.Graphics]$g, [float]$x, [float]$y, [float]$w, [float]$h, $fill, $pen) {
    $b = New-Object System.Drawing.SolidBrush($fill)
    $g.FillRectangle($b, $x, $y, $w, $h)
    if ($pen -ne $null) { $g.DrawRectangle($pen, $x, $y, $w, $h) }
    $b.Dispose()
}

function Draw-Poly([System.Drawing.Graphics]$g, $pts, $fill, $pen) {
    $arr = [System.Drawing.PointF[]]::new($pts.Count)
    for ($i = 0; $i -lt $pts.Count; $i++) {
        $arr[$i] = New-Object System.Drawing.PointF([float]$pts[$i][0], [float]$pts[$i][1])
    }
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddPolygon($arr)
    $b = New-Object System.Drawing.SolidBrush($fill)
    $g.FillPath($b, $path)
    if ($pen -ne $null) { $g.DrawPath($pen, $path) }
    $b.Dispose(); $path.Dispose()
}

function Draw-Ellipse([System.Drawing.Graphics]$g, [float]$x, [float]$y, [float]$w, [float]$h, $fill, $pen) {
    $b = New-Object System.Drawing.SolidBrush($fill)
    $g.FillEllipse($b, $x, $y, $w, $h)
    if ($pen -ne $null) { $g.DrawEllipse($pen, $x, $y, $w, $h) }
    $b.Dispose()
}

function Save-Icon([string]$name, [System.Drawing.Bitmap]$bmp) {
    $png = Join-Path $outDir ($name + '.png')
    $bmp.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
    $vmt = Join-Path $outDir ($name + '.vmt')
@"
"UnlitGeneric"
{
	"$basetexture"		"zombiesurvival/icons/$name"
	"$translucent"		1
	"$vertexcolor"		1
	"$vertexalpha"		1
	"$nolod"			1
}
"@ | Out-File -FilePath $vmt -Encoding ascii
    Write-Host "OK $name"
}

# ----------------------------------------------------------------------------
function Make-WeaponIcon([string]$name, [scriptblock]$shapes) {
    $c = New-Canvas 128
    $bmp = $c[0]; $g = $c[1]
    Clear-G $g $bmp
    $fill = $SILVER
    $pen = New-Object System.Drawing.Pen($EDGE, 2)
    & $shapes $g $pen ([ref]$fill)
    $pen.Dispose()
    $g.Dispose()
    Save-Icon $name $bmp
    $bmp.Dispose()
}

# ----------------------------------------------------------------------------
# PISTOLA
Make-WeaponIcon 'pistol' {
    param($g, $pen, [ref]$fill)
    Draw-Rect $g 30 40 6 6   $fill.Value $pen   # mirino
    Draw-Rect $g 26 46 64 14 $fill.Value $pen   # carrello
    Draw-Rect $g 90 49 14 8  $fill.Value $pen   # canna
    Draw-Poly $g @(,@(30,60) + @(50,60) + @(46,98) + @(28,98)) $fill.Value $pen  # impugnatura
    Draw-Rect $g 50 60 10 5  $fill.Value $pen   # grilletto
}

# MITRAGLIETTA
Make-WeaponIcon 'smg' {
    param($g, $pen, [ref]$fill)
    Draw-Rect $g 6 52 18 8   $fill.Value $pen   # calcio
    Draw-Rect $g 22 50 66 18 $fill.Value $pen   # corpo
    Draw-Rect $g 88 54 22 8  $fill.Value $pen   # canna
    Draw-Poly $g @(,@(46,68) + @(60,68) + @(63,98) + @(48,100)) $fill.Value $pen # caricatore
    Draw-Poly $g @(,@(24,68) + @(36,68) + @(34,92) + @(24,90)) $fill.Value $pen  # impugnatura
}

# FUCILE A POMPA
Make-WeaponIcon 'shotgun' {
    param($g, $pen, [ref]$fill)
    Draw-Poly $g @(,@(2,50) + @(16,54) + @(16,72) + @(6,76)) $fill.Value $pen    # calcio
    Draw-Rect $g 14 54 96 6    $fill.Value $pen  # canna
    Draw-Rect $g 20 62 86 6    $fill.Value $pen  # serbatoio
    Draw-Rect $g 62 60 20 10   $fill.Value $pen  # pompa
    Draw-Poly $g @(,@(52,68) + @(64,68) + @(62,88) + @(52,86)) $fill.Value $pen  # impugnatura
}

# FUCILE D'ASSALTO
Make-WeaponIcon 'rifle' {
    param($g, $pen, [ref]$fill)
    Draw-Poly $g @(,@(2,54) + @(16,54) + @(16,72) + @(4,70)) $fill.Value $pen    # calcio
    Draw-Rect $g 58 42 10 10   $fill.Value $pen  # mirino
    Draw-Rect $g 16 52 72 14   $fill.Value $pen  # corpo
    Draw-Rect $g 88 56 28 6    $fill.Value $pen  # canna
    Draw-Rect $g 114 54 6 10   $fill.Value $pen  # freno di bocca
    Draw-Poly $g @(,@(54,66) + @(68,66) + @(72,94) + @(58,98)) $fill.Value $pen  # caricatore
    Draw-Poly $g @(,@(36,66) + @(48,66) + @(46,88) + @(36,86)) $fill.Value $pen  # impugnatura
}

# CECCHINO
Make-WeaponIcon 'sniper' {
    param($g, $pen, [ref]$fill)
    Draw-Poly $g @(,@(4,58) + @(40,54) + @(40,68) + @(8,70)) $fill.Value $pen    # calcio
    Draw-Rect $g 40 54 34 12   $fill.Value $pen  # ricevitore
    Draw-Rect $g 48 38 36 10   $fill.Value $pen  # ottica
    Draw-Rect $g 52 34 4 18    $fill.Value $pen  # ghiera 1
    Draw-Rect $g 76 34 4 18    $fill.Value $pen  # ghiera 2
    Draw-Rect $g 8 60 110 5    $fill.Value $pen  # canna lunga
    Draw-Poly $g @(,@(58,66) + @(68,66) + @(68,84) + @(60,84)) $fill.Value $pen  # caricatore
}

# RPG / PESANTE
Make-WeaponIcon 'rpg' {
    param($g, $pen, [ref]$fill)
    Draw-Rect $g 34 44 12 4    $fill.Value $pen  # mirino
    Draw-Rect $g 38 48 4 10    $fill.Value $pen  # supporto
    Draw-Rect $g 8 56 8 16     $fill.Value $pen  # imboccatura
    Draw-Rect $g 16 58 80 12   $fill.Value $pen  # tubo
    Draw-Poly $g @(,@(96,50) + @(118,64) + @(96,78)) $fill.Value $pen             # testata
    Draw-Poly $g @(,@(44,70) + @(56,70) + @(54,92) + @(44,90)) $fill.Value $pen  # impugnatura
}

# BALESTRA
Make-WeaponIcon 'crossbow' {
    param($g, $pen, [ref]$fill)
    Draw-Rect $g 56 20 8 76    $fill.Value $pen  # arco verticale
    Draw-Rect $g 56 52 62 12   $fill.Value $pen  # calcio/orizzonte
    Draw-Rect $g 64 56 46 4    $fill.Value $pen  # dardo
    Draw-Poly $g @(,@(56,64) + @(70,64) + @(68,84) + @(58,82)) $fill.Value $pen  # impugnatura
}

# PIEDE DI PORCO
Make-WeaponIcon 'crowbar' {
    param($g, $pen, [ref]$fill)
    Draw-Poly $g @(,@(20,84) + @(92,40) + @(98,50) + @(26,94)) $fill.Value $pen  # manico
    Draw-Poly $g @(,@(88,34) + @(112,24) + @(116,32) + @(96,46) + @(88,44)) $fill.Value $pen # uncinetto sopra
    Draw-Poly $g @(,@(94,48) + @(110,42) + @(114,50) + @(98,58)) $fill.Value $pen # uncinetto sotto
    Draw-Rect $g 14 80 12 16   $fill.Value $pen  # fine manico
}

# GRANATA
Make-WeaponIcon 'grenade' {
    param($g, $pen, [ref]$fill)
    Draw-Poly $g @(,@(70,40) + @(84,44) + @(82,52) + @(70,48)) $fill.Value $pen  # leva
    Draw-Rect $g 60 44 10 12   $fill.Value $pen  # collo
    Draw-Ellipse $g 46 54 34 42 $fill.Value $pen # corpo
}

# SCATOLA MUNIZIONI
Make-WeaponIcon 'ammo' {
    param($g, $pen, [ref]$fill)
    Draw-Rect $g 34 26 8 22  $fill.Value $pen    # proiettile 1
    Draw-Rect $g 46 26 8 22  $fill.Value $pen    # proiettile 2
    Draw-Rect $g 58 26 8 22  $fill.Value $pen    # proiettile 3
    Draw-Rect $g 22 46 84 10 $fill.Value $pen    # coperchio
    Draw-Rect $g 22 56 84 34 $fill.Value $pen    # scatola
    Draw-Rect $g 44 66 40 8  $DARK $null         # etichetta
}

# TESCHIO (HUD/branding)
Make-WeaponIcon 'skull' {
    param($g, $pen, [ref]$fill)
    Draw-Ellipse $g 34 24 60 56 $fill.Value $pen  # cranio
    Draw-Poly $g @(,@(46,68) + @(82,68) + @(80,96) + @(50,96)) $fill.Value $pen # mascella
    Draw-Ellipse $g 46 42 14 16 $DARK $null       # occhio sx
    Draw-Ellipse $g 68 42 14 16 $DARK $null       # occhio dx
    Draw-Poly $g @(,@(60,58) + @(68,58) + @(64,68)) $DARK $null  # naso
    Draw-Rect $g 54 80 5 12 $DARK $null           # dente 1
    Draw-Rect $g 62 80 5 12 $DARK $null           # dente 2
    Draw-Rect $g 70 80 5 12 $DARK $null           # dente 3
}

# ----------------------------------------------------------------------------
# LOGO 256x256 (teschio verde + anello) per documentazione/branding
$c = New-Canvas 256
$bmp = $c[0]; $g = $c[1]
Clear-G $g $bmp
$penG = New-Object System.Drawing.Pen($GREEN, 6)
$penD = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 30, 60, 35), 3)
$g.DrawEllipse($penG, 8, 8, 240, 240)
Draw-Ellipse $g 68 48 120 112 $GREEN $penD      # cranio
Draw-Poly $g @(,@(92,136) + @(164,136) + @(160,192) + @(96,192)) $GREEN $penD  # mascella
Draw-Ellipse $g 92 84 28 32 $DARK $null         # occhio sx
Draw-Ellipse $g 136 84 28 32 $DARK $null        # occhio dx
Draw-Poly $g @(,@(120,116) + @(136,116) + @(128,132)) $DARK $null  # naso
Draw-Rect $g 108 160 9 24 $DARK $null
Draw-Rect $g 124 160 9 24 $DARK $null
Draw-Rect $g 140 160 9 24 $DARK $null
$penG.Dispose(); $penD.Dispose()
Save-Icon 'logo' $bmp
$g.Dispose(); $bmp.Dispose()

Write-Host "`nIcone generate in: $outDir"
