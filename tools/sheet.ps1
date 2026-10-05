# Capture N simulator frames (every $Every seconds), crop the watch display, tile into a contact sheet.
param([int]$N = 9, [double]$Every = 3, [string]$Out = "sheet.png", [int]$X = 140, [int]$Y = 270, [int]$S = 460, [int]$H = 0, [int]$Cols = 3)
Add-Type -AssemblyName System.Drawing
$tmp = Join-Path $env:TEMP "pcd_frame.png"
$rows = [Math]::Ceiling($N / $Cols); if ($H -le 0) { $H = $S }
$sheet = New-Object System.Drawing.Bitmap ($Cols * $S), ($rows * $H)
$g = [System.Drawing.Graphics]::FromImage($sheet)
for ($i = 0; $i -lt $N; $i++) {
    & (Join-Path $PSScriptRoot capture.ps1) -Out $tmp
    $img = [System.Drawing.Image]::FromFile($tmp)
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle (($i % $Cols) * $S), ([Math]::Floor($i / $Cols) * $H), $S, $H),
        (New-Object System.Drawing.Rectangle $X, $Y, $S, $H), [System.Drawing.GraphicsUnit]::Pixel)
    $img.Dispose()
    if ($i -lt $N - 1) { Start-Sleep -Milliseconds ($Every * 1000) }
}
$g.Dispose(); $sheet.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $sheet.Dispose()

