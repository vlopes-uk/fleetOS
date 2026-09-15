<#
.SYNOPSIS
    Generates the 12 epic markdown files under backlog/epics/.
.DESCRIPTION
    Each epic file contains its features, stories, and tasks as rendered from
    the same data that drives the backlog CSV. Re-run safely — files are
    overwritten.
.EXAMPLE
    .\generate-epics.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$epicsDir = Join-Path $PSScriptRoot '..\epics'
$epicsDir = (Resolve-Path (New-Item -ItemType Directory -Force -Path $epicsDir)).Path

Write-Host "Generating epic files in: $epicsDir" -ForegroundColor Cyan
Write-Host ""

# ---- Data ------------------------------------------------------------------
$epics = @(
    @{
        File = 'EPIC-01.md'
        Number = 1
        Title = 'Platform Foundation & Authentication'
        Labels = 'type: epic, module: core, priority: critical'
        Goal = 'Establish the core .NET solution, database schema, and secure authentication so all other modules can be built on a solid base.'
        Features = @(
            @{
                Title = 'Feature 1.1: Solution Scaffolding'
                Description = 'Set up the .NET solution with API, Blazor, MAUI, Functions, and Mock projects.'
                Stories = @(
                    @{
                        Title = 'Story 1.1.1: Developer can build the solution locally'
                        Description = 'As a developer I want a solution with all projects so I can work consistently.'
                        Tasks = @(
                            'Create TvdeFleetManagement.sln',
                            'Create API, Application, Domain, Infrastructure, Functions, MaponMock, Blazor, MAUI projects',
                            'Configure project references per solution structure',
                            'Add NuGet packages per spec',
                            'Set up appsettings.json for each environment'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 1.2: Database Schema & Migrations'
                Description = 'Create all tables, indexes, and partitions via EF Core migrations.'
                Stories = @(
                    @{
                        Title = 'Story 1.2.1: Developer can apply migrations to a fresh DB'
                        Description = 'As a developer I want migrations that create the entire schema.'
                        Tasks = @(
                            'Create AppDbContext with all DbSets',
                            'Configure entity relationships and constraints',
                            'Add SQL Server partitioning for telematics_events',
                            'Add columnstore index on telematics_events',
                            'Generate initial migration',
                            'Write seed data script'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 1.3: JWT Authentication'
                Description = 'Implement login, refresh, and logout with JWT tokens.'
                Stories = @(
                    @{
                        Title = 'Story 1.3.1: User can log in with email and password'
                        Description = 'As a user I want to log in so I can access the platform securely.'
                        Tasks = @(
                            'Implement POST /auth/login',
                            'Implement POST /auth/refresh',
                            'Implement POST /auth/logout',
                            'Configure JWT issuer, audience, signing key',
                            'Add bcrypt or PBKDF2 password hashing',
                            'Write auth unit tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 1.4: RBAC Authorization'
                Description = 'Enforce role-based access control across all controllers.'
                Stories = @(
                    @{
                        Title = 'Story 1.4.1: Admin can control role-based access'
                        Description = 'As an admin I want to restrict what each role can access.'
                        Tasks = @(
                            'Define roles admin, fleet_manager, accountant, viewer',
                            'Create Authorize policies',
                            'Apply policies to all controllers',
                            'Write authorization tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-02.md'
        Number = 2
        Title = 'Fleet & Vehicle Management'
        Labels = 'type: epic, module: fleet, priority: high'
        Goal = 'Register, track, and manage every vehicle in the fleet, including its compliance and telematics mapping.'
        Features = @(
            @{
                Title = 'Feature 2.1: Vehicle CRUD'
                Description = 'Allow fleet managers to add, view, edit, and retire vehicles.'
                Stories = @(
                    @{
                        Title = 'Story 2.1.1: Fleet manager can manage vehicle inventory'
                        Description = 'As a fleet manager I want to add view edit and retire vehicles.'
                        Tasks = @(
                            'Implement GET POST PUT /vehicles',
                            'Implement GET /vehicles/{id}',
                            'Add filters status make fuel_type',
                            'Build Blazor Vehicles/List page',
                            'Build Blazor Vehicles/Detail page',
                            'Write API and UI tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 2.2: Vehicle Compliance Tracking'
                Description = 'Record IPO, insurance, sticker, and IMT registration details.'
                Stories = @(
                    @{
                        Title = 'Story 2.2.1: Fleet manager can record and monitor compliance'
                        Description = 'As a fleet manager I want to track IPO insurance sticker and IMT reg.'
                        Tasks = @(
                            'Implement GET POST /vehicles/{id}/compliance',
                            'Add expiry alert calculation',
                            'Build compliance section on Vehicle/Detail',
                            'Write compliance service unit tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 2.3: Mapon Unit Mapping'
                Description = 'Link each vehicle to its Mapon unit ID.'
                Stories = @(
                    @{
                        Title = 'Story 2.3.1: Fleet manager can link a vehicle to Mapon'
                        Description = 'As a fleet manager I want to map a vehicle to its Mapon unit ID.'
                        Tasks = @(
                            'Add mapon_unit_id and mapon_unit_number columns',
                            'Build UI to search and link Mapon units',
                            'Handle unmapped vehicles gracefully',
                            'Write mapping validation tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 2.4: Vehicle Analytics'
                Description = 'Show TCO, revenue/km, and utilisation per vehicle.'
                Stories = @(
                    @{
                        Title = 'Story 2.4.1: Fleet manager can compare vehicle performance'
                        Description = 'As a fleet manager I want TCO revenue per km and utilisation per vehicle.'
                        Tasks = @(
                            'Implement GET /vehicles/{id}/analytics',
                            'Implement GET /vehicles/analytics/compare',
                            'Build Blazor Vehicles/Comparison page',
                            'Add 5-minute cache for analytics',
                            'Write aggregation tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-03.md'
        Number = 3
        Title = 'Driver Management & Compliance'
        Labels = 'type: epic, module: drivers, priority: high'
        Goal = 'Onboard drivers, track their CMTVDE and criminal record validity, and manage vehicle assignments.'
        Features = @(
            @{
                Title = 'Feature 3.1: Driver CRUD'
                Description = 'Register, view, and manage drivers.'
                Stories = @(
                    @{
                        Title = 'Story 3.1.1: Fleet manager can manage drivers'
                        Description = 'As a fleet manager I want to register and edit drivers.'
                        Tasks = @(
                            'Implement GET POST PUT /drivers',
                            'Implement GET /drivers/{id}',
                            'Build Blazor Drivers/List page',
                            'Build Blazor Drivers/Detail page',
                            'Write API and UI tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 3.2: CMTVDE & Document Tracking'
                Description = 'Upload and track CMTVDE, criminal record, and training certificates.'
                Stories = @(
                    @{
                        Title = 'Story 3.2.1: Fleet manager can track driver documents'
                        Description = 'As a fleet manager I want to upload and track CMTVDE and other docs.'
                        Tasks = @(
                            'Implement GET POST /drivers/{id}/compliance',
                            'Add document upload to Blob Storage',
                            'Build compliance section on Driver/Detail',
                            'Write expiry validation tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 3.3: Vehicle Assignment & Handover'
                Description = 'Assign vehicle to driver and log handover condition.'
                Stories = @(
                    @{
                        Title = 'Story 3.3.1: Fleet manager can assign vehicle and log handover'
                        Description = 'As a fleet manager I want to assign a vehicle and capture handover.'
                        Tasks = @(
                            'Implement POST /drivers/{id}/assign-vehicle',
                            'Implement handover log endpoints',
                            'Block assignment if compliance expired',
                            'Build assignment UI in Blazor',
                            'Write assignment tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 3.4: Driver Performance Summary'
                Description = 'Show ratings, complaints, and incidents in one view.'
                Stories = @(
                    @{
                        Title = 'Story 3.4.1: Fleet manager can see driver performance'
                        Description = 'As a fleet manager I want ratings complaints and incidents in one view.'
                        Tasks = @(
                            'Implement GET /drivers/{id}/performance',
                            'Aggregate from ratings complaints incidents',
                            'Build performance card on Driver/Detail',
                            'Write aggregation tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-04.md'
        Number = 4
        Title = 'Trip & Revenue Synchronisation'
        Labels = 'type: epic, module: trips, priority: high'
        Goal = 'Ingest trip data from Uber (mock API) and Bolt (CSV) into a unified trips table.'
        Features = @(
            @{
                Title = 'Feature 4.1: Uber Sync (Azure Function)'
                Description = 'Sync Uber payment data every 15 minutes.'
                Stories = @(
                    @{
                        Title = 'Story 4.1.1: Fleet manager gets Uber data synced automatically'
                        Description = 'As a fleet manager I want Uber payments synced every 15 minutes.'
                        Tasks = @(
                            'Create UberSyncFunction (Timer trigger)',
                            'Implement Uber mock API client',
                            'Paginate 10-day windows',
                            'Convert cents to EUR and map Unix timestamp',
                            'Deduplicate on platform_trip_id',
                            'Log to integration_sync_logs',
                            'Write sync tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 4.2: Bolt CSV Import'
                Description = 'Upload Bolt CSV exports to import historical trips.'
                Stories = @(
                    @{
                        Title = 'Story 4.2.1: Fleet manager can upload Bolt CSV export'
                        Description = 'As a fleet manager I want to import historical Bolt trips.'
                        Tasks = @(
                            'Implement POST /integrations/bolt/import',
                            'Parse with CsvHelper',
                            'Validate headers and data types',
                            'Deduplicate on order_time driver_id ride_price',
                            'Return import summary',
                            'Build upload UI in Blazor',
                            'Write parser and import tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 4.3: Trip List & Detail'
                Description = 'Browse and filter trips by driver, vehicle, platform, and date.'
                Stories = @(
                    @{
                        Title = 'Story 4.3.1: Fleet manager can browse and filter trips'
                        Description = 'As a fleet manager I want to audit trips by driver vehicle and date.'
                        Tasks = @(
                            'Implement GET /trips with filters',
                            'Implement GET /trips/{id}',
                            'Build Blazor Trips page with filters',
                            'Add export to CSV',
                            'Write query tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-05.md'
        Number = 5
        Title = 'Telemetry (Mapon Mock)'
        Labels = 'type: epic, module: telemetry, priority: high'
        Goal = 'Build an API-faithful Mapon mock server and integrate it via a provider-agnostic client.'
        Features = @(
            @{
                Title = 'Feature 5.1: Mapon Mock Server'
                Description = 'Standalone mock that mirrors the Mapon REST contract.'
                Stories = @(
                    @{
                        Title = 'Story 5.1.1: Developer can develop without real Mapon API'
                        Description = 'As a developer I want an API-faithful mock so I can develop offline.'
                        Tasks = @(
                            'Create TvdeFleet.MaponMock project',
                            'Implement /unit/list.json',
                            'Implement /unit_data/list.json',
                            'Implement /route/list.json',
                            'Implement /driver/list.json',
                            'Implement ApiKeyMiddleware',
                            'Implement ConcurrencyLimitMiddleware',
                            'Create MockFleetSeeder',
                            'Create VehicleMovementSimulator',
                            'Write contract tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 5.2: MaponClient Integration'
                Description = 'Single client that works against mock and real Mapon via config.'
                Stories = @(
                    @{
                        Title = 'Story 5.2.1: Developer can switch mock and real via config'
                        Description = 'As a developer I want a single client so switching is BaseUrl only.'
                        Tasks = @(
                            'Define IMaponClient interface',
                            'Implement MaponClient with Polly retry and bulkhead',
                            'Add MaponOptions configuration',
                            'Register HttpClient in DI',
                            'Write unit and integration tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 5.3: Mapon Sync Function'
                Description = 'Sync positions, unit data, and routes every 5 minutes.'
                Stories = @(
                    @{
                        Title = 'Story 5.3.1: Fleet manager gets telemetry synced every 5 minutes'
                        Description = 'As a fleet manager I want up-to-date positions and mileage.'
                        Tasks = @(
                            'Create MaponSyncFunction (Timer trigger)',
                            'Upsert positions unit data and routes',
                            'Write to telematics_events partitioned table',
                            'Populate IMemoryCache for live map',
                            'Log to background_job_logs',
                            'Write sync tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 5.4: Live Fleet Map'
                Description = 'Live map of all vehicles with status.'
                Stories = @(
                    @{
                        Title = 'Story 5.4.1: Fleet manager can see live vehicle positions'
                        Description = 'As a fleet manager I want a live map of all vehicles.'
                        Tasks = @(
                            'Implement GET /telematics/vehicles',
                            'Build Blazor map component with Leaflet',
                            'Poll every 30 seconds from cache',
                            'Show vehicle status moving idle offline',
                            'Write map integration tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-06.md'
        Number = 6
        Title = 'Billing Engine (3 Business Models)'
        Labels = 'type: epic, module: billing, priority: critical'
        Goal = 'Automate billing cycles for rental, profit-share, and salary-plus-commission models.'
        Features = @(
            @{
                Title = 'Feature 6.1: Rental Billing (Model 1)'
                Description = 'Generate weekly or monthly rental invoices.'
                Stories = @(
                    @{
                        Title = 'Story 6.1.1: Accountant gets rental invoices generated'
                        Description = 'As an accountant I want weekly/monthly rental invoices.'
                        Tasks = @(
                            'Implement billing logic for rental contracts',
                            'Create rental_fee line items',
                            'Apply penalties from complaints and incidents',
                            'Build Billing/Cycles review UI',
                            'Write billing tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 6.2: Profit Share Billing (Model 2)'
                Description = 'Calculate profit-share settlements.'
                Stories = @(
                    @{
                        Title = 'Story 6.2.1: Accountant gets profit-share settlements'
                        Description = 'As an accountant I want profit-share calculated automatically.'
                        Tasks = @(
                            'Aggregate trips and expenses per driver/period',
                            'Apply profit_share_driver_pct',
                            'Add expense reimbursement lines',
                            'Apply penalty engine',
                            'Build review UI',
                            'Write billing tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 6.3: Salary + Commission Billing (Model 3)'
                Description = 'Calculate payroll with base salary, commission, IRS, and TSU.'
                Stories = @(
                    @{
                        Title = 'Story 6.3.1: Accountant gets payroll calculated with IRS and TSU'
                        Description = 'As an accountant I want employee payroll computed correctly.'
                        Tasks = @(
                            'Prorate base salary',
                            'Calculate commission from net earnings',
                            'Compute IRS withholding',
                            'Compute TSU employee and employer',
                            'Generate payslip data',
                            'Write payroll tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 6.4: Penalty & Bonus Engine'
                Description = 'Apply penalties and bonuses based on complaints, accidents, ratings.'
                Stories = @(
                    @{
                        Title = 'Story 6.4.1: Fleet manager gets penalties and bonuses applied'
                        Description = 'As a fleet manager I want automatic adjustments to driver earnings.'
                        Tasks = @(
                            'Implement complaint penalty logic',
                            'Implement at-fault accident amortisation',
                            'Implement rating threshold deduction',
                            'Implement perfect rating bonus',
                            'Write rule engine tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 6.5: Billing Cycle Function'
                Description = 'Generate billing cycles weekly via Azure Function.'
                Stories = @(
                    @{
                        Title = 'Story 6.5.1: Developer gets billing cycles generated weekly'
                        Description = 'As a developer I want a weekly billing function.'
                        Tasks = @(
                            'Create BillingCycleFunction (Timer Mon 00:00)',
                            'Load active contracts by business model',
                            'Call appropriate billing service',
                            'Save billing_cycles and line items',
                            'Log to background_job_logs',
                            'Write function tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-07.md'
        Number = 7
        Title = 'Payments (Manual Workflow)'
        Labels = 'type: epic, module: payments, priority: high'
        Goal = 'Enable admins to mark payments as paid and notify drivers automatically.'
        Features = @(
            @{
                Title = 'Feature 7.1: Pending Payments List'
                Description = 'Show all pending payments with driver IBANs.'
                Stories = @(
                    @{
                        Title = 'Story 7.1.1: Accountant can see all pending payments'
                        Description = 'As an accountant I want pending payments with IBANs to process.'
                        Tasks = @(
                            'Implement GET /payments/pending',
                            'Build Blazor Billing/Payments page',
                            'Show driver name amount IBAN',
                            'Add CSV and PDF export',
                            'Write query tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 7.2: Mark Payment as Paid'
                Description = 'Record payment completion with audit trail.'
                Stories = @(
                    @{
                        Title = 'Story 7.2.1: Accountant can mark payment as paid'
                        Description = 'As an accountant I want an audit trail when marking payments.'
                        Tasks = @(
                            'Implement POST /payments/{id}/mark-paid',
                            'Update payment_records.status to paid',
                            'Record marked_paid_at and marked_paid_by',
                            'Write payment tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 7.3: Driver Notification'
                Description = 'Push notification when payment is processed.'
                Stories = @(
                    @{
                        Title = 'Story 7.3.1: Driver receives push when payment processed'
                        Description = 'As a driver I want a push notification so I know payment was sent.'
                        Tasks = @(
                            'Create NotifyDriverFunction (Queue trigger)',
                            'Enqueue message from mark-paid endpoint',
                            'Send via Azure Notification Hubs',
                            'Update driver_notified_at',
                            'Build MAUI Payment Status page',
                            'Write notification tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-08.md'
        Number = 8
        Title = 'Incidents, Complaints & Expenses'
        Labels = 'type: epic, module: incidents, priority: medium'
        Goal = 'Allow drivers to report incidents and expenses, and managers to log complaints.'
        Features = @(
            @{
                Title = 'Feature 8.1: Driver Expense Logging'
                Description = 'Log expenses with photos and GPS.'
                Stories = @(
                    @{
                        Title = 'Story 8.1.1: Driver can log expenses with photo'
                        Description = 'As a driver I want to log expenses so I can be reimbursed.'
                        Tasks = @(
                            'Implement POST /expenses',
                            'Build MAUI Log Expense page',
                            'Capture GPS and photo',
                            'Support offline logging with SQLite',
                            'Sync when online',
                            'Write expense tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 8.2: Incident Reporting'
                Description = 'Report accidents, damage, or theft with photos.'
                Stories = @(
                    @{
                        Title = 'Story 8.2.1: Driver can report accidents with photos'
                        Description = 'As a driver I want to report incidents so my manager is informed.'
                        Tasks = @(
                            'Implement POST /incidents',
                            'Build MAUI Report Incident page',
                            'Capture GPS and photos',
                            'Set severity and at_fault flag',
                            'Notify fleet manager',
                            'Write incident tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 8.3: Complaint Management'
                Description = 'Log and resolve customer complaints with penalties.'
                Stories = @(
                    @{
                        Title = 'Story 8.3.1: Fleet manager can log and resolve complaints'
                        Description = 'As a fleet manager I want to resolve complaints with a penalty.'
                        Tasks = @(
                            'Implement GET POST /complaints',
                            'Implement PUT /complaints/{id}/resolve',
                            'Build Blazor Complaints page',
                            'Link penalty to billing engine',
                            'Write complaint tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-09.md'
        Number = 9
        Title = 'Analytics, Reporting & Export'
        Labels = 'type: epic, module: analytics, priority: medium'
        Goal = 'Provide dashboards, vehicle comparisons, driver rankings, and tax exports.'
        Features = @(
            @{
                Title = 'Feature 9.1: Fleet Analytics Dashboard'
                Description = 'Fleet KPIs at a glance.'
                Stories = @(
                    @{
                        Title = 'Story 9.1.1: Fleet manager sees fleet KPIs'
                        Description = 'As a fleet manager I want a dashboard with key metrics.'
                        Tasks = @(
                            'Implement GET /analytics/fleet-overview',
                            'Build Blazor Dashboard page',
                            'Show revenue costs utilisation alerts',
                            'Cache aggregates with 5-min TTL',
                            'Write dashboard tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 9.2: Vehicle Comparison'
                Description = 'Compare makes and models by TCO, revenue/km, and rating.'
                Stories = @(
                    @{
                        Title = 'Story 9.2.1: Fleet manager can compare makes and models'
                        Description = 'As a fleet manager I want to see which cars perform best.'
                        Tasks = @(
                            'Implement GET /analytics/vehicle-comparison',
                            'Calculate Vehicle Score',
                            'Build Blazor Vehicles/Comparison page',
                            'Add chart visualisations',
                            'Write comparison tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 9.3: Driver Ranking'
                Description = 'Rank drivers by performance.'
                Stories = @(
                    @{
                        Title = 'Story 9.3.1: Fleet manager can rank drivers'
                        Description = 'As a fleet manager I want to identify top and low performers.'
                        Tasks = @(
                            'Implement GET /analytics/driver-ranking',
                            'Aggregate ratings complaints revenue trips',
                            'Build Blazor Analytics/Drivers page',
                            'Write ranking tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 9.4: Tax Export (IVA/IRS)'
                Description = 'Export IVA and IRS data for the accountant.'
                Stories = @(
                    @{
                        Title = 'Story 9.4.1: Accountant can export IVA and IRS data'
                        Description = 'As an accountant I want to file taxes correctly.'
                        Tasks = @(
                            'Implement GET /reports/tax-export',
                            'Build CSV with IVA 6% and IRS withholding',
                            'Build Blazor Reports/Tax page',
                            'Write export tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-10.md'
        Number = 10
        Title = 'Mobile App & Push Notifications'
        Labels = 'type: epic, module: mobile, priority: high'
        Goal = 'Deliver the .NET MAUI driver app with offline capability and push notifications.'
        Features = @(
            @{
                Title = 'Feature 10.1: MAUI App Scaffolding'
                Description = 'MAUI project with all screens and navigation.'
                Stories = @(
                    @{
                        Title = 'Story 10.1.1: Developer has MAUI project with all screens'
                        Description = 'As a developer I want the MAUI project ready to build.'
                        Tasks = @(
                            'Create TvdeFleet.Maui project',
                            'Create all Views and ViewModels',
                            'Configure Shell navigation',
                            'Add API Auth Location Notification services',
                            'Write UI tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 10.2: Offline Sync'
                Description = 'Log expenses and incidents offline and sync later.'
                Stories = @(
                    @{
                        Title = 'Story 10.2.1: Driver can log expenses and incidents offline'
                        Description = 'As a driver I want to work without connectivity.'
                        Tasks = @(
                            'Implement SQLite local storage',
                            'Queue expenses and incidents for sync',
                            'Sync when connectivity returns',
                            'Show pending badge',
                            'Write offline sync tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 10.3: Push Notifications'
                Description = 'Payment and compliance alerts via push.'
                Stories = @(
                    @{
                        Title = 'Story 10.3.1: Driver receives push notifications'
                        Description = 'As a driver I want push for payment and compliance alerts.'
                        Tasks = @(
                            'Configure Azure Notification Hubs',
                            'Implement PushNotificationFunction',
                            'Register device tokens in MAUI',
                            'Handle notification tap to navigate',
                            'Write notification tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-11.md'
        Number = 11
        Title = 'Compliance Alert Engine'
        Labels = 'type: epic, module: compliance, priority: critical'
        Goal = 'Automatically scan and alert on all vehicle and driver compliance expiries.'
        Features = @(
            @{
                Title = 'Feature 11.1: Daily Compliance Scan'
                Description = 'Daily scan of all compliance expiries.'
                Stories = @(
                    @{
                        Title = 'Story 11.1.1: Fleet manager gets daily scan of all expiries'
                        Description = 'As a fleet manager I want daily scanning so I never miss a renewal.'
                        Tasks = @(
                            'Create ComplianceAlertFunction (Timer daily 06:00)',
                            'Scan vehicle IMT reg insurance IPO sticker',
                            'Scan driver CMTVDE criminal record licence',
                            'Scan vehicle age 10y or 12y EV',
                            'Generate alerts at 30 15 and 7-day thresholds',
                            'Write alert tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 11.2: Alert Notifications'
                Description = 'Email and push alerts for expiring documents.'
                Stories = @(
                    @{
                        Title = 'Story 11.2.1: Driver or manager receives expiring-doc alerts'
                        Description = 'As a driver or manager I want alerts so I can renew in time.'
                        Tasks = @(
                            'Enqueue notifications from alert engine',
                            'Send via NotifyDriverFunction',
                            'Build Blazor Compliance/Alerts page',
                            'Write notification tests'
                        )
                    }
                )
            }
        )
    }
    @{
        File = 'EPIC-12.md'
        Number = 12
        Title = 'Settings & Administration'
        Labels = 'type: epic, module: settings, priority: medium'
        Goal = 'Configure Mapon, manage users, and control system settings.'
        Features = @(
            @{
                Title = 'Feature 12.1: Mapon Settings'
                Description = 'Configure Mapon base URL, API key, and sync interval.'
                Stories = @(
                    @{
                        Title = 'Story 12.1.1: Admin can configure Mapon settings'
                        Description = 'As an admin I want to configure Mapon so telemetry works.'
                        Tasks = @(
                            'Build Blazor Settings/Mapon page',
                            'Store settings securely in Key Vault',
                            'Add Test Connection button',
                            'Show sync status and last sync time',
                            'Write settings tests'
                        )
                    }
                )
            }
            @{
                Title = 'Feature 12.2: User Management'
                Description = 'Create, edit, and deactivate users and assign roles.'
                Stories = @(
                    @{
                        Title = 'Story 12.2.1: Admin can manage users'
                        Description = 'As an admin I want to create edit and deactivate users.'
                        Tasks = @(
                            'Implement GET POST PUT /users',
                            'Build Blazor Settings/Users page',
                            'Assign roles',
                            'Write user management tests'
                        )
                    }
                )
            }
        )
    }
)

# ---- Generate --------------------------------------------------------------
$written = 0

foreach ($epic in $epics) {
    $sb = New-Object System.Text.StringBuilder

    [void]$sb.AppendLine("# Epic $($epic.Number): $($epic.Title)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Labels:** ``$($epic.Labels)``")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Goal")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine($epic.Goal)
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Features")

    foreach ($feature in $epic.Features) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("### $($feature.Title)")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("> $($feature.Description)")

        foreach ($story in $feature.Stories) {
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("#### $($story.Title)")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine($story.Description)
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("**Tasks:**")
            [void]$sb.AppendLine("")
            foreach ($task in $story.Tasks) {
                [void]$sb.AppendLine("- [ ] $task")
            }
        }
    }

    $path = Join-Path $epicsDir $epic.File
    $sb.ToString() | Out-File -FilePath $path -Encoding UTF8 -NoNewline
    Write-Host ("  + {0}" -f $epic.File) -ForegroundColor Gray
    $written++
}

Write-Host ""
Write-Host ("Generated {0} epic files in {1}" -f $written, $epicsDir) -ForegroundColor Green