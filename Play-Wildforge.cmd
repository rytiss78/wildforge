@echo off
setlocal
set "WILDFORGE_BUILD=%~dp0build\repair-1.1.2-build16"
if not exist "%WILDFORGE_BUILD%\Wildforge.exe" set "WILDFORGE_BUILD=%~dp0build\red-moon-1.1.1-build15"
if not exist "%WILDFORGE_BUILD%\Wildforge.exe" (
  echo Build not found. Run node scripts/agent-workflow.mjs build or download the published release.
  pause
  exit /b 1
)
echo Opening %WILDFORGE_BUILD%
start "" /D "%WILDFORGE_BUILD%" "%WILDFORGE_BUILD%\Wildforge.exe"
