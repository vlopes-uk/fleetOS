using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using TvdeFleet.Domain.Entities;

namespace TvdeFleet.Infrastructure.Persistence.Configurations;

internal class ContractConfiguration : IEntityTypeConfiguration<Contract>
{
    public void Configure(EntityTypeBuilder<Contract> builder)
    {
        builder.ToTable("Contracts");

        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("NEWSEQUENTIALID()");

        builder.Property(x => x.BusinessModel).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(x => x.Status).HasConversion<string>().HasMaxLength(30).IsRequired();

        builder.Property(x => x.ProfitShareDriverPct).HasColumnType("decimal(5,2)");
        builder.Property(x => x.RentalFee).HasColumnType("decimal(12,2)");

        builder.HasOne(x => x.Driver).WithMany(x => x.Contracts).HasForeignKey(x => x.DriverId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(x => x.Vehicle).WithMany(x => x.Contracts).HasForeignKey(x => x.VehicleId).OnDelete(DeleteBehavior.SetNull);
    }
}
