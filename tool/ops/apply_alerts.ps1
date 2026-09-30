# Shared preflight and nonzero failure exit; no temporary files or deletion.
param(
    [switch]$DryRun,
    [ValidateSet('01', '02', '03', '04', '05')]
    [string[]]$Policy = @()
)
$ErrorActionPreference = 'Stop'
$OpsPython = if ($env:PYTHON) { $env:PYTHON } else { 'python' }
$OpsArguments = @((Join-Path $PSScriptRoot 'apply_alerts.py'))
if ($DryRun) { $OpsArguments += '--dry-run' }
foreach ($OpsPolicy in $Policy) { $OpsArguments += @('--policy', $OpsPolicy) }
& $OpsPython @OpsArguments
exit $LASTEXITCODE
