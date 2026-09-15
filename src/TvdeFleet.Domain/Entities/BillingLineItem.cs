using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class BillingLineItem : BaseEntity
{
    public Guid BillingCycleId { get; set; }
    public BillingLineType LineType { get; set; }
    public decimal Amount { get; set; }
}
