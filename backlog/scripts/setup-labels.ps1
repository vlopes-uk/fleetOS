<#
.SYNOPSIS
    Creates all labels referenced by the TVDE backlog CSV.
.DESCRIPTION
    Idempotent: existing labels are skipped. Requires gh CLI v2.40+ and
    authentication with repo scope.

    Run this ONCE before importing the backlog.
.PARAMETER Repo
    Target repository in owner/name format.
.EXAMPLE
    .\setup-labels.ps1 -Repo "my-org/fleetOS"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Repo
)

$ErrorActionPreference = 'Stop'

# ---- Verify gh CLI ---------------------------------------------------------
try {
    $ghVersion = (gh --version | Select-Object -First 1)
    Write-Host "gh CLI: $ghVersion" -ForegroundColor DarkGray
}
catch {
    Write-Host "GitHub CLI (gh) is not installed or not on PATH." -ForegroundColor Red
    Write-Host "Install it with: winget install --id GitHub.cli -e" -ForegroundColor Yellow
    exit 1
}

# ---- Verify repo access ----------------------------------------------------
Write-Host "Verifying access to $Repo..." -ForegroundColor Cyan
gh repo view $Repo --json name 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Cannot access $Repo. Check the name and your authentication." -ForegroundColor Red
    exit 1
}

# ---- Label definitions -----------------------------------------------------
# Format: Name | Color (hex, no #) | Description
$labels = @(
    # Type labels
    @{ Name = 'type: epic';    Color = '6f42c1'; Desc = 'Epic-level work' }
    @{ Name = 'type: feature'; Color = '0075ca'; Desc = 'Feature-level work' }
    @{ Name = 'type: story';   Color = '1d76db'; Desc = 'User story' }
    @{ Name = 'type: task';    Color = '0e8a16'; Desc = 'Implementation task' }

    # Module labels
    @{ Name = 'module: core';        Color = 'ededed'; Desc = 'Module: core' }
    @{ Name = 'module: auth';        Color = 'ededed'; Desc = 'Module: authentication' }
    @{ Name = 'module: fleet';       Color = 'ededed'; Desc = 'Module: fleet and vehicles' }
    @{ Name = 'module: drivers';     Color = 'ededed'; Desc = 'Module: drivers' }
    @{ Name = 'module: trips';       Color = 'ededed'; Desc = 'Module: trips and revenue' }
    @{ Name = 'module: telemetry';   Color = 'ededed'; Desc = 'Module: telemetry (Mapon)' }
    @{ Name = 'module: billing';     Color = 'ededed'; Desc = 'Module: billing engine' }
    @{ Name = 'module: payments';    Color = 'ededed'; Desc = 'Module: payments' }
    @{ Name = 'module: incidents';   Color = 'ededed'; Desc = 'Module: incidents and complaints' }
    @{ Name = 'module: analytics';   Color = 'ededed'; Desc = 'Module: analytics and reports' }
    @{ Name = 'module: mobile';      Color = 'ededed'; Desc = 'Module: mobile app' }
    @{ Name = 'module: compliance';  Color = 'ededed'; Desc = 'Module: compliance alerts' }
    @{ Name = 'module: settings';    Color = 'ededed'; Desc = 'Module: settings and admin' }

    # Priority labels
    @{ Name = 'priority: critical'; Color = 'b60205'; Desc = 'Must be done first' }
    @{ Name = 'priority: high';     Color = 'd93f0b'; Desc = 'High priority' }
    @{ Name = 'priority: medium';   Color = 'fbca04'; Desc = 'Medium priority' }
    @{ Name = 'priority: low';      Color = '0e8a16'; Desc = 'Low priority' }
)

# ---- Create labels ---------------------------------------------------------
$created = 0
$skipped = 0
$failed  = 0

Write-Host "`nCreating labels in $Repo..." -ForegroundColor Cyan
Write-Host ""

foreach ($label in $labels) {
    $name = $label.Name
    Write-Host ("  {0,-24}" -f $name) -NoNewline -ForegroundColor Gray

    # Suppress stderr to avoid noisy output when label already exists
    $output = gh label create $name `
        --color $label.Color `
        --description $label.Desc `
        --repo $Repo 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  created" -ForegroundColor Green
        $created++
    }
    elseif ($output -match 'already exists') {
        Write-Host "  exists (skipped)" -ForegroundColor DarkYellow
        $skipped++
    }
    else {
        Write-Host "  FAILED" -ForegroundColor Red
        Write-Host "    $output" -ForegroundColor DarkRed
        $failed++
    }
}

# ---- Summary ---------------------------------------------------------------
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host ("  Created: {0}" -f $created) -ForegroundColor Green
Write-Host ("  Skipped: {0}" -f $skipped) -ForegroundColor DarkYellow
if ($failed -gt 0) {
    Write-Host ("  Failed:  {0}" -f $failed) -ForegroundColor Red
}

if ($failed -eq 0) {
    Write-Host "`nAll labels ready. Next: run csv-to-github.ps1" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`nSome labels failed. Review the errors above." -ForegroundColor Red
    exit 1
}