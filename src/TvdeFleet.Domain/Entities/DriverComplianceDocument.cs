using System;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class DriverComplianceDocument : BaseEntity
{
    public Guid DriverId { get; set; }
    public string DocumentType { get; set; } = string.Empty;
    public DateTime IssuedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
}
