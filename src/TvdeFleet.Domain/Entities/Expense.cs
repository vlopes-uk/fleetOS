using System;
using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class Expense : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Guid DriverId { get; set; }

    public ExpenseType Type { get; set; }
    public decimal Amount { get; set; }
    public DateTime IncurredAt { get; set; }
    public string? Notes { get; set; }
}
