# Pixel regression test: builds the demo build with fixed data, a fixed time and date, captures the face
# in the simulator (active and always-on) for each device and data variant, and compares every capture with
# the reference images in tests\golden\ pixel by pixel.
#   .\tools\regress.ps1             compare; differing captures and diff images go to tests\out\
#   .\tools\regress.ps1 -Baseline   (re)write tests\golden\ from the current code
#   .\tools\regress.ps1 -Show 6,10,15,19,20[,18] [-Bars] [-Wide] [-Font 0|1|2]
#                                   showcase, no comparison: these Field ids in data windows 1-3, date block,
#                                   bottom row[, gauge] (resources\settings\properties.xml of the copy); -Wide uses the
#                                   widest values; captures go to tests\out\show-*.png
# The sources are patched in a copy (tests\work\), never in place. Takes over the simulator; about 4 minutes.
param([switch]$Baseline, [string[]]$Device = @('fenix847mm', 'venu3s'), [string]$Show, [switch]$Bars, [switch]$Wide, [int]$Font = 1)
# -Show as one comma-separated string, so it also survives `powershell -File` (which cannot pass arrays).
$ShowIds = @(); if ($Show) { $ShowIds = @($Show -split '[,\s]+' | Where-Object { $_ } | ForEach-Object { [int]$_ }) }
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot
Set-Location $root
$sdk = (Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
$work = "$root\tests\work"
$outDir = if ($Baseline) { "$root\tests\golden" } else { "$root\tests\out" }
$enc = New-Object Text.UTF8Encoding $false
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class ImgDiff {
  static int[] Px(Bitmap b) {
    var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    var a = new int[b.Width * b.Height]; Marshal.Copy(d.Scan0, a, 0, a.Length); b.UnlockBits(d); return a;
  }
  // Number of differing pixels; writes a diff image (red = differs, dimmed reference elsewhere).
  public static int Diff(string refPath, string newPath, string diffPath) {
    using (var r = new Bitmap(refPath)) using (var n = new Bitmap(newPath)) {
      if (r.Width != n.Width || r.Height != n.Height) return -1;
      int[] pa = Px(r), pb = Px(n); int count = 0;
      var o = new int[pa.Length];
      for (int i = 0; i < pa.Length; i++) {
        if ((pa[i] & 0xFFFFFF) != (pb[i] & 0xFFFFFF)) { count++; o[i] = unchecked((int)0xFFFF0000); }
        else { int c = pa[i]; int g = (((c >> 16) & 255) + ((c >> 8) & 255) + (c & 255)) / 9; o[i] = unchecked((int)0xFF000000) | (g << 16) | (g << 8) | g; }
      }
      if (count > 0) {
        using (var bm = new Bitmap(r.Width, r.Height, PixelFormat.Format32bppArgb)) {
          var d = bm.LockBits(new Rectangle(0, 0, bm.Width, bm.Height), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
          Marshal.Copy(o, 0, d.Scan0, o.Length); bm.UnlockBits(d); bm.Save(diffPath, ImageFormat.Png);
        }
      }
      return count;
    }
  }
}
"@

# Display position in the simulator window: centre x, centre y, radius.
$geo = @{ 'fenix847mm' = @(371, 500, 227); 'venu3s' = @(297, 476, 195) }
# Data variants: battery, stress. main = everyday look, bingo = BINGO warning, stress = amber stress
# (gauge on the 454 px layout, STRESS warning on the Venu 3S).
$vars = [ordered]@{ 'main' = @('80.0', '28'); 'bingo' = @('8.0', '28'); 'stress' = @('80.0', '62') }
if ($Show) {
  if ($ShowIds.Count -lt 5 -or $ShowIds.Count -gt 6) { throw "-Show needs 5 or 6 Field ids: data window 1, 2, 3, date block, bottom row[, gauge]" }
  $vars = [ordered]@{ 'show' = @('80.0', '28') }
}

function Must($c, $s) { if (-not $c.Contains($s)) { throw "patch anchor missing: $s" } }

# Fresh copy of the buildable project.
Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $work, $outDir | Out-Null
foreach ($p in 'source', 'resources', 'resources-fenix847mm', 'resources-venu3s') { Copy-Item -Recurse "$root\$p" "$work\$p" }
foreach ($p in 'manifest.xml', 'monkey.jungle', 'demo.jungle', 'build.ps1') { Copy-Item "$root\$p" "$work\$p" }
if (-not $Baseline) { Get-ChildItem $outDir -File | Remove-Item -Force }

# Fixed time and date (10:42, TUE 09/29, lunar 八月十九) in the view.
$view0 = [IO.File]::ReadAllText("$root\source\PcdView.mc")
$lunM = [string][char]0x516B + [char]0x6708; $lunD = [string][char]0x5341 + [char]0x4E5D
foreach ($a in 'var minuteKey = t.hour * 60 + t.min;', 'var wday = DAYS[t.day_of_week - 1];', 'updateLunar(t);') { Must $view0 $a }
$view = $view0.Replace('var minuteKey = t.hour * 60 + t.min;', 'var minuteKey = 0;')
$view = $view.Replace('var wday = DAYS[t.day_of_week - 1];', 'var wday = "TUE";')
$view = $view.Replace('updateLunar(t);', "_lunarMonth = `"$lunM`"; _lunarDay = `"$lunD`";")
$view = [regex]::Replace($view, 'var timeStr = [^;]+;', 'var timeStr = "1042";')
$view = [regex]::Replace($view, 'var mmdd = [^;]+;', 'var mmdd = "09/29";')
[IO.File]::WriteAllText("$work\source\PcdView.mc", $view, $enc)
$data0 = [IO.File]::ReadAllText("$root\source\Data.mc")
$anchor = '        System.println("demo "'; Must $data0 $anchor
if ($Show) {
  $keys = 'field1', 'field2', 'field3', 'dateField', 'bottomField', 'gaugeField'
  $props = [IO.File]::ReadAllText("$root\resources\settings\properties.xml")
  for ($i = 0; $i -lt $ShowIds.Count; $i++) { $props = [regex]::Replace($props, "(id=`"$($keys[$i])`" type=`"number`">)-?\d+", "`${1}$($ShowIds[$i])") }
  $props = [regex]::Replace($props, "(id=`"fontStyle`" type=`"number`">)\d", "`${1}$Font")
  $props = $props.Replace('id="showBars" type="boolean">false', "id=`"showBars`" type=`"boolean`">$(if ($Bars) { 'true' } else { 'false' })")
  [IO.File]::WriteAllText("$work\resources\settings\properties.xml", $props, $enc)
}

$results = @()
try {
  foreach ($v in $vars.Keys) {
    $bat = $vars[$v][0]; $str = $vars[$v][1]
    # Fixed data, applied after the demo cycle in every update.
    $fix = "        wxOk = true; wxStale = false; wxCond = 14; wxCover = Wx.cover(14, 70, 5000);`n" +
           "        wxTemp = 18.0; wxDew = 12.0; wxPressure = 101300.0; wxWindDir = 45; wxWindKt = 15.0;`n" +
           "        hr = 128; altitude = 1250.0; bodyBattery = 74; spo2 = 97; actMin = 95; actGoal = 150;`n" +
           "        battery = $bat; stress = $str; sunIsSet = true; sunTime = `"1856`";`n" +
           $(if ($Wide) {
           "        steps = 23456; stepGoal = 10000; floors = 128; floorsGoal = 10; floorsDn = 99; kcal = 3456;`n" +
           "        distM = 123400.0; actDay = 240; climbM = 2345.0; vo2Run = 65; vo2Bike = 52; runWkM = 112300.0;`n" +
           "        bikeWkM = 312000.0; rhr = 104; sleepScore = 100; visM = 50000.0; pop = 100; utcTime = `"2359`";`n"
           } else {
           "        steps = 8642; stepGoal = 10000; floors = 7; floorsGoal = 10; floorsDn = 5; kcal = 1840;`n" +
           "        distM = 8420.0; actDay = 35; climbM = 312.0; vo2Run = 48; vo2Bike = null; runWkM = 23400.0;`n" +
           "        bikeWkM = 0.0; rhr = 48; sleepScore = 82; visM = 4800.0; pop = 40; utcTime = `"0242`";`n"
           })
    [IO.File]::WriteAllText("$work\source\Data.mc", $data0.Replace($anchor, $fix + $anchor), $enc)
    foreach ($dev in $Device) {
      $o = powershell -NoProfile -File "$work\build.ps1" -Demo -Device $dev -Key "$root\developer_key" | Out-String
      if ($o -notmatch 'BUILD SUCCESSFUL') { Write-Host "BUILD FAILED $dev $v"; $o; $results += "$dev-${v}: build failed"; continue }
      Get-Process simulator -ErrorAction SilentlyContinue | Stop-Process -Force
      Get-Job | Stop-Job -ErrorAction SilentlyContinue; Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
      # The simulator keeps an app's settings between runs (.SET); start from the build's properties.xml.
      Remove-Item "$env:TEMP\com.garmin.connectiq\GARMIN\APPS\SETTINGS\PCDCOCKPIT-*.SET" -Force -ErrorAction SilentlyContinue
      Start-Sleep 2; Start-Process "$sdk\bin\simulator.exe"; Start-Sleep 6
      $prg = "$work\bin\PcdCockpit-$dev.prg"
      Start-Job -ScriptBlock { param($b, $p, $d) & "$b\monkeydo.bat" $p $d } -ArgumentList "$sdk\bin", $prg, $dev | Out-Null
      Start-Sleep 16
      $a = $geo[$dev]; $got = @{}
      for ($i = 0; $i -lt 24 -and $got.Count -lt 2; $i++) {
        $f = "$work\raw.png"; & "$root\tools\capture.ps1" -Out $f | Out-Null
        $b = [System.Drawing.Bitmap]::FromFile($f); $lit = 0
        for ($x = $a[0] - 120; $x -lt $a[0] + 120; $x += 2) { $px = $b.GetPixel($x, $a[1] + [int]($a[2] * 0.55)); if ($px.R -gt 60 -or $px.G -gt 60) { $lit++ } }
        $b.Dispose()
        $kind = if ($lit -gt 5) { 'act' } else { 'aod' }
        if (-not $got.ContainsKey($kind)) {
          & "$root\tools\crop.ps1" -In $f -Out "$outDir\$dev-$v-$kind.png" -X ($a[0] - $a[2]) -Y ($a[1] - $a[2]) -W (2 * $a[2]) -H (2 * $a[2]) -Scale 1
          $got[$kind] = 1
        }
        Start-Sleep 2
      }
      foreach ($k in 'act', 'aod') { if (-not $got.ContainsKey($k)) { $results += "$dev-$v-${k}: NOT CAPTURED" } }
    }
  }
} finally {
  Get-Process simulator -ErrorAction SilentlyContinue | Stop-Process -Force
  Get-Job | Stop-Job -ErrorAction SilentlyContinue; Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
}

if ($Show) {
  $results
  Get-ChildItem "$outDir\*-show-*.png" | ForEach-Object { "showcase  tests\out\$($_.Name)" }
  return
}
if ($Baseline) {
  $results
  Get-ChildItem "$outDir\*.png" | ForEach-Object { "baseline  $($_.Name)" }
  return
}
$fail = $results.Count
foreach ($g in Get-ChildItem "$root\tests\golden\*.png") {
  $new = "$outDir\$($g.Name)"
  if (-not (Test-Path $new)) { "MISSING   $($g.Name)"; $fail++; continue }
  $n = [ImgDiff]::Diff($g.FullName, $new, ($new -replace '\.png$', '.diff.png'))
  if ($n -eq 0) { "same      $($g.Name)"; Remove-Item $new }
  else { "DIFFERS   $($g.Name): $n px (see tests\out\)"; $fail++ }
}
$results
if ($fail -eq 0) { "REGRESSION PASSED" } else { "REGRESSION FAILED ($fail)" }
