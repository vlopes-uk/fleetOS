using TvdeFleet.Domain.Common;

namespace TvdeFleet.Domain.Entities;

public class DriverRating : BaseEntity
{
    public Guid DriverId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
}
