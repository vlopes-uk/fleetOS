# Epic 7: Payments (Manual Workflow)

**Labels:** `type: epic, module: payments, priority: high`

## Goal

Enable admins to mark payments as paid and notify drivers automatically.

## Features

### Feature 7.1: Pending Payments List

> Show all pending payments with driver IBANs.

#### Story 7.1.1: Accountant can see all pending payments

As an accountant I want pending payments with IBANs to process.

**Tasks:**

- [ ] Implement GET /payments/pending
- [ ] Build Blazor Billing/Payments page
- [ ] Show driver name amount IBAN
- [ ] Add CSV and PDF export
- [ ] Write query tests

### Feature 7.2: Mark Payment as Paid

> Record payment completion with audit trail.

#### Story 7.2.1: Accountant can mark payment as paid

As an accountant I want an audit trail when marking payments.

**Tasks:**

- [ ] Implement POST /payments/{id}/mark-paid
- [ ] Update payment_records.status to paid
- [ ] Record marked_paid_at and marked_paid_by
- [ ] Write payment tests

### Feature 7.3: Driver Notification

> Push notification when payment is processed.

#### Story 7.3.1: Driver receives push when payment processed

As a driver I want a push notification so I know payment was sent.

**Tasks:**

- [ ] Create NotifyDriverFunction (Queue trigger)
- [ ] Enqueue message from mark-paid endpoint
- [ ] Send via Azure Notification Hubs
- [ ] Update driver_notified_at
- [ ] Build MAUI Payment Status page
- [ ] Write notification tests
