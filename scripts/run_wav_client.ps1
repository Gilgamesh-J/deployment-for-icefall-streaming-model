param(
    [string]$WavPath
)

. "$PSScriptRoot\windows_common.ps1"

Set-Location $RepoRoot

$serverUri = $env:SERVER_URI
if ([string]::IsNullOrWhiteSpace($serverUri)) {
    $serverUri = "ws://127.0.0.1:8766"
}

$chunkMs = $env:CHUNK_MS
if ([string]::IsNullOrWhiteSpace($chunkMs)) {
    $chunkMs = "100"
}

$simulateRealtime = $env:SIMULATE_REALTIME
if ([string]::IsNullOrWhiteSpace($simulateRealtime)) {
    $simulateRealtime = "1"
}

if ([string]::IsNullOrWhiteSpace($WavPath)) {
    $WavPath = Join-Path $RepoRoot "examples\sample_zh.wav"
}

$clientArgs = @(
    "server/sherpa_streaming_client.py",
    "--server-uri", $serverUri,
    "--wav", $WavPath,
    "--chunk-ms", $chunkMs,
    "--simulate-realtime", $simulateRealtime
)

Invoke-RepoPython -PreferVenv -Arguments $clientArgs
