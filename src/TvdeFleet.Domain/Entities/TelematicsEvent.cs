using System;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class TelematicsEvent : BaseEntity
{
    public Guid VehicleId { get; set; }
    public DateTime Time { get; set; }
    public string? EventType { get; set; }
    public Vehicle? Vehicle { get; set; }
}
