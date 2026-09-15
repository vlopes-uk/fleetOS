using System;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class BackgroundJobLog : BaseEntity
{
    public string JobName { get; set; } = string.Empty;
    public DateTime StartedAt { get; set; }
    public DateTime? FinishedAt { get; set; }
    public string? Result { get; set; }
}
