param(
  [Parameter(Mandatory=$true)][ValidateRange(1,2147483647)][int]$BuildNumber,
  [string]$BuildDirectory,
  [string]$SourceCommit
)
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskVersion=(Get-Content -LiteralPath (Join-Path $taskRoot 'package.json') -Raw | ConvertFrom-Json).version
$taskBuild=if($BuildDirectory){[IO.Path]::GetFullPath($BuildDirectory)}else{Join-Path $taskRoot 'build'}
foreach($taskName in @('Wildforge.exe','Wildforge.pck')){
  if(!(Test-Path -LiteralPath (Join-Path $taskBuild $taskName))){throw 'Build the native game first.'}
}
$taskDist=Join-Path $taskRoot 'dist'
New-Item -ItemType Directory -Path $taskDist -Force | Out-Null
$taskArchive=Join-Path $taskDist "Wildforge-$taskVersion-Build-$BuildNumber-Windows.zip"
if(Test-Path -LiteralPath $taskArchive){throw 'Build number already packaged. Use the next build number.'}
$taskSource=if($SourceCommit){git -C $taskRoot rev-parse --verify "$SourceCommit^{commit}"}else{git -C $taskRoot rev-parse HEAD}
if($LASTEXITCODE -ne 0){throw 'Invalid source commit.'}
$taskManifest=[ordered]@{version=$taskVersion;build=$BuildNumber;source=$taskSource;packagedUtc=[DateTime]::UtcNow.ToString('o')}
$taskManifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $taskBuild 'build-info.json')
$taskFiles=Get-ChildItem -LiteralPath $taskBuild -File | Where-Object {$_.Name -ne 'Wildforge.console.exe' -and $_.Extension -ne '.log'}
Compress-Archive -LiteralPath $taskFiles.FullName -DestinationPath $taskArchive
$taskHash=(Get-FileHash -LiteralPath $taskArchive -Algorithm SHA256).Hash.ToLower()
[IO.File]::WriteAllText((Join-Path $taskDist "SHA256SUMS-Build-$BuildNumber.txt"),$taskHash+'  '+[IO.Path]::GetFileName($taskArchive)+[Environment]::NewLine)
Write-Output $taskArchive
