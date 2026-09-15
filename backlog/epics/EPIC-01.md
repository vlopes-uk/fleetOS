# Epic 1: Platform Foundation & Authentication

**Labels:** `type: epic, module: core, priority: critical`

## Goal

Establish the core .NET solution, database schema, and secure authentication so all other modules can be built on a solid base.

## Features

### Feature 1.1: Solution Scaffolding

> Set up the .NET solution with API, Blazor, MAUI, Functions, and Mock projects.

#### Story 1.1.1: Developer can build the solution locally

As a developer I want a solution with all projects so I can work consistently.

**Tasks:**

- [ ] Create TvdeFleetManagement.sln
- [ ] Create API, Application, Domain, Infrastructure, Functions, MaponMock, Blazor, MAUI projects
- [ ] Configure project references per solution structure
- [ ] Add NuGet packages per spec
- [ ] Set up appsettings.json for each environment

### Feature 1.2: Database Schema & Migrations

> Create all tables, indexes, and partitions via EF Core migrations.

#### Story 1.2.1: Developer can apply migrations to a fresh DB

As a developer I want migrations that create the entire schema.

**Tasks:**

- [ ] Create AppDbContext with all DbSets
- [ ] Configure entity relationships and constraints
- [ ] Add SQL Server partitioning for telematics_events
- [ ] Add columnstore index on telematics_events
- [ ] Generate initial migration
- [ ] Write seed data script

### Feature 1.3: JWT Authentication

> Implement login, refresh, and logout with JWT tokens.

#### Story 1.3.1: User can log in with email and password

As a user I want to log in so I can access the platform securely.

**Tasks:**

- [ ] Implement POST /auth/login
- [ ] Implement POST /auth/refresh
- [ ] Implement POST /auth/logout
- [ ] Configure JWT issuer, audience, signing key
- [ ] Add bcrypt or PBKDF2 password hashing
- [ ] Write auth unit tests

### Feature 1.4: RBAC Authorization

> Enforce role-based access control across all controllers.

#### Story 1.4.1: Admin can control role-based access

As an admin I want to restrict what each role can access.

**Tasks:**

- [ ] Define roles admin, fleet_manager, accountant, viewer
- [ ] Create Authorize policies
- [ ] Apply policies to all controllers
- [ ] Write authorization tests
