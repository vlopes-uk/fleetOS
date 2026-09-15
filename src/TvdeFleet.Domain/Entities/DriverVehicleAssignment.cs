using System;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class DriverVehicleAssignment : BaseEntity
{
    public Guid DriverId { get; set; }
    public Guid VehicleId { get; set; }
    public DateTime AssignedAt { get; set; }
    public DateTime? ReleasedAt { get; set; }
}
