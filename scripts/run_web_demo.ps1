param(
    [string]$WebPort = $env:WEB_PORT
)

. "$PSScriptRoot\windows_common.ps1"

if ([string]::IsNullOrWhiteSpace($WebPort)) {
    $WebPort = "7860"
}

$pythonSpec = Get-RepoPython -PreferVenv
$webDir = Join-Path $RepoRoot "web"
Set-Location $webDir

Write-Host "Open http://127.0.0.1:${WebPort}"
& $pythonSpec.File @($pythonSpec.Prefix + @("-m", "http.server", $WebPort, "--bind", "127.0.0.1"))
exit $LASTEXITCODE
