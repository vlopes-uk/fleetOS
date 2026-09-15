# Epic 12: Settings & Administration

**Labels:** `type: epic, module: settings, priority: medium`

## Goal

Configure Mapon, manage users, and control system settings.

## Features

### Feature 12.1: Mapon Settings

> Configure Mapon base URL, API key, and sync interval.

#### Story 12.1.1: Admin can configure Mapon settings

As an admin I want to configure Mapon so telemetry works.

**Tasks:**

- [ ] Build Blazor Settings/Mapon page
- [ ] Store settings securely in Key Vault
- [ ] Add Test Connection button
- [ ] Show sync status and last sync time
- [ ] Write settings tests

### Feature 12.2: User Management

> Create, edit, and deactivate users and assign roles.

#### Story 12.2.1: Admin can manage users

As an admin I want to create edit and deactivate users.

**Tasks:**

- [ ] Implement GET POST PUT /users
- [ ] Build Blazor Settings/Users page
- [ ] Assign roles
- [ ] Write user management tests
