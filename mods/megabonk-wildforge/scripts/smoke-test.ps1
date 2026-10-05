param([string]$GameDir = 'G:\SteamLibrary\steamapps\common\Megabonk', [switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot
if (Get-Process Megabonk -ErrorAction SilentlyContinue) { throw 'Close Megabonk before the batch test.' }
if (-not $SkipBuild) { & (Join-Path $PSScriptRoot 'build.ps1') -GameDir $GameDir }
& (Join-Path $PSScriptRoot 'install.ps1') -GameDir $GameDir
$log = Join-Path $GameDir 'BepInEx\LogOutput.log'
$launchTime = [DateTime]::UtcNow
$testProcess = Start-Process -FilePath (Join-Path $GameDir 'Megabonk.exe') -WorkingDirectory $GameDir -ArgumentList '--wildforge-smoke' -WindowStyle Normal -PassThru
$timer = [Diagnostics.Stopwatch]::StartNew()
$passed = $false
try {
    while ($timer.Elapsed.TotalSeconds -lt 120) {
        Start-Sleep -Seconds 1
        $testProcess.Refresh()
        if (Test-Path -LiteralPath $log) {
            if ((Get-Item -LiteralPath $log).LastWriteTimeUtc -ge $launchTime) {
                $text = Get-Content -LiteralPath $log -Raw
                if ($text -match 'SMOKE PASS:') { $passed = $true; break }
                if ($text -match 'Error loading \[Megabonk Wildforge Mod|Wildforge runtime failed:|Wildforge hero model failed:|Wildforge enemy model failed:|Wildforge registration failed:') { break }
            }
        }
        if ($testProcess.HasExited) { break }
    }
    Copy-Item -LiteralPath $log -Destination (Join-Path $modRoot 'artifacts\latest-smoke.log') -Force
    if (-not $passed) { throw 'Batch smoke did not pass. See artifacts/latest-smoke.log.' }
    Write-Output 'Full merge batch smoke passed: roster, perks, cards, weapon inventories, enemy forms, icons and HP orbs.'
} finally {
    $testProcess.Refresh()
    if (-not $testProcess.HasExited) { Stop-Process -Id $testProcess.Id; $testProcess.WaitForExit(10000) | Out-Null }
}
