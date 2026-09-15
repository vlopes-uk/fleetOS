using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class User : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Operator Operator { get; set; } = null!;

    [MaxLength(255)]
    public string Email { get; set; } = string.Empty;

    [MaxLength(255)]
    public string PasswordHash { get; set; } = string.Empty;

    public UserRole Role { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigations
    public ICollection<PaymentRecord> MarkedPayments { get; set; } = new List<PaymentRecord>();
}
