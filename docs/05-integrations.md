# Integration Specifications

**Version:** 4.0 · **Companion to:** Requirements Documentation v4.0

All external integrations are **mocked** for now. Each mock is designed to be swapped for the real provider via configuration only — no application code changes.

| Integration | Type | Swap mechanism |
|---|---|---|
| Uber | Mocked API | `UberOptions.BaseUrl` |
| Bolt | Mocked CSV import | Real export uses same column names |
| Mapon | API-faithful mock server | `MaponOptions.BaseUrl` + `ApiKey` |

---

## 8.1 Uber — Mocked API

Mirrors the Uber Driver API payments endpoint.

**Endpoint:** `GET /mock/uber/v1/partners/payments`

### Sample Response

```json
{
  "count": 1200,
  "limit": 50,
  "offset": 0,
  "payments": [
    {
      "payment_id": "5cb8304c-f3f0-4a46-b6e3-b55e020750d7",
      "category": "fare",
      "event_time": 1726380000,
      "trip_id": "trip_abc123",
      "amount": 1250,
      "currency_code": "EUR"
    },
    {
      "payment_id": "7dc9415d-g4g1-5b57-c7f4-c66f131861e8",
      "category": "fare",
      "event_time": 1726383600,
      "trip_id": "trip_def456",
      "amount": 980,
      "currency_code": "EUR"
    }
  ]
}
```

### Constraints (matching real API)

- Maximum time range per query: **10 days**.
- `limit` max: 50; default: 5.
- Payments available in near real-time.
- Cancelled trips with no payment do not appear.
- Fleet-managed drivers have no payments associated (response is an empty array).

### Sync Logic

The `UberSyncFunction` paginates through 10-day windows, converts `amount` from cents to EUR, and maps `event_time` (Unix timestamp) to `started_at`. Deduplication is performed on `platform_trip_id`.

```csharp
public interface IUberClient
{
    Task<IReadOnlyList<UberPayment>> GetPaymentsAsync(
        DateTime fromUtc, DateTime toUtc, CancellationToken ct);
}
```

---

## 8.2 Bolt — Mocked CSV Import

Based on the Bolt Fleet Manager Portal export format.

### Sample CSV

```csv
order_time,pickup_address,dropoff_address,ride_price,booking_fee,driver_earnings,driver_id,vehicle_id,tip,ride_distance_km,ride_duration_min
2026-09-15 08:30:00,"Rua Augusta, Lisbon","Av. da Liberdade, Lisbon",12.50,0.63,9.87,drv_001,veh_001,0.00,4.2,18
2026-09-15 09:15:00,"Praça do Comércio, Lisbon","Belém, Lisbon",18.75,0.94,14.81,drv_001,veh_001,1.50,8.7,32
2026-09-15 10:00:00,"Cascais","Sintra",28.00,1.40,22.12,drv_002,veh_002,0.00,22.5,45
```

### Column Mapping

| CSV Column | Target Column | Notes |
|---|---|---|
| `order_time` | `trips.started_at` | Parsed as `DATETIME2(3)` |
| `pickup_address` | `trips.pickup_address` | |
| `dropoff_address` | `trips.dropoff_address` | |
| `ride_price` | `trips.gross_fare` | |
| `booking_fee` | `trips.platform_fee` | |
| `driver_earnings` | `trips.net_earning` | |
| `driver_id` | matched to `drivers.id` via external mapping | |
| `vehicle_id` | matched to `vehicles.id` via external mapping | |
| `tip` | `trips.tip_amount` | |
| `ride_distance_km` | `trips.distance_km` | |
| `ride_duration_min` | `trips.duration_minutes` | |

### Import Logic

Parsed **synchronously** by the API using `CsvHelper`:

1. Validate file size and MIME type.
2. Read CSV into typed row objects.
3. Validate required headers.
4. For each row:
   - Look up driver by `driver_id` mapping.
   - Look up vehicle by `vehicle_id` mapping.
   - Deduplicate on `order_time + driver_id + ride_price`.
   - Insert if new.
