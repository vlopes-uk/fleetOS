# Epic 2: Fleet & Vehicle Management

**Labels:** `type: epic, module: fleet, priority: high`

## Goal

Register, track, and manage every vehicle in the fleet, including its compliance and telematics mapping.

## Features

### Feature 2.1: Vehicle CRUD

> Allow fleet managers to add, view, edit, and retire vehicles.

#### Story 2.1.1: Fleet manager can manage vehicle inventory

As a fleet manager I want to add view edit and retire vehicles.

**Tasks:**

- [ ] Implement GET POST PUT /vehicles
- [ ] Implement GET /vehicles/{id}
- [ ] Add filters status make fuel_type
- [ ] Build Blazor Vehicles/List page
- [ ] Build Blazor Vehicles/Detail page
- [ ] Write API and UI tests

### Feature 2.2: Vehicle Compliance Tracking

> Record IPO, insurance, sticker, and IMT registration details.

#### Story 2.2.1: Fleet manager can record and monitor compliance

As a fleet manager I want to track IPO insurance sticker and IMT reg.

**Tasks:**

- [ ] Implement GET POST /vehicles/{id}/compliance
- [ ] Add expiry alert calculation
- [ ] Build compliance section on Vehicle/Detail
- [ ] Write compliance service unit tests

### Feature 2.3: Mapon Unit Mapping

> Link each vehicle to its Mapon unit ID.

#### Story 2.3.1: Fleet manager can link a vehicle to Mapon

As a fleet manager I want to map a vehicle to its Mapon unit ID.

**Tasks:**

- [ ] Add mapon_unit_id and mapon_unit_number columns
- [ ] Build UI to search and link Mapon units
- [ ] Handle unmapped vehicles gracefully
- [ ] Write mapping validation tests

### Feature 2.4: Vehicle Analytics

> Show TCO, revenue/km, and utilisation per vehicle.

#### Story 2.4.1: Fleet manager can compare vehicle performance

As a fleet manager I want TCO revenue per km and utilisation per vehicle.

**Tasks:**

- [ ] Implement GET /vehicles/{id}/analytics
- [ ] Implement GET /vehicles/analytics/compare
- [ ] Build Blazor Vehicles/Comparison page
- [ ] Add 5-minute cache for analytics
- [ ] Write aggregation tests
