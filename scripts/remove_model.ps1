. "$PSScriptRoot\windows_common.ps1"

Set-Location $RepoRoot
$pythonArgs = @("scripts/model_admin.py", "remove") + $args
Invoke-RepoPython -PreferVenv -Arguments $pythonArgs
