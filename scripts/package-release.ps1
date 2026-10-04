$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskVersion=(Get-Content -LiteralPath (Join-Path $taskRoot 'package.json') -Raw | ConvertFrom-Json).version
$taskBuild=Join-Path $taskRoot 'build'
foreach($taskName in @('Wildforge.exe','Wildforge.pck')){
  if(!(Test-Path -LiteralPath (Join-Path $taskBuild $taskName))){throw 'Build the native game first.'}
}
$taskDist=Join-Path $taskRoot 'dist'
New-Item -ItemType Directory -Path $taskDist -Force | Out-Null
$taskArchive=Join-Path $taskDist "Wildforge-$taskVersion-Windows.zip"
$taskFiles=Get-ChildItem -LiteralPath $taskBuild -File | Where-Object {$_.Name -ne 'Wildforge.console.exe' -and $_.Extension -ne '.log'}
Compress-Archive -LiteralPath $taskFiles.FullName -DestinationPath $taskArchive -Force
$taskHash=(Get-FileHash -LiteralPath $taskArchive -Algorithm SHA256).Hash.ToLower()
[IO.File]::WriteAllText((Join-Path $taskDist 'SHA256SUMS.txt'),$taskHash+'  '+[IO.Path]::GetFileName($taskArchive)+[Environment]::NewLine)
Write-Output $taskArchive
