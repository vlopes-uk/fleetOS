using System.ComponentModel.DataAnnotations;
using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class Driver : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Operator Operator { get; set; } = null!;

    public string FullName { get; set; } = string.Empty;

    [MaxLength(9)]
    public string Nif { get; set; } = string.Empty;

    [MaxLength(255)]
    public string? Email { get; set; }

    [MaxLength(20)]
    public string? Phone { get; set; }

    public DateOnly? DateOfBirth { get; set; }

    public DriverStatus Status { get; set; } = DriverStatus.Active;
    public string? MaponDriverId { get; set; }

    // Navigations
    public ICollection<Contract> Contracts { get; set; } = new List<Contract>();
    public ICollection<Trip> Trips { get; set; } = new List<Trip>();
}
