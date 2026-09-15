# Epic 3: Driver Management & Compliance

**Labels:** `type: epic, module: drivers, priority: high`

## Goal

Onboard drivers, track their CMTVDE and criminal record validity, and manage vehicle assignments.

## Features

### Feature 3.1: Driver CRUD

> Register, view, and manage drivers.

#### Story 3.1.1: Fleet manager can manage drivers

As a fleet manager I want to register and edit drivers.

**Tasks:**

- [ ] Implement GET POST PUT /drivers
- [ ] Implement GET /drivers/{id}
- [ ] Build Blazor Drivers/List page
- [ ] Build Blazor Drivers/Detail page
- [ ] Write API and UI tests

### Feature 3.2: CMTVDE & Document Tracking

> Upload and track CMTVDE, criminal record, and training certificates.

#### Story 3.2.1: Fleet manager can track driver documents

As a fleet manager I want to upload and track CMTVDE and other docs.

**Tasks:**

- [ ] Implement GET POST /drivers/{id}/compliance
- [ ] Add document upload to Blob Storage
- [ ] Build compliance section on Driver/Detail
- [ ] Write expiry validation tests

### Feature 3.3: Vehicle Assignment & Handover

> Assign vehicle to driver and log handover condition.

#### Story 3.3.1: Fleet manager can assign vehicle and log handover

As a fleet manager I want to assign a vehicle and capture handover.

**Tasks:**

- [ ] Implement POST /drivers/{id}/assign-vehicle
- [ ] Implement handover log endpoints
- [ ] Block assignment if compliance expired
- [ ] Build assignment UI in Blazor
- [ ] Write assignment tests

### Feature 3.4: Driver Performance Summary

> Show ratings, complaints, and incidents in one view.

#### Story 3.4.1: Fleet manager can see driver performance

As a fleet manager I want ratings complaints and incidents in one view.

**Tasks:**

- [ ] Implement GET /drivers/{id}/performance
- [ ] Aggregate from ratings complaints incidents
- [ ] Build performance card on Driver/Detail
- [ ] Write aggregation tests
