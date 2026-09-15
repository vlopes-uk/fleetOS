# Epic 6: Billing Engine (3 Business Models)

**Labels:** `type: epic, module: billing, priority: critical`

## Goal

Automate billing cycles for rental, profit-share, and salary-plus-commission models.

## Features

### Feature 6.1: Rental Billing (Model 1)

> Generate weekly or monthly rental invoices.

#### Story 6.1.1: Accountant gets rental invoices generated

As an accountant I want weekly/monthly rental invoices.

**Tasks:**

- [ ] Implement billing logic for rental contracts
- [ ] Create rental_fee line items
- [ ] Apply penalties from complaints and incidents
- [ ] Build Billing/Cycles review UI
- [ ] Write billing tests

### Feature 6.2: Profit Share Billing (Model 2)

> Calculate profit-share settlements.

#### Story 6.2.1: Accountant gets profit-share settlements

As an accountant I want profit-share calculated automatically.

**Tasks:**

- [ ] Aggregate trips and expenses per driver/period
- [ ] Apply profit_share_driver_pct
- [ ] Add expense reimbursement lines
- [ ] Apply penalty engine
- [ ] Build review UI
- [ ] Write billing tests

### Feature 6.3: Salary + Commission Billing (Model 3)

> Calculate payroll with base salary, commission, IRS, and TSU.

#### Story 6.3.1: Accountant gets payroll calculated with IRS and TSU

As an accountant I want employee payroll computed correctly.

**Tasks:**

- [ ] Prorate base salary
- [ ] Calculate commission from net earnings
- [ ] Compute IRS withholding
- [ ] Compute TSU employee and employer
- [ ] Generate payslip data
- [ ] Write payroll tests

### Feature 6.4: Penalty & Bonus Engine

> Apply penalties and bonuses based on complaints, accidents, ratings.

#### Story 6.4.1: Fleet manager gets penalties and bonuses applied

As a fleet manager I want automatic adjustments to driver earnings.

**Tasks:**

- [ ] Implement complaint penalty logic
- [ ] Implement at-fault accident amortisation
- [ ] Implement rating threshold deduction
- [ ] Implement perfect rating bonus
- [ ] Write rule engine tests

### Feature 6.5: Billing Cycle Function

> Generate billing cycles weekly via Azure Function.

#### Story 6.5.1: Developer gets billing cycles generated weekly

As a developer I want a weekly billing function.

**Tasks:**

- [ ] Create BillingCycleFunction (Timer Mon 00:00)
- [ ] Load active contracts by business model
- [ ] Call appropriate billing service
- [ ] Save billing_cycles and line items
- [ ] Log to background_job_logs
- [ ] Write function tests
