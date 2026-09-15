# Epic 11: Compliance Alert Engine

**Labels:** `type: epic, module: compliance, priority: critical`

## Goal

Automatically scan and alert on all vehicle and driver compliance expiries.

## Features

### Feature 11.1: Daily Compliance Scan

> Daily scan of all compliance expiries.

#### Story 11.1.1: Fleet manager gets daily scan of all expiries

As a fleet manager I want daily scanning so I never miss a renewal.

**Tasks:**

- [ ] Create ComplianceAlertFunction (Timer daily 06:00)
- [ ] Scan vehicle IMT reg insurance IPO sticker
- [ ] Scan driver CMTVDE criminal record licence
- [ ] Scan vehicle age 10y or 12y EV
- [ ] Generate alerts at 30 15 and 7-day thresholds
- [ ] Write alert tests

### Feature 11.2: Alert Notifications

> Email and push alerts for expiring documents.

#### Story 11.2.1: Driver or manager receives expiring-doc alerts

As a driver or manager I want alerts so I can renew in time.

**Tasks:**

- [ ] Enqueue notifications from alert engine
- [ ] Send via NotifyDriverFunction
- [ ] Build Blazor Compliance/Alerts page
- [ ] Write notification tests
