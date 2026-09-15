<#
.SYNOPSIS
    Links parent-child relationships for the TVDE backlog using the GitHub REST API.
.DESCRIPTION
    Standalone script. Uses POST /repos/{owner}/{repo}/issues/{parent}/sub_issues.
    Idempotent: if a child already has a parent (HTTP 422), it is counted as
    "already linked" and skipped rather than aborting the run.

    Accepts Repo as "owner/repo", full URL, or git remote URL.

    Pure ASCII - safe to save as UTF-8 without BOM or Windows-1252.
.PARAMETER CsvFile
    Path to the backlog CSV. Defaults to ..\csv\tvde-backlog.csv.
.PARAMETER Repo
    Target repository. Accepts owner/repo, https URL, or git@ URL. Required.
.PARAMETER MappingFile
    Path to import-mapping.json produced by csv-to-github.ps1.
    Defaults to import-mapping.json in this script's folder.
.PARAMETER Delay
    Seconds between API calls. Default 1.0.
.PARAMETER ConflictsFile
    Where to write the list of conflicts (children that already had a parent).
    Defaults to link-conflicts.json in the script folder.
.EXAMPLE
    .\link-backlog.ps1 -Repo "vlopes-uk/fleetOS"
.EXAMPLE
    .\link-backlog.ps1 -Repo "https://github.com/vlopes-uk/fleetOS" -Delay 0.5
#>

[CmdletBinding()]
param(
    [string]$CsvFile = '',
    [Parameter(Mandatory = $true)]
    [string]$Repo,
    [string]$MappingFile = '',
    [double]$Delay = 1.0,
    [string]$ConflictsFile = ''
)

$ErrorActionPreference = 'Stop'

# ---- Normalise Repo parameter ----------------------------------------------
$Repo = $Repo.Trim().TrimEnd('/')
if ($Repo -match 'github\.com[:/]([^/]+)/([^/]+?)(\.git)?$') {
    $Repo = "$($Matches[1])/$($Matches[2])"
}
if ($Repo -notmatch '^[^/]+/[^/]+$') {
    Write-Host "Invalid -Repo value: '$Repo'" -ForegroundColor Red
    Write-Host "Expected format: owner/repo (e.g. vlopes-uk/fleetOS)" -ForegroundColor Yellow
    exit 1
}
Write-Host "Using repo: $Repo" -ForegroundColor DarkGray

# ---- Resolve script directory ----------------------------------------------
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
if ([string]::IsNullOrWhiteSpace($MappingFile)) {
    $MappingFile = Join-Path $scriptDir 'import-mapping.json'
}
if ([string]::IsNullOrWhiteSpace($ConflictsFile)) {
    $ConflictsFile = Join-Path $scriptDir 'link-conflicts.json'
}

# ---- Verify prerequisites --------------------------------------------------
try {
    $ghRaw = (gh --version | Select-Object -First 1)
    Write-Host "gh CLI: $ghRaw" -ForegroundColor DarkGray
}
catch {
    Write-Host "gh CLI not found. Install with: winget install --id GitHub.cli -e" -ForegroundColor Red
    exit 1
}

Write-Host "Verifying access to $Repo..." -ForegroundColor Cyan
gh repo view $Repo --json name 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Cannot access $Repo." -ForegroundColor Red
    exit 1
}

# ---- Load CSV --------------------------------------------------------------
if (-not (Test-Path $CsvFile)) {
    Write-Host "CSV not found: $CsvFile" -ForegroundColor Red
    exit 1
}
$csvPath = (Resolve-Path $CsvFile).Path
Write-Host "Loading $csvPath..." -ForegroundColor Cyan

$rows = Import-Csv -Path $csvPath
if ($rows.Count -eq 0) {
    Write-Host "CSV has no rows." -ForegroundColor Red
    exit 1
}

$pairs = @()
foreach ($row in $rows) {
    $child  = $row.temp_id.Trim()
    $parent = if ($row.parent_temp_id) { $row.parent_temp_id.Trim() } else { '' }
    if ([string]::IsNullOrWhiteSpace($parent)) { continue }
    $pairs += [PSCustomObject]@{ Child = $child; Parent = $parent }
}

Write-Host ("Found {0} parent-child pairs to link." -f $pairs.Count) -ForegroundColor Cyan
Write-Host ""

