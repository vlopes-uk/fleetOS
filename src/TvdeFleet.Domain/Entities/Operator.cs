using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class Operator : BaseEntity
{
    public string Name { get; set; } = string.Empty;

    [MaxLength(9)]
    public string Nif { get; set; } = string.Empty;

    [MaxLength(50)]
    public string? ImtLicenceNumber { get; set; }

    public DateOnly? ImtLicenceExpiry { get; set; }

    public decimal? DefaultProfitShareDriverPct { get; set; }

    [MaxLength(500)]
    public string? Address { get; set; }

    [MaxLength(255)]
    public string? Email { get; set; }

    [MaxLength(20)]
    public string? Phone { get; set; }

    // Navigations
    public ICollection<User> Users { get; set; } = new List<User>();
    public ICollection<Driver> Drivers { get; set; } = new List<Driver>();
    public ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
}
