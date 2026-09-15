# Domain Model (C# / Entity Framework Core)

**Version:** 1.0 · **Companion to:** Requirements Documentation v4.0
**Target:** .NET 8, EF Core 8, SQL Server 2022 / Azure SQL

This document defines the C# entity classes, enums, and `DbContext` configuration for the TVDE platform. It maps directly to the SQL Server schema in `docs/03-database-schema.md`.

---

## Table of Contents

1. [Naming Conventions](#1-naming-conventions)
2. [Shared Primitives](#2-shared-primitives)
3. [Enums](#3-enums)
4. [Core Identity](#4-core-identity)
5. [Drivers](#5-drivers)
6. [Vehicles](#6-vehicles)
7. [Assignments & Handover](#7-assignments--handover)
8. [Contracts & Billing](#8-contracts--billing)
9. [Trips](#9-trips)
10. [Expenses & Incidents](#10-expenses--incidents)
11. [Ratings & Complaints](#11-ratings--complaints)
12. [Telematics](#12-telematics)
13. [Payments](#13-payments)
14. [Integration & Audit](#14-integration--audit)
15. [DbContext](#15-dbcontext)
16. [Design Decisions](#16-design-decisions)

---

## 1. Naming Conventions

| Aspect | Rule |
|---|---|
| Namespace | `TvdeFleet.Domain.Entities`, `TvdeFleet.Domain.Enums`, `TvdeFleet.Domain.Common` |
| Class names | PascalCase, singular (`Driver`, not `Drivers`) |
| Properties | PascalCase |
| Foreign keys | `<Navigation>Id` (e.g. `DriverId`) |
| Navigation collections | Plural, initialized to `new List<T>()` |
| Optional properties | Nullable reference types enabled (`string?`) |
| Enums | PascalCase members; stored as `VARCHAR(30)` in DB |
| Money | `decimal` (precision 12, scale 2) |
| Dates | `DateOnly` for date-only, `DateTime` (UTC) for timestamps |
| Identifiers | `Guid` with `NEWSEQUENTIALID()` in DB |

---

## 2. Shared Primitives

### BaseEntity

```csharp
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TvdeFleet.Domain.Common;

/// <summary>
/// Base entity with a sequential GUID primary key and UTC audit timestamps.
/// </summary>
public abstract class BaseEntity
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public Guid Id { get; set; } = Guid.NewGuid();

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
```

---

## 3. Enums

```csharp
namespace TvdeFleet.Domain.Enums;

public enum UserRole              { Admin, FleetManager, Accountant, Viewer }
public enum DriverStatus          { Active, Suspended, Inactive }
public enum VehicleStatus         { Active, Maintenance, Retired, Reserved }
public enum FuelType              { Petrol, Diesel, Hybrid, PlugInHybrid, Electric }
public enum PurchaseType          { Cash, Leasing, Loan }
public enum BusinessModel         { Rental, ProfitShare, SalaryPlus }
public enum ContractStatus        { Draft, Active, Suspended, Terminated }
public enum BillingStatus         { Draft, Approved, Invoiced, Paid }
public enum BillingLineType       { TripEarning, RentalFee, BaseSalary, Commission, Penalty, ExpenseReimbursement, Bonus }
public enum Platform              { Uber, Bolt, FreeNow, Other }
public enum TripStatus            { Completed, CancelledByRider, CancelledByDriver, NoShow }
public enum ExpenseType           { Fuel, Charging, Toll, Parking, Cleaning, Maintenance, Repair, Insurance, Other }
public enum IncidentType          { Accident, Damage, Theft, Vandalism, TrafficViolation, Other }
public enum IncidentSeverity      { Minor, Moderate, Major }
public enum IncidentStatus        { Reported, UnderReview, Resolved, Closed }
public enum ComplaintSeverity     { Low, Medium, High, Critical }
public enum ComplaintStatus       { Open, UnderInvestigation, Resolved, Dismissed }
public enum PaymentStatus         { Pending, Processing, Paid, Failed }
public enum PaymentMethod         { BankTransfer, Cash, Mbway, Other }
public enum NotificationMethod    { Push, Email, Sms }
public enum ComplianceRecordType  { Ipo, InsuranceThirdParty, InsurancePersonalAccident, Sticker, ImtRegistration }
public enum ComplianceDocumentType{ Cmtvde, CriminalRecord, Licence, TrainingCertificate }
public enum IntegrationType       { Uber, Bolt, Mapon }
public enum SyncStatus            { Running, Success, Partial, Failed }
public enum JobStatus             { Running, Success, Failed }
```

---

## 4. Core Identity

### Operator

```csharp
using System.ComponentModel.DataAnnotations;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class Operator : BaseEntity
{
    public string Name { get; set; } = string.Empty;

    [MaxLength(9)]
    public string Nif { get; set; } = string.Empty;

    [MaxLength(50)]
    public string? ImtLicenceNumber { get; set; }

    public DateOnly? ImtLicenceExpiry { get; set; }

    /// <summary>
    /// Optional operator-wide default for the profit-share model.
    /// Used as a fallback when a contract's <see cref="Contract.ProfitShareDriverPct"/>
    /// is null. Expressed as the driver's share, 0-100.
    /// </summary>
    public decimal? DefaultProfitShareDriverPct { get; set; }

    [MaxLength(500)]
    public string? Address { get; set; }

    [MaxLength(255)]
    public string? Email { get; set; }

    [MaxLength(20)]
    public string? Phone { get; set; }

    // Navigations
    public ICollection<User> Users { get; set; } = new List<User>();
    public ICollection<Driver> Drivers { get; set; } = new List<Driver>();
    public ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
}
```

### User

```csharp
public class User : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Operator Operator { get; set; } = null!;

    [MaxLength(255)]
    public string Email { get; set; } = string.Empty;

    [MaxLength(255)]
    public string PasswordHash { get; set; } = string.Empty;

    public UserRole Role { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigations
    public ICollection<PaymentRecord> MarkedPayments { get; set; } = new List<PaymentRecord>();
}
```

---

## 5. Drivers

### Driver

```csharp
public class Driver : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Operator Operator { get; set; } = null!;

    public string FullName { get; set; } = string.Empty;

    [MaxLength(9)]
    public string Nif { get; set; } = string.Empty;

    [MaxLength(255)]
    public string? Email { get; set; }

    [MaxLength(20)]
    public string? Phone { get; set; }

    public DateOnly? DateOfBirth { get; set; }

    [MaxLength(50)]
    public string? LicenceNumber { get; set; }

    public DateOnly? LicenceExpiry { get; set; }

    [MaxLength(50)]
    public string? CmtvdeNumber { get; set; }

    public DateOnly? CmtvdeIssueDate { get; set; }
    public DateOnly? CmtvdeExpiryDate { get; set; }

    public DateOnly? CriminalRecordCheckDate { get; set; }
    public DateOnly? CriminalRecordExpiryDate { get; set; }

    public int TrainingHoursCompleted { get; set; }
    public DateOnly? LastTrainingDate { get; set; }

    [MaxLength(34)]
    public string? Iban { get; set; }

    public int? MaponDriverId { get; set; }

    public DriverStatus Status { get; set; } = DriverStatus.Active;

    // Navigations
    public ICollection<DriverComplianceDocument> ComplianceDocuments { get; set; } = new List<DriverComplianceDocument>();
    public ICollection<DriverVehicleAssignment> VehicleAssignments { get; set; } = new List<DriverVehicleAssignment>();
    public ICollection<Contract> Contracts { get; set; } = new List<Contract>();
    public ICollection<Trip> Trips { get; set; } = new List<Trip>();
    public ICollection<Incident> Incidents { get; set; } = new List<Incident>();
    public ICollection<Complaint> Complaints { get; set; } = new List<Complaint>();
    public ICollection<DriverRating> Ratings { get; set; } = new List<DriverRating>();
    public ICollection<PaymentRecord> Payments { get; set; } = new List<PaymentRecord>();
    public ICollection<VehicleExpense> Expenses { get; set; } = new List<VehicleExpense>();
}
```

### DriverComplianceDocument

```csharp
public class DriverComplianceDocument : BaseEntity
{
    public Guid DriverId { get; set; }
    public Driver Driver { get; set; } = null!;

    public ComplianceDocumentType DocumentType { get; set; }

    [MaxLength(100)]
    public string? DocumentNumber { get; set; }

    public DateOnly? IssueDate { get; set; }
    public DateOnly? ExpiryDate { get; set; }

    [MaxLength(500)]
    public string? FileUrl { get; set; }

    public bool IsVerified { get; set; }
}
```

---

## 6. Vehicles

### Vehicle

```csharp
public class Vehicle : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Operator Operator { get; set; } = null!;

    [MaxLength(100)]
    public string Make { get; set; } = string.Empty;

    [MaxLength(100)]
    public string Model { get; set; } = string.Empty;

    public int Year { get; set; }

    [MaxLength(17)]
    public string? Vin { get; set; }

    [MaxLength(20)]
    public string LicensePlate { get; set; } = string.Empty;

    [MaxLength(50)]
    public string? Colour { get; set; }

    public FuelType FuelType { get; set; }

    // Persisted computed column in the database; read-only from the domain side.
    public bool IsElectric { get; private set; }

    public PurchaseType PurchaseType { get; set; }
    public decimal? PurchasePrice { get; set; }
    public decimal? MonthlyLeaseCost { get; set; }
    public DateOnly? LeaseEndDate { get; set; }

    [MaxLength(50)]
    public string? ImtRegistrationNumber { get; set; }

    public DateOnly? ImtRegistrationExpiry { get; set; }

    public int? MaponUnitId { get; set; }

    [MaxLength(50)]
    public string? MaponUnitNumber { get; set; }

    public VehicleStatus Status { get; set; } = VehicleStatus.Active;

    // Navigations
    public ICollection<VehicleComplianceRecord> ComplianceRecords { get; set; } = new List<VehicleComplianceRecord>();
    public ICollection<DriverVehicleAssignment> DriverAssignments { get; set; } = new List<DriverVehicleAssignment>();
    public ICollection<Contract> Contracts { get; set; } = new List<Contract>();
    public ICollection<Trip> Trips { get; set; } = new List<Trip>();
    public ICollection<VehicleExpense> Expenses { get; set; } = new List<VehicleExpense>();
    public ICollection<Incident> Incidents { get; set; } = new List<Incident>();
}
```

### VehicleComplianceRecord

```csharp
public class VehicleComplianceRecord : BaseEntity
{
    public Guid VehicleId { get; set; }
    public Vehicle Vehicle { get; set; } = null!;

    public ComplianceRecordType RecordType { get; set; }

    [MaxLength(100)]
    public string? ReferenceNumber { get; set; }

    public DateOnly? IssueDate { get; set; }
    public DateOnly? ExpiryDate { get; set; }

    [MaxLength(255)]
    public string? ProviderName { get; set; }

    public decimal? Cost { get; set; }

    [MaxLength(500)]
    public string? FileUrl { get; set; }
}
```

---

## 7. Assignments & Handover

### DriverVehicleAssignment

```csharp
public class DriverVehicleAssignment : BaseEntity
{
    public Guid DriverId { get; set; }
    public Driver Driver { get; set; } = null!;

    public Guid VehicleId { get; set; }
    public Vehicle Vehicle { get; set; } = null!;

    public DateTime AssignedFrom { get; set; }
    public DateTime? AssignedTo { get; set; }

    public bool IsPrimary { get; set; } = true;

    // Navigations
    public ICollection<VehicleHandoverLog> HandoverLogs { get; set; } = new List<VehicleHandoverLog>();
}
```

### VehicleHandoverLog

```csharp
public class VehicleHandoverLog : BaseEntity
{
    public Guid AssignmentId { get; set; }
    public DriverVehicleAssignment Assignment { get; set; } = null!;

    public int? OdometerReading { get; set; }
    public int? FuelLevelPct { get; set; }

    public string? ConditionNotes { get; set; }

    // Stored as NVARCHAR(MAX) JSON in the database.
    public string? Photos { get; set; }

    public DateTime LoggedAt { get; set; } = DateTime.UtcNow;
}
```

---

## 8. Contracts & Billing

### Contract

```csharp
public class Contract : BaseEntity
{
    public Guid DriverId { get; set; }
    public Driver Driver { get; set; } = null!;

    public Guid VehicleId { get; set; }
    public Vehicle Vehicle { get; set; } = null!;

    public BusinessModel BusinessModel { get; set; }

    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }

    public ContractStatus Status { get; set; } = ContractStatus.Draft;

    // Model 1 - Rental
    public decimal? RentalWeeklyRate { get; set; }
    public decimal? RentalMonthlyRate { get; set; }

    /// <summary>
    /// Driver's share of net revenue for the profit-share model, expressed
    /// as a percentage (0-100). When null, the billing engine falls back to
    /// <see cref="Operator.DefaultProfitShareDriverPct"/>.
    /// </summary>
    public decimal? ProfitShareDriverPct { get; set; }

    // Model 3 - Salary + Percentage
    public decimal? BaseSalary { get; set; }

    /// <summary>
    /// Driver's commission on net revenue for the salary-plus model,
    /// expressed as a percentage (0-100).
    /// </summary>
    public decimal? CommissionPct { get; set; }

    public string? Notes { get; set; }

    // Navigations
    public ICollection<BillingCycle> BillingCycles { get; set; } = new List<BillingCycle>();
}
```

### BillingCycle

```csharp
public class BillingCycle : BaseEntity
{
    public Guid ContractId { get; set; }
    public Contract Contract { get; set; } = null!;

    public DateOnly PeriodStart { get; set; }
    public DateOnly PeriodEnd { get; set; }

    public BillingStatus Status { get; set; } = BillingStatus.Draft;

    public decimal TotalRevenue { get; set; }
    public decimal TotalExpenses { get; set; }
    public decimal DriverShare { get; set; }
    public decimal CompanyShare { get; set; }
    public decimal PenaltiesApplied { get; set; }
    public decimal NetPayable { get; set; }

    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;

    // Navigations
    public ICollection<BillingLineItem> LineItems { get; set; } = new List<BillingLineItem>();
    public ICollection<PaymentRecord> Payments { get; set; } = new List<PaymentRecord>();
}
```

### BillingLineItem

```csharp
public class BillingLineItem : BaseEntity
{
    public Guid BillingCycleId { get; set; }
    public BillingCycle BillingCycle { get; set; } = null!;

    public BillingLineType LineType { get; set; }

    public string? Description { get; set; }

    public decimal Amount { get; set; }

    /// <summary>
    /// Polymorphic reference. Points to a trip, expense, complaint, or
    /// incident UUID depending on the line type.
    /// </summary>
    public Guid? ReferenceId { get; set; }
}
```

---

## 9. Trips

### Trip

```csharp
public class Trip : BaseEntity
{
    public Guid DriverId { get; set; }
    public Driver Driver { get; set; } = null!;

    public Guid VehicleId { get; set; }
    public Vehicle Vehicle { get; set; } = null!;

    public Platform Platform { get; set; }

    [MaxLength(100)]
    public string? PlatformTripId { get; set; }

    public long? MaponRouteId { get; set; }

    public DateTime StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }

    [MaxLength(500)]
    public string? PickupAddress { get; set; }

    [MaxLength(500)]
    public string? DropoffAddress { get; set; }

    public decimal? DistanceKm { get; set; }
    public int? DurationMinutes { get; set; }

    public decimal? GrossFare { get; set; }
    public decimal? PlatformFee { get; set; }
    public decimal? NetEarning { get; set; }

    public decimal TipAmount { get; set; }

    public decimal? SurgeMultiplier { get; set; }

    public TripStatus Status { get; set; } = TripStatus.Completed;

    // Navigations
    public ICollection<Complaint> Complaints { get; set; } = new List<Complaint>();
}
```

---

## 10. Expenses & Incidents

### VehicleExpense

```csharp
public class VehicleExpense : BaseEntity
{
    public Guid VehicleId { get; set; }
    public Vehicle Vehicle { get; set; } = null!;

    public Guid? DriverId { get; set; }
    public Driver? Driver { get; set; }

    public ExpenseType ExpenseType { get; set; }

    public decimal Amount { get; set; }

    public string? Description { get; set; }

    [MaxLength(500)]
    public string? ReceiptUrl { get; set; }

    public int? OdometerReading { get; set; }

    public DateOnly ExpenseDate { get; set; }

    public bool IsReconciled { get; set; }
}
```

### Incident

```csharp
public class Incident : BaseEntity
{
    public Guid VehicleId { get; set; }
    public Vehicle Vehicle { get; set; } = null!;

    public Guid? DriverId { get; set; }
    public Driver? Driver { get; set; }

    public IncidentType IncidentType { get; set; }
    public IncidentSeverity Severity { get; set; }

    public string Description { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Location { get; set; }

    public decimal? GpsLat { get; set; }
    public decimal? GpsLng { get; set; }

    public DateTime IncidentDate { get; set; }

    [MaxLength(100)]
    public string? PoliceReport { get; set; }

    [MaxLength(100)]
    public string? InsuranceClaim { get; set; }

    public decimal? RepairCost { get; set; }

    public bool? AtFault { get; set; }

    public IncidentStatus Status { get; set; } = IncidentStatus.Reported;

    public string? Photos { get; set; }
}
```

---

## 11. Ratings & Complaints

### DriverRating

```csharp
public class DriverRating : BaseEntity
{
    public Guid DriverId { get; set; }
    public Driver Driver { get; set; } = null!;

    public Platform? Platform { get; set; }

    public decimal Rating { get; set; }

    public int? TotalRatings { get; set; }

    public DateOnly? PeriodStart { get; set; }
    public DateOnly? PeriodEnd { get; set; }
}
```

### Complaint

```csharp
public class Complaint : BaseEntity
{
    public Guid DriverId { get; set; }
    public Driver Driver { get; set; } = null!;

    public Guid? TripId { get; set; }
    public Trip? Trip { get; set; }

    public Platform? Platform { get; set; }

    [MaxLength(50)]
    public string? ComplaintType { get; set; }

    public string Description { get; set; } = string.Empty;

    public ComplaintSeverity Severity { get; set; }
    public ComplaintStatus Status { get; set; } = ComplaintStatus.Open;

    public string? ResolutionNotes { get; set; }

    public decimal PenaltyApplied { get; set; }

    public DateTime ComplaintDate { get; set; }
    public DateTime? ResolvedAt { get; set; }
}
```

---

## 12. Telematics

### TelematicsEvent

This entity maps to the partitioned `telematics_events` table. The primary key is composite: `(VehicleId, Time)`. It does **not** inherit `BaseEntity` because the table has no `created_at`/`updated_at` columns.

```csharp
using System.ComponentModel.DataAnnotations;

public class TelematicsEvent
{
    public DateTime Time { get; set; }

    public Guid VehicleId { get; set; }
    public Vehicle Vehicle { get; set; } = null!;

    public int? MaponUnitId { get; set; }

    [MaxLength(30)]
    public string EventType { get; set; } = string.Empty;

    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }

    public decimal? SpeedKmh { get; set; }
    public int? OdometerKm { get; set; }

    public decimal? FuelLevelPct { get; set; }
    public decimal? BatteryLevelPct { get; set; }

    public bool? EngineOn { get; set; }

    public bool? HarshBraking { get; set; }
    public bool? HarshAcceleration { get; set; }
    public bool? HarshCornering { get; set; }

    public string? Metadata { get; set; }
}
```

---

## 13. Payments

### PaymentRecord

```csharp
public class PaymentRecord : BaseEntity
{
    public Guid BillingCycleId { get; set; }
    public BillingCycle BillingCycle { get; set; } = null!;

    public Guid DriverId { get; set; }
    public Driver Driver { get; set; } = null!;

    public decimal Amount { get; set; }

    public PaymentMethod? PaymentMethod { get; set; }

    [MaxLength(100)]
    public string? PaymentReference { get; set; }

    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;

    public Guid? MarkedPaidBy { get; set; }
    public User? MarkedPaidByUser { get; set; }

    public DateTime? MarkedPaidAt { get; set; }
    public DateTime? DriverNotifiedAt { get; set; }

    public NotificationMethod? NotificationMethod { get; set; }

    public string? Notes { get; set; }
}
```

---

## 14. Integration & Audit

### IntegrationSyncLog

```csharp
public class IntegrationSyncLog : BaseEntity
{
    public IntegrationType IntegrationType { get; set; }

    public DateTime SyncStartedAt { get; set; }
    public DateTime? SyncCompletedAt { get; set; }

    public SyncStatus Status { get; set; }

    public int RecordsProcessed { get; set; }
    public int RecordsFailed { get; set; }

    public string? ErrorDetails { get; set; }
}
```

### BackgroundJobLog

```csharp
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class BackgroundJobLog
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public long Id { get; set; }

    [MaxLength(100)]
    public string JobName { get; set; } = string.Empty;

    [MaxLength(50)]
    public string JobType { get; set; } = string.Empty;

    public DateTime StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }

    public JobStatus Status { get; set; }

    public int? RecordsAffected { get; set; }

    public string? ErrorMessage { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

### AuditLog

```csharp
public class AuditLog
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public long Id { get; set; }

    public Guid? UserId { get; set; }

    [MaxLength(50)]
    public string Action { get; set; } = string.Empty;

    [MaxLength(50)]
    public string EntityType { get; set; } = string.Empty;

    public Guid? EntityId { get; set; }

    public string? OldValues { get; set; }
    public string? NewValues { get; set; }

    [MaxLength(45)]
    public string? IpAddress { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

---

## 15. DbContext

### AppDbContext

```csharp
using Microsoft.EntityFrameworkCore;
using TvdeFleet.Domain.Entities;

namespace TvdeFleet.Infrastructure.Persistence;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Operator> Operators => Set<Operator>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Driver> Drivers => Set<Driver>();
    public DbSet<DriverComplianceDocument> DriverComplianceDocuments => Set<DriverComplianceDocument>();
    public DbSet<Vehicle> Vehicles => Set<Vehicle>();
    public DbSet<VehicleComplianceRecord> VehicleComplianceRecords => Set<VehicleComplianceRecord>();
    public DbSet<DriverVehicleAssignment> DriverVehicleAssignments => Set<DriverVehicleAssignment>();
    public DbSet<VehicleHandoverLog> VehicleHandoverLogs => Set<VehicleHandoverLog>();
    public DbSet<Contract> Contracts => Set<Contract>();
    public DbSet<BillingCycle> BillingCycles => Set<BillingCycle>();
    public DbSet<BillingLineItem> BillingLineItems => Set<BillingLineItem>();
    public DbSet<Trip> Trips => Set<Trip>();
    public DbSet<VehicleExpense> VehicleExpenses => Set<VehicleExpense>();
    public DbSet<Incident> Incidents => Set<Incident>();
    public DbSet<DriverRating> DriverRatings => Set<DriverRating>();
    public DbSet<Complaint> Complaints => Set<Complaint>();
    public DbSet<TelematicsEvent> TelematicsEvents => Set<TelematicsEvent>();
    public DbSet<PaymentRecord> PaymentRecords => Set<PaymentRecord>();
    public DbSet<IntegrationSyncLog> IntegrationSyncLogs => Set<IntegrationSyncLog>();
    public DbSet<BackgroundJobLog> BackgroundJobLogs => Set<BackgroundJobLog>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        // Telematics: composite key aligned with partition scheme
        modelBuilder.Entity<TelematicsEvent>(e =>
        {
            e.ToTable("telematics_events");
            e.HasKey(x => new { x.VehicleId, x.Time });
            e.HasIndex(x => new { x.VehicleId, x.Time })
                .IsClustered()
                .IsDescending(false, true);

            e.HasOne(x => x.Vehicle)
                .WithMany()
                .HasForeignKey(x => x.VehicleId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Vehicle: computed IsElectric column
        modelBuilder.Entity<Vehicle>(e =>
        {
            e.Property(v => v.IsElectric)
                .HasComputedColumnSql(
                    "CONVERT(BIT, CASE WHEN fuel_type = 'electric' THEN 1 ELSE 0 END)",
                    stored: true);
        });

        // Money: precision 12, scale 2 for all decimal properties
        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            foreach (var property in entityType.GetProperties())
            {
                if (property.ClrType == typeof(decimal) || property.ClrType == typeof(decimal?))
                {
                    property.SetPrecision(12);
                    property.SetScale(2);
                }
            }
        }

        // Enums stored as VARCHAR(30) to match schema CHECK constraints
        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            foreach (var property in entityType.GetProperties())
            {
                var t = Nullable.GetUnderlyingType(property.ClrType) ?? property.ClrType;
                if (t.IsEnum)
                {
                    property.SetProviderClrType(typeof(string));
                    property.SetMaxLength(30);
                }
            }
        }

        // Unique and filtered indexes
        modelBuilder.Entity<Operator>().HasIndex(o => o.Nif).IsUnique();
        modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();
        modelBuilder.Entity<Driver>().HasIndex(d => d.Nif).IsUnique();
        modelBuilder.Entity<Driver>().HasIndex(d => d.MaponDriverId)
            .IsUnique().HasFilter("[mapon_driver_id] IS NOT NULL");
        modelBuilder.Entity<Vehicle>().HasIndex(v => v.Vin)
            .IsUnique().HasFilter("[vin] IS NOT NULL");
        modelBuilder.Entity<Vehicle>().HasIndex(v => v.LicensePlate).IsUnique();
        modelBuilder.Entity<Vehicle>().HasIndex(v => v.MaponUnitId)
            .IsUnique().HasFilter("[mapon_unit_id] IS NOT NULL");
        modelBuilder.Entity<Operator>(e =>
        {
            e.Property(o => o.DefaultProfitShareDriverPct)
                .HasPrecision(5, 2);
        });
        modelBuilder.Entity<Contract>(e =>
        {
            e.Property(c => c.ProfitShareDriverPct).HasPrecision(5, 2);
            e.Property(c => c.CommissionPct).HasPrecision(5, 2);
        });     
        modelBuilder.Entity<Trip>().HasIndex(t => t.PlatformTripId)
            .IsUnique().HasFilter("[platform_trip_id] IS NOT NULL");
        modelBuilder.Entity<BillingCycle>()
            .HasIndex(b => new { b.ContractId, b.PeriodStart, b.PeriodEnd })
            .IsUnique();
    }

    public override Task<int> SaveChangesAsync(CancellationToken ct = default)
    {
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            if (entry.State == EntityState.Modified)
                entry.Entity.UpdatedAt = DateTime.UtcNow;
        }
        return base.SaveChangesAsync(ct);
    }
}
```

---

## 16. Design Decisions

### Enums stored as strings

The database schema uses `VARCHAR(30)` with `CHECK` constraints for constrained string columns. Mapping C# enums to strings keeps the domain type-safe while the database remains queryable by humans and stable against enum reordering. The `SetProviderClrType(typeof(string))` loop in `OnModelCreating` applies this uniformly.

If you prefer integer storage, remove that loop. The change is reversible with a migration.

### DateOnly vs DateTime

The SQL schema uses `DATE` for date-only fields (expiry dates, contract start/end, expense dates) and `DATETIME2(3)` for timestamps. EF Core 8 maps `DateOnly` to `DATE` natively without a value converter.

### Navigation properties are not virtual

Lazy loading requires the `Microsoft.EntityFrameworkCore.Proxies` package and `virtual` properties. This model intentionally disables lazy loading because the API layer uses explicit `Include` calls and projections, which is the recommended pattern for performance and predictability.

### TelematicsEvent does not inherit BaseEntity

The `telematics_events` table has no `created_at` or `updated_at` columns — it is a high-volume append-only log. The entity has a composite key `(VehicleId, Time)` matching the partitioned clustered index.

### JSON columns stored as strings

`VehicleHandoverLog.Photos`, `Incident.Photos`, `TelematicsEvent.Metadata`, and `AuditLog.OldValues`/`NewValues` are all `NVARCHAR(MAX)` with `ISJSON` checks in the database. EF Core 8 supports native JSON columns via `OwnsMany` or `ToJson`, but the existing schema keeps them as plain strings for compatibility with the SQL scripts in `docs/03-database-schema.md`.

To upgrade these to native JSON in a future iteration, use:

```csharp
modelBuilder.Entity<Incident>()
    .OwnsMany(i => i.PhotoList, b => b.ToJson());
```

### Filtered unique indexes

`MaponDriverId`, `Vin`, `MaponUnitId`, and `PlatformTripId` are unique only when non-null, matching the SQL Server `UNIQUE` constraints that permit multiple NULL values. The `.HasFilter("[column] IS NOT NULL")` call reproduces this behaviour.

### Sequential GUIDs

`NEWSEQUENTIALID()` in SQL Server generates GUIDs in monotonic order, avoiding the clustered index fragmentation that random `NEWGUID()` would cause. The C# default `Guid.NewGuid()` applies only when the entity is constructed client-side; the database overrides it on insert.

### UpdatedAt handling

The `SaveChangesAsync` override stamps `UpdatedAt` on modified entities. This is a lightweight alternative to a full audit interceptor. For an application-wide audit trail, add an EF Core `SaveChangesInterceptor` that writes rows to `audit_log`.

---

## 17. Entity Summary

| Entity | Table | Notes |
|---|---|---|
| `Operator` | `operators` | Root tenant entity |
| `User` | `users` | Platform users with roles |
| `Driver` | `drivers` | CMTVDE, IBAN, Mapon link |
| `DriverComplianceDocument` | `driver_compliance_documents` | Doc tracking |
| `Vehicle` | `vehicles` | Includes computed `IsElectric` |
| `VehicleComplianceRecord` | `vehicle_compliance_records` | IPO, insurance, IMT |
| `DriverVehicleAssignment` | `driver_vehicle_assignments` | Active when `AssignedTo` is null |
| `VehicleHandoverLog` | `vehicle_handover_logs` | JSON photos column |
| `Contract` | `contracts` | Three business models |
| `BillingCycle` | `billing_cycles` | Weekly/monthly periods |
| `BillingLineItem` | `billing_line_items` | Polymorphic `ReferenceId` |
| `Trip` | `trips` | Dedupe on `PlatformTripId` |
| `VehicleExpense` | `vehicle_expenses` | Optional driver attribution |
| `Incident` | `incidents` | At-fault flag feeds penalties |
| `DriverRating` | `driver_ratings` | Periodic snapshots |
| `Complaint` | `complaints` | Links to trip and driver |
| `TelematicsEvent` | `telematics_events` | Composite key, partitioned |
| `PaymentRecord` | `payment_records` | Manual workflow |
| `IntegrationSyncLog` | `integration_sync_logs` | Uber, Bolt, Mapon |
| `BackgroundJobLog` | `background_job_logs` | Azure Functions |
| `AuditLog` | `audit_log` | Financial mutations |

---

*End of domain model document.*