<#
.SYNOPSIS
    Creates GitHub issues from the TVDE backlog CSV and links parent/child relationships.
.DESCRIPTION
    Two-pass import with idempotent behaviour. Auto-detects whether the target
    repo supports issue types and gracefully skips --type if not.
.PARAMETER CsvFile
    Path to the CSV. Defaults to ..\csv\tvde-backlog.csv relative to this script.
.PARAMETER Repo
    Target repository in owner/name format.
.PARAMETER Delay
    Seconds between API calls. Default 1.5.
.PARAMETER SkipLinking
    Create issues only, skip the parent-linking pass.
#>

[CmdletBinding()]
param(
    [string]$CsvFile = '',
    [Parameter(Mandatory = $true)]
    [string]$Repo,
    [double]$Delay = 1.5,
    [switch]$SkipLinking
)

$ErrorActionPreference = 'Stop'

# ---- Resolve script folder -------------------------------------------------
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    if ($MyInvocation.MyCommand.Path) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $scriptDir = (Get-Location).Path
    }
}

if ([string]::IsNullOrWhiteSpace($CsvFile)) {
    $CsvFile = Join-Path $scriptDir '..\csv\tvde-backlog.csv'
}

# ---- Verify gh CLI ---------------------------------------------------------
try {
    $ghRaw = (gh --version | Select-Object -First 1)
    Write-Host "gh CLI: $ghRaw" -ForegroundColor DarkGray
}
catch {
    Write-Host "GitHub CLI (gh) is not installed or not on PATH." -ForegroundColor Red
    exit 1
}

# ---- Verify repo access ----------------------------------------------------
Write-Host "Verifying access to $Repo..." -ForegroundColor Cyan
gh repo view $Repo --json name 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Cannot access $Repo." -ForegroundColor Red
    exit 1
}

# ---- Detect issue type support ---------------------------------------------
$script:availableTypes = @()

Write-Host "Checking issue type support..." -ForegroundColor DarkGray
$owner = $Repo.Split('/')[0]
try {
    $typesJson = gh api "orgs/$owner/issue-types" --jq '.[].name' 2>$null
    if ($LASTEXITCODE -eq 0 -and $typesJson) {
        $script:availableTypes = @(
            $typesJson -split "`n" |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ }
        )
    }
}
catch { }

if ($script:availableTypes.Count -gt 0) {
    Write-Host ("  Types available: {0}" -f ($script:availableTypes -join ', ')) -ForegroundColor DarkGray
} else {
    Write-Host "  No issue types available — using labels only." -ForegroundColor DarkYellow
}

# ---- Load CSV --------------------------------------------------------------
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

$hasTypeColumn   = 'type'           -in $rows[0].PSObject.Properties.Name
$hasBodyColumn   = 'body'           -in $rows[0].PSObject.Properties.Name
$hasLabelsColumn = 'labels'         -in $rows[0].PSObject.Properties.Name
$hasParentColumn = 'parent_temp_id' -in $rows[0].PSObject.Properties.Name

Write-Host ("Loaded {0} rows. Target: {1}" -f $rows.Count, $Repo) -ForegroundColor Cyan
Write-Host ""

# ---- Issue cache -----------------------------------------------------------
$script:issueCache = $null

function Initialize-IssueCache {
    if ($null -ne $script:issueCache) { return }
    Write-Host "Fetching existing issues..." -ForegroundColor DarkGray
    $script:issueCache = @{}

    $json = gh issue list --repo $Repo --state all --limit 5000 --json number,title 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $json) {
        Write-Host "  Could not fetch — assuming empty." -ForegroundColor DarkYellow
        return
    }

    $issues = $json | ConvertFrom-Json
    foreach ($issue in $issues) {
        $script:issueCache[$issue.title] = $issue.number
    }
    Write-Host ("  Loaded {0} existing issues" -f $script:issueCache.Count) -ForegroundColor DarkGray
}

function Get-ExistingIssueNumber {
    param([string]$Title)
    Initialize-IssueCache
    if ($script:issueCache.ContainsKey($Title)) { return $script:issueCache[$Title] }
    return $null
}

function Add-IssueToCache {
    param([string]$Title, [int]$Number)
    if ($null -eq $script:issueCache) { $script:issueCache = @{} }
    $script:issueCache[$Title] = $Number
}

# ---- Retry helper ----------------------------------------------------------
function Invoke-GhWithRetry {
    param([string[]]$Arguments, [int]$MaxAttempts = 5)
    $attempt = 1
    while ($attempt -le $MaxAttempts) {
        $output = & gh @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) {
            return @{ Success = $true; Output = $output }
        }
        if ("$output" -match 'rate limit|429|secondary rate') {
            $wait = 60 * $attempt
            Write-Host ("    rate limited, waiting {0}s" -f $wait) -ForegroundColor DarkYellow
            Start-Sleep -Seconds $wait
            $attempt++
            continue
        }
        return @{ Success = $false; Output = "$output" }
    }
    return @{ Success = $false; Output = "Exceeded retry attempts" }
}

# ---- Pass 1: Create all issues ---------------------------------------------
$mapping = @{}
$created = 0
$reused  = 0
$failed  = 0

Write-Host "=== Pass 1: Creating issues ===" -ForegroundColor Yellow
Write-Host ""

