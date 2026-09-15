using System;
using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class Incident : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Guid DriverId { get; set; }

    public IncidentType Type { get; set; }
    public IncidentSeverity Severity { get; set; }
    public IncidentStatus Status { get; set; } = IncidentStatus.Reported;
    public DateTime OccurredAt { get; set; }
    public string? Description { get; set; }
}
