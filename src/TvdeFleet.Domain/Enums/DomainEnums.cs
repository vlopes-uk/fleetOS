namespace TvdeFleet.Domain.Enums;

public enum UserRole              { Admin, FleetManager, Accountant, Viewer }
public enum DriverStatus          { Active, Suspended, Inactive }
public enum VehicleStatus         { Active, Maintenance, Retired, Reserved }
public enum FuelType              { Petrol, Diesel, Hybrid, PlugInHybrid, Electric }
public enum PurchaseType          { Cash, Leasing, Loan }
public enum BusinessModel         { Rental, ProfitShare, SalaryPlus }
public enum ContractStatus        { Draft, Active, Suspended, Terminated }
public enum BillingStatus         { Draft, Approved, Invoiced, Paid }
public enum BillingLineType       { TripEarning, RentalFee, BaseSalary, Commission, Penalty, ExpenseReimbursement, Bonus }
public enum Platform              { Uber, Bolt, FreeNow, Other }
public enum TripStatus            { Completed, CancelledByRider, CancelledByDriver, NoShow }
public enum ExpenseType           { Fuel, Charging, Toll, Parking, Cleaning, Maintenance, Repair, Insurance, Other }
public enum IncidentType          { Accident, Damage, Theft, Vandalism, TrafficViolation, Other }
public enum IncidentSeverity      { Minor, Moderate, Major }
public enum IncidentStatus        { Reported, UnderReview, Resolved, Closed }
public enum ComplaintSeverity     { Low, Medium, High, Critical }
public enum ComplaintStatus       { Open, UnderInvestigation, Resolved, Dismissed }
public enum PaymentStatus         { Pending, Processing, Paid, Failed }
public enum PaymentMethod         { BankTransfer, Cash, Mbway, Other }
public enum NotificationMethod    { Push, Email, Sms }
public enum ComplianceRecordType  { Ipo, InsuranceThirdParty, InsurancePersonalAccident, Sticker, ImtRegistration }
public enum ComplianceDocumentType{ Cmtvde, CriminalRecord, Licence, TrainingCertificate }
public enum IntegrationType       { Uber, Bolt, Mapon }
public enum SyncStatus            { Running, Success, Partial, Failed }
public enum JobStatus             { Running, Success, Failed }
