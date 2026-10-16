@echo off
setlocal
set "WILDFORGE_BUILD=%~dp0build\baron-1.1.3-build17"
if not exist "%WILDFORGE_BUILD%\Wildforge.exe" set "WILDFORGE_BUILD=%~dp0build\repair-1.1.2-build16"
if not exist "%WILDFORGE_BUILD%\Wildforge.exe" (
  echo Build not found. Run node scripts/agent-workflow.mjs build or download the published release.
  pause
  exit /b 1
)
echo Opening %WILDFORGE_BUILD%
start "" /D "%WILDFORGE_BUILD%" "%WILDFORGE_BUILD%\Wildforge.exe"
