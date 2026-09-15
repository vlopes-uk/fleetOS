<#
.SYNOPSIS
    Creates GitHub issues from the TVDE backlog CSV and links parent/child relationships.
.DESCRIPTION
    Two-pass import:
      Pass 1 - Create every issue, capturing temp_id -> issue number.
      Pass 2 - Link children to parents via gh issue edit --set-parent.

    Idempotent enough to re-run: if an issue title already exists in the repo,
    it is reused rather than duplicated.

    Requires gh CLI v2.94.0+ for --set-parent support.
.PARAMETER CsvFile
    Path to the CSV file. Defaults to ..\csv\tvde-backlog.csv relative to the script.
.PARAMETER Repo
    Target repository in owner/name format.
.PARAMETER Delay
    Seconds between API calls. Default 1.5. Increase if rate-limited.
.PARAMETER SkipLinking
    Create issues only, skip the parent-linking pass. Useful for debugging.
.EXAMPLE
    .\csv-to-github.ps1 -Repo "my-org/fleetOS"

.EXAMPLE
    .\csv-to-github.ps1 -CsvFile "C:\temp\backlog.csv" -Repo "my-org/fleetOS" -Delay 3
#>

[CmdletBinding()]
param(
    [string]$CsvFile = (Join-Path $PSScriptRoot '..\csv\tvde-backlog.csv'),
    [Parameter(Mandatory = $true)]
    [string]$Repo,
    [double]$Delay = 1.5,
    [switch]$SkipLinking
)

$ErrorActionPreference = 'Stop'

# ---- Verify gh CLI ---------------------------------------------------------
try {
    $ghRaw = (gh --version | Select-Object -First 1)
    Write-Host "gh CLI: $ghRaw" -ForegroundColor DarkGray

    # Extract version number
    if ($ghRaw -match 'gh version (\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        if ($major -lt 2 -or ($major -eq 2 -and $minor -lt 94)) {
            Write-Host "Warning: --set-parent requires gh v2.94.0+." -ForegroundColor Yellow
            Write-Host "Your version: $major.$minor. Parent linking may fail." -ForegroundColor Yellow
            Write-Host "Run: winget upgrade --id GitHub.cli" -ForegroundColor Yellow
        }
    }
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

# ---- Load and validate CSV -------------------------------------------------
if (-not (Test-Path $CsvFile)) {
    Write-Host "CSV file not found: $CsvFile" -ForegroundColor Red
    exit 1
}

$csvPath = (Resolve-Path $CsvFile).Path
Write-Host "Loading $csvPath..." -ForegroundColor Cyan

$rows = Import-Csv -Path $csvPath
if ($rows.Count -eq 0) {
    Write-Host "CSV has no data rows." -ForegroundColor Red
    exit 1
}

$requiredColumns = @('temp_id', 'title')
$missing = $requiredColumns | Where-Object { $_ -notin $rows[0].PSObject.Properties.Name }
if ($missing) {
    Write-Host ("CSV is missing required columns: {0}" -f ($missing -join ', ')) -ForegroundColor Red
    exit 1
}

$hasTypeColumn   = 'type'           -in $rows[0].PSObject.Properties.Name
$hasBodyColumn   = 'body'           -in $rows[0].PSObject.Properties.Name
$hasLabelsColumn = 'labels'         -in $rows[0].PSObject.Properties.Name
$hasParentColumn = 'parent_temp_id' -in $rows[0].PSObject.Properties.Name

Write-Host ("Loaded {0} rows. Target: {1}" -f $rows.Count, $Repo) -ForegroundColor Cyan
Write-Host ("Delay between calls: {0}s" -f $Delay) -ForegroundColor DarkGray
Write-Host ""

# ---- Helpers ---------------------------------------------------------------
function Invoke-GhWithRetry {
    param(
        [string[]]$Arguments,
        [int]$MaxAttempts = 5
    )
    $attempt = 1
    while ($attempt -le $MaxAttempts) {
        $output = & gh @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) {
            return @{ Success = $true; Output = $output }
        }
        if ($output -match 'rate limit|429|secondary rate') {
            $wait = 60 * $attempt
            Write-Host ("    rate limited, waiting {0}s (attempt {1}/{2})" -f $wait, $attempt, $MaxAttempts) -ForegroundColor DarkYellow
            Start-Sleep -Seconds $wait
            $attempt++
            continue
        }
        return @{ Success = $false; Output = $output }
    }
    return @{ Success = $false; Output = "Exceeded retry attempts" }
}

