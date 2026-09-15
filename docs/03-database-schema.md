# Database Schema (SQL Server)

**Database:** SQL Server 2022 / Azure SQL Database
**Version:** 4.0 · **Companion to:** Requirements Documentation v4.0

## Conventions

| Concern | Convention |
|---|---|
| Primary keys | `UNIQUEIDENTIFIER` with `DEFAULT NEWSEQUENTIALID()` |
| Timestamps | `DATETIME2(3)` storing UTC |
| Booleans | `BIT` |
| JSON payloads | `NVARCHAR(MAX)` with `ISJSON` check constraint |
| Unicode | `NVARCHAR` for names/addresses; `VARCHAR` for codes, emails, tokens |
| Enums | `VARCHAR(30)` with `CHECK` constraint |
| Money | `DECIMAL(12,2)` or `DECIMAL(10,2)` |
| Identities | `BIGINT IDENTITY(1,1)` for log tables |
| Indexes | Filtered indexes with `WHERE` for hot subsets |

## Entity Relationships

```
operators ──1:N── users
operators ──1:N── drivers
operators ──1:N── vehicles
drivers   ──M:N── vehicles  (via driver_vehicle_assignments)
vehicles  ──1:N── vehicle_compliance_records
vehicles  ──1:N── telematics_events         (partitioned by month)
vehicles  ──1:N── trips
vehicles  ──1:N── vehicle_expenses
vehicles  ──1:N── incidents
drivers   ──1:N── trips
drivers   ──1:N── incidents
drivers   ──1:N── complaints
drivers   ──1:N── driver_ratings
drivers   ──1:N── contracts ──1:N── billing_cycles ──1:N── billing_line_items
billing_cycles ──1:N── payment_records
```

---

## 3.1 Operators & Users

```sql
CREATE TABLE operators (
    id                  UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    name                NVARCHAR(255) NOT NULL,
    nif                 VARCHAR(9)    NOT NULL UNIQUE,
    imt_licence_number  VARCHAR(50)   NULL,
    imt_licence_expiry  DATE          NULL,
    address             NVARCHAR(500) NULL,
    email               VARCHAR(255)  NULL,
    phone               VARCHAR(20)   NULL,
    created_at          DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at          DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE users (
    id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    operator_id     UNIQUEIDENTIFIER NOT NULL REFERENCES operators(id),
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    role            VARCHAR(20)  NOT NULL
                    CHECK (role IN ('admin','fleet_manager','accountant','viewer')),
    is_active       BIT          NOT NULL DEFAULT 1,
    created_at      DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_users_operator ON users(operator_id) WHERE is_active = 1;
```

## 3.2 Drivers

```sql
CREATE TABLE drivers (
    id                          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    operator_id                 UNIQUEIDENTIFIER NOT NULL REFERENCES operators(id),
    full_name                   NVARCHAR(255) NOT NULL,
    nif                         VARCHAR(9)    NOT NULL UNIQUE,
    email                       VARCHAR(255)  NULL,
    phone                       VARCHAR(20)   NULL,
    date_of_birth               DATE          NULL,
    licence_number              VARCHAR(50)   NULL,
    licence_expiry              DATE          NULL,
    cmtvde_number               VARCHAR(50)   NULL,
    cmtvde_issue_date           DATE          NULL,
    cmtvde_expiry_date          DATE          NULL,
    criminal_record_check_date  DATE          NULL,
    criminal_record_expiry_date DATE          NULL,
    training_hours_completed    INT           NOT NULL DEFAULT 0,
    last_training_date          DATE          NULL,
    iban                        VARCHAR(34)   NULL,
    mapon_driver_id             INT           NULL UNIQUE,
    status                      VARCHAR(20)   NOT NULL
                                CHECK (status IN ('active','suspended','inactive')),
    created_at                  DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at                  DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_drivers_operator_status ON drivers(operator_id, status);
CREATE INDEX IX_drivers_cmtvde_expiry   ON drivers(cmtvde_expiry_date)
    WHERE status = 'active';

CREATE TABLE driver_compliance_documents (
    id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    driver_id       UNIQUEIDENTIFIER NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    document_type   VARCHAR(50)  NOT NULL
                    CHECK (document_type IN ('cmtvde','criminal_record','licence','training_certificate')),
    document_number VARCHAR(100) NULL,
    issue_date      DATE         NULL,
    expiry_date     DATE         NULL,
    file_url        NVARCHAR(500) NULL,
    is_verified     BIT          NOT NULL DEFAULT 0,
    created_at      DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_dcd_driver ON driver_compliance_documents(driver_id);
CREATE INDEX IX_dcd_expiry ON driver_compliance_documents(expiry_date);
```

