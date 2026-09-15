using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class Complaint : BaseEntity
{
    public Guid DriverId { get; set; }
    public ComplaintSeverity Severity { get; set; }
    public ComplaintStatus Status { get; set; }
    public string? Details { get; set; }
}
