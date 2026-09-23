# Same preflight and receipts as the Bash entrypoint; no temporary credentials.
param(
    [switch]$DryRun,
    [ValidateSet('ai_cost_breaker_unavailable', 'apple_revocation_config_invalid', 'auth_anonymous_account_created')]
    [string[]]$Metric = @()
)
$ErrorActionPreference = 'Stop'
$OpsPython = if ($env:PYTHON) { $env:PYTHON } else { 'python' }
$OpsArguments = @((Join-Path $PSScriptRoot 'log_metrics.py'))
if ($DryRun) { $OpsArguments += '--dry-run' }
foreach ($OpsMetric in $Metric) { $OpsArguments += @('--metric', $OpsMetric) }
& $OpsPython @OpsArguments
exit $LASTEXITCODE
