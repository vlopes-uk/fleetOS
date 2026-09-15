using System.ComponentModel.DataAnnotations;
using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class Contract : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Guid DriverId { get; set; }
    public Guid? VehicleId { get; set; }

    public Operator Operator { get; set; } = null!;
    public Driver Driver { get; set; } = null!;
    public Vehicle? Vehicle { get; set; }

    public BusinessModel BusinessModel { get; set; }
    public ContractStatus Status { get; set; } = ContractStatus.Draft;

    // Example financials
    public decimal? ProfitShareDriverPct { get; set; }
    public decimal? RentalFee { get; set; }
    public decimal? CommissionPct { get; set; }
}
