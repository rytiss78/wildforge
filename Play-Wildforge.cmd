@echo off
setlocal
set "WILDFORGE_BUILD=%~dp0build\giant-combat-1.1.1"
if not exist "%WILDFORGE_BUILD%\Wildforge.exe" (
  echo Build not found. Run node scripts/agent-workflow.mjs build or download the published release.
  pause
  exit /b 1
)
start "" /D "%WILDFORGE_BUILD%" "%WILDFORGE_BUILD%\Wildforge.exe"
