param([string]$GameDir = 'G:\SteamLibrary\steamapps\common\Megabonk')
$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'build.ps1') -GameDir $GameDir
foreach ($gameProcess in @(Get-Process Megabonk -ErrorAction SilentlyContinue)) {
    # Test helper only: close the development game process before replacing its DLL.
    Stop-Process -Id $gameProcess.Id
    if (-not $gameProcess.WaitForExit(10000)) { throw 'Megabonk did not exit.' }
}
$source = Join-Path $modRoot 'artifacts\bootstrap\BepInEx\plugins\Wildforge'
$destination = Join-Path $GameDir 'BepInEx\plugins\Wildforge'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Get-ChildItem -LiteralPath $source | Copy-Item -Destination $destination -Recurse -Force
Start-Process -FilePath (Join-Path $GameDir 'Megabonk.exe') -WorkingDirectory $GameDir -WindowStyle Normal