## 3.3 Vehicles

```sql
CREATE TABLE vehicles (
    id                      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    operator_id             UNIQUEIDENTIFIER NOT NULL REFERENCES operators(id),
    make                    NVARCHAR(100) NOT NULL,
    model                   NVARCHAR(100) NOT NULL,
    year                    INT           NOT NULL,
    vin                     VARCHAR(17)   NULL UNIQUE,
    license_plate           VARCHAR(20)   NOT NULL UNIQUE,
    colour                  NVARCHAR(50)  NULL,
    fuel_type               VARCHAR(20)   NOT NULL
                            CHECK (fuel_type IN ('petrol','diesel','hybrid','plug_in_hybrid','electric')),
    is_electric             AS CONVERT(BIT, CASE WHEN fuel_type = 'electric' THEN 1 ELSE 0 END) PERSISTED,
    purchase_type           VARCHAR(20)   NOT NULL
                            CHECK (purchase_type IN ('cash','leasing','loan')),
    purchase_price          DECIMAL(12,2) NULL,
    monthly_lease_cost      DECIMAL(10,2) NULL,
    lease_end_date          DATE          NULL,
    imt_registration_number VARCHAR(50)   NULL,
    imt_registration_expiry DATE          NULL,
    mapon_unit_id           INT           NULL UNIQUE,
    mapon_unit_number       VARCHAR(50)   NULL,
    status                  VARCHAR(20)   NOT NULL
                            CHECK (status IN ('active','maintenance','retired','reserved')),
    created_at              DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at              DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_vehicles_operator_status ON vehicles(operator_id, status);
CREATE INDEX IX_vehicles_make_model      ON vehicles(make, model);
CREATE INDEX IX_vehicles_imt_expiry      ON vehicles(imt_registration_expiry)
    WHERE status = 'active';

CREATE TABLE vehicle_compliance_records (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    vehicle_id       UNIQUEIDENTIFIER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    record_type      VARCHAR(30)  NOT NULL
                     CHECK (record_type IN ('ipo','insurance_third_party','insurance_personal_accident','sticker','imt_registration')),
    reference_number VARCHAR(100) NULL,
    issue_date       DATE         NULL,
    expiry_date      DATE         NULL,
    provider_name    NVARCHAR(255) NULL,
    cost             DECIMAL(10,2) NULL,
    file_url         NVARCHAR(500) NULL,
    created_at       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_vcr_vehicle ON vehicle_compliance_records(vehicle_id);
CREATE INDEX IX_vcr_expiry  ON vehicle_compliance_records(expiry_date);
```

## 3.4 Assignments & Handover

```sql
CREATE TABLE driver_vehicle_assignments (
    id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    driver_id       UNIQUEIDENTIFIER NOT NULL REFERENCES drivers(id),
    vehicle_id      UNIQUEIDENTIFIER NOT NULL REFERENCES vehicles(id),
    assigned_from   DATETIME2(3)  NOT NULL,
    assigned_to     DATETIME2(3)  NULL,
    is_primary      BIT           NOT NULL DEFAULT 1,
    created_at      DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_dva_driver_active  ON driver_vehicle_assignments(driver_id)
    WHERE assigned_to IS NULL;
CREATE INDEX IX_dva_vehicle_active ON driver_vehicle_assignments(vehicle_id)
    WHERE assigned_to IS NULL;

CREATE TABLE vehicle_handover_logs (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    assignment_id    UNIQUEIDENTIFIER NOT NULL REFERENCES driver_vehicle_assignments(id),
    odometer_reading INT           NULL,
    fuel_level_pct   INT           NULL,
    condition_notes  NVARCHAR(MAX) NULL,
    photos           NVARCHAR(MAX) NULL CHECK (photos IS NULL OR ISJSON(photos) = 1),
    logged_at        DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);
```

## 3.5 Contracts & Billing

