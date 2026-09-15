using System;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class BillingCycle : BaseEntity
{
    public Guid ContractId { get; set; }
    public DateTime PeriodStart { get; set; }
    public DateTime PeriodEnd { get; set; }
}
