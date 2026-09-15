# Setup-Structure.ps1 — creates the folder structure and empty files
$dirs = @(
    "docs",
    "backlog",
    "backlog\epics",
    "backlog\csv",
    "backlog\scripts"
)

foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    Write-Host "  + $d" -ForegroundColor Gray
}

# Create placeholder files (contents come in later messages)
$files = @(
    "README.md",
    "docs\01-requirements.md",
    "docs\02-appendix-flows.md",
    "docs\03-database-schema.md",
    "docs\04-api-specification.md",
    "docs\05-integrations.md",
    "docs\06-business-logic.md",
    "backlog\README.md",
    "backlog\csv\tvde-backlog.csv",
    "backlog\scripts\csv-to-github.ps1",
    "backlog\scripts\setup-labels.ps1"
)

1..12 | ForEach-Object {
    $n = "{0:D2}" -f $_
    $files += "backlog\epics\EPIC-$n.md"
}

foreach ($f in $files) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType File -Path $f | Out-Null
        Write-Host "  + $f" -ForegroundColor DarkGray
    }
}

Write-Host "`nStructure created. Ready for file contents." -ForegroundColor Green