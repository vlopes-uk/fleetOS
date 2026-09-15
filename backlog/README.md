# TVDE Backlog

Epic → Feature → Story → Task hierarchy for the TVDE Fleet Management Platform.

## Structure

```
backlog/
├── README.md                <- this file
├── csv/
│   └── tvde-backlog.csv     <- import-ready CSV
├── epics/                   <- one markdown file per Epic
│   ├── EPIC-01.md
│   ├── EPIC-02.md
│   └── ... (12 total)
└── scripts/
    ├── csv-to-github.ps1
    └── setup-labels.ps1
```

## Counts

| Level | Count |
|---|---|
| Epics | 12 |
| Features | 40 |
| User Stories | 45 |
| Tasks | 180 |
| **Total issues** | **277** |

## How to Import to GitHub

### Prerequisites

```powershell
# Install GitHub CLI (once)
winget install --id GitHub.cli -e
# Close and reopen PowerShell

# Authenticate with required scopes
gh auth login
gh auth refresh -s repo,project,read:org

# Verify
gh --version
```

### Step 1 — Create labels

```powershell
cd scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup-labels.ps1 -Repo "your-org/your-repo"
```

### Step 2 — Import the backlog

```powershell
.\csv-to-github.ps1 -CsvFile ..\csv\tvde-backlog.csv -Repo "your-org/your-repo"
```

If you hit rate limits, increase the delay:

```powershell
.\csv-to-github.ps1 -CsvFile ..\csv\tvde-backlog.csv -Repo "your-org/your-repo" -Delay 3
```

### Step 3 — Verify

```powershell
gh issue list --repo your-org/your-repo --type Epic
gh issue list --repo your-org/your-repo --label "module: billing"
gh issue view <epic-number> --repo your-org/your-repo
```

## Issue Types

The CSV uses GitHub Issue Types (Epic, Feature, Story, Task). These must be configured at the **organization level**. If your repo is under a personal account:

1. Open the CSV and delete the `type` column.
2. The `type: epic` / `type: feature` labels will carry the classification instead.

To create issue types at the org level, an org admin runs:

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/orgs/{org}/issue-types \
  -d '{"name":"Epic","description":"Large body of work","color":"purple","is_enabled":true}'
```

Repeat for `Feature`, `Story`, `Task`.

## Labels

Every label referenced in the CSV must exist before import. The `setup-labels.ps1` script creates all of them:

**Type labels:** `type: epic`, `type: feature`, `type: story`, `type: task`

**Module labels:** `module: core`, `module: auth`, `module: fleet`, `module: drivers`, `module: trips`, `module: telemetry`, `module: billing`, `module: payments`, `module: incidents`, `module: analytics`, `module: mobile`, `module: compliance`, `module: settings`

**Priority labels:** `priority: critical`, `priority: high`, `priority: medium`, `priority: low`

## Regenerating the CSV

The CSV is the source of truth for import. The per-epic markdown files under `epics/` are human-readable mirrors of the same content. If you edit the markdown, update the CSV accordingly before re-importing.

## Rate Limits

Creating 277 issues plus linking them takes roughly 15–20 minutes at 1.5s delay per call. If you hit `429 Too Many Requests`, the script retries automatically with exponential backoff (up to 5 attempts per issue). Increase `-Delay` if needed.

## Structure of the CSV

| Column | Purpose |
|---|---|
| `temp_id` | Unique identifier used only during import to resolve parents |
| `title` | Issue title |
| `type` | Epic / Feature / Story / Task |
| `body` | Short description |
| `labels` | Comma-separated labels |
| `parent_temp_id` | Reference to parent's `temp_id` (blank for Epics) |