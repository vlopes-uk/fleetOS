# Epic 8: Incidents, Complaints & Expenses

**Labels:** `type: epic, module: incidents, priority: medium`

## Goal

Allow drivers to report incidents and expenses, and managers to log complaints.

## Features

### Feature 8.1: Driver Expense Logging

> Log expenses with photos and GPS.

#### Story 8.1.1: Driver can log expenses with photo

As a driver I want to log expenses so I can be reimbursed.

**Tasks:**

- [ ] Implement POST /expenses
- [ ] Build MAUI Log Expense page
- [ ] Capture GPS and photo
- [ ] Support offline logging with SQLite
- [ ] Sync when online
- [ ] Write expense tests

### Feature 8.2: Incident Reporting

> Report accidents, damage, or theft with photos.

#### Story 8.2.1: Driver can report accidents with photos

As a driver I want to report incidents so my manager is informed.

**Tasks:**

- [ ] Implement POST /incidents
- [ ] Build MAUI Report Incident page
- [ ] Capture GPS and photos
- [ ] Set severity and at_fault flag
- [ ] Notify fleet manager
- [ ] Write incident tests

### Feature 8.3: Complaint Management

> Log and resolve customer complaints with penalties.

#### Story 8.3.1: Fleet manager can log and resolve complaints

As a fleet manager I want to resolve complaints with a penalty.

**Tasks:**

- [ ] Implement GET POST /complaints
- [ ] Implement PUT /complaints/{id}/resolve
- [ ] Build Blazor Complaints page
- [ ] Link penalty to billing engine
- [ ] Write complaint tests
