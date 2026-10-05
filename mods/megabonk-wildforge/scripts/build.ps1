param([string]$GameDir = $env:MEGABONK_DIR)
$ErrorActionPreference = 'Stop'
if (-not $GameDir) { $GameDir = 'G:\SteamLibrary\steamapps\common\Megabonk' }
$modRoot = Split-Path -Parent $PSScriptRoot
$sdkCommand = Get-Command dotnet -ErrorAction SilentlyContinue
$sdkPath = if ($sdkCommand) { $sdkCommand.Source } else { Join-Path $modRoot '..\..\tools\megabonk-mod\dotnet\dotnet.exe' }
if (-not (Test-Path -LiteralPath $sdkPath)) {
    throw 'A .NET SDK is required. See PLAN.md stage 1.'
}
foreach ($name in @('BepInEx.Core.dll', 'BepInEx.Unity.IL2CPP.dll')) {
    if (-not (Test-Path -LiteralPath (Join-Path $GameDir "BepInEx\core\$name"))) {
        throw "Missing loader assembly: $name. See PLAN.md stage 1."
    }
}
$env:DOTNET_CLI_HOME = Join-Path $modRoot 'artifacts\dotnet-home'
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
& $sdkPath build (Join-Path $modRoot 'src\Wildforge.Megabonk.csproj') -c Release "-p:GameDir=$GameDir"
if ($LASTEXITCODE -ne 0) { throw 'Build failed; no plugin staged.' }
$stage = Join-Path $modRoot 'artifacts\bootstrap\BepInEx\plugins\Wildforge'
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $modRoot 'src\bin\Release\net6.0\Wildforge.Megabonk.dll') -Destination $stage -Force
$assets = Join-Path $stage 'assets'
New-Item -ItemType Directory -Path $assets -Force | Out-Null
$repoRoot = (Resolve-Path (Join-Path $modRoot '..\..')).Path
& node (Join-Path $PSScriptRoot 'export-catalog.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Catalog export failed.' }
& node (Join-Path $PSScriptRoot 'audit-skills.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Skill coverage audit failed.' }
Copy-Item -LiteralPath (Join-Path $modRoot 'content\wildforge-catalog.json') -Destination $assets -Force
Get-ChildItem -LiteralPath (Join-Path $repoRoot 'native\assets\style3d') -Filter '*.glb' | Copy-Item -Destination $assets -Force
Get-ChildItem -LiteralPath (Join-Path $repoRoot 'native\assets\illustrated') -Recurse -File -Filter '*.png' | ForEach-Object {
    $relative = $_.FullName.Substring((Join-Path $repoRoot 'native\assets').Length + 1)
    $target = Join-Path $assets $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
}
foreach ($asset in @('native\assets\style3d\count_duck.glb','native\assets\illustrated\heroes\rubber_duck_toy.png','native\assets\illustrated\paper.png')) {
    Copy-Item -LiteralPath (Join-Path $repoRoot $asset) -Destination $assets -Force
}
Write-Output "Wildforge plugin and runtime assets staged at $stage."
