param([Parameter(Mandatory=$true)][string]$GameDir)
$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot
if (Get-Process Megabonk -ErrorAction SilentlyContinue) { throw 'Close Megabonk before installing.' }
if (-not (Test-Path -LiteralPath (Join-Path $GameDir 'BepInEx\core\BepInEx.Unity.IL2CPP.dll'))) {
    throw 'Install BepInEx 6 IL2CPP x64 and launch Megabonk once first.'
}
$source = Join-Path $modRoot 'BepInEx\plugins\Wildforge'
if (-not (Test-Path -LiteralPath $source)) { $source = Join-Path $modRoot 'artifacts\bootstrap\BepInEx\plugins\Wildforge' }
if (-not (Test-Path -LiteralPath (Join-Path $source 'Wildforge.Megabonk.dll'))) { throw 'Build or extract the mod package first.' }
$destination = Join-Path $GameDir 'BepInEx\plugins\Wildforge'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Get-ChildItem -LiteralPath $source | Copy-Item -Destination $destination -Recurse -Force
Write-Output "Installed Megabonk Wildforge Mod in $destination"
