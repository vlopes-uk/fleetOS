using Microsoft.EntityFrameworkCore;
using TvdeFleet.Domain.Common;
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
