# TVDE Fleet Management Platform — Requirements Documentation

**Version:** 4.0 (Consolidated) · **Date:** 15 September 2026 · **Status:** Approved baseline for development

> This is the consolidated baseline. It supersedes all prior drafts (v1.0, v2.0, v2.1, v3.0).

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Confirmed Decisions](#2-confirmed-decisions)
3. [Legal & Regulatory Requirements](#3-legal--regulatory-requirements)
4. [Business Models](#4-business-models)
5. [System Architecture](#5-system-architecture)
6. [Database Schema](#6-database-schema)
7. [API Specification](#7-api-specification)
8. [Integration Specifications](#8-integration-specifications)
9. [Blazor Web Application](#9-blazor-web-application)
10. [.NET MAUI Driver Application](#10-net-maui-driver-application)
11. [Business Logic](#11-business-logic)
12. [Non-Functional Requirements](#12-non-functional-requirements)
13. [Development Roadmap](#13-development-roadmap)
14. [Deployment & Environments](#14-deployment--environments)
15. [Open Items](#15-open-items)

---

## 1. Project Overview

A single-tenant platform to manage a Portuguese TVDE (Transporte em Veículo Descaracterizado) fleet operating across three commercial models: vehicle rental, profit sharing, and salary-plus-commission. The platform handles regulatory compliance, driver management, trip revenue ingestion, expense and incident capture, automated billing, and manual payment processing with driver notification.

| Component | Technology | Purpose |
|---|---|---|
| Admin Web Application | Blazor | Fleet, driver, compliance, billing, analytics |
| Driver Mobile Application | .NET MAUI | Expense/incident logging, earnings, payment status |
| Backend API | ASP.NET Core (.NET 8+) | Business logic, integrations, persistence |
| Background Processing | Azure Functions | Scheduled syncs, alerts, billing, notifications |
| Telemetry Mock | ASP.NET Core minimal API | Mirrors the Mapon REST contract |
| Database | Azure SQL Database | Relational core + partitioned telemetry |

---

## 2. Confirmed Decisions

| Decision Area | Choice | Notes |
|---|---|---|
| API Framework | .NET 8+ (ASP.NET Core Web API) | |
| Web Application | Blazor | Admin, fleet manager, accountant |
| Driver Mobile App | .NET MAUI | iOS + Android |
| Telemetry Provider | Mapon API — mocked, API-faithful | Swap to real Mapon via config only |
| Database | SQL Server 2022 / Azure SQL | Partitioning + columnstore for telemetry |
| Background Jobs | Azure Functions | Timer, queue, and HTTP triggers |
| Caching | IMemoryCache | Single-instance; no Redis |
| Tenancy Model | Single-tenant | One operator per deployment |
| Payment Processing | Manual from report | Admin marks as paid; driver notified |
| Uber Integration | Mocked API | Mirrors Uber Driver API contract |
| Bolt Integration | Mocked CSV import | Mirrors Bolt Fleet export format |
| Video Recording | Out of scope | Deferred to future phase |
| Accounting Integration | Out of scope | Export/report only |

---

## 3. Legal & Regulatory Requirements

### 3.1 Operator Licensing

Applications to become a TVDE operator must be submitted electronically to the IMT (Institute for Mobility and Transport). A tacit approval system applies: if the IMT does not issue a decision within 30 working days of the fee being paid, the application is deemed approved. Licences are valid for a maximum of five years and can be renewed for equal periods. Any change affecting the requirements for accessing or carrying on the activity must be reported to the IMT within ten working days.

### 3.2 Vehicle Requirements

- **Maximum age:** 10 years, extended to 12 years for fully electric vehicles.
- **Annual roadworthiness inspections** and third-party liability insurance covering passengers are mandatory.
- **Non-removable identification sticker** with anti-fraud security features (holographic or equivalent) and a QR code, visible from outside and associated with the vehicle registration.
- **Loan-for-use and usufruct arrangements are prohibited** as a general rule.
- **Per-vehicle IMT registration** with validity of five years, renewable, never exceeding the operator licence validity.

### 3.3 Driver Certification (CMTVDE)

Drivers must hold a CMTVDE (Certificado de Motorista de Transporte em Veículo Descaracterizado), issued by the IMT, valid for five years and renewable for equal periods. Requirements:

- At least **50 hours of initial training** (theoretical and practical).
- **Compulsory final assessment** of 30 multiple-choice questions; pass mark 27/30.
- **At least 8 hours of continuing training** for renewal.
- **Functional command of Portuguese** demonstrated.
- **Criminal record certificate** required; for applicants who lived outside Portugal for six months or more in the previous five years, a certificate from that country is also required.

### 3.4 Insurance Requirements

Two distinct policies are mandatory:

1. **Motor third-party liability insurance** covering professional use of the vehicle for paid passenger transport. Minimum mandatory capital in 2026: bodily injury €6,450,000 per claim; property damage €1,300,000 per claim.
2. **Personal accident insurance for passengers**, providing compensation for death, permanent disability, or treatment expenses resulting from accidents during transport.

The absence of either policy can result in suspension or revocation of the operator licence, in addition to fines.

### 3.5 Platform Information Obligations

Digital platforms must provide, before and during each journey: route information, real-time tracking, vehicle details, and the method used to calculate the fare, including a breakdown of the total fare, the intermediation fee, and other relevant components. Electronic invoices must detail how the fare was calculated.

---

## 4. Business Models

| Feature | Model 1: Rental | Model 2: Profit Share | Model 3: Salary + Percentage |
|---|---|---|---|
| **Contract Type** | Contrato de Aluguer | Contrato de Prestação de Serviços | Contrato de Trabalho |
| **Driver Status** | Independent (Entrepreneur) | Independent (Service Provider) | Employee |
| **Remuneration** | Fixed weekly/monthly rental fee | % of net revenue (e.g. 45/55 split) | Base salary + % of net revenue |
| **Tax Withholding** | Driver invoices company | Company withholds IRS/IVA | Company withholds IRS + Social Security |
| **Social Security** | Driver responsible | Driver responsible | Employer + employee TSU (21.4% general regime) |
| **Core Modules** | Rental invoicing, asset depreciation | Settlement statements, revenue splits | Payroll, commission calc, payslips |
| **VAT (IVA)** | 6% reduced rate on transport | 6% reduced rate | 6% reduced rate |

---

## 5. System Architecture

### 5.1 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                          CLIENT APPLICATIONS                          │
│  ┌───────────────────────┐        ┌───────────────────────────────┐  │
│  │  Blazor Web App        │        │  .NET MAUI Driver App         │  │
│  │  Admin / Fleet Mgr /   │        │  iOS + Android                │  │
│  │  Accountant            │        │  Expenses, incidents, trips,  │  │
│  │                        │        │  earnings, payment status     │  │
│  └──────────┬────────────┘        └───────────────┬───────────────┘  │
└─────────────┼──────────────────────────────────────┼──────────────────┘
              │  HTTPS / JSON                        │  HTTPS / JSON
              ▼                                      ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    ASP.NET Core Web API (.NET 8+)                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐ │
│  │ Fleet    │ │ Driver   │ │Compliance│ │ Billing  │ │ Analytics  │ │
│  │ Mgmt     │ │ Mgmt     │ │ Engine   │ │ Engine   │ │ Service    │ │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └────────────┘ │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐ │
│  │ Trips &  │ │ Incidents│ │ Payments │ │ Export   │ │ Integration│ │
│  │ Earnings │ │&Complaints│ │ Service │ │ Service  │ │ Orchestr.  │ │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └────────────┘ │
│                                                                       │
│  IMemoryCache (Mapon snapshot, lookups, Mapon API key validation)    │
└───────────────┬──────────────────────────────────┬───────────────────┘
                │                                  │
                ▼                                  ▼
┌───────────────────────────────┐   ┌───────────────────────────────────┐
│   SQL Server / Azure SQL       │   │       Azure Functions             │
│  ┌──────────────────────────┐  │   │  ┌─────────────────────────────┐  │
│  │ Core relational schema    │  │   │  │ Timer: MaponSyncFunction    │  │
│  │ Telematics (partitioned)  │  │   │  │ Timer: UberSyncFunction     │  │
│  │ Columnstore for analytics │  │   │  │ Timer: ComplianceAlertsFn   │  │
│  │ Audit log                 │  │   │  │ Timer: BillingCycleFn       │  │
│  └──────────────────────────┘  │   │  │ Queue: NotifyDriverFn       │  │
└───────────────────────────────┘   │  │ Queue: PushNotificationFn   │  │
                                    │  └─────────────────────────────┘  │
                                    └───────────────────────────────────┘
```

### 5.2 Solution Structure

```
TvdeFleetManagement.sln
├── src/
│   ├── TvdeFleet.Api/                    # ASP.NET Core Web API
│   │   ├── Controllers/
│   │   ├── Middleware/
│   │   ├── Filters/
│   │   └── Program.cs
│   ├── TvdeFleet.Application/            # Services, DTOs, validators
│   │   ├── Services/
│   │   ├── Interfaces/
│   │   └── DTOs/
│   ├── TvdeFleet.Domain/                 # Entities, enums, value objects
│   │   ├── Entities/
│   │   ├── Enums/
│   │   └── Specifications/
│   ├── TvdeFleet.Infrastructure/         # EF Core, repos, integrations
│   │   ├── Persistence/
│   │   │   ├── AppDbContext.cs
│   │   │   ├── Configurations/
│   │   │   └── Migrations/
│   │   ├── Caching/
│   │   │   └── MemoryCacheService.cs
│   │   ├── Integrations/
│   │   │   ├── Uber/                     # Mocked API client
│   │   │   ├── Bolt/                     # CSV importer
│   │   │   └── Mapon/
│   │   │       ├── IMaponClient.cs
│   │   │       ├── MaponClient.cs
│   │   │       ├── MaponOptions.cs
│   │   │       └── Dtos/
│   │   └── Messaging/
│   ├── TvdeFleet.Functions/              # Azure Functions app
│   │   ├── TimerTriggers/
│   │   │   ├── MaponSyncFunction.cs
│   │   │   ├── UberSyncFunction.cs
│   │   │   ├── ComplianceAlertFunction.cs
│   │   │   └── BillingCycleFunction.cs
│   │   ├── QueueTriggers/
│   │   │   ├── NotifyDriverFunction.cs
│   │   │   └── PushNotificationFunction.cs
│   │   ├── Shared/
│   │   │   └── FunctionServiceFactory.cs
│   │   ├── host.json
│   │   └── local.settings.json
│   ├── TvdeFleet.MaponMock/              # Standalone mock server
│   │   ├── Program.cs
│   │   ├── Endpoints/
│   │   ├── Auth/
│   │   ├── Data/
│   │   └── Simulation/
│   ├── TvdeFleet.Blazor/                 # Admin web application
│   │   ├── Components/
│   │   ├── Pages/
│   │   └── Services/
│   └── TvdeFleet.Maui/                   # Driver mobile application
│       ├── Views/
│       ├── ViewModels/
│       ├── Services/
│       └── Platforms/
└── tests/
    ├── TvdeFleet.UnitTests/
    ├── TvdeFleet.IntegrationTests/
    └── TvdeFleet.ContractTests/
```

### 5.3 Technology Stack

| Layer | Technology |
|---|---|
| API | ASP.NET Core Web API (.NET 8+) |
| Web UI | Blazor Server |
| Mobile UI | .NET MAUI |
| Background Jobs | Azure Functions (.NET 8 isolated worker) |
| ORM | Entity Framework Core |
| Database | SQL Server 2022 / Azure SQL Database |
| Caching | IMemoryCache (in-process) |
| Messaging | Azure Storage Queues |
| Auth | JWT Bearer |
| Logging | Serilog → Seq / Application Insights |
| Mapping | AutoMapper |
| Validation | FluentValidation |
| CSV Parsing | CsvHelper |
| HTTP Resilience | Polly |
| Push Notifications | Azure Notification Hubs |

### 5.4 Key NuGet Packages

`Microsoft.EntityFrameworkCore.SqlServer`, `Microsoft.AspNetCore.Authentication.JwtBearer`, `Microsoft.Azure.Functions.Worker`, `Microsoft.Azure.Functions.Worker.Extensions.Timer`, `Microsoft.Azure.Functions.Worker.Extensions.Storage.Queues`, `Azure.Storage.Queues`, `Serilog.AspNetCore`, `FluentValidation`, `AutoMapper`, `Polly`, `CsvHelper`, `Microsoft.Extensions.Caching.Memory`, `Microsoft.Maui.Controls`.

### 5.5 Caching Strategy (In-Memory)

`IMemoryCache` is registered as a singleton and injected into application services. The cache is per-instance; since this is a single-tenant deployment with the API running in a single App Service instance, this is acceptable.

| Cache Entry | TTL | Invalidation |
|---|---|---|
| Mapon units snapshot (live map) | 30 seconds | Absolute expiry |
| Mapon unit data | 60 seconds | Absolute expiry |
| Vehicle makes/models lookup | 24 hours | Absolute expiry |
| Statuses / enums | 24 hours | Absolute expiry |
| User permissions (per session) | 5 minutes | Absolute expiry |
| Analytics aggregates (fleet overview) | 5 minutes | Absolute expiry |

> **Note:** If the API is later scaled to multiple instances, cached values become per-instance. At that point, introduce a distributed cache (Azure Cache for Redis) behind the same `ICacheService` abstraction — no application code changes required.

### 5.6 Azure Functions — Role & Design

Azure Functions handle all scheduled and asynchronous work. The API is stateless and never runs long-running tasks inline.

| Function | Trigger | Schedule / Source | Purpose |
|---|---|---|---|
| `MaponSyncFunction` | Timer | Every 5 minutes | Pull units, unit data, and routes from Mapon |
| `UberSyncFunction` | Timer | Every 15 minutes | Pull payments from Uber mock API |
| `ComplianceAlertFunction` | Timer | Daily at 06:00 WET | Scan compliance expiries; raise alerts |
| `BillingCycleFunction` | Timer | Weekly, Monday 00:00 | Generate billing cycles for active contracts |
| `RatingSyncFunction` | Timer | Daily at 02:00 | Pull driver ratings from platform mocks |
| `NotifyDriverFunction` | Queue | `driver-notifications` | Send payment/compliance notifications |
| `PushNotificationFunction` | Queue | `push-notifications` | Deliver push via Azure Notification Hubs |

**Function App configuration:**

- **Hosting plan:** Premium (EP1) recommended for reliable timer execution.
- **Runtime:** .NET 8 isolated worker model.
- **Storage:** Azure Storage account for queue triggers and timer state.
- **Configuration:** Sourced from Key Vault via managed identity.
- **Shared code:** References `TvdeFleet.Application` and `TvdeFleet.Infrastructure`.

**Sample — `MaponSyncFunction`:**

```csharp
public class MaponSyncFunction
{
    private readonly IMaponClient _mapon;
    private readonly ITelematicsStore _store;
    private readonly ILogger<MaponSyncFunction> _logger;

    public MaponSyncFunction(IMaponClient mapon, ITelematicsStore store, ILogger<MaponSyncFunction> logger)
    {
        _mapon = mapon;
        _store = store;
        _logger = logger;
    }

    [Function("MaponSyncFunction")]
    public async Task Run([TimerTrigger("0 */5 * * * *")] TimerInfo timer, CancellationToken ct)
    {
        _logger.LogInformation("Mapon sync started at {Time}", DateTime.UtcNow);

        var units = await _mapon.GetUnitsAsync(ct);
        await _store.UpsertLatestPositionsAsync(units, ct);

        var ids = units.Select(u => u.UnitId).ToList();
        var data = await _mapon.GetUnitDataAsync(ids, ct);
        await _store.UpsertUnitDataAsync(data, ct);

        var yesterday = DateTime.UtcNow.AddDays(-1);
        foreach (var id in ids)
        {
            var routes = await _mapon.GetRoutesAsync(id, yesterday, DateTime.UtcNow, ct);
            await _store.UpsertRoutesAsync(id, routes, ct);
        }

        _logger.LogInformation("Mapon sync completed: {Count} units", units.Count);
    }
}
```

---

## 6. Database Schema

See `docs/03-database-schema.md` for the full schema. Summary of conventions:

| Concern | Convention |
|---|---|
| Primary keys | `UNIQUEIDENTIFIER` with `DEFAULT NEWSEQUENTIALID()` |
| Timestamps | `DATETIME2(3)` storing UTC |
| Booleans | `BIT` |
| JSON payloads | `NVARCHAR(MAX)` with `ISJSON` check |
| Enums | `VARCHAR(30)` with `CHECK` constraint |
| Money | `DECIMAL(12,2)` or `DECIMAL(10,2)` |
| Telemetry | Partitioned by month + columnstore index |

---

## 7. API Specification

See `docs/04-api-specification.md` for the full API reference. All endpoints prefixed with `/api/v1`.

---

## 8. Integration Specifications

See `docs/05-integrations.md`.

- **Uber** — mocked API mirroring the Uber Driver API payments endpoint
- **Bolt** — mocked CSV import based on Bolt Fleet Manager Portal export
- **Mapon** — API-faithful mock server, config-swappable to real Mapon

---

## 9. Blazor Web Application

### 9.1 Hosting Model

Recommended: **Blazor Server** for the admin console — smaller initial download, faster iteration for internal users, simplified authentication integration with the ASP.NET Core API.

### 9.2 Pages

| Page / Component | Description |
|---|---|
| Dashboard | Fleet KPIs, revenue summary, compliance alerts, Mapon live map |
| Vehicles / List | Vehicle list with status, make/model, compliance expiry, Mapon sync state |
| Vehicles / Detail | Full profile, telematics history, expenses, incidents, assignments |
| Vehicles / Comparison | Side-by-side make/model analytics (TCO, revenue/km, rating) |
| Drivers / List | Driver list with status, CMTVDE expiry, average rating |
| Drivers / Detail | Profile, compliance docs, trips, earnings, incidents, complaints |
| Contracts / List | Active contracts with business model indicator |
| Contracts / Detail | Contract terms, billing cycles, payment history |
| Billing / Cycles | Generate, review, approve billing cycles |
| Billing / Payments | Pending/paid payments, mark-as-paid, driver notification |
| Compliance / Alerts | All upcoming expiries (vehicles + drivers) |
| Incidents / List | Reported incidents with status, severity, at-fault flag |
| Complaints / List | Customer complaints with resolution and penalty tracking |
| Analytics / Fleet | Revenue, costs, utilisation, revenue/km by vehicle |
| Analytics / Drivers | Driver ranking, rating trends, earnings breakdown |
| Reports / Financial | Revenue/expense summary, export for accountant |
| Reports / Tax | IVA/IRS data export |
| Settings / Mapon | Mapon base URL, API key, sync interval, unit mapping status |
| Settings / Users | User management (admin only) |

### 9.3 Live Map Component

Use Leaflet or OpenLayers via JS interop. For Blazor Server, initialise the map once and push updates over SignalR. The API serves `/telematics/vehicles` from `IMemoryCache` with a 30-second TTL.

---

## 10. .NET MAUI Driver Application

### 10.1 Features

| Feature | Description | API Endpoint |
|---|---|---|
| Login | JWT-based auth | `POST /auth/login` |
| My Vehicle | Assigned vehicle details, status | `GET /vehicles/{id}` |
| Trip List | Today's trips with earnings | `GET /trips?driverId=X&date=Y` |
| Log Expense | Photo capture, GPS auto-capture, category | `POST /expenses` |
| Report Incident | Photo capture, GPS, severity, description | `POST /incidents` |
| My Earnings | Current billing cycle summary | `GET /earnings/summary` |
| Payment Status | Payment history, paid indicator | `GET /payments/driver/{id}` |
| Compliance Docs | View CMTVDE, insurance, expiry warnings | `GET /drivers/{id}/compliance` |
| Notifications | Payment & compliance alerts | Push via Azure Notification Hubs |

### 10.2 Project Structure

```
TvdeFleet.Maui/
├── Views/
│   ├── LoginPage.xaml
│   ├── DashboardPage.xaml
│   ├── TripListPage.xaml
│   ├── LogExpensePage.xaml
│   ├── ReportIncidentPage.xaml
│   ├── EarningsPage.xaml
│   └── PaymentHistoryPage.xaml
├── ViewModels/
├── Services/
│   ├── ApiService.cs
│   ├── AuthService.cs
│   ├── LocationService.cs
│   └── NotificationService.cs
└── Platforms/
    ├── Android/
    └── iOS/
```

### 10.3 Payment Notification Flow

```
1. Admin marks payment as "paid" in Blazor webapp
       │
       ▼
2. API updates payment_records.status = 'paid'
       │
       ▼
3. API enqueues a message to the "driver-notifications" queue
       │
       ▼
4. NotifyDriverFunction (queue trigger) picks up the message
       │
       ▼
5. Azure Notification Hubs delivers the push to the MAUI app
       │
       ▼
6. MAUI app receives notification → updates PaymentHistoryPage
       │
       ▼
7. Driver sees: "Payment of €504.20 processed on 15/09/2026"
```

### 10.4 Offline Capability

The app supports offline expense and incident logging: entries stored locally (SQLite), synchronised when connectivity is restored. GPS coordinates and photos captured at creation and queued for upload.

---

## 11. Business Logic

See `docs/06-business-logic.md`.

Highlights:

- **Compliance Alert Engine** — daily scan, 30/15/7-day thresholds
- **Penalty & Bonus Engine** — complaints, at-fault accidents, rating thresholds, perfect-rating bonus
- **Vehicle Performance Ranking** — weighted score using revenue/km, rating, cost/km, complaints
- **Manual Payment Workflow** — generate, approve, transfer, mark-paid, notify

---

## 12. Non-Functional Requirements

| Requirement | Specification |
|---|---|
| **Performance** | API response < 200 ms (p95) for standard queries |
| **Scalability** | 500+ vehicles, 1,000+ drivers, 100k+ trips/month |
| **Availability** | 99.5% uptime during business hours (06:00–23:00 WET) |
| **Data retention** | Telematics: 24 months (partition switching); financial: 10 years |
| **Security** | JWT auth, RBAC, TLS 1.3, GDPR-compliant |
| **Audit** | All financial mutations logged with before/after values |
| **Localisation** | Portuguese (pt-PT) and English |
| **Mobile** | Offline-capable expense logging; GPS auto-capture |
| **Resilience** | Polly retries on Mapon, Uber, Bolt; circuit breaker |
| **Observability** | Serilog, health endpoint, Application Insights |
| **Caching** | IMemoryCache (single-instance) |

---

## 13. Development Roadmap

| Phase | Scope | Duration |
|---|---|---|
| **Phase 1** | .NET solution, EF Core + SQL Server, auth, CRUD | 4 weeks |
| **Phase 2** | Compliance engine, document management, alerts | 3 weeks |
| **Phase 3** | Uber mock + Bolt CSV import, expense tracking | 3 weeks |
| **Phase 4** | Mapon mock server + `MaponClient` + contract tests | 2 weeks |
| **Phase 5** | Billing engine (3 models), penalty/bonus, payments | 4 weeks |
| **Phase 6** | Blazor dashboard, comparison, reports, live map | 4 weeks |
| **Phase 7** | MAUI driver app, push notifications, offline sync | 4 weeks |
| **Phase 8** | Tax export (IVA/IRS), testing, UAT, swap validation | 3 weeks |

**Total:** ~27 weeks with a team of 3–4 .NET developers.

---

## 14. Deployment & Environments

| Environment | Mapon BaseUrl | Notes |
|---|---|---|
| **Local dev** | `http://localhost:5100/api/v1/` | Mock server via `dotnet run` or Docker |
| **CI** | `http://mapon-mock:5100/api/v1/` | Mock server as a pipeline service |
| **Staging** | Mock server alongside API | For UAT — realistic but isolated |
| **Production** | `https://www.mapon.com/api/v1/` | Real Mapon API key from Key Vault |

### Deployment Targets

| Component | Recommendation |
|---|---|
| API hosting | Azure App Service (Linux, .NET 8) |
| Blazor hosting | Same App Service (Blazor Server) |
| Functions hosting | Azure Functions Premium plan (EP1) |
| Database | Azure SQL Database |
| Queue storage | Azure Storage account |
| Push Notifications | Azure Notification Hubs |
| Secrets | Azure Key Vault (managed identity) |
| CI/CD | GitHub Actions or Azure DevOps |
| Logging | Serilog → Application Insights |

---

## 15. Open Items

| # | Item | Status |
|---|---|---|
| 1 | Multi-operator support | ❌ Out of scope |
| 2 | Telemetry provider | ✅ Mapon API — mocked |
| 3 | Payment gateway | ✅ Manual bank transfer |
| 4 | Video recording | ❌ Deferred |
| 5 | Accounting integration | ❌ Out of scope |
| 6 | Real Mapon API key | ⏳ Pending |
| 7 | Push notification provider | ⏳ Notification Hubs vs Firebase |
| 8 | Driver IBAN storage | ⏳ GDPR basis to confirm |
| 9 | Blazor hosting model | ⏳ Server vs WASM |
| 10 | Vehicle portfolio baseline | ⏳ Confirm fleet list |
| 11 | Azure Functions plan | ⏳ Premium EP1 vs Consumption |
| 12 | SQL Server edition | ⏳ Azure SQL vs on-prem |

---

*End of requirements document — v4.0 Consolidated Baseline.*