if ($pairs.Count -eq 0) {
    Write-Host "Nothing to link. Exiting." -ForegroundColor Yellow
    exit 0
}

# ---- Build temp_id to issue number mapping ---------------------------------
$mapping = @{}

if (Test-Path $MappingFile) {
    Write-Host "Loading mapping from $MappingFile..." -ForegroundColor Cyan
    try {
        $mapJson = Get-Content $MappingFile -Raw | ConvertFrom-Json
        foreach ($entry in $mapJson) {
            $mapping[$entry.temp_id] = [int]$entry.number
        }
        Write-Host ("  Loaded {0} entries." -f $mapping.Count) -ForegroundColor DarkGray
    }
    catch {
        Write-Host "  Could not parse mapping file. Will fall back to title lookup." -ForegroundColor DarkYellow
    }
}

$missingTempIds = $pairs | Where-Object { -not $mapping.ContainsKey($_.Child) -or -not $mapping.ContainsKey($_.Parent) } |
    ForEach-Object { $_.Child; $_.Parent } | Select-Object -Unique

if ($missingTempIds.Count -gt 0) {
    Write-Host ("Resolving {0} temp_ids via title lookup..." -f $missingTempIds.Count) -ForegroundColor DarkGray

    $titleByTempId = @{}
    foreach ($row in $rows) {
        $titleByTempId[$row.temp_id.Trim()] = $row.title.Trim()
    }

    $allIssuesJson = gh issue list --repo $Repo --state all --limit 5000 --json number,title 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $allIssuesJson) {
        Write-Host "Could not fetch issues for title lookup." -ForegroundColor Red
        exit 1
    }
    $allIssues = $allIssuesJson | ConvertFrom-Json
    $titleToNumber = @{}
    foreach ($issue in $allIssues) {
        $titleToNumber[$issue.title] = [int]$issue.number
    }

    foreach ($tempId in $missingTempIds) {
        if ($mapping.ContainsKey($tempId)) { continue }
        $title = $titleByTempId[$tempId]
        if ($title -and $titleToNumber.ContainsKey($title)) {
            $mapping[$tempId] = $titleToNumber[$title]
        }
    }
}

Write-Host ("Mapping resolved: {0} entries total." -f $mapping.Count) -ForegroundColor Cyan
Write-Host ""

# ---- Issue number to database id cache -------------------------------------
$dbIdCache = @{}

function Get-IssueDatabaseId {
    param([int]$Number)

    if ($dbIdCache.ContainsKey($Number)) {
        return $dbIdCache[$Number]
    }

    # Suppress stderr-as-error behaviour for native calls
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    $idJson = gh api "repos/$Repo/issues/$Number" --jq '.id' 2>$null

    $ErrorActionPreference = $prevEAP

    if ($LASTEXITCODE -ne 0 -or -not $idJson) {
        return $null
    }

    $id = [int64]$idJson.Trim()
    $dbIdCache[$Number] = $id
    return $id
}

# ---- Link loop -------------------------------------------------------------
Write-Host "=== Linking parent-child relationships ===" -ForegroundColor Yellow
Write-Host ""

$linked        = 0
$alreadyLinked = 0
$skipped       = 0
$failed        = 0

$conflicts = @()

$total = $pairs.Count
$index = 0

