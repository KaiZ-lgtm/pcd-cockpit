# Percentage of lit pixels inside the round display in a simulator capture.
#   .\tools\litpct.ps1 -In shot.png -Cx 370 -Cy 500 -R 225
param([string]$In, [int]$Cx, [int]$Cy, [int]$R, [int]$Threshold = 8)
Add-Type -AssemblyName System.Drawing
$b = New-Object System.Drawing.Bitmap (Resolve-Path $In).Path
$lit = 0; $tot = 0
for ($y = $Cy - $R; $y -le $Cy + $R; $y++) {
    for ($x = $Cx - $R; $x -le $Cx + $R; $x++) {
        if ((($x - $Cx) * ($x - $Cx) + ($y - $Cy) * ($y - $Cy)) -gt $R * $R) { continue }
        $tot++
        $c = $b.GetPixel($x, $y)
        if ([Math]::Max($c.R, [Math]::Max($c.G, $c.B)) -gt $Threshold) { $lit++ }
    }
}
$b.Dispose()
"{0:N2}% lit ({1} of {2})" -f (100.0 * $lit / $tot), $lit, $tot
