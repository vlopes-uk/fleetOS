using System;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class AuditLog : BaseEntity
{
    public string EntityName { get; set; } = string.Empty;
    public Guid EntityId { get; set; }
    public string Action { get; set; } = string.Empty;
    public DateTime OccurredAt { get; set; }
    public string? Data { get; set; }
}
