# tool/ops/apply_alerts.ps1
#
# PowerShell equivalent of apply_alerts.sh. Applies every policy in
# tool/ops/alert_policies/*.json to Cloud Monitoring via
# `gcloud alpha monitoring policies create --policy-from-file=...`. Never
# updates or deletes an existing policy — rerunning this creates duplicates
# (review + delete the old one by hand instead).
#
# Requires env vars GCP_PROJECT=ko-lernen-app and NOTIFICATION_CHANNEL_ID (see
# tool/ops/.env.ops.example). Run tool/ops/log_metrics.sh first — policy 03
# depends on the log-based metrics it creates.
#
# Usage:
#   $env:GCP_PROJECT = "ko-lernen-app"; $env:NOTIFICATION_CHANNEL_ID = "xxxx"
#   powershell -File tool/ops/apply_alerts.ps1
#   powershell -File tool/ops/apply_alerts.ps1 -DryRun

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not $env:GCP_PROJECT) {
    Write-Error "GCP_PROJECT env var is required (expected: ko-lernen-app)."
    exit 1
}
if ($env:GCP_PROJECT -ne "ko-lernen-app") {
    Write-Error "GCP_PROJECT must be exactly 'ko-lernen-app', got '$($env:GCP_PROJECT)'."
    exit 1
}
if (-not $env:NOTIFICATION_CHANNEL_ID) {
    Write-Error "NOTIFICATION_CHANNEL_ID env var is required. Create a channel first with 'gcloud alpha monitoring channels create'."
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PolicyDir = Join-Path $ScriptDir "alert_policies"
$WorkDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ops-alerts-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

try {
    "{0,-40} {1,-10} {2}" -f "POLICY FILE", "STATUS", "POLICY NAME / ERROR"
    "{0,-40} {1,-10} {2}" -f ("-" * 40), ("-" * 10), ("-" * 20)

    $policyFiles = Get-ChildItem -Path $PolicyDir -Filter "*.json" | Where-Object { $_.Name -match '^\d' } | Sort-Object Name

    foreach ($policyFile in $policyFiles) {
        $tmpFile = Join-Path $WorkDir $policyFile.Name

        # Strip metadata keys (anything starting with "_") not part of the
        # AlertPolicy API schema, then substitute the channel placeholder.
        $json = Get-Content $policyFile.FullName -Raw | ConvertFrom-Json
        $clean = [ordered]@{}
        foreach ($prop in $json.PSObject.Properties) {
            if (-not $prop.Name.StartsWith("_")) {
                $clean[$prop.Name] = $prop.Value
            }
        }
        $rendered = ($clean | ConvertTo-Json -Depth 20)
        $rendered = $rendered.Replace('${NOTIFICATION_CHANNEL_ID}', $env:NOTIFICATION_CHANNEL_ID)
        Set-Content -Path $tmpFile -Value $rendered -Encoding utf8

        if ($DryRun) {
            "{0,-40} {1,-10} {2}" -f $policyFile.Name, "DRY-RUN", "gcloud alpha monitoring policies create --project=$($env:GCP_PROJECT) --policy-from-file=$tmpFile"
            continue
        }

        try {
            $output = & gcloud alpha monitoring policies create `
                --project=$env:GCP_PROJECT `
                --policy-from-file=$tmpFile `
                --format="value(name)" 2>&1
            if ($LASTEXITCODE -eq 0) {
                "{0,-40} {1,-10} {2}" -f $policyFile.Name, "CREATED", ($output -join " ")
            } else {
                "{0,-40} {1,-10} {2}" -f $policyFile.Name, "FAILED", ($output -join " ")
            }
        } catch {
            "{0,-40} {1,-10} {2}" -f $policyFile.Name, "FAILED", $_.Exception.Message
        }
    }

    Write-Host ""
    Write-Host "Receipt: paste the CREATED policy name/ID rows above into docs/runbooks/ops-alerts.md 적용 영수증 section."
    Write-Host "Verify with: gcloud alpha monitoring policies list --project=$($env:GCP_PROJECT)"
} finally {
    Remove-Item -Recurse -Force -Path $WorkDir -ErrorAction SilentlyContinue
}