foreach ($row in $rows) {
    $tempId = $row.temp_id.Trim()
    $title  = $row.title.Trim()

    if ([string]::IsNullOrWhiteSpace($tempId) -or [string]::IsNullOrWhiteSpace($title)) {
        continue
    }

    $type   = if ($hasTypeColumn)   { $row.type.Trim() }   else { '' }
    $body   = if ($hasBodyColumn   -and $row.body)   { $row.body.Trim() }   else { 'No description provided.' }
    $labels = if ($hasLabelsColumn -and $row.labels) { $row.labels.Trim() } else { '' }

    Write-Host ("  [{0}] {1}" -f $tempId, $title) -ForegroundColor Gray

    $existing = Get-ExistingIssueNumber -Title $title
    if ($existing) {
        $mapping[$tempId] = $existing
        Write-Host ("    -> #{0} (already exists)" -f $existing) -ForegroundColor DarkYellow
        $reused++
        continue
    }

    $ghArgs = @(
        'issue', 'create',
        '--repo', $Repo,
        '--title', $title,
        '--body', $body
    )

    # Only pass --type if the repo actually supports the requested type
    if ($type -and ($script:availableTypes -contains $type)) {
        $ghArgs += @('--type', $type)
    }

    if ($labels) { $ghArgs += @('--label', $labels) }

    $result = Invoke-GhWithRetry -Arguments $ghArgs
    if ($result.Success) {
        $url = $result.Output | Select-Object -Last 1
        if ("$url" -match '(\d+)\s*$') {
            $num = [int]$Matches[1]
            $mapping[$tempId] = $num
            Add-IssueToCache -Title $title -Number $num
            Write-Host ("    -> #{0}" -f $num) -ForegroundColor DarkGreen
            $created++
        } else {
            Write-Host ("    !! Could not parse number: {0}" -f $url) -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host ("    !! Failed: {0}" -f $result.Output) -ForegroundColor Red
        $failed++
    }

    Start-Sleep -Milliseconds ([int]($Delay * 1000))
}

Write-Host ""
Write-Host ("Pass 1 complete. Created: {0}, Reused: {1}, Failed: {2}" -f $created, $reused, $failed) -ForegroundColor Yellow
Write-Host ""

# ---- Save mapping ----------------------------------------------------------
$mappingPath = Join-Path $scriptDir 'import-mapping.json'
$mapping.GetEnumerator() | ForEach-Object {
    [PSCustomObject]@{ temp_id = $_.Key; number = $_.Value }
} | ConvertTo-Json | Out-File -FilePath $mappingPath -Encoding UTF8
Write-Host "Mapping saved to $mappingPath" -ForegroundColor DarkGray

# ---- Pass 2: Link parents --------------------------------------------------
if ($SkipLinking) {
    Write-Host "Skipping Pass 2." -ForegroundColor Yellow
    exit 0
}

if (-not $hasParentColumn) {
    Write-Host "No parent_temp_id column. Skipping Pass 2." -ForegroundColor Yellow
    exit 0
}

Write-Host "=== Pass 2: Linking parent relationships ===" -ForegroundColor Yellow
Write-Host ""

$linked       = 0
$linkFailed   = 0
$skipNoParent = 0

foreach ($row in $rows) {
    $tempId       = $row.temp_id.Trim()
    $parentTempId = if ($row.parent_temp_id) { $row.parent_temp_id.Trim() } else { '' }

    if ([string]::IsNullOrWhiteSpace($parentTempId)) { $skipNoParent++; continue }
    if (-not $mapping.ContainsKey($tempId))           { continue }
    if (-not $mapping.ContainsKey($parentTempId))     { continue }

    $childNum  = $mapping[$tempId]
    $parentNum = $mapping[$parentTempId]

    Write-Host ("  Linking #{0} -> #{1}" -f $childNum, $parentNum) -ForegroundColor Gray

    $result = Invoke-GhWithRetry -Arguments @(
        'issue', 'edit', "$childNum",
        '--repo', $Repo,
        '--set-parent', "$parentNum"
    )

    if ($result.Success) {
        $linked++
    } else {
        # Detect unsupported sub-issues and stop trying (saves API calls)
        if ("$($result.Output)" -match 'not found|not supported|unknown flag') {
            Write-Host "    !! Sub-issues not supported in this repo — stopping linking." -ForegroundColor Red
            break
        }
        Write-Host ("    !! Failed: {0}" -f $result.Output) -ForegroundColor Red
        $linkFailed++
    }

    Start-Sleep -Milliseconds ([int]($Delay * 1000))
}

# ---- Summary ---------------------------------------------------------------
Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
Write-Host ("  Created:       {0}" -f $created)     -ForegroundColor Green
Write-Host ("  Reused:        {0}" -f $reused)      -ForegroundColor DarkYellow
Write-Host ("  Failed:        {0}" -f $failed)      -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host ("  Links:         {0}" -f $linked)      -ForegroundColor Green
Write-Host ("  Link failures: {0}" -f $linkFailed)  -ForegroundColor $(if ($linkFailed -gt 0) { 'Red' } else { 'Gray' })
Write-Host ("  Leaf nodes:    {0}" -f $skipNoParent) -ForegroundColor DarkGray
Write-Host ""