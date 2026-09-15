using System;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class VehicleHandoverLog : BaseEntity
{
    public Guid VehicleId { get; set; }
    public Guid FromDriverId { get; set; }
    public Guid ToDriverId { get; set; }
    public DateTime HandoverAt { get; set; }
}
