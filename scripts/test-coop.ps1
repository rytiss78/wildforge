param([switch]$RenderedClient,[switch]$Packaged)
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskGodot=Join-Path $taskRoot 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$taskHostArgs=@('--headless','--path',(Join-Path $taskRoot 'native'),'--','--coop-host-test')
if ($Packaged) { $taskGodot=Join-Path $taskRoot 'build/Wildforge.console.exe'; $taskHostArgs=@('--headless','--','--coop-host-test') }
$taskHost=Start-Process -FilePath $taskGodot -ArgumentList $taskHostArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $taskRoot 'tools/coop-host.log') -RedirectStandardError (Join-Path $taskRoot 'tools/coop-host-errors.log')
Start-Sleep -Milliseconds 1500
$taskClientArgs=@('--headless','--path',(Join-Path $taskRoot 'native'),'--','--coop-client-test')
if ($RenderedClient) { $taskClientArgs=@('--path',(Join-Path $taskRoot 'native'),'--position','-32000,-32000','--','--coop-client-test') }
if ($Packaged) {
  $taskClientArgs=@('--headless','--','--coop-client-test')
  if ($RenderedClient) { $taskClientArgs=@('--position','-32000,-32000','--','--coop-client-test') }
}
$taskClient=Start-Process -FilePath $taskGodot -ArgumentList $taskClientArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $taskRoot 'tools/coop-client.log') -RedirectStandardError (Join-Path $taskRoot 'tools/coop-client-errors.log')
try { Wait-Process -Id $taskHost.Id,$taskClient.Id -Timeout 40 }
catch {
  # Stop only the two diagnostic processes created above, never a player's game.
  Stop-Process -Id $taskHost.Id,$taskClient.Id -ErrorAction SilentlyContinue
  throw
}
foreach ($taskRole in @('host','client')) {
  $taskLog=Get-Content -Raw -LiteralPath (Join-Path $taskRoot "tools/coop-$taskRole.log")
  $taskErrors=Get-Content -Raw -LiteralPath (Join-Path $taskRoot "tools/coop-$taskRole-errors.log")
  if ($taskErrors -match 'SCRIPT ERROR|ERROR:') { throw $taskErrors }
  $taskResult=($taskLog -split "`n" | Where-Object { $_ -like 'COOP_TEST {*' } | Select-Object -Last 1).Substring(10) | ConvertFrom-Json
  if (-not $taskResult.standalone -or -not $taskResult.discovery -or -not $taskResult.connected -or $taskResult.avatars -lt 1 -or -not $taskResult.same_enemies -or $taskResult.realm -ne 1) { throw "Co-op $taskRole failed: $taskLog" }
  if (-not $taskResult.downed -or -not $taskResult.rescued -or -not $taskResult.ping -or -not $taskResult.merchant -or -not $taskResult.supply) { throw "Co-op $taskRole interaction checks failed: $taskLog" }
  if ($taskRole -eq 'host' -and $taskResult.remote_hits -lt 1) { throw 'Guest attacks did not reach the host.' }
  if ($taskRole -eq 'client' -and ($taskResult.snapshots -lt 20 -or $taskResult.kills_received -lt 1 -or -not $taskResult.party_pause -or -not $taskResult.realm_received -or -not $taskResult.moved)) { throw 'Guest world replication failed.' }
  $taskResult | ConvertTo-Json -Compress
}
