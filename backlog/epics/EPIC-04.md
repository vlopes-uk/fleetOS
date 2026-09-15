# Epic 4: Trip & Revenue Synchronisation

**Labels:** `type: epic, module: trips, priority: high`

## Goal

Ingest trip data from Uber (mock API) and Bolt (CSV) into a unified trips table.

## Features

### Feature 4.1: Uber Sync (Azure Function)

> Sync Uber payment data every 15 minutes.

#### Story 4.1.1: Fleet manager gets Uber data synced automatically

As a fleet manager I want Uber payments synced every 15 minutes.

**Tasks:**

- [ ] Create UberSyncFunction (Timer trigger)
- [ ] Implement Uber mock API client
- [ ] Paginate 10-day windows
- [ ] Convert cents to EUR and map Unix timestamp
- [ ] Deduplicate on platform_trip_id
- [ ] Log to integration_sync_logs
- [ ] Write sync tests

### Feature 4.2: Bolt CSV Import

> Upload Bolt CSV exports to import historical trips.

#### Story 4.2.1: Fleet manager can upload Bolt CSV export

As a fleet manager I want to import historical Bolt trips.

**Tasks:**

- [ ] Implement POST /integrations/bolt/import
- [ ] Parse with CsvHelper
- [ ] Validate headers and data types
- [ ] Deduplicate on order_time driver_id ride_price
- [ ] Return import summary
- [ ] Build upload UI in Blazor
- [ ] Write parser and import tests

### Feature 4.3: Trip List & Detail

> Browse and filter trips by driver, vehicle, platform, and date.

#### Story 4.3.1: Fleet manager can browse and filter trips

As a fleet manager I want to audit trips by driver vehicle and date.

**Tasks:**

- [ ] Implement GET /trips with filters
- [ ] Implement GET /trips/{id}
- [ ] Build Blazor Trips page with filters
- [ ] Add export to CSV
- [ ] Write query tests
