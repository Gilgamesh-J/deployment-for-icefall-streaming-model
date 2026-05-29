$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Get-RepoPython {
    param(
        [switch]$PreferVenv
    )

    if ($env:PYTHON) {
        return @{ File = $env:PYTHON; Prefix = @() }
    }

    $venvPython = Join-Path $RepoRoot ".venv\Scripts\python.exe"
    if ($PreferVenv -and (Test-Path $venvPython)) {
        return @{ File = $venvPython; Prefix = @() }
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        return @{ File = $python.Source; Prefix = @() }
    }

    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        return @{ File = $pyLauncher.Source; Prefix = @("-3") }
    }

    throw "Could not find Python. Install Python 3.9+ or set the PYTHON environment variable."
}

function Invoke-RepoPython {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [switch]$PreferVenv
    )

    $pythonSpec = Get-RepoPython -PreferVenv:$PreferVenv
    & $pythonSpec.File @($pythonSpec.Prefix + $Arguments)
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
