# Epic 5: Telemetry (Mapon Mock)

**Labels:** `type: epic, module: telemetry, priority: high`

## Goal

Build an API-faithful Mapon mock server and integrate it via a provider-agnostic client.

## Features

### Feature 5.1: Mapon Mock Server

> Standalone mock that mirrors the Mapon REST contract.

#### Story 5.1.1: Developer can develop without real Mapon API

As a developer I want an API-faithful mock so I can develop offline.

**Tasks:**

- [ ] Create TvdeFleet.MaponMock project
- [ ] Implement /unit/list.json
- [ ] Implement /unit_data/list.json
- [ ] Implement /route/list.json
- [ ] Implement /driver/list.json
- [ ] Implement ApiKeyMiddleware
- [ ] Implement ConcurrencyLimitMiddleware
- [ ] Create MockFleetSeeder
- [ ] Create VehicleMovementSimulator
- [ ] Write contract tests

### Feature 5.2: MaponClient Integration

> Single client that works against mock and real Mapon via config.

#### Story 5.2.1: Developer can switch mock and real via config

As a developer I want a single client so switching is BaseUrl only.

**Tasks:**

- [ ] Define IMaponClient interface
- [ ] Implement MaponClient with Polly retry and bulkhead
- [ ] Add MaponOptions configuration
- [ ] Register HttpClient in DI
- [ ] Write unit and integration tests

### Feature 5.3: Mapon Sync Function

> Sync positions, unit data, and routes every 5 minutes.

#### Story 5.3.1: Fleet manager gets telemetry synced every 5 minutes

As a fleet manager I want up-to-date positions and mileage.

**Tasks:**

- [ ] Create MaponSyncFunction (Timer trigger)
- [ ] Upsert positions unit data and routes
- [ ] Write to telematics_events partitioned table
- [ ] Populate IMemoryCache for live map
- [ ] Log to background_job_logs
- [ ] Write sync tests

### Feature 5.4: Live Fleet Map

> Live map of all vehicles with status.

#### Story 5.4.1: Fleet manager can see live vehicle positions

As a fleet manager I want a live map of all vehicles.

**Tasks:**

- [ ] Implement GET /telematics/vehicles
- [ ] Build Blazor map component with Leaflet
- [ ] Poll every 30 seconds from cache
- [ ] Show vehicle status moving idle offline
- [ ] Write map integration tests
