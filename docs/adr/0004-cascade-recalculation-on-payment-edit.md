# ADR 0004: Cascade recalculation on payment edit

## Status

Accepted

## Context

Payments store a snapshot of their interest/principal split (`interest_applied`, `principal_applied`) computed at creation time based on the loan's remaining balance and the period's accrued interest. When a lender edits a payment's amount or date, that snapshot becomes stale — and so does every subsequent payment's snapshot, because each one was computed against a balance that has now changed.

Options considered:

1. **No recalculation** — Edit only the target payment's split. Downstream payments keep their original snapshots. Simple, but the numbers on screen stop adding up: the sum of `principal_applied` across payments won't match the balance change, and individual payment breakdowns will be wrong. For a financial tool, this erodes trust.
2. **Recalculate only the edited payment** — Recompute the target payment's split but leave downstream payments alone. Better than option 1 for the edited row, but the same inconsistency propagates to every payment after it.
3. **Cascade recalculation of all subsequent payments** — After editing a payment, reprocess every payment on the loan in chronological order, recomputing each one's `interest_applied` and `principal_applied` against the running balance. If any downstream payment becomes invalid (e.g., amount exceeds the new remaining balance), reject the entire edit.

## Decision

Option 3: cascade recalculation with transactional rollback on downstream validation failure.

When a payment is updated:

1. Save the edited payment's new attributes (amount, date).
2. Collect all payments on the loan in chronological order (by date, then creation order for same-date ties).
3. Walk the list from the beginning, recomputing each payment's `interest_applied` and `principal_applied` against the cumulative balance at that point.
4. Validate each recomputed payment. If any fails (amount exceeds remaining balance, etc.), roll back the entire transaction and surface the error on the edited payment's form.
5. Save all recomputed payments in a single transaction and touch the loan's `updated_at` within the same transaction — so HTTP caching (ETags, `fresh_when`) always reflects the latest recalculation.

`Loan#recalculate_payments` owns its own transaction so it is safe to call standalone (e.g., from tests or future background jobs) as well as nested inside the outer transaction from `Payment#save_with_cascade_recalculation`. Rails uses savepoints for nesting.

Date edits are allowed to reorder payments on the timeline. The recalculation processes payments in their new chronological order, so reordering is handled naturally without special-casing.

Editing payments on paid-off loans is allowed. If the edit causes the balance to go above zero, the loan simply becomes active again (paid-off is derived state).

## Consequences

- Every payment edit touches all subsequent payment records on the loan. For a typical loan (12–60 payments), this is trivial. If the app ever supports loans with thousands of payments, this should be revisited.
- The lender sees a clear error when an edit would break a downstream payment, rather than silently corrupted data. The trade-off is that some edits require fixing downstream payments first.
- The `excluding: self` pattern already used in `remaining_balance` and `interest_due_on` supports this approach — the recalculation can reuse existing model methods.
- No audit trail of the previous split values is kept. If that becomes a requirement, an event/version log would need to be added separately.
