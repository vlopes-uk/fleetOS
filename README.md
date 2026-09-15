# TVDE Fleet Management Platform — Documentation

**Version:** 4.0 (Consolidated)
**Date:** 15 September 2026
**Status:** Approved baseline for development

Single-tenant platform to manage a Portuguese TVDE fleet across three commercial models: vehicle rental, profit sharing, and salary-plus-commission.

## Contents

| Path | Description |
|---|---|
| `docs/01-requirements.md` | Full requirements documentation (v4.0) |
| `docs/02-appendix-flows.md` | Mermaid flow diagrams |
| `docs/03-database-schema.md` | SQL Server schema (tables, indexes, partitions) |
| `docs/04-api-specification.md` | REST API endpoints |
| `docs/05-integrations.md` | Uber mock, Bolt CSV, Mapon mock specs |
| `docs/06-business-logic.md` | Billing, penalty engine, workflows |
| `backlog/README.md` | Backlog structure and GitHub import guide |
| `backlog/epics/*.md` | 12 Epic files with features, stories, tasks |
| `backlog/csv/tvde-backlog.csv` | CSV ready for GitHub import |
| `backlog/scripts/csv-to-github.ps1` | PowerShell importer |
| `backlog/scripts/setup-labels.ps1` | One-time label setup |

## Tech Stack Summary

| Layer | Choice |
|---|---|
| API | ASP.NET Core (.NET 8+) |
| Web | Blazor Server |
| Mobile | .NET MAUI |
| Database | SQL Server 2022 / Azure SQL |
| Background Jobs | Azure Functions (.NET 8 isolated) |
| Cache | IMemoryCache (in-process) |
| Telemetry | Mapon API — mocked, API-faithful |
| Tenancy | Single-tenant |
| Payments | Manual from report |
| Video Recording | Out of scope |
| Accounting Integration | Out of scope |

## Quick Start

### Review the documentation

Start with `docs/01-requirements.md`, then read the appendices in order:

1. `docs/02-appendix-flows.md` — how the system behaves
2. `docs/03-database-schema.md` — the data model
3. `docs/04-api-specification.md` — the API surface
4. `docs/05-integrations.md` — external integrations
5. `docs/06-business-logic.md` — billing and rules

### Import the backlog to GitHub

```powershell
# Install GitHub CLI (once)
winget install --id GitHub.cli -e
# Close and reopen PowerShell

# Authenticate
gh auth login
gh auth refresh -s repo,project,read:org

# Create labels (once per repo)
cd backlog\scripts
.\setup-labels.ps1 -Repo "your-org/your-repo"

# Import the backlog
.\csv-to-github.ps1 -CsvFile ..\csv\tvde-backlog.csv -Repo "your-org/your-repo"
```

See `backlog/README.md` for full instructions.

## Repository Structure

```
.
├── README.md                        <- this file
├── .gitignore
├── docs/
│   ├── 01-requirements.md
│   ├── 02-appendix-flows.md
│   ├── 03-database-schema.md
│   ├── 04-api-specification.md
│   ├── 05-integrations.md
│   └── 06-business-logic.md
└── backlog/
    ├── README.md
    ├── csv/
    │   └── tvde-backlog.csv
    ├── epics/
    │   ├── EPIC-01.md
    │   ├── EPIC-02.md
    │   └── ... (12 total)
    └── scripts/
        ├── csv-to-github.ps1
        └── setup-labels.ps1
```

## Key Legal Context (Portugal)

This platform supports a TVDE (Transporte em Veículo Descaracterizado) operation, which is subject to Portuguese Law No. 45/2018 and the 2026 amendments (Law No. 59/2026). Key requirements:

- Operator licensing through the IMT (tacit approval after 30 working days)
- Per-vehicle IMT registration (5-year validity, renewable)
- Driver CMTVDE certification (5-year validity, renewable)
- Two mandatory insurance policies: motor third-party liability and passenger personal accident
- Minimum mandatory insurance capital in 2026: €6,450,000 bodily injury / €1,300,000 property damage

See `docs/01-requirements.md` §3 for full detail.

## Version History

| Version | Date | Changes |
|---|---|---|
| 1.0 | 2026-09-15 | Initial (Node.js/Python, React/Vue, React Native) |
| 2.0 | 2026-09-15 | .NET/Blazor/MAUI, Mapon real integration |
| 2.1 | 2026-09-15 | Mapon switched to API-faithful mock |
| 3.0 | 2026-09-15 | Consolidated baseline |
| 4.0 | 2026-09-15 | SQL Server, Azure Functions, IMemoryCache |

## License

Internal — not for public distribution.