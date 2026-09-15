using System;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class IntegrationSyncLog : BaseEntity
{
    public string Source { get; set; } = string.Empty;
    public DateTime StartedAt { get; set; }
    public DateTime? FinishedAt { get; set; }
    public string? Details { get; set; }
}
