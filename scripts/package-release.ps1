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
$taskArchive=Join-Path $taskDist "Wildforge-$taskVersion-Windows.zip"
if(Test-Path -LiteralPath $taskArchive){throw 'Build number already packaged. Use the next build number.'}
$taskSource=if($SourceCommit){git -C $taskRoot rev-parse --verify "$SourceCommit^{commit}"}else{git -C $taskRoot rev-parse HEAD}
if($LASTEXITCODE -ne 0){throw 'Invalid source commit.'}
$taskInfo=Join-Path $taskBuild 'build-info.json'
if(!(Test-Path -LiteralPath $taskInfo)){throw 'Missing verified build-info.json; use agent-workflow build.'}
$taskManifest=Get-Content -LiteralPath $taskInfo -Raw | ConvertFrom-Json
if($taskManifest.source -ne $taskSource -or $taskManifest.version -ne $taskVersion -or $taskManifest.build -ne $BuildNumber){throw 'Build provenance does not match the requested commit/version/build.'}
foreach($taskName in @('Wildforge.exe','Wildforge.pck')){
  $taskActualHash=(Get-FileHash -LiteralPath (Join-Path $taskBuild $taskName) -Algorithm SHA256).Hash.ToLower()
  if($taskActualHash -ne $taskManifest.artifacts.$taskName){throw "Build artifact changed: $taskName"}
}
$taskFiles=@('Wildforge.exe','Wildforge.pck','build-info.json') | ForEach-Object {Get-Item -LiteralPath (Join-Path $taskBuild $_)}
# The video panel's web view (godot_wry, MIT) loads its DLL from beside the
# executable; ship it with its license, or the panel only shows "Loading…".
$taskAddon=Join-Path $taskRoot 'native/addons/godot_wry'
if(Test-Path -LiteralPath $taskAddon){
  $taskDll=Join-Path $taskBuild 'godot_wry.dll'
  if(!(Test-Path -LiteralPath $taskDll)){throw 'The build lacks godot_wry.dll; rebuild with agent-workflow build.'}
  $taskLicense=Join-Path $taskDist 'godot_wry-LICENSE.txt'
  Copy-Item -LiteralPath (Join-Path $taskAddon 'LICENSE') -Destination $taskLicense -Force
  $taskFiles+=@((Get-Item -LiteralPath $taskDll),(Get-Item -LiteralPath $taskLicense))
}
Compress-Archive -LiteralPath $taskFiles.FullName -DestinationPath $taskArchive
if($taskLicense){Remove-Item -LiteralPath $taskLicense}
$taskHash=(Get-FileHash -LiteralPath $taskArchive -Algorithm SHA256).Hash.ToLower()
[IO.File]::WriteAllText((Join-Path $taskDist "SHA256SUMS-$taskVersion.txt"),$taskHash+'  '+[IO.Path]::GetFileName($taskArchive)+[Environment]::NewLine)
Write-Output $taskArchive