5. Return import summary: `{ imported, skipped, errors }`.

**Endpoint:** `POST /api/v1/integrations/bolt/import` (multipart/form-data)

---

## 8.3 Mapon — API-Faithful Mock

### Design Principles

The mock is **not** an in-process fake. It is a standalone ASP.NET Core minimal API that faithfully reproduces Mapon's REST contract, so that:

1. The production `MaponClient` HTTP path is exercised during development.
2. Serialisation, pagination, auth, retries (Polly), and timeouts are tested against a realistic surface.
3. Going live requires **only** `BaseUrl` + `ApiKey` change.

### Fidelity Requirements

| Aspect | Requirement |
|---|---|
| Base path | `/api/v1/` |
| Auth | API key via `?key=` query param (optionally `Authorization` header) |
| Response envelope | `{ "data": { ... } }` |
| Content type | `application/json` |
| Date format | ISO 8601 UTC (`2026-09-15T10:30:00Z`) |
| Rate limiting | Max 5 concurrent requests → HTTP 429 |
| Error format | `{ "error": { "code": N, "message": "...", "details": "..." } }` |
| HTTP codes | 200, 400, 401, 403, 404, 429, 500 |

### Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/v1/unit/list.json` | Units with latest GPS + metadata |
| GET | `/api/v1/unit_data/list.json` | Unit data (mileage, fuel, ignition, CAN) |
| GET | `/api/v1/unit_group/list.json` | Unit groups |
| GET | `/api/v1/route/list.json` | Route history for a unit |
| GET | `/api/v1/route_data/list.json` | Detailed route (polyline, stops) |
| GET | `/api/v1/driver/list.json` | Drivers registered in telematics |
| GET | `/api/v1/driver_data/list.json` | Driver-specific data |

### Sample — `GET /api/v1/unit/list.json?key=...`

```json
{
  "data": {
    "units": [
      {
        "unit_id": 101,
        "unit_number": "AA-12-BB",
        "name": "Toyota Corolla Hybrid #1",
        "make": "Toyota",
        "model": "Corolla Hybrid",
        "year": 2023,
        "group_id": 5,
        "lat": 38.7223,
        "lng": -9.1393,
        "speed": 42.5,
        "direction": 180,
        "altitude": 12,
        "mileage": 45230,
        "fuel_level": 68.2,
        "ignition": true,
        "last_update": "2026-09-15T10:30:00Z",
        "driver_id": 501
      }
    ]
  }
}
```

### Sample — `GET /api/v1/unit_data/list.json?unit_ids=101,102`

```json
{
  "data": {
    "units": [
      {
        "unit_id": 101,
        "mileage": 45230,
        "fuel_level": 68.2,
        "ignition": true,
        "movement": true,
        "can": {
          "engine_rpm": 1850,
          "coolant_temp": 88,
          "fuel_consumption_l_per_100km": 4.8
        },
        "timestamp": "2026-09-15T10:30:00Z"
      }
    ]
  }
}
```

### Sample — `GET /api/v1/route/list.json?unit_id=101&from=...&to=...`

```json
{
  "data": {
    "routes": [
      {
        "route_id": 900123,
        "unit_id": 101,
        "driver_id": 501,
        "start_time": "2026-09-15T08:14:00Z",
        "end_time": "2026-09-15T08:32:00Z",
        "start_address": "Rua Augusta, Lisbon",
        "end_address": "Av. da Liberdade, Lisbon",
        "distance_km": 4.2,
        "duration_min": 18,
        "avg_speed_kmh": 14.0,
        "max_speed_kmh": 52.3,
        "fuel_used_l": 0.31,
        "harsh_braking_count": 1,
        "harsh_acceleration_count": 0,
        "harsh_cornering_count": 0
      }
    ]
  }
}
```

### Sample — `GET /api/v1/driver/list.json`

