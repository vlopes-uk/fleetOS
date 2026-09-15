using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using TvdeFleet.Domain.Entities;

namespace TvdeFleet.Infrastructure.Persistence.Configurations;

internal class OperatorConfiguration : IEntityTypeConfiguration<Operator>
{
    public void Configure(EntityTypeBuilder<Operator> builder)
    {
        builder.ToTable("Operators");

        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("NEWSEQUENTIALID()");

        builder.Property(x => x.Name).IsRequired().HasMaxLength(200);
        builder.Property(x => x.Nif).IsRequired().HasMaxLength(9);
        builder.Property(x => x.ImtLicenceNumber).HasMaxLength(50);
        builder.Property(x => x.Address).HasMaxLength(500);
        builder.Property(x => x.Email).HasMaxLength(255);
        builder.Property(x => x.Phone).HasMaxLength(20);

        builder.HasMany(x => x.Users).WithOne(x => x.Operator).HasForeignKey(x => x.OperatorId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(x => x.Drivers).WithOne(x => x.Operator).HasForeignKey(x => x.OperatorId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(x => x.Vehicles).WithOne(x => x.Operator).HasForeignKey(x => x.OperatorId).OnDelete(DeleteBehavior.Cascade);
    }
}
