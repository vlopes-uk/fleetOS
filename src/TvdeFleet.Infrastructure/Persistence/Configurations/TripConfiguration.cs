using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using TvdeFleet.Domain.Entities;

namespace TvdeFleet.Infrastructure.Persistence.Configurations;

internal class TripConfiguration : IEntityTypeConfiguration<Trip>
{
    public void Configure(EntityTypeBuilder<Trip> builder)
    {
        builder.ToTable("Trips");

        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("NEWSEQUENTIALID()");

        builder.Property(x => x.StartTime).IsRequired();
        builder.Property(x => x.EndTime).IsRequired();

        builder.Property(x => x.Fare).HasColumnType("decimal(12,2)");

        builder.Property(x => x.Platform).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(x => x.Status).HasConversion<string>().HasMaxLength(30).IsRequired();

        builder.HasOne(x => x.Driver).WithMany(x => x.Trips).HasForeignKey(x => x.DriverId).OnDelete(DeleteBehavior.Cascade);
    }
}
