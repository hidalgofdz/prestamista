# ADR 0001: Cards over tables for list views

## Status

Accepted

## Context

Prestamista has three list views: loans index, payment history (on loan detail), and borrowers index. All three were initially built with HTML `<table>` elements and responsive column-hiding (`table__cell--show-md`, `table__cell--show-sm`) to fit on small screens.

Two facts made this approach problematic:

1. **Most users are on mobile.** Hiding columns means the primary audience sees less information than desktop users. In a lending app, the hidden data (principal/interest split, start date, loan count) is financially meaningful, not decorative.
2. **The dataset is small.** A typical lender manages 5-15 borrowers and loans. Tables earn their complexity when users need to compare values across many rows — sorting a column of 200 amounts to find the outlier. At 5-15 items, that comparison need doesn't exist. Users are scanning for a specific borrower or checking whether a payment arrived.

## Decision

Replace `<table>` with card/stacked-list layouts in all three views. Each item becomes a self-contained block with label-value pairs that reflow naturally at any viewport width. No information is hidden at any breakpoint.

### Loan card (loans index)
- **Primary:** Borrower name, with start date + term as subtitle (disambiguates multiple loans to the same borrower)
- **Supporting:** Amount, next payment date, status tag (active/overdue/paid off)

### Payment card (loan detail)
- **Primary:** Date and total amount
- **Secondary:** Principal/interest split (visually subordinate — smaller text, muted color)

### Borrower card (borrowers index)
- **Primary:** Name
- **Supporting:** Phone, loan count

Each view has its own markup — no shared generic card component. The surrounding chrome (toolbar, filters, empty state) remains unchanged.

## Consequences

- **All data visible at all breakpoints.** Mobile users see the same information as desktop users.
- **No column-hiding CSS needed.** The `table__cell--show-md` / `table__cell--show-sm` pattern is no longer used in these views.
- **Less scannable at scale.** If the app ever serves lenders with 50+ loans, cards will feel sparse compared to a dense table. At that point, reintroduce tables for the index views — but that's a different product with different users.
- **The existing table CSS component is retained** in the design system for future use where comparison-heavy views warrant it.
