param([string]$PythonExe = 'python')
$ErrorActionPreference = 'Stop'
& $PythonExe -X utf8 (Join-Path $PSScriptRoot 'generate-neural-voices.py')
if ($LASTEXITCODE -ne 0) { throw 'Neural voice rendering failed. Install the local voice dependencies and fetch the model first; see generate-neural-voices.py.' }
