🔹 MASTER SYSTEM CONTEXT (PASTE FIRST)
You are building a grocery commerce system called GalliKart.
Implement RECURSIVE ORDERS with exactly three independent modes:
DAILY, WEEKLY, MONTHLY.

Rules:
- Each mode has independent orders, baskets, schedules, and payments
- Users can create unlimited orders per mode
- Never re-charge full order amount after first payment
- All edits use DELTA PAYMENT logic
- Removed item value goes to GalliKart Wallet
- Wallet can be used across any order

🔹 TASK 1 — Core Data Models
Design database models for recursive orders.

Entities required:
- User
- Address
- Product
- RecurringOrder
- RecurringOrderItem
- Wallet
- WalletLedger
- PaymentTransaction

RecurringOrder must store:
- id
- user_id
- mode (DAILY | WEEKLY | MONTHLY)
- delivery_address_id
- schedule_config (json)
- base_paid_amount
- current_total_amount
- status
- next_delivery_date

🔹 TASK 2 — Daily Recurring Order Logic
Implement DAILY recurring order flow.

Requirements:
- Show product categories: Milk, Fruits, Vegetables, Meat, Others
- Allow selecting multiple products and quantities
- Allow daily or multi-day repeat selection
- On order submit:
   - Ask user to select saved address
   - Redirect to payment
- After payment:
   - Save order
   - Display under Show Orders → Daily

🔹 TASK 3 — Weekly Recurring Order Planner
Implement WEEKLY recurring order planning.

Requirements:
- Allow user to plan products per weekday (Mon–Sun)
- Allow different products per day
- Show selected week on top
- Allow selecting multiple future weeks (N weeks)
- Calculate total upfront payment
- Save weekly plan and payment
- Display under Show Orders → Weekly

🔹 TASK 4 — Monthly Recurring Order Logic
Implement MONTHLY recurring order flow.

Requirements:
- User selects all groceries needed for a month
- User selects delivery day of month (e.g., 5th or 10th)
- Calculate monthly total
- Take one-time payment
- Save order
- Display under Show Orders → Monthly

🔹 TASK 5 — Show Orders Screen
Implement Show Orders screen.

Requirements:
- Group orders into three sections:
   1. Daily Orders
   2. Weekly Orders
   3. Monthly Orders
- Each order card shows:
   - Order mode
   - Products summary
   - Delivery address
   - Next delivery date
   - Edit button

🔹 TASK 6 — Edit Order Cut-Off Rule
Implement edit restriction for recurring orders.

Rules:
- Orders can be edited anytime BEFORE 4:00 AM of delivery day
- If edit happens after 4:00 AM:
   - Changes apply from next delivery cycle

🔹 TASK 7 — Delta Payment Calculation (CRITICAL)
Implement delta payment logic for recurring orders.

Inputs:
- current_total_amount
- updated_order_total

Rules:
- If updated > current:
   - Pay only (updated - current)
- If updated < current:
   - Credit (current - updated) to GalliKart Wallet
- Never charge base amount again
- Update recurring order total after adjustment

🔹 TASK 8 — GalliKart Wallet System
Implement GalliKart Wallet with ledger-based accounting.

Rules:
- One wallet per user
- WalletLedger must store:
   - credit / debit
   - amount
   - reason
   - order_id
   - balance_after
- Wallet credits come from removed products
- Wallet debits happen during checkout

🔹 TASK 9 — Wallet Usage During Payment
Implement wallet usage during checkout.

Requirements:
- Show checkbox: "Use wallet balance"
- If checked:
   - Deduct wallet balance first
   - If wallet >= payable amount → no gateway payment
   - Else → wallet + gateway payment
- Update wallet balance after payment

🔹 TASK 10 — Payment Flow (Unified)
Implement unified payment flow for all order types.

Rules:
- Same payment UI for daily, weekly, monthly
- Supports UPI / payment gateway
- Accepts wallet + gateway combination
- On success:
   - Save payment transaction
   - Update order state

🔹 TASK 11 — Validation & Safeguards
Add system safeguards.

Rules:
- Prevent full re-payment of recurring orders
- Validate delta calculations on backend
- Prevent wallet balance from going negative
- Ensure removed-product refunds always go to wallet

🔹 TASK 12 — API Contracts
Design REST APIs for recurring orders.

Endpoints:
- POST /recurring-orders
- GET /recurring-orders
- PUT /recurring-orders/{id}
- POST /recurring-orders/{id}/edit
- POST /payments
- GET /wallet

🔹 TASK 13 — UI State Management
Implement frontend state logic.

Requirements:
- Track current basket
- Track previous paid total
- Show real-time delta amount:
   - "Additional payment required"
   - "Amount credited to wallet"
