# Business Logic

**Version:** 4.0 · **Companion to:** Requirements Documentation v4.0

This document specifies the core business rules that the platform must enforce — compliance monitoring, billing calculations, penalty/bonus adjustments, and the manual payment workflow.

---

## 11.1 Compliance Alert Engine

Executed daily by `ComplianceAlertFunction` at 06:00 WET.

| Trigger | Level | Action |
|---|---|---|
| Vehicle IMT registration expires in 30 days | Warning | Email fleet manager |
| Vehicle IMT registration expires in 7 days | Critical | Block vehicle assignment |
| Driver CMTVDE expires in 30 days | Warning | Email driver + manager |
| Driver CMTVDE expires in 7 days | Critical | Block driver assignment |
| Insurance expires in 15 days | Warning | Email fleet manager |
| IPO due in 15 days | Warning | Email fleet manager |
| Vehicle age exceeds 10 years (12 for EV) | Critical | Flag for decommissioning |
| Criminal record check expired | Critical | Block driver assignment |

### Pseudocode

```
For each active vehicle:
    For each compliance record (IMT reg, insurance, IPO, sticker):
        days = expiry_date - today
        if days <= 7:
            raise_critical_alert(vehicle, record)
            block_assignment(vehicle)
        elif days <= 30:
            raise_warning_alert(vehicle, record)

    if vehicle.age > 10 years OR (is_electric AND vehicle.age > 12 years):
        raise_critical_alert(vehicle, "over_age_limit")
        flag_for_decommissioning(vehicle)

For each active driver:
    For each compliance doc (CMTVDE, criminal record, licence):
        days = expiry_date - today
        if days <= 7:
            raise_critical_alert(driver, doc)
            block_assignment(driver)
        elif days <= 30:
            raise_warning_alert(driver, doc)
```

### Blocking Enforcement

`POST /drivers/{id}/assign-vehicle` returns **409 Conflict** if any compliance record on either the driver or the vehicle is expired or within 7 days of expiry. The response body includes the specific blocking reasons.

---

## 11.2 Penalty & Bonus Engine

Applied automatically at billing cycle generation.

### Rule 1 — Complaint with Penalty

**Trigger:** A complaint is `resolved` with `penalty_applied > 0` within the billing period.

**Action:** Deduct the sum of `penalty_applied` from the driver's share in the current cycle.

```
driver_share -= SUM(complaints.penalty_applied
                    WHERE driver_id = ?
                    AND status = 'resolved'
                    AND resolved_at BETWEEN period_start AND period_end)
```

### Rule 2 — At-Fault Accident

**Trigger:** An incident with `at_fault = true` in the period.

**Action:** Deduct the repair cost (up to insurance excess) over a configurable number of cycles (default 4).

```
amortized_cost = MIN(repair_cost, insurance_excess) / N_cycles
driver_share -= amortized_cost
```

### Rule 3 — Rating Threshold Deduction

**Trigger:** Driver's average rating for the period falls below 4.5.

**Action:** Reduce commission percentage by a configurable amount (default 2 percentage points).

```
if avg_rating < 4.5:
    effective_commission_pct = commission_pct - penalty_points
```

### Rule 4 — Perfect Rating Bonus

**Trigger:** Driver's average rating for the period exceeds 4.9 **and** has zero complaints.

**Action:** Apply a bonus percentage to the driver's share (default 2%).

```
if avg_rating > 4.9 AND complaint_count == 0:
    driver_share *= (1 + bonus_pct / 100)
```

### Configuration

All thresholds and defaults are configurable per operator via `appsettings.json`:

```json
{
  "PenaltyEngine": {
    "RatingThreshold": 4.5,
    "RatingPenaltyPoints": 2.0,
    "PerfectRatingThreshold": 4.9,
    "PerfectRatingBonusPct": 2.0,
    "AccidentAmortizationCycles": 4,
    "InsuranceExcessDefault": 500.00
  }
}
```

---

## 11.3 Vehicle Performance Ranking

Composite score used to rank vehicles and identify which makes/models deliver the best return for each business model.

```
Vehicle Score = (revenue_per_km × 0.4)
              + (average_rating × 0.3)
              - (cost_per_km × 0.2)
              - (complaints_per_100_trips × 0.1)
```

### Metric Definitions

| Metric | Computation |
|---|---|
| `revenue_per_km` | `SUM(trips.net_earning) / SUM(trips.distance_km)` for the period |
| `average_rating` | `AVG(driver_ratings.rating)` weighted by trips for the period |
| `cost_per_km` | `SUM(vehicle_expenses.amount) / SUM(trips.distance_km)` |
| `complaints_per_100_trips` | `COUNT(complaints) / COUNT(trips) × 100` |

### SQL Sketch

```sql
WITH vehicle_metrics AS (
    SELECT
        v.id AS vehicle_id,
        v.make,
        v.model,
        COALESCE(SUM(t.net_earning), 0) / NULLIF(SUM(t.distance_km), 0) AS revenue_per_km,
        COALESCE(SUM(e.amount), 0) / NULLIF(SUM(t.distance_km), 0)     AS cost_per_km,
        AVG(r.rating)                                                   AS average_rating,
        COUNT(DISTINCT c.id) * 100.0 / NULLIF(COUNT(DISTINCT t.id), 0) AS complaints_per_100_trips
    FROM vehicles v
    LEFT JOIN trips t            ON t.vehicle_id = v.id AND t.started_at BETWEEN @from AND @to
    LEFT JOIN vehicle_expenses e ON e.vehicle_id = v.id AND e.expense_date BETWEEN @from AND @to
    LEFT JOIN driver_ratings r   ON r.driver_id = t.driver_id
    LEFT JOIN complaints c       ON c.trip_id = t.id
    WHERE v.status = 'active'
    GROUP BY v.id, v.make, v.model
)
SELECT *,
    (revenue_per_km * 0.4) + (average_rating * 0.3)
    - (cost_per_km * 0.2) - (complaints_per_100_trips * 0.1) AS vehicle_score
FROM vehicle_metrics
ORDER BY vehicle_score DESC;
```

