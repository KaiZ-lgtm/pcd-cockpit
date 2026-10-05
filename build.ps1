# Build PCD Cockpit.
#   .\build.ps1                    -> bin\PcdCockpit-fenix847mm.prg + venu3s.prg (the watches it is sideloaded on)
#   .\build.ps1 -Device venu3s     -> one device; -Device all -> every product in manifest.xml
#   .\build.ps1 -Run -Device venu3s -> build and launch in the simulator
#   .\build.ps1 -Export            -> bin\PcdCockpit.iq for the Connect IQ Store (every product in manifest.xml)
param(
    [string[]]$Device = @('fenix847mm', 'venu3s'),
    [string]$Key = "$PSScriptRoot\developer_key",
    [switch]$Run,
    [switch]$Demo,     # cycle synthetic data scenarios (simulator testing only)
    [switch]$Export    # store package, release build (no debug info)
)
$ErrorActionPreference = 'Stop'
$java = 'C:\Program Files\Java\jdk-27\bin'
if (-not (Get-Command java -ErrorAction SilentlyContinue)) { $env:PATH = "$java;$env:PATH" }
$sdk = (Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
$bin = Join-Path $sdk 'bin'
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force bin | Out-Null

if ($Export) {
    if ($Demo) { throw "-Export and -Demo cannot be combined: the store package must not contain demo data" }
    & "$bin\monkeyc.bat" -e -r -f monkey.jungle -o bin\PcdCockpit.iq -y $Key -w
    if ($LASTEXITCODE -ne 0) { throw "monkeyc export failed" }
    return
}

if ($Device -contains 'all') {
    $Device = @(([xml](Get-Content manifest.xml -Raw)).manifest.application.products.product | ForEach-Object { $_.id })
}
foreach ($d in $Device) {
    $out = "bin\PcdCockpit-$d.prg"
    $jungle = if ($Demo) { 'monkey.jungle;demo.jungle' } else { 'monkey.jungle' }
    & "$bin\monkeyc.bat" -f $jungle -d $d -o $out -y $Key -w
    if ($LASTEXITCODE -ne 0) { throw "monkeyc failed for $d" }
}

if ($Run) {
    $d = $Device[0]
    if (-not (Get-Process simulator -ErrorAction SilentlyContinue)) {
        Start-Process "$bin\simulator.exe"
        Start-Sleep -Seconds 4
    }
    & "$bin\monkeydo.bat" "bin\PcdCockpit-$d.prg" $d
}
