$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskGodot = Join-Path $taskRoot 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$taskBuild = Join-Path $taskRoot 'build'
$taskActive = Get-CimInstance Win32_Process | Where-Object { $_.ExecutablePath -and $_.ExecutablePath.StartsWith($taskBuild + '\', [StringComparison]::OrdinalIgnoreCase) }
if ($taskActive) { throw 'Close Wildforge before rebuilding its single build folder.' }
New-Item -ItemType Directory -Path $taskBuild -Force | Out-Null
Push-Location $taskRoot
try {
  node scripts/export-native-data.mjs
  if ($LASTEXITCODE -ne 0) { throw 'Catalog export failed.' }
  node scripts/create-content-art.mjs
  if ($LASTEXITCODE -ne 0) { throw 'Content art export failed.' }
  & $taskGodot --headless --path native --editor --import
  & $taskGodot --headless --path native --script scripts/bake_content_icons.gd
  if ($LASTEXITCODE -ne 0) { throw 'Painted icon bake failed.' }
  & $taskGodot --headless --path native --editor --import
  foreach ($taskScript in @('res://scripts/game.gd','res://scripts/style_lab.gd')) {
    $taskPreflight = & $taskGodot --headless --path native --check-only --script $taskScript 2>&1
    if ($LASTEXITCODE -ne 0 -or ($taskPreflight -join "`n") -match 'SCRIPT ERROR|Parse Error|Compile Error') { throw ('Native script preflight failed: ' + ($taskPreflight -join "`n")) }
  }
  $taskBake = & $taskGodot --headless --path native --script scripts/bake_models.gd 2>&1
  if ($LASTEXITCODE -ne 0 -or ($taskBake -join "`n") -match 'SCRIPT ERROR|Parse Error|Compile Error') { throw ('Mesh bake failed: ' + ($taskBake -join "`n")) }
  & $taskGodot --headless --path native --export-release 'Windows Native' (Join-Path $taskBuild 'Wildforge.exe')
  if ($LASTEXITCODE -ne 0) { throw 'Native export failed.' }
  Copy-Item -LiteralPath (Join-Path $taskRoot 'native/assets/voices/voice-provenance.json') -Destination (Join-Path $taskBuild 'voice-provenance.json')
  Copy-Item -LiteralPath (Join-Path $taskRoot 'native/assets/voices/hero-voice-provenance.json') -Destination (Join-Path $taskBuild 'hero-voice-provenance.json')
  Copy-Item -LiteralPath (Join-Path $taskRoot 'native/assets/voices/Pocket-TTS-license.txt') -Destination (Join-Path $taskBuild 'Pocket-TTS-license.txt')
  Copy-Item -LiteralPath (Join-Path $taskRoot 'native/assets/voices/Pocket-TTS-voice-credits.txt') -Destination (Join-Path $taskBuild 'Pocket-TTS-voice-credits.txt')
  Copy-Item -LiteralPath (Join-Path $taskRoot 'native/assets/voices/MODEL-LICENSE.txt') -Destination (Join-Path $taskBuild 'Kokoro-model-license.txt')
  Copy-Item -LiteralPath (Join-Path $taskRoot 'native/GODOT-LICENSE.txt') -Destination (Join-Path $taskBuild 'Godot-license.txt')
  Write-Output $taskBuild
} finally { Pop-Location }
