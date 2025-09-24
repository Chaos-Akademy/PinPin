## PinPin Scheduled Subscription Handler

This document specifies the subscription Handler behavior you will implement manually. It focuses on protecting users from fee or contract-update abuse while enabling predictable monthly charges via Flow Scheduled Transactions.

### Goals
- Enforce a hard budget equal to `feeAmount * subscriptionCycles` using a dedicated fee pot vault.
- Verify fee integrity on every cycle against the contract’s canonical fee before withdrawing.
- Support safe extension (additional months and/or updated fee with explicit re-consent) while preserving remaining time.

### Concepts
- **Fee Pot Vault**: A dedicated `FlowToken.Vault` per user that holds only subscription funds. The Handler receives a capability to this pot (not the user’s main vault).
- **Per-Month Fee (`feeAmount`)**: The user’s agreed monthly price snapshot at initialization (and optionally updated on extend with explicit consent).
- **Subscription Cycles (`subscriptionCycles`)**: Number of months the user commits to. One cycle equals one month.
- **Canonical Contract Fee (`currentFee`)**: A public value stored in the contract (e.g., `PinPin.currentFee`) that represents the current official price.

### Handler State (stored in the resource)
- `feeVaultCap`: Capability to the user’s fee pot with at least `{FungibleToken.Provider, FungibleToken.Balance}`.
- `feeAmount: UFix64`: User-agreed monthly fee snapshot.
- `cyclesTotal: UInt64`: Total committed cycles across the lifetime (including extensions).
- `cyclesConsumed: UInt64`: Number of completed/charged cycles.
- `cycleSeconds: UFix64`: Seconds per cycle (e.g., 30 days).
- `startedAt: UFix64`: Timestamp of initial start.
- `expiresAt: UFix64`: When the commitment ends (`startedAt + cycleSeconds * subscriptionCycles`, adjusted on extend).
- Optional: `lastRunAt`, `nextRunAt` for scheduling metadata.

### Initialization (User Opt-In)
Inputs:
- `feeVaultCap`: Capability to the fee pot vault.
- `feeAmount: UFix64`: Expected monthly fee.
- `subscriptionCycles: UInt64`: Number of months.

Validation and setup:
1. Assert `feeAmount > 0.0` and `subscriptionCycles > 0`.
2. Read `onChainFee = PinPin.currentFee`; assert `onChainFee == feeAmount` (fee integrity at opt-in).
3. Verify `feeVaultCap.check()` and `borrow` success; read pot balance.
4. Assert `potBalance == feeAmount * subscriptionCycles` (exact prepay ensures a hard cap on spend).
5. Set `cyclesTotal = subscriptionCycles`, `cyclesConsumed = 0`.
6. Set `startedAt = getCurrentBlock().timestamp`.
7. Set `expiresAt = startedAt + cycleSeconds * subscriptionCycles`.
8. Emit `SubscriptionInitialized` event.

### Execution Flow (Per Cycle)
Each scheduled run performs:
1. Fee integrity check: assert `PinPin.currentFee == feeAmount`.
2. Lifecycle checks: `cyclesConsumed < cyclesTotal` and `now <= expiresAt`.
3. Balance check: the pot has at least `feeAmount`.
4. Withdraw `feeAmount` from the pot and deliver per business logic.
5. Increment `cyclesConsumed` and emit `CycleCharged`.
6. Compute `nextRunAt = startedAt + (cyclesConsumed + 1) * cycleSeconds`.
7. If `cyclesConsumed == cyclesTotal`, emit `Completed` and stop scheduling.
8. Otherwise, estimate scheduler fees for `nextRunAt`; if acceptable, schedule the next run.

### Fee Integrity Guard
- Before any withdrawal, the Handler compares the stored `feeAmount` with the contract’s `currentFee`.
- If different, the Handler halts (no withdrawal, no reschedule) and emits a `Halted` event with reason `fee_mismatch`.
- Users must explicitly re-consent (via extend/refresh) to adopt a new price.

### Extension Flow (Add Months and/or Update Fee)
Authorized caller (the subscriber or delegate) can extend:
Inputs:
- `additionalCycles: UInt64` (≥ 1).
- Optional `newFeeAmount: UFix64` if the user agrees to a new price.

