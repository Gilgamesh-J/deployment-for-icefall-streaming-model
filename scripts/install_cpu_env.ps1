. "$PSScriptRoot\windows_common.ps1"

Set-Location $RepoRoot

$pythonSpec = Get-RepoPython
& $pythonSpec.File @($pythonSpec.Prefix + @("-m", "venv", ".venv"))
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$venvPython = Join-Path $RepoRoot ".venv\Scripts\python.exe"
& $venvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $venvPython -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $venvPython scripts/check_env.py
exit $LASTEXITCODE