```sql
CREATE TABLE contracts (
    id                      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    driver_id               UNIQUEIDENTIFIER NOT NULL REFERENCES drivers(id),
    vehicle_id              UNIQUEIDENTIFIER NOT NULL REFERENCES vehicles(id),
    business_model          VARCHAR(20)  NOT NULL
                            CHECK (business_model IN ('rental','profit_share','salary_plus')),
    start_date              DATE         NOT NULL,
    end_date                DATE         NULL,
    status                  VARCHAR(20)  NOT NULL
                            CHECK (status IN ('draft','active','suspended','terminated')),
    rental_weekly_rate      DECIMAL(10,2) NULL,
    rental_monthly_rate     DECIMAL(10,2) NULL,
    profit_share_driver_pct DECIMAL(5,2)  NULL,
    base_salary             DECIMAL(10,2) NULL,
    commission_pct          DECIMAL(5,2)  NULL,
    notes                   NVARCHAR(MAX) NULL,
    created_at              DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_contracts_driver_active ON contracts(driver_id) WHERE status = 'active';
CREATE INDEX IX_contracts_vehicle       ON contracts(vehicle_id);

CREATE TABLE billing_cycles (
    id                UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    contract_id       UNIQUEIDENTIFIER NOT NULL REFERENCES contracts(id),
    period_start      DATE          NOT NULL,
    period_end        DATE          NOT NULL,
    status            VARCHAR(20)   NOT NULL
                      CHECK (status IN ('draft','approved','invoiced','paid')),
    total_revenue     DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_expenses    DECIMAL(12,2) NOT NULL DEFAULT 0,
    driver_share      DECIMAL(12,2) NOT NULL DEFAULT 0,
    company_share     DECIMAL(12,2) NOT NULL DEFAULT 0,
    penalties_applied DECIMAL(10,2) NOT NULL DEFAULT 0,
    net_payable       DECIMAL(12,2) NOT NULL DEFAULT 0,
    generated_at      DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE UNIQUE INDEX UX_billing_cycle_period ON billing_cycles(contract_id, period_start, period_end);
CREATE INDEX IX_billing_cycles_status ON billing_cycles(status);

CREATE TABLE billing_line_items (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    billing_cycle_id UNIQUEIDENTIFIER NOT NULL REFERENCES billing_cycles(id) ON DELETE CASCADE,
    line_type        VARCHAR(30)   NOT NULL
                     CHECK (line_type IN ('trip_earning','rental_fee','base_salary','commission','penalty','expense_reimbursement','bonus')),
    description      NVARCHAR(MAX) NULL,
    amount           DECIMAL(10,2) NOT NULL,
    reference_id     UNIQUEIDENTIFIER NULL,
    created_at       DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_bli_cycle ON billing_line_items(billing_cycle_id);
```

## 3.6 Trips

```sql
CREATE TABLE trips (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    driver_id        UNIQUEIDENTIFIER NOT NULL REFERENCES drivers(id),
    vehicle_id       UNIQUEIDENTIFIER NOT NULL REFERENCES vehicles(id),
    platform         VARCHAR(20)   NOT NULL
                     CHECK (platform IN ('uber','bolt','free_now','other')),
    platform_trip_id VARCHAR(100)  NULL UNIQUE,
    mapon_route_id   BIGINT        NULL,
    started_at       DATETIME2(3)  NOT NULL,
    completed_at     DATETIME2(3)  NULL,
    pickup_address   NVARCHAR(500) NULL,
    dropoff_address  NVARCHAR(500) NULL,
    distance_km      DECIMAL(8,2)  NULL,
    duration_minutes INT           NULL,
    gross_fare       DECIMAL(10,2) NULL,
    platform_fee     DECIMAL(10,2) NULL,
    net_earning      DECIMAL(10,2) NULL,
    tip_amount       DECIMAL(10,2) NOT NULL DEFAULT 0,
    surge_multiplier DECIMAL(5,2)  NULL,
    status           VARCHAR(30)   NOT NULL
                     CHECK (status IN ('completed','cancelled_by_rider','cancelled_by_driver','no_show')),
    created_at       DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_trips_driver_started  ON trips(driver_id, started_at DESC);
CREATE INDEX IX_trips_vehicle_started ON trips(vehicle_id, started_at DESC);
CREATE INDEX IX_trips_platform        ON trips(platform, started_at DESC);
```

## 3.7 Expenses & Incidents