```json
{
  "data": {
    "drivers": [
      {
        "driver_id": 501,
        "name": "João Silva",
        "unit_id": 101,
        "card_number": "DRV-0001",
        "active": true
      }
    ]
  }
}
```

### Error Response

```json
{
  "error": {
    "code": 404,
    "message": "Unit not found",
    "details": "No unit with id 999 exists for this API key"
  }
}
```

### Configuration Switch (Mock ⇄ Real)

**Development (`appsettings.Development.json`)**

```json
{
  "Mapon": {
    "BaseUrl": "http://localhost:5100/api/v1/",
    "ApiKey": "mock-key-dev",
    "SyncIntervalMinutes": 5,
    "MaxConcurrentRequests": 4,
    "Enabled": true
  }
}
```

**Production (`appsettings.Production.json`)**

```json
{
  "Mapon": {
    "BaseUrl": "https://www.mapon.com/api/v1/",
    "ApiKey": "REPLACE_WITH_KEY_VAULT_REFERENCE",
    "SyncIntervalMinutes": 5,
    "MaxConcurrentRequests": 4,
    "Enabled": true
  }
}
```

### Service Registration (identical across environments)

```csharp
services.Configure<MaponOptions>(configuration.GetSection("Mapon"));

services.AddHttpClient<IMaponClient, MaponClient>((sp, http) =>
{
    var opts = sp.GetRequiredService<IOptions<MaponOptions>>().Value;
    http.BaseAddress = new Uri(opts.BaseUrl);
    http.Timeout = TimeSpan.FromSeconds(30);
})
.AddTransientHttpErrorPolicy(p => p
    .WaitAndRetryAsync(3, attempt => TimeSpan.FromSeconds(Math.Pow(2, attempt))))
.AddPolicyHandler(Policy.BulkheadAsync<HttpResponseMessage>(
    maxParallelization: 4, maxQueuingActions: 10,
    onBulkheadRejectedAsync: _ => Task.CompletedTask));
```

### `MaponClient` Implementation

```csharp
public interface IMaponClient
{
    Task<IReadOnlyList<MaponUnit>> GetUnitsAsync(CancellationToken ct);
    Task<IReadOnlyList<MaponUnitData>> GetUnitDataAsync(IEnumerable<int> unitIds, CancellationToken ct);
    Task<IReadOnlyList<MaponRoute>> GetRoutesAsync(int unitId, DateTime fromUtc, DateTime toUtc, CancellationToken ct);
    Task<IReadOnlyList<MaponDriver>> GetDriversAsync(CancellationToken ct);
}

public sealed class MaponClient : IMaponClient
{
    private readonly HttpClient _http;
    private readonly MaponOptions _options;

    public MaponClient(HttpClient http, IOptions<MaponOptions> options)
    {
        _http = http;
        _options = options.Value;
    }

    private string WithKey(string path)
        => $"{path}{(path.Contains('?') ? "&" : "?")}key={Uri.EscapeDataString(_options.ApiKey)}";

    public async Task<IReadOnlyList<MaponUnit>> GetUnitsAsync(CancellationToken ct)
    {
        var url = WithKey("unit/list.json");
        var envelope = await _http.GetFromJsonAsync<MaponEnvelope<MaponUnitList>>(url, ct);
        return envelope?.Data?.Units ?? [];
    }

    public async Task<IReadOnlyList<MaponUnitData>> GetUnitDataAsync(IEnumerable<int> unitIds, CancellationToken ct)
    {
        var ids = string.Join(",", unitIds);
        var url = WithKey($"unit_data/list.json?unit_ids={ids}");
        var envelope = await _http.GetFromJsonAsync<MaponEnvelope<MaponUnitDataList>>(url, ct);
        return envelope?.Data?.Units ?? [];
    }

    public async Task<IReadOnlyList<MaponRoute>> GetRoutesAsync(int unitId, DateTime fromUtc, DateTime toUtc, CancellationToken ct)
    {
        var url = WithKey($"route/list.json?unit_id={unitId}" +
                          $"&from={fromUtc:yyyy-MM-ddTHH:mm:ssZ}" +
                          $"&to={toUtc:yyyy-MM-ddTHH:mm:ssZ}");
        var envelope = await _http.GetFromJsonAsync<MaponEnvelope<MaponRouteList>>(url, ct);
        return envelope?.Data?.Routes ?? [];
    }

    public async Task<IReadOnlyList<MaponDriver>> GetDriversAsync(CancellationToken ct)
    {
        var url = WithKey("driver/list.json");
        var envelope = await _http.GetFromJsonAsync<MaponEnvelope<MaponDriverList>>(url, ct);
        return envelope?.Data?.Drivers ?? [];
    }
}
```

