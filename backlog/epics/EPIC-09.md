# Epic 9: Analytics, Reporting & Export

**Labels:** `type: epic, module: analytics, priority: medium`

## Goal

Provide dashboards, vehicle comparisons, driver rankings, and tax exports.

## Features

### Feature 9.1: Fleet Analytics Dashboard

> Fleet KPIs at a glance.

#### Story 9.1.1: Fleet manager sees fleet KPIs

As a fleet manager I want a dashboard with key metrics.

**Tasks:**

- [ ] Implement GET /analytics/fleet-overview
- [ ] Build Blazor Dashboard page
- [ ] Show revenue costs utilisation alerts
- [ ] Cache aggregates with 5-min TTL
- [ ] Write dashboard tests

### Feature 9.2: Vehicle Comparison

> Compare makes and models by TCO, revenue/km, and rating.

#### Story 9.2.1: Fleet manager can compare makes and models

As a fleet manager I want to see which cars perform best.

**Tasks:**

- [ ] Implement GET /analytics/vehicle-comparison
- [ ] Calculate Vehicle Score
- [ ] Build Blazor Vehicles/Comparison page
- [ ] Add chart visualisations
- [ ] Write comparison tests

### Feature 9.3: Driver Ranking

> Rank drivers by performance.

#### Story 9.3.1: Fleet manager can rank drivers

As a fleet manager I want to identify top and low performers.

**Tasks:**

- [ ] Implement GET /analytics/driver-ranking
- [ ] Aggregate ratings complaints revenue trips
- [ ] Build Blazor Analytics/Drivers page
- [ ] Write ranking tests

### Feature 9.4: Tax Export (IVA/IRS)

> Export IVA and IRS data for the accountant.

#### Story 9.4.1: Accountant can export IVA and IRS data

As an accountant I want to file taxes correctly.

**Tasks:**

- [ ] Implement GET /reports/tax-export
- [ ] Build CSV with IVA 6% and IRS withholding
- [ ] Build Blazor Reports/Tax page
- [ ] Write export tests
