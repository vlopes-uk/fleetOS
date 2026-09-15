using System;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class VehicleComplianceRecord : BaseEntity
{
    public Guid VehicleId { get; set; }
    public string RecordType { get; set; } = string.Empty;
    public DateTime IssuedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
}
