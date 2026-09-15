using System;
using TvdeFleet.Domain.Common;
using TvdeFleet.Domain.Enums;

namespace TvdeFleet.Domain.Entities;

public class PaymentRecord : BaseEntity
{
    public Guid OperatorId { get; set; }
    public Guid? DriverId { get; set; }
    public Guid? UserId { get; set; }

    public decimal Amount { get; set; }
    public DateTime PaymentDate { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public PaymentMethod Method { get; set; } = PaymentMethod.BankTransfer;
}
