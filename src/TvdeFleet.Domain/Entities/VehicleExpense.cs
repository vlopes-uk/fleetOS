using System;
using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class VehicleExpense : BaseEntity
{
    public Guid VehicleId { get; set; }
    public ExpenseType Type { get; set; }
    public decimal Amount { get; set; }
    public DateTime IncurredAt { get; set; }
}