- Disable edit after 4 AM

🔹 TASK 14 — Test Cases (Must Generate)
Generate unit and integration test cases.

Include:
- Add product after payment
- Remove product after payment
- Wallet partial usage
- Wallet full usage
- Multiple orders per mode
- Edit before 4 AM vs after 4 AM

🔹 TASK 15 — Non-Functional Requirements
Ensure:
- Idempotent payments
- Transaction safety
- Accurate ledger balance
- Scalability for multiple orders per user

🔹 ADDENDUM — COPILOT / CODEX TASK PROMPTS
🔹 TASK 16 — Product Categories by Recurring Mode
Extend product categorization logic per recurring mode.

Rules:

DAILY and WEEKLY modes must show the following categories:
- Fruits
- Dairy
- Vegetables
- Meat
- Health

Health category includes:
- Sprouts
- Fresh juice
- Salads
- Health bowls
- Similar items

MONTHLY mode must show:
- Complete groceries list
- Example categories:
   - Rice
   - Oil
   - Pulses
   - Spices
   - Household essentials
   - Other monthly groceries

Ensure category visibility depends on selected recurring mode.

🔹 TASK 17 — Weekly Calendar & Week Range Banner
Implement weekly calendar selection for WEEKLY recurring orders.

Requirements:
- Display week ranges dynamically based on current date
- Example:
   - Week of 21 Dec – 28 Dec
   - Week of 29 Dec – 05 Jan
- Show week range selector at top as horizontal banner
- User can select:
   - Any future week
   - Multiple future weeks

🔹 TASK 18 — Day-Level Ordering Inside Weekly Mode
Implement day-level ordering inside WEEKLY mode.

Requirements:
- Under selected week, display days:
   - Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
- Each day acts as an independent order slot
- User can:
   - Add products to specific days
   - Skip any day

🔹 TASK 19 — Past Day & 4 AM Cut-Off Handling (CRITICAL)
Implement time-based availability rules.

Rules:
- Past days must be hidden or disabled in WEEKLY mode
- Current day becomes unavailable after 4:00 AM local time
- If current time > 4:00 AM:
   - Disable ordering for that day in WEEKLY mode
   - Show message:
     "Ordering for today is closed. Please use Daily orders."

DAILY mode remains available for same-day ordering.

🔹 TASK 20 — Edit / Alter Orders Before 4 AM (GLOBAL RULE)
Enforce edit cutoff for all recurring orders.

Rules:
- User can add, remove, or modify products:
   - DAILY
   - WEEKLY
   - MONTHLY
- Changes are allowed only before 4:00 AM of delivery date
- If edited before 4 AM:
   - Apply changes to next delivery
   - Calculate delta payment
- If edited after 4 AM:
   - Block edit for that delivery
   - Apply changes from next cycle

🔹 TASK 21 — Delta Settlement on Edits (Reinforced)
Apply delta settlement on all accepted edits.

Rules:
- Added products → charge only added amount
- Removed products → credit removed amount to GalliKart Wallet
- Do not re-charge full order
- Update order total after settlement

🔹 TASK 22 — UI Guardrails & Messaging
Add user-facing guardrails.

Requirements:
- Disabled past days must appear greyed out
- Disabled days must show tooltip:
   "Ordering closed for this day"
- Edit attempts after 4 AM must show:
   "Edits for this delivery are closed. Changes will apply to next delivery."

🔹 TASK 23 — Backend Validation (Non-Bypassable)
Add backend validation for time rules.

Rules:
- Frontend checks are not sufficient
- Backend must validate:
   - Delivery date
   - Current server time
   - 4:00 AM cutoff
- Reject invalid edits even if frontend allows them

🔹 TASK 24 — Timezone Handling
Implement timezone-safe logic.

Rules:
- Use delivery location timezone
- Do not rely on client time
- All 4 AM cutoffs must be calculated server-side

🔹 TASK 25 — Test Scenarios for Weekly Calendar
Generate test cases for weekly calendar logic.

Include:
- Ordering future week
- Ordering same day before 4 AM
- Ordering same day after 4 AM (blocked)
- Past day hidden
- Daily fallback for blocked weekly day

HOW TO USE THIS WITH YOUR EXISTING TASKS

Keep MASTER SYSTEM CONTEXT

Run TASKS 16–25 after Tasks 1–15

Validate:

Category switching

Week banner logic

4 AM enforcement

Delta settlement

RESULT AFTER IMPLEMENTATION

✔ Clear category separation per mode
✔ Weekly planner feels calendar-based, intuitive
✔ No accidental late-night orders
✔ Daily acts as emergency same-day fallback
✔ Clean delta-based billing with wallet safety