foreach ($pair in $pairs) {
    $index++
    $childTemp  = $pair.Child
    $parentTemp = $pair.Parent

    $prefix = "  [{0,3}/{1,3}]" -f $index, $total

    if (-not $mapping.ContainsKey($childTemp)) {
        Write-Host ("{0} SKIP  {1} (child not found in repo)" -f $prefix, $childTemp) -ForegroundColor DarkYellow
        $skipped++
        continue
    }
    if (-not $mapping.ContainsKey($parentTemp)) {
        Write-Host ("{0} SKIP  {1} (parent {2} not found)" -f $prefix, $childTemp, $parentTemp) -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    $childNum  = $mapping[$childTemp]
    $parentNum = $mapping[$parentTemp]

    $childDbId = Get-IssueDatabaseId -Number $childNum
    if (-not $childDbId) {
        Write-Host ("{0} FAIL  #{1} ({2}) - could not fetch database id" -f $prefix, $childNum, $childTemp) -ForegroundColor Red
        $failed++
        Start-Sleep -Milliseconds ([int]($Delay * 1000))
        continue
    }

    Write-Host ("{0} {1} (#{2}) -> {3} (#{4})" -f $prefix, $childTemp, $childNum, $parentTemp, $parentNum) -ForegroundColor Gray

    $apiPath = "repos/$Repo/issues/$parentNum/sub_issues"
    $body = "{`"sub_issue_id`":$childDbId}"

    # Suppress Stop-on-stderr so 422s can be caught and handled below
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    $output = $body | gh api $apiPath --method POST --input - 2>&1
    $exitCode = $LASTEXITCODE

    $ErrorActionPreference = $prevEAP

    if ($exitCode -eq 0) {
        Write-Host "       -> linked" -ForegroundColor DarkGreen
        $linked++
    }
    elseif ("$output" -match '422|already|Validation Failed|may only have one parent') {
        Write-Host ("       -> SKIP #{0} (already has a parent)" -f $childNum) -ForegroundColor DarkYellow
        $alreadyLinked++
        $conflicts += [PSCustomObject]@{
            ChildTempId  = $childTemp
            ChildNumber  = $childNum
            ParentTempId = $parentTemp
            ParentNumber = $parentNum
            Reason       = 'already has a parent'
        }
    }
    elseif ("$output" -match 'rate limit|429') {
        Write-Host "       !! rate limited, waiting 60s" -ForegroundColor DarkYellow
        Start-Sleep -Seconds 60

        $prevEAP2 = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $output = $body | gh api $apiPath --method POST --input - 2>&1
        $retryExit = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP2

        if ($retryExit -eq 0) {
            Write-Host "       -> linked (retry)" -ForegroundColor DarkGreen
            $linked++
        }
        elseif ("$output" -match '422|already|may only have one parent') {
            Write-Host ("       -> SKIP #{0} (already has a parent, retry)" -f $childNum) -ForegroundColor DarkYellow
            $alreadyLinked++
            $conflicts += [PSCustomObject]@{
                ChildTempId  = $childTemp
                ChildNumber  = $childNum
                ParentTempId = $parentTemp
                ParentNumber = $parentNum
                Reason       = 'already has a parent (retry)'
            }
        }
        else {
            Write-Host ("       !! failed on retry: {0}" -f $output) -ForegroundColor Red
            $failed++
        }
    }
    else {
        Write-Host ("       !! failed: {0}" -f $output) -ForegroundColor Red
        $failed++
    }

    Start-Sleep -Milliseconds ([int]($Delay * 1000))
}

# ---- Write conflict report -------------------------------------------------
if ($conflicts.Count -gt 0) {
    $conflicts | ConvertTo-Json -Depth 3 | Out-File -FilePath $ConflictsFile -Encoding UTF8
    Write-Host ""
    Write-Host ("Conflict report written to {0}" -f $ConflictsFile) -ForegroundColor DarkGray
}

# ---- Summary ---------------------------------------------------------------
Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
Write-Host ("  Linked:         {0}" -f $linked)        -ForegroundColor Green
Write-Host ("  Already linked: {0}" -f $alreadyLinked) -ForegroundColor DarkYellow
Write-Host ("  Skipped:        {0}" -f $skipped)       -ForegroundColor DarkYellow
Write-Host ("  Failed:         {0}" -f $failed)        -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Gray' })
Write-Host ""

if ($conflicts.Count -gt 0) {
    Write-Host "Conflicting children (already had a parent):" -ForegroundColor Yellow
    $conflicts | Format-Table ChildTempId, ChildNumber, ParentTempId, ParentNumber -AutoSize |
        Out-String -Width 200 | Write-Host
}

if ($failed -eq 0) {
    Write-Host "Verify with:" -ForegroundColor Cyan
    Write-Host ("  gh issue list --repo {0} --label 'type: epic'" -f $Repo) -ForegroundColor Gray
    Write-Host ("  gh issue view <epic-number> --repo {0}" -f $Repo) -ForegroundColor Gray
    exit 0
}
else {
    Write-Host "Some links failed. Re-run the script - already-linked pairs are skipped." -ForegroundColor Yellow
    exit 1
}