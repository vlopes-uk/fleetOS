using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using TvdeFleet.Domain.Entities;

namespace TvdeFleet.Infrastructure.Persistence.Configurations;

internal class ExpenseConfiguration : IEntityTypeConfiguration<Expense>
{
    public void Configure(EntityTypeBuilder<Expense> builder)
    {
        builder.ToTable("Expenses");

        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("NEWSEQUENTIALID()");

        builder.Property(x => x.Type).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(x => x.Amount).HasColumnType("decimal(12,2)");
        builder.Property(x => x.IncurredAt).IsRequired();
        builder.Property(x => x.Notes).HasMaxLength(1000);

        builder.HasOne<Driver>().WithMany().HasForeignKey(x => x.DriverId).OnDelete(DeleteBehavior.Cascade);
    }
}