The score is cached in `IMemoryCache` with a 5-minute TTL to avoid recomputation on every dashboard refresh.

---

## 11.4 Manual Payment Workflow

Payment processing is entirely manual, driven by the billing cycle report.

### State Transitions

```
[billing cycle: draft]
       │
       ▼ (admin reviews and approves)
[billing cycle: approved]
       │
       ▼ (system creates payment record)
[payment: pending]
       │
       ▼ (admin performs bank transfer externally)
[payment: processing]
       │
       ▼ (admin marks as paid in Blazor)
[payment: paid] ──► enqueue notification
       │
       ▼ (NotifyDriverFunction sends push)
[driver_notified_at recorded]
```

### Endpoint Behaviour

`POST /api/v1/payments/{id}/mark-paid`

Request body:

```json
{
  "payment_method": "bank_transfer",
  "payment_reference": "TRF-20260915-001",
  "notes": "SEPA transfer to driver IBAN",
  "notify_driver": true,
  "notification_method": "push"
}
```

Server-side actions:

1. Update `payment_records.status = 'paid'`.
2. Set `marked_paid_at = SYSUTCDATETIME()`.
3. Set `marked_paid_by = current_user_id`.
4. If `notify_driver = true`, enqueue a message to the `driver-notifications` queue.
5. Return `200 OK` with `notification_queued: true`.

The `driver_notified_at` field is populated asynchronously by `NotifyDriverFunction`.

---

## 11.5 Telematics Sync (Provider-Agnostic)

The sync service uses the `IMaponClient` interface and does not care whether it points at the mock or the real Mapon API. It runs every 5 minutes as an Azure Function.

```csharp
public sealed class TelemetrySyncService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IOptions<MaponOptions> _options;
    private readonly ILogger<TelemetrySyncService> _logger;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var mapon = scope.ServiceProvider.GetRequiredService<IMaponClient>();
                var store = scope.ServiceProvider.GetRequiredService<ITelematicsStore>();

                var units = await mapon.GetUnitsAsync(stoppingToken);
                await store.UpsertLatestPositionsAsync(units, stoppingToken);

                var ids = units.Select(u => u.UnitId).ToList();
                var data = await mapon.GetUnitDataAsync(ids, stoppingToken);
                await store.UpsertUnitDataAsync(data, stoppingToken);

                var yesterday = DateTime.UtcNow.AddDays(-1);
                foreach (var id in ids)
                {
                    var routes = await mapon.GetRoutesAsync(id, yesterday, DateTime.UtcNow, stoppingToken);
                    await store.UpsertRoutesAsync(id, routes, stoppingToken);
                }

                _logger.LogInformation("Mapon sync OK: {Count} units", units.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Mapon sync failed");
            }

            await Task.Delay(TimeSpan.FromMinutes(_options.Value.SyncIntervalMinutes), stoppingToken);
        }
    }
}
```

---

## 11.6 Billing Cycle Computation (per model)

### Model 1 — Rental

```
period = current week (Mon–Sun)
line_items = [
    { type: 'rental_fee', amount: rental_weekly_rate OR rental_monthly_rate / 4 }
]
penalties = SUM(complaints.penalty_applied in period) + amortized_accident_cost
net_payable = rental_fee + penalties   (penalties are negative)
```

### Model 2 — Profit Share

```
net_revenue = SUM(trips.net_earning in period for driver)
driver_share = net_revenue * (profit_share_driver_pct / 100)
company_share = net_revenue - driver_share
reimbursements = SUM(eligible vehicle_expenses in period)
penalties = complaint_penalties + accident_amortization + rating_deduction
net_payable = driver_share + reimbursements - penalties + perfect_rating_bonus
```

### Model 3 — Salary + Percentage

```
base_prorated = base_salary * (days_in_period / days_in_month)
commission = SUM(trips.net_earning in period) * (commission_pct / 100)
gross = base_prorated + commission
penalties = same as Model 2
tsu_employee = gross * 0.11
tsu_employer = gross * 0.104
irs = compute_withholding(gross, driver.marital_status, driver.dependents)
net_payable = gross - penalties - tsu_employee - irs
```

### Penalty rules applied identically across models

All three models apply the same penalty/bonus engine (§11.2) before computing the final `net_payable`.

---

## 11.7 Audit & Traceability

Every mutation to a financial entity writes a row to `audit_log` with:

- `user_id` — the acting user
- `action` — e.g. `payment.mark_paid`, `billing.approve`
- `entity_type` — e.g. `payment_records`
- `entity_id` — the affected row
- `old_values` / `new_values` — JSON snapshots
- `created_at` — UTC timestamp

This is enforced at the service layer via a decorator pattern or EF Core interceptor, not at the controller, so background jobs are also covered.

---

*End of business logic document — v4.0.*