function Get-ExistingIssueNumber {
    param([string]$Title)
    # Search exact title in open + closed issues
    $json = gh issue list --repo $Repo --state all --search "`"$Title`" in:title" --json number,title --limit 100 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $json) { return $null }
    $issues = $json | ConvertFrom-Json
    $match = $issues | Where-Object { $_.title -eq $Title } | Select-Object -First 1
    if ($match) { return $match.number }
    return $null
}

# ---- Pass 1: Create all issues ---------------------------------------------
$mapping = @{}      # temp_id -> issue number
$created = 0
$reused  = 0
$failed  = 0

Write-Host "=== Pass 1: Creating issues ===" -ForegroundColor Yellow
Write-Host ""

foreach ($row in $rows) {
    $tempId = $row.temp_id.Trim()
    $title  = $row.title.Trim()

    if ([string]::IsNullOrWhiteSpace($tempId) -or [string]::IsNullOrWhiteSpace($title)) {
        Write-Host "  Skipping row with empty temp_id or title" -ForegroundColor DarkYellow
        continue
    }

    $type   = if ($hasTypeColumn)   { $row.type.Trim() }   else { '' }
    $body   = if ($hasBodyColumn   -and $row.body)   { $row.body.Trim() }   else { 'No description provided.' }
    $labels = if ($hasLabelsColumn -and $row.labels) { $row.labels.Trim() } else { '' }

    Write-Host ("  [{0}] {1}" -f $tempId, $title) -ForegroundColor Gray

    # ---- Check for existing issue (idempotency) ----
    $existing = Get-ExistingIssueNumber -Title $title
    if ($existing) {
        $mapping[$tempId] = $existing
        Write-Host ("    -> #{0} (already exists)" -f $existing) -ForegroundColor DarkYellow
        $reused++
        continue
    }

    # ---- Build gh arguments ----
    $ghArgs = @(
        'issue', 'create',
        '--repo', $Repo,
        '--title', $title,
        '--body', $body
    )

    if ($type)   { $ghArgs += @('--type',  $type) }
    if ($labels) { $ghArgs += @('--label', $labels) }

    # ---- Create ----
    $result = Invoke-GhWithRetry -Arguments $ghArgs
    if ($result.Success) {
        $url = $result.Output | Select-Object -Last 1
        if ($url -match '(\d+)\s*$') {
            $num = [int]$Matches[1]
            $mapping[$tempId] = $num
            Write-Host ("    -> #{0}" -f $num) -ForegroundColor DarkGreen
            $created++
        }
        else {
            Write-Host ("    !! Created but could not parse issue number from: {0}" -f $url) -ForegroundColor Red
            $failed++
        }
    }
    else {
        Write-Host ("    !! Failed: {0}" -f $result.Output) -ForegroundColor Red
        $failed++
    }

    Start-Sleep -Milliseconds ([int]($Delay * 1000))
}

Write-Host ""
Write-Host ("Pass 1 complete. Created: {0}, Reused: {1}, Failed: {2}" -f $created, $reused, $failed) -ForegroundColor Yellow
Write-Host ""

# ---- Save mapping to disk (for recovery) -----------------------------------
$mappingPath = Join-Path $PSScriptRoot 'import-mapping.json'
$mapping.GetEnumerator() | ForEach-Object {
    [PSCustomObject]@{ temp_id = $_.Key; number = $_.Value }
} | ConvertTo-Json | Out-File -FilePath $mappingPath -Encoding UTF8
Write-Host "Mapping saved to $mappingPath" -ForegroundColor DarkGray

# ---- Pass 2: Link parents --------------------------------------------------
if ($SkipLinking) {
    Write-Host "Skipping Pass 2 (--SkipLinking)." -ForegroundColor Yellow
    exit 0
}

if (-not $hasParentColumn) {
    Write-Host "No parent_temp_id column. Skipping Pass 2." -ForegroundColor Yellow
    exit 0
}

Write-Host "=== Pass 2: Linking parent relationships ===" -ForegroundColor Yellow
Write-Host ""

$linked     = 0
$linkFailed = 0
$skipNoParent = 0

foreach ($row in $rows) {
    $tempId       = $row.temp_id.Trim()
    $parentTempId = if ($row.parent_temp_id) { $row.parent_temp_id.Trim() } else { '' }

    if ([string]::IsNullOrWhiteSpace($parentTempId)) {
        $skipNoParent++
        continue
    }
    if (-not $mapping.ContainsKey($tempId)) {
        Write-Host ("  {0}: no issue number in mapping, skipping" -f $tempId) -ForegroundColor DarkYellow
        continue
    }
    if (-not $mapping.ContainsKey($parentTempId)) {
        Write-Host ("  {0}: parent {1} not in mapping, skipping" -f $tempId, $parentTempId) -ForegroundColor DarkYellow
        continue
    }

    $childNum  = $mapping[$tempId]
    $parentNum = $mapping[$parentTempId]

    Write-Host ("  Linking #{0} ({1}) -> #{2} ({3})" -f $childNum, $tempId, $parentNum, $parentTempId) -ForegroundColor Gray

    $result = Invoke-GhWithRetry -Arguments @(
        'issue', 'edit', $childNum,
        '--repo', $Repo,
        '--set-parent', $parentNum
    )

    if ($result.Success) {
        $linked++
    }
    else {
        Write-Host ("    !! Failed to link: {0}" -f $result.Output) -ForegroundColor Red
        $linkFailed++
    }

    Start-Sleep -Milliseconds ([int]($Delay * 1000))
}

# ---- Summary ---------------------------------------------------------------
Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
Write-Host ("  Issues created:  {0}" -f $created) -ForegroundColor Green
Write-Host ("  Issues reused:   {0}" -f $reused)  -ForegroundColor DarkYellow
Write-Host ("  Issues failed:   {0}" -f $failed)  -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host ("  Parent links:    {0}" -f $linked)  -ForegroundColor Green
Write-Host ("  Link failures:   {0}" -f $linkFailed) -ForegroundColor $(if ($linkFailed -gt 0) { 'Red' } else { 'Gray' })
Write-Host ("  Leaf nodes:      {0}" -f $skipNoParent) -ForegroundColor DarkGray
Write-Host ""

if ($failed -eq 0 -and $linkFailed -eq 0) {
    Write-Host "Verify with:" -ForegroundColor Cyan
    Write-Host ("  gh issue list --repo {0} --type Epic" -f $Repo) -ForegroundColor Gray
    Write-Host ("  gh issue view <number> --repo {0}" -f $Repo) -ForegroundColor Gray
    exit 0
}
else {
    Write-Host "Some operations failed. Re-run the script — existing issues will be reused." -ForegroundColor Yellow
    exit 1
}