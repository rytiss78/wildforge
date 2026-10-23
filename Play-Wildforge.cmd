@echo off
setlocal
rem Opens the most recent build exported by "node scripts/agent-workflow.mjs build".
set "WILDFORGE_EXE="
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "try { $b=Get-Content '%~dp0.build-staging\agent-workflow\latest-build.json' -Raw | ConvertFrom-Json; Join-Path (Split-Path $b.isolatedProfile -Parent | Split-Path -Parent) 'Wildforge.exe' } catch {}"`) do set "WILDFORGE_EXE=%%P"
if not defined WILDFORGE_EXE goto missing
if not exist "%WILDFORGE_EXE%" goto missing
echo Opening %WILDFORGE_EXE%
for %%D in ("%WILDFORGE_EXE%") do start "" /D "%%~dpD" "%WILDFORGE_EXE%"
exit /b 0
:missing
echo Build not found. Run node scripts/agent-workflow.mjs build or download the published release.
pause
exit /b 1
