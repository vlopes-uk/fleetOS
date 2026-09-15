using System.ComponentModel.DataAnnotations;
using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class Vehicle : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Operator Operator { get; set; } = null!;

    [MaxLength(20)]
    public string RegistrationNumber { get; set; } = string.Empty;

    [MaxLength(100)]
    public string Make { get; set; } = string.Empty;

    [MaxLength(100)]
    public string Model { get; set; } = string.Empty;

    public int Year { get; set; }
    public FuelType FuelType { get; set; }
    public VehicleStatus Status { get; set; } = VehicleStatus.Active;
    [MaxLength(50)]
    public string? Vin { get; set; }

    [MaxLength(20)]
    public string? LicensePlate { get; set; }

    public string? MaponUnitId { get; set; }

    public bool IsElectric { get; set; }

    // Navigations
    public ICollection<Contract> Contracts { get; set; } = new List<Contract>();
}
