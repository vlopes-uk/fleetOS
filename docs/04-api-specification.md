# API Specification

**Version:** 4.0 · **Companion to:** Requirements Documentation v4.0

All endpoints are prefixed with `/api/v1`. Except `/auth/*`, all require a JWT Bearer token.

## 7.1 Authentication

| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth/login` | Authenticate, receive access + refresh tokens |
| POST | `/auth/refresh` | Refresh access token |
| POST | `/auth/logout` | Revoke refresh token |

## 7.2 Fleet & Vehicles

| Method | Endpoint | Description |
|---|---|---|
| GET | `/vehicles` | List vehicles (filter: status, make, fuel_type) |
| POST | `/vehicles` | Register new vehicle |
| GET | `/vehicles/{id}` | Vehicle details with compliance status |
| PUT | `/vehicles/{id}` | Update vehicle |
| GET | `/vehicles/{id}/compliance` | Compliance records & expiry alerts |
| POST | `/vehicles/{id}/compliance` | Add compliance record |
| GET | `/vehicles/{id}/analytics` | TCO, revenue/km, utilisation |
| GET | `/vehicles/analytics/compare` | Compare makes/models by performance |

### Sample — `GET /vehicles/{id}/analytics`

```json
{
  "vehicle_id": "a1b2c3d4-...",
  "make": "Toyota",
  "model": "Corolla Hybrid",
  "period": "2026-08",
  "metrics": {
    "total_revenue": 3250.00,
    "total_expenses": 580.50,
    "net_revenue": 2669.50,
    "distance_km": 4200,
    "revenue_per_km": 0.775,
    "cost_per_km": 0.138,
    "trips_completed": 310,
    "average_rating": 4.82,
    "utilisation_pct": 78.5
  }
}
```

## 7.3 Drivers

| Method | Endpoint | Description |
|---|---|---|
| GET | `/drivers` | List drivers |
| POST | `/drivers` | Register driver |
| GET | `/drivers/{id}` | Driver profile & compliance |
| PUT | `/drivers/{id}` | Update driver |
| GET | `/drivers/{id}/compliance` | Compliance documents & expiry |
| GET | `/drivers/{id}/performance` | Ratings, complaints, incidents summary |
| GET | `/drivers/{id}/earnings` | Earnings breakdown by period |
| POST | `/drivers/{id}/assign-vehicle` | Assign vehicle to driver |

## 7.4 Trips & Earnings

| Method | Endpoint | Description |
|---|---|---|
| GET | `/trips` | List trips (filter: driver, vehicle, platform, date) |
| GET | `/trips/{id}` | Trip details |
| POST | `/trips/sync/uber` | Trigger Uber sync (mock) — queues a message |
| POST | `/trips/import/bolt` | Upload Bolt CSV (multipart) |
| GET | `/earnings/summary` | Consolidated earnings by driver/vehicle/period |
| GET | `/earnings/export` | Export earnings CSV |

## 7.5 Billing & Payments

| Method | Endpoint | Description |
|---|---|---|
| GET | `/billing/cycles` | List billing cycles |
| POST | `/billing/cycles/generate` | Generate cycle for contract |
| GET | `/billing/cycles/{id}` | Cycle details with line items |
| POST | `/billing/cycles/{id}/approve` | Approve cycle |
| POST | `/billing/cycles/{id}/invoice` | Generate invoice |
| GET | `/billing/penalties` | List applied penalties |
| GET | `/payments/pending` | List pending payments |
| GET | `/payments/driver/{driverId}` | Payment history for a driver |
| POST | `/payments/{id}/mark-paid` | Mark payment as paid |
| POST | `/payments/{id}/notify` | Notify driver (push/email/SMS) |
| GET | `/payments/export` | Export payment report (CSV/PDF) |

### Sample — `POST /billing/cycles/generate`

**Request:**

```json
{
  "contract_id": "c1d2e3f4-...",
  "period_start": "2026-09-01",
  "period_end": "2026-09-07"
}
```

**Response:**

```json
{
  "billing_cycle_id": "b1c2d3e4-...",
  "contract_id": "c1d2e3f4-...",
  "business_model": "profit_share",
  "period": { "start": "2026-09-01", "end": "2026-09-07" },
  "revenue": {
    "uber_gross": 850.00,
    "bolt_gross": 620.00,
    "total_gross": 1470.00,
    "platform_fees": 294.00,
    "net_revenue": 1176.00
  },
  "expenses": { "fuel": 85.00, "tolls": 22.50, "total": 107.50 },
  "split": { "driver_pct": 45.0, "driver_share": 529.20, "company_share": 646.80 },
  "penalties": [
    { "type": "complaint", "amount": 25.00, "reference": "complaint-uuid" }
  ],
  "net_payable_to_driver": 504.20
}
```

### Sample — `POST /payments/{id}/mark-paid`

**Request:**

```json
{
  "payment_method": "bank_transfer",
  "payment_reference": "TRF-20260915-001",
  "notes": "SEPA transfer to driver IBAN",
  "notify_driver": true,
  "notification_method": "push"
}
```

**Response:**

```json
{
  "payment_id": "p1a2b3c4-...",
  "billing_cycle_id": "b1c2d3e4-...",
  "driver_id": "d1e2f3g4-...",
  "amount": 504.20,
  "status": "paid",
  "marked_paid_at": "2026-09-15T14:30:00Z",
  "marked_paid_by": "admin-user-uuid",
  "driver_notified_at": null,
  "notification_queued": true,
  "notification_method": "push"
}
```

> `driver_notified_at` is populated asynchronously by the `NotifyDriverFunction` once it processes the queue message.

## 7.6 Incidents & Complaints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/incidents` | List incidents |
| POST | `/incidents` | Report incident |
| PUT | `/incidents/{id}` | Update incident status |
| GET | `/complaints` | List complaints |
| POST | `/complaints` | Log complaint |
| PUT | `/complaints/{id}/resolve` | Resolve & apply penalty |

