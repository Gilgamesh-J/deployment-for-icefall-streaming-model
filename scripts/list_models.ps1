. "$PSScriptRoot\windows_common.ps1"

Set-Location $RepoRoot
$pythonArgs = @("scripts/model_admin.py", "list") + $args
Invoke-RepoPython -PreferVenv -Arguments $pythonArgs
