param([string]$GameDir = 'G:\SteamLibrary\steamapps\common\Megabonk', [switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot
if (-not $SkipBuild) { & (Join-Path $PSScriptRoot 'build.ps1') -GameDir $GameDir }
$package = Join-Path $modRoot 'artifacts\package'
$plugins = Join-Path $package 'BepInEx\plugins\Wildforge'
New-Item -ItemType Directory -Path $plugins -Force | Out-Null
Get-ChildItem -LiteralPath (Join-Path $modRoot 'artifacts\bootstrap\BepInEx\plugins\Wildforge') | Copy-Item -Destination $plugins -Recurse -Force
Copy-Item -LiteralPath (Join-Path $modRoot 'README.md') -Destination $package -Force
Copy-Item -LiteralPath (Join-Path $modRoot 'PLAN.md') -Destination $package -Force
Copy-Item -LiteralPath (Join-Path $modRoot 'VERIFICATION.md') -Destination $package -Force
Copy-Item -LiteralPath (Join-Path $modRoot 'artifacts\skill-coverage.json') -Destination $package -Force
$scripts = Join-Path $package 'scripts'
New-Item -ItemType Directory -Path $scripts -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'install.ps1') -Destination $scripts -Force
$zip = Join-Path $modRoot 'artifacts\Megabonk-Wildforge-Mod-0.3.0-skills-compatible.zip'
Compress-Archive -Path (Join-Path $package '*') -DestinationPath $zip -Force
Get-FileHash -LiteralPath $zip -Algorithm SHA256 | Format-List