```sql
CREATE TABLE vehicle_expenses (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    vehicle_id       UNIQUEIDENTIFIER NOT NULL REFERENCES vehicles(id),
    driver_id        UNIQUEIDENTIFIER NULL REFERENCES drivers(id),
    expense_type     VARCHAR(30)  NOT NULL
                     CHECK (expense_type IN ('fuel','charging','toll','parking','cleaning','maintenance','repair','insurance','other')),
    amount           DECIMAL(10,2) NOT NULL,
    description      NVARCHAR(MAX) NULL,
    receipt_url      NVARCHAR(500) NULL,
    odometer_reading INT           NULL,
    expense_date     DATE          NOT NULL,
    is_reconciled    BIT           NOT NULL DEFAULT 0,
    created_at       DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_expenses_vehicle_date ON vehicle_expenses(vehicle_id, expense_date DESC);
CREATE INDEX IX_expenses_driver       ON vehicle_expenses(driver_id) WHERE driver_id IS NOT NULL;

CREATE TABLE incidents (
    id              UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    vehicle_id      UNIQUEIDENTIFIER NOT NULL REFERENCES vehicles(id),
    driver_id       UNIQUEIDENTIFIER NULL REFERENCES drivers(id),
    incident_type   VARCHAR(20)  NOT NULL
                    CHECK (incident_type IN ('accident','damage','theft','vandalism','traffic_violation','other')),
    severity        VARCHAR(10)  NOT NULL
                    CHECK (severity IN ('minor','moderate','major')),
    description     NVARCHAR(MAX) NOT NULL,
    location        NVARCHAR(500) NULL,
    gps_lat         DECIMAL(9,6)  NULL,
    gps_lng         DECIMAL(9,6)  NULL,
    incident_date   DATETIME2(3)  NOT NULL,
    police_report   VARCHAR(100)  NULL,
    insurance_claim VARCHAR(100)  NULL,
    repair_cost     DECIMAL(10,2) NULL,
    at_fault        BIT           NULL,
    status          VARCHAR(20)   NOT NULL
                    CHECK (status IN ('reported','under_review','resolved','closed')),
    photos          NVARCHAR(MAX) NULL CHECK (photos IS NULL OR ISJSON(photos) = 1),
    created_at      DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_incidents_driver  ON incidents(driver_id, incident_date DESC);
CREATE INDEX IX_incidents_vehicle ON incidents(vehicle_id, incident_date DESC);
```

## 3.8 Ratings & Complaints

```sql
CREATE TABLE driver_ratings (
    id            UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    driver_id     UNIQUEIDENTIFIER NOT NULL REFERENCES drivers(id),
    platform      VARCHAR(20)  NULL,
    rating        DECIMAL(3,2) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    total_ratings INT          NULL,
    period_start  DATE         NULL,
    period_end    DATE         NULL,
    created_at    DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_ratings_driver_period ON driver_ratings(driver_id, period_start DESC);

CREATE TABLE complaints (
    id               UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    driver_id        UNIQUEIDENTIFIER NOT NULL REFERENCES drivers(id),
    trip_id          UNIQUEIDENTIFIER NULL REFERENCES trips(id),
    platform         VARCHAR(20)  NULL,
    complaint_type   VARCHAR(50)  NULL,
    description      NVARCHAR(MAX) NOT NULL,
    severity         VARCHAR(10)  NOT NULL
                     CHECK (severity IN ('low','medium','high','critical')),
    status           VARCHAR(20)  NOT NULL
                     CHECK (status IN ('open','under_investigation','resolved','dismissed')),
    resolution_notes NVARCHAR(MAX) NULL,
    penalty_applied  DECIMAL(10,2) NOT NULL DEFAULT 0,
    complaint_date   DATETIME2(3)  NOT NULL,
    resolved_at      DATETIME2(3)  NULL,
    created_at       DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_complaints_driver_status ON complaints(driver_id, status);
CREATE INDEX IX_complaints_open          ON complaints(status)
    WHERE status IN ('open','under_investigation');
```

## 3.9 Telematics (Partitioned Table)

SQL Server replaces TimescaleDB with native partitioning by month plus a nonclustered columnstore index for analytics.

```sql
CREATE PARTITION FUNCTION PF_Telematics_Monthly (DATETIME2(3))
    AS RANGE RIGHT FOR VALUES (
        '2026-01-01', '2026-02-01', '2026-03-01', '2026-04-01',
        '2026-05-01', '2026-06-01', '2026-07-01', '2026-08-01',
        '2026-09-01', '2026-10-01', '2026-11-01', '2026-12-01'
    );

CREATE PARTITION SCHEME PS_Telematics_Monthly
    AS PARTITION PF_Telematics_Monthly ALL TO ([PRIMARY]);

CREATE TABLE telematics_events (
    time               DATETIME2(3)      NOT NULL,
    vehicle_id         UNIQUEIDENTIFIER  NOT NULL,
    mapon_unit_id      INT               NULL,
    event_type         VARCHAR(30)       NOT NULL,
    latitude           DECIMAL(9,6)      NULL,
    longitude          DECIMAL(9,6)      NULL,
    speed_kmh          DECIMAL(6,2)      NULL,
    odometer_km        INT               NULL,
    fuel_level_pct     DECIMAL(5,2)      NULL,
    battery_level_pct  DECIMAL(5,2)      NULL,
    engine_on          BIT               NULL,
    harsh_braking      BIT               NULL,
    harsh_acceleration BIT               NULL,
    harsh_cornering    BIT               NULL,
    metadata           NVARCHAR(MAX)     NULL CHECK (metadata IS NULL OR ISJSON(metadata) = 1)
) ON PS_Telematics_Monthly(time);

CREATE CLUSTERED INDEX CIX_telematics_vehicle_time
    ON telematics_events(vehicle_id, time DESC)
    ON PS_Telematics_Monthly(time);

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_telematics_analytics
    ON telematics_events(time, vehicle_id, speed_kmh, odometer_km, fuel_level_pct, battery_level_pct)
    ON PS_Telematics_Monthly(time);
```

