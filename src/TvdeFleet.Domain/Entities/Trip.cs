using System;
using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class Trip : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Guid DriverId { get; set; }

    public Operator Operator { get; set; } = null!;
    public Driver Driver { get; set; } = null!;

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    public decimal Fare { get; set; }
    public Platform Platform { get; set; } = Platform.Other;
    public TripStatus Status { get; set; } = TripStatus.Completed;
    public string? PlatformTripId { get; set; }
}