### Auth Middleware

```csharp
public sealed class ApiKeyMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ApiKeyValidator _validator;

    public ApiKeyMiddleware(RequestDelegate next, ApiKeyValidator validator)
    {
        _next = next;
        _validator = validator;
    }

    public async Task InvokeAsync(HttpContext ctx)
    {
        if (ctx.Request.Path.StartsWithSegments("/api/v1"))
        {
            var key = ctx.Request.Query["key"].FirstOrDefault()
                      ?? ctx.Request.Headers["Authorization"].FirstOrDefault()?.Replace("Bearer ", "");

            if (string.IsNullOrWhiteSpace(key))
            {
                ctx.Response.StatusCode = StatusCodes.Status401Unauthorized;
                await ctx.Response.WriteAsJsonAsync(new { error = new { code = 401, message = "API key required" } });
                return;
            }

            if (!_validator.IsValid(key))
            {
                ctx.Response.StatusCode = StatusCodes.Status401Unauthorized;
                await ctx.Response.WriteAsJsonAsync(new { error = new { code = 401, message = "Invalid API key" } });
                return;
            }
        }
        await _next(ctx);
    }
}
```

### Concurrency Limit Middleware (5 concurrent)

```csharp
public sealed class ConcurrencyLimitMiddleware
{
    private readonly SemaphoreSlim _semaphore = new(5, 5);
    private readonly RequestDelegate _next;

    public ConcurrencyLimitMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext ctx)
    {
        if (!await _semaphore.WaitAsync(0))
        {
            ctx.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            await ctx.Response.WriteAsJsonAsync(new
            {
                error = new { code = 429, message = "Too many concurrent requests (limit 5)" }
            });
            return;
        }

        try { await _next(ctx); }
        finally { _semaphore.Release(); }
    }
}
```

### Mock Data Seeder

The seeder produces a realistic Portuguese fleet:

| Field | Strategy |
|---|---|
| `unit_id` | Sequential from 101 |
| `unit_number` | Portuguese plate format (`AA-12-BB`) |
| `make` / `model` | Toyota Corolla Hybrid, Tesla Model 3, Skoda Octavia iV, Opel Astra, Peugeot 308 |
| `lat` / `lng` | Anchored around Lisbon and Porto metro areas |
| `mileage` | 20,000–120,000 km, incremental |
| `fuel_level` | 20–95%; EV recharge cycles simulated |
| `ignition` / `speed` | Simulated driving cycles |

The `VehicleMovementSimulator` hosted service updates each unit's position, speed, mileage, and fuel level every 5–30 seconds, producing realistic driving patterns within Lisbon/Porto bounding boxes, and injecting occasional harsh-braking and harsh-acceleration events.

### Contract Testing

1. **`MaponClientContractTests`** — Run the full `MaponClient` against the mock; assert response shapes, error handling, retries, rate limiting.
2. **Recorded Fixtures** — Store redacted real Mapon responses under `tests/Fixtures/Mapon/`; replay through `MaponClient` to verify deserialisation.
3. **Swap Validation** — CI job switches `BaseUrl` to the real Mapon sandbox (when available) and runs the same suite.
4. **Schema Diff** — Store mock and documented Mapon schemas; diff job flags drift.