**Retention policy:** A `TelematicsRetentionFunction` (Azure Function, monthly) switches out partitions older than 24 months and drops them.

**Volume estimate:** With a 5-minute sync and 500 vehicles, ~144,000 rows/day → 4.3M/month → 52M/year.

## 3.10 Payments (Manual Workflow)

```sql
CREATE TABLE payment_records (
    id                  UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    billing_cycle_id    UNIQUEIDENTIFIER NOT NULL REFERENCES billing_cycles(id),
    driver_id           UNIQUEIDENTIFIER NOT NULL REFERENCES drivers(id),
    amount              DECIMAL(12,2) NOT NULL,
    payment_method      VARCHAR(30)  NULL
                        CHECK (payment_method IN ('bank_transfer','cash','mbway','other')),
    payment_reference   VARCHAR(100) NULL,
    status              VARCHAR(20)  NOT NULL
                        CHECK (status IN ('pending','processing','paid','failed')),
    marked_paid_by      UNIQUEIDENTIFIER NULL REFERENCES users(id),
    marked_paid_at      DATETIME2(3) NULL,
    driver_notified_at  DATETIME2(3) NULL,
    notification_method VARCHAR(20)  NULL
                        CHECK (notification_method IN ('push','email','sms')),
    notes               NVARCHAR(MAX) NULL,
    created_at          DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_payments_driver_status ON payment_records(driver_id, status);
CREATE INDEX IX_payments_cycle         ON payment_records(billing_cycle_id);
CREATE INDEX IX_payments_pending       ON payment_records(status)
    WHERE status IN ('pending','processing');
```

## 3.11 Integration & Audit

```sql
CREATE TABLE integration_sync_logs (
    id                UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    integration_type  VARCHAR(30)  NOT NULL
                      CHECK (integration_type IN ('uber','bolt','mapon')),
    sync_started_at   DATETIME2(3) NOT NULL,
    sync_completed_at DATETIME2(3) NULL,
    status            VARCHAR(20)  NOT NULL
                      CHECK (status IN ('running','success','partial','failed')),
    records_processed INT          NOT NULL DEFAULT 0,
    records_failed    INT          NOT NULL DEFAULT 0,
    error_details     NVARCHAR(MAX) NULL,
    created_at        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_sync_logs_type_time ON integration_sync_logs(integration_type, sync_started_at DESC);

CREATE TABLE background_job_logs (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    job_name         VARCHAR(100) NOT NULL,
    job_type         VARCHAR(50)  NOT NULL,
    started_at       DATETIME2(3) NOT NULL,
    completed_at     DATETIME2(3) NULL,
    status           VARCHAR(20)  NOT NULL
                     CHECK (status IN ('running','success','failed')),
    records_affected INT          NULL,
    error_message    NVARCHAR(MAX) NULL,
    created_at       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_bg_logs_job_time ON background_job_logs(job_name, started_at DESC);

CREATE TABLE audit_log (
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id     UNIQUEIDENTIFIER NULL,
    action      VARCHAR(50)  NOT NULL,
    entity_type VARCHAR(50)  NOT NULL,
    entity_id   UNIQUEIDENTIFIER NULL,
    old_values  NVARCHAR(MAX) NULL CHECK (old_values IS NULL OR ISJSON(old_values) = 1),
    new_values  NVARCHAR(MAX) NULL CHECK (new_values IS NULL OR ISJSON(new_values) = 1),
    ip_address  VARCHAR(45)  NULL,
    created_at  DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_audit_entity ON audit_log(entity_type, entity_id, created_at DESC);
CREATE INDEX IX_audit_time   ON audit_log(created_at DESC);
```