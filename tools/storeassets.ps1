# Store assets (STORE.md): demo build with fixed, realistic data and a fixed time, simulator captures of the
# display (store\raw\<dev>-<variant>-act/aod.png), then the masked screenshots, icons and hero in store\.
# Restores the sources and rebuilds the release .prg files. Run from anywhere: .\tools\storeassets.ps1
$ErrorActionPreference = 'Continue'
Set-Location (Split-Path $PSScriptRoot)
$sdk = (Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
$S = "$(Split-Path $PSScriptRoot)\store\raw"
Add-Type -AssemblyName System.Drawing
$enc = New-Object Text.UTF8Encoding $false
$files = @{ data = (Resolve-Path source\Data.mc).Path; view = (Resolve-Path source\PcdView.mc).Path }
$orig = @{}; foreach ($k in $files.Keys) { $orig[$k] = [IO.File]::ReadAllText($files[$k]) }
$vars = [ordered]@{ 'main' = '80.0'; 'bingo' = '8.0' }
$geo = @{ 'fenix847mm' = @(371, 500, 227); 'venu3s' = @(297, 476, 195) }
New-Item -ItemType Directory -Force $S | Out-Null
function Must($c, $s) { if (-not $c.Contains($s)) { throw "patch anchor missing: $s" } }
try {
  foreach ($v in $vars.Keys) {
    $d = $orig.data; $anchor = '        System.println("demo "'; Must $d $anchor
    $fix = "        wxOk = true; wxStale = false; wxCond = 14; wxCover = Wx.cover(14, 70, 5000);`n" +
           "        wxTemp = 18.0; wxDew = 12.0; wxPressure = 101300.0; wxWindDir = 45; wxWindKt = 15.0;`n" +
           "        hr = 128; altitude = 1250.0; bodyBattery = 74; spo2 = 97; actMin = 95; actGoal = 150;`n" +
           "        battery = $($vars[$v]); stress = 28; sunIsSet = true; sunTime = `"1856`";`n"
    $d = $d.Replace($anchor, $fix + $anchor)
    $w = $orig.view; Must $w 'var minuteKey = t.hour * 60 + t.min;'
    $w = $w.Replace('var minuteKey = t.hour * 60 + t.min;', 'var minuteKey = 0;')
    $w = [regex]::Replace($w, 'var timeStr = [^;]+;', 'var timeStr = "1042";')
    [IO.File]::WriteAllText($files.data, $d, $enc); [IO.File]::WriteAllText($files.view, $w, $enc)
    foreach ($dev in $geo.Keys) {
      $o = powershell -NoProfile -File .\build.ps1 -Demo -Device $dev | Out-String
      if ($o -notmatch 'BUILD SUCCESSFUL') { "build failed $dev $v"; $o; continue }
      Get-Process simulator -ErrorAction SilentlyContinue | Stop-Process -Force
      Get-Job | Stop-Job -ErrorAction SilentlyContinue; Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
      Start-Sleep 2; Start-Process "$sdk\bin\simulator.exe"; Start-Sleep 6
      $prg = (Resolve-Path "bin\PcdCockpit-$dev.prg").Path
      Start-Job -ScriptBlock { param($b, $p, $d) & "$b\monkeydo.bat" $p $d } -ArgumentList "$sdk\bin", $prg, $dev | Out-Null
      Start-Sleep 16
      $a = $geo[$dev]; $got = @{}
      for ($i = 0; $i -lt 24 -and $got.Count -lt 2; $i++) {
        $f = "$S\raw.png"; .\tools\capture.ps1 -Out $f | Out-Null
        $b = [System.Drawing.Bitmap]::FromFile($f); $lit = 0
        for ($x = $a[0] - 120; $x -lt $a[0] + 120; $x += 2) { $px = $b.GetPixel($x, $a[1] + [int]($a[2] * 0.55)); if ($px.R -gt 60 -or $px.G -gt 60) { $lit++ } }
        $b.Dispose()
        $kind = if ($lit -gt 5) { 'act' } else { 'aod' }
        if (-not $got.ContainsKey($kind)) {
          & .\tools\crop.ps1 -In $f -Out "$S\$dev-$v-$kind.png" -X ($a[0] - $a[2]) -Y ($a[1] - $a[2]) -W (2 * $a[2]) -H (2 * $a[2]) -Scale 1
          $got[$kind] = 1
        }
        Start-Sleep 2
      }
    }
  }
} finally {
  foreach ($k in $files.Keys) { [IO.File]::WriteAllText($files[$k], $orig[$k], $enc) }
  Get-Process simulator -ErrorAction SilentlyContinue | Stop-Process -Force
  Get-Job | Stop-Job -ErrorAction SilentlyContinue; Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
}
powershell -NoProfile -File .\build.ps1 | Out-Null

# ---- Compose the store images from the captures ----
$outDir = "$(Split-Path $PSScriptRoot)\store"
New-Item -ItemType Directory -Force $outDir | Out-Null

# Draw the round display of a crop (diameter = crop width) centred at (cx, cy), anti-aliased edge.
function DrawFace($g, $file, $cx, $cy, $scale = 1.0) {
    $im = [System.Drawing.Image]::FromFile("$S\$file.png")
    $d = $im.Width * $scale
    $br = New-Object System.Drawing.TextureBrush($im)
    $br.TranslateTransform($cx - $d / 2, $cy - $d / 2)
    $br.ScaleTransform($scale, $scale)
    $g.FillEllipse($br, [single]($cx - $d / 2), [single]($cy - $d / 2), [single]$d, [single]$d)
    $br.Dispose(); $im.Dispose()
}
function NewCanvas($w, $h, $color) {
    $bm = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bm)
    $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
    $g.Clear($color)
    return @($bm, $g)
}
function Save($c, $name) { $c[1].Dispose(); $c[0].Save("$outDir\$name", [System.Drawing.Imaging.ImageFormat]::Png); $c[0].Dispose() }

