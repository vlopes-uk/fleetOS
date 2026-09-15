# Epic 10: Mobile App & Push Notifications

**Labels:** `type: epic, module: mobile, priority: high`

## Goal

Deliver the .NET MAUI driver app with offline capability and push notifications.

## Features

### Feature 10.1: MAUI App Scaffolding

> MAUI project with all screens and navigation.

#### Story 10.1.1: Developer has MAUI project with all screens

As a developer I want the MAUI project ready to build.

**Tasks:**

- [ ] Create TvdeFleet.Maui project
- [ ] Create all Views and ViewModels
- [ ] Configure Shell navigation
- [ ] Add API Auth Location Notification services
- [ ] Write UI tests

### Feature 10.2: Offline Sync

> Log expenses and incidents offline and sync later.

#### Story 10.2.1: Driver can log expenses and incidents offline

As a driver I want to work without connectivity.

**Tasks:**

- [ ] Implement SQLite local storage
- [ ] Queue expenses and incidents for sync
- [ ] Sync when connectivity returns
- [ ] Show pending badge
- [ ] Write offline sync tests

### Feature 10.3: Push Notifications

> Payment and compliance alerts via push.

#### Story 10.3.1: Driver receives push notifications

As a driver I want push for payment and compliance alerts.

**Tasks:**

- [ ] Configure Azure Notification Hubs
- [ ] Implement PushNotificationFunction
- [ ] Register device tokens in MAUI
- [ ] Handle notification tap to navigate
- [ ] Write notification tests