Steps:
1. If `newFeeAmount` is provided: assert `newFeeAmount == PinPin.currentFee`; set `feeAmount = newFeeAmount`.
2. Compute `remainingCycles = cyclesTotal - cyclesConsumed`.
3. Update `cyclesTotal += additionalCycles`.
4. Require the user to top-up the fee pot so that `potBalance == feeAmount * (remainingCycles + additionalCycles)`.
5. Preserve remaining time and stack new time:
   - `remainingTime = max(0.0, expiresAt - now)`
   - `expiresAt = now + remainingTime + additionalCycles * cycleSeconds`
6. Recompute `nextRunAt` if needed and emit `SubscriptionExtended`.

### Halt Conditions (No Reschedule, No Funds Lost)
On any check failure, do not withdraw and do not schedule the next run. Emit `Halted(reason, timestamp)` if applicable.
- `PinPin.currentFee != feeAmount` (fee mismatch)
- `cyclesConsumed >= cyclesTotal`
- `now > expiresAt`
- `potBalance < feeAmount`
- Scheduler fee estimation fails or exceeds policy

Remaining balance stays in the user’s fee pot for them to reclaim.

### Events
- `SubscriptionInitialized(user, fee, cycles, startedAt, expiresAt)`
- `CycleCharged(user, index, fee, timestamp, nextRunAt)`
- `SubscriptionExtended(user, addedCycles, newTotal, newFee?, newExpiresAt)`
- `Halted(user, reason, timestamp)`
- `Completed(user, totalCycles, timestamp)`

### Security & Safety Practices
- Use a dedicated fee pot; never grant an unbounded withdraw over the main vault.
- Enforce exact pot balance at init/extend to cap maximum exposure.
- Re-check fee equality before every withdrawal to defend against contract fee changes.
- Bound scheduler parameters (priority, effort) and verify `estimate` before scheduling.
- Provide user tooling to revoke capabilities or empty the fee pot at any time outside active withdrawals.

### Integration Checklist
- Contract exposes `currentFee: UFix64` for integrity checks.
- Transactions always use string imports (`"FlowToken"`, `"FungibleToken"`, `"FlowTransactionScheduler"`).
- Emulator should be started with scheduled transactions enabled when testing: `flow emulator --scheduled-transactions`.
- For each run, perform estimation with `FlowTransactionScheduler.estimate(...)` and assert success before scheduling.

This spec ensures users are protected by hard budget limits, fee integrity checks against contract updates, and a safe extension path that preserves remaining time while stacking new cycles.

### Daily Registry Maintenance (Scheduled Job)

Purpose: once per day, run a lightweight job that reconciles exactly one registry entry and self-schedules for the next day. There is no broad scan across multiple accounts.

What it needs:
- A dedicated maintenance handler implementing `{FlowTransactionScheduler.TransactionHandler}` with its own small FLOW fee pot (no user caps).
- Self-scheduling parameters per run:
  - `timestamp = getCurrentBlock().timestamp + 86400.0`
  - `priority = Medium (1)`
  - `executionEffort ≈ 500–1000` (very small since we touch one entry)
  - `transactionData` (optional) holds a tiny cursor `{index}` within 100 bytes.
- Before scheduling, call `FlowTransactionScheduler.estimate(...)` and assert fees within a small max-per-tx.

Handler logic per run (single-entry update):
1. Read `{index}` (default `0`).
2. Lookup the address at `allSubscribers[index]` (or equivalent key order).
3. Recompute `isActive` for that address from invariants (fee equality, cycles, expiry) and write it to the registry `{Address: {subscription: isActive}}`.
4. Emit `SubscriptionStatusUpdated(address, isActive)` if the value changed.
5. Compute `nextIndex = (index + 1) % allSubscribers.length`.
6. Schedule the next run for `+86400.0` with `transactionData = {nextIndex}`.

Why no scanning/pagination:
- The registry already stores `isActive` per address; the handler touches exactly one entry per day to keep on-chain truth fresh without iterating large sets.
- Single-entry updates keep computation predictable and cheap, avoiding any need to paginate or batch.
- The 100-byte `transactionData` limit easily accommodates a tiny `{index}` cursor.