$black = [System.Drawing.Color]::Black
$bg = [System.Drawing.ColorTranslator]::FromHtml('#1C3350')   # store icon / hero background: dark navy, not black

# Screenshots, 500 x 500, face at native size on black.
$shots = [ordered]@{ 'screenshot-1-fenix8.png' = 'fenix847mm-main-act'; 'screenshot-2-always-on.png' = 'fenix847mm-main-aod';
                     'screenshot-3-bingo.png' = 'fenix847mm-bingo-act'; 'screenshot-4-venu3s.png' = 'venu3s-main-act' }
foreach ($k in $shots.Keys) { $c = NewCanvas 500 500 $black; DrawFace $c[1] $shots[$k] 250 250; Save $c $k }

# Store icon, 500 x 500: the face (454 px, >= 10 px padding) on a solid colour.
$c = NewCanvas 500 500 $bg; DrawFace $c[1] 'fenix847mm-main-act' 250 250; Save $c 'icon-500.png'

# On-device store icon, 128 x 128 (AMOLED).
$c = NewCanvas 128 128 $bg; DrawFace $c[1] 'fenix847mm-main-act' 64 64 (118.0 / 454); Save $c 'icon-128.png'

# Hero, 1440 x 720: fenix active, fenix always-on, Venu 3S active.
$c = NewCanvas 1440 720 $bg
$gap = (1440 - 454 - 454 - 390) / 4
$x1 = $gap + 227; $x2 = $x1 + 227 + $gap + 227; $x3 = $x2 + 227 + $gap + 195
DrawFace $c[1] 'fenix847mm-main-act' $x1 360
DrawFace $c[1] 'fenix847mm-main-aod' $x2 360
DrawFace $c[1] 'venu3s-main-act' $x3 360
Save $c 'hero.png'

Get-ChildItem $outDir -File | ForEach-Object { $im = [System.Drawing.Image]::FromFile($_.FullName); "{0,-28} {1}x{2} {3,7:N0} bytes" -f $_.Name, $im.Width, $im.Height, $_.Length; $im.Dispose() }