## 7.7 Expenses

| Method | Endpoint | Description |
|---|---|---|
| GET | `/expenses` | List expenses |
| POST | `/expenses` | Record expense |
| PUT | `/expenses/{id}/reconcile` | Reconcile expense |

## 7.8 Telematics (Mapon)

| Method | Endpoint | Description |
|---|---|---|
| GET | `/telematics/vehicles` | All vehicles with latest GPS (from cache) |
| GET | `/telematics/vehicles/{id}/location` | Latest position |
| GET | `/telematics/vehicles/{id}/history` | GPS history (range) |
| GET | `/telematics/vehicles/{id}/odometer` | Odometer readings |
| GET | `/telematics/vehicles/{id}/routes` | Route history |
| POST | `/telematics/sync` | Queue an immediate Mapon sync |
| GET | `/telematics/sync/status` | Last sync status |

## 7.9 Integrations

| Method | Endpoint | Description |
|---|---|---|
| POST | `/integrations/uber/sync` | Queue Uber sync (mock) |
| POST | `/integrations/bolt/import` | Upload Bolt CSV (multipart) |
| GET | `/integrations/status` | Health of Uber, Bolt, Mapon |
| GET | `/integrations/logs` | Sync history |

## 7.10 Analytics & Reports

| Method | Endpoint | Description |
|---|---|---|
| GET | `/analytics/fleet-overview` | Fleet-wide KPIs |
| GET | `/analytics/vehicle-comparison` | Compare makes/models |
| GET | `/analytics/driver-ranking` | Driver performance ranking |
| GET | `/reports/compliance-expiry` | Upcoming expiries |
| GET | `/reports/financial-summary` | Revenue/expense summary |
| GET | `/reports/tax-export` | IVA/IRS export |

## Error Response Shape

All errors follow a consistent envelope:

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "One or more fields are invalid.",
    "details": [
      { "field": "nif", "message": "NIF must contain exactly 9 digits." }
    ]
  }
}
```

| HTTP Status | Meaning |
|---|---|
| 200 | Success |
| 201 | Created |
| 204 | No Content (successful delete) |
| 400 | Bad Request / validation failed |
| 401 | Unauthenticated |
| 403 | Forbidden (role mismatch) |
| 404 | Not Found |
| 409 | Conflict (e.g., compliance expired, duplicate) |
| 429 | Rate limited |
| 500 | Server error |

## Versioning

The API uses URL path versioning (`/api/v1/`). Breaking changes increment the major version. Non-breaking additions are made within the current version.