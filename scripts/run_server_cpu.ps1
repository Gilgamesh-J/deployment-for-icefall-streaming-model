param(
    [string]$ModelId = $env:MODEL_ID,
    [string]$BindHost = $env:HOST,
    [string]$Port = $env:PORT,
    [string]$NumThreads = $env:NUM_THREADS,
    [string]$TextFormat = $env:TEXT_FORMAT,
    [string]$DecodingMethod = $env:DECODING_METHOD,
    [switch]$DryRun
)

. "$PSScriptRoot\windows_common.ps1"

Set-Location $RepoRoot

if ([string]::IsNullOrWhiteSpace($BindHost)) {
    $BindHost = "127.0.0.1"
}
if ([string]::IsNullOrWhiteSpace($Port)) {
    $Port = "8766"
}
if ([string]::IsNullOrWhiteSpace($NumThreads)) {
    $NumThreads = "1"
}

$pythonSpec = Get-RepoPython -PreferVenv
$resolveArgs = @("scripts/model_admin.py", "resolve", "--model-id", $ModelId, "--format", "json")
$resolvedJson = & $pythonSpec.File @($pythonSpec.Prefix + $resolveArgs)
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$model = $resolvedJson | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($TextFormat)) {
    $TextFormat = $model.text_format
}
if ([string]::IsNullOrWhiteSpace($DecodingMethod)) {
    $DecodingMethod = $model.decoding_method
}

$env:OMP_NUM_THREADS = $NumThreads
$env:OPENBLAS_NUM_THREADS = $NumThreads
$env:MKL_NUM_THREADS = $NumThreads
$env:NUMEXPR_NUM_THREADS = $NumThreads
$env:ORT_INTRA_OP_NUM_THREADS = $NumThreads
if ([string]::IsNullOrWhiteSpace($env:ORT_INTER_OP_NUM_THREADS)) {
    $env:ORT_INTER_OP_NUM_THREADS = "1"
}

Write-Host "Starting model: $($model.model_id) ($($model.label))"
Write-Host "Model dir: $($model.model_dir)"
Write-Host "WebSocket: ws://${BindHost}:${Port}"
Write-Host "CPU threads: $NumThreads"

$serverArgs = @(
    "server/sherpa_streaming_server.py",
    "--host", $BindHost,
    "--port", $Port,
    "--tokens", $model.tokens,
    "--encoder", $model.encoder,
    "--decoder", $model.decoder,
    "--joiner", $model.joiner,
    "--provider", "cpu",
    "--sample-rate", [string]$model.sample_rate,
    "--feature-dim", [string]$model.feature_dim,
    "--num-threads", $NumThreads,
    "--decoding-method", $DecodingMethod,
    "--model-type", $model.model_type,
    "--enable-endpoint-detection", "0",
    "--text-format", $TextFormat
)

if ($DryRun -or $env:DRY_RUN -eq "1") {
    $commandPreview = @($pythonSpec.File) + $pythonSpec.Prefix + $serverArgs
    Write-Host ("Command: " + ($commandPreview -join " "))
    exit 0
}

& $pythonSpec.File @($pythonSpec.Prefix + $serverArgs)
exit $LASTEXITCODE
