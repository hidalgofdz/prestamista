# Prestamista — Domain Language

## Glossary

| Term | Definition |
|------|-----------|
| **Lender** | The person who operates the lending business. Maps to a User + Account in the system. One lender = one user = one account (for now). |
| **User** | The authentication identity. Has email (unique) and name. Belongs to one account. Logs in via magic link. |
| **Account** | The multi-tenancy container. Every data record (borrowers, loans, payments) is scoped to an account. Created automatically on sign up, named after the user. Derived from session (not URL). |
| **Session** | A server-side record of an authenticated login. Stored in the database, referenced by encrypted cookie. Revocable. |
| **Magic link** | A signed, time-limited URL (15 minutes) sent to the user's email. Clicking it creates a session. No passwords. |
| **Borrower** | A person who receives a loan. A record managed by the lender, not an independent user. Has a name and phone number. Scoped to a single lender's account. In the future, borrowers may receive a signed link to view their loan status (read-only, no login required). |
| **Loan** | A lending agreement between a lender and a borrower. Defined by: principal amount (MXN), annual interest rate (can be 0%), term in months (no cap), and start date (defaults to today). Active immediately on creation. |
| **Principal** | The original amount of money lent to the borrower. |
| **Interest (on remaining balance)** | Each month, interest is calculated as `remaining_balance × monthly_rate`. Not pre-calculated on the original amount (not flat). Not compounding (not amortized). |
| **Fixed principal payment** | Each month the borrower pays a fixed portion of principal (`amount / term_months`) plus interest on the current balance. Payments decrease slightly over time as the balance shrinks. |
| **Principal payment (extra)** | An additional payment toward the principal balance, beyond the scheduled amount. Reduces the balance immediately, lowering all future interest charges. |
| **Loans page** | Flat list of all loans across all borrowers for the lender's account. Each card shows: borrower name (with start date + term as subtitle), amount, next payment date, and status. |
| **Loan detail** | Summary view showing: borrower, amount, rate, term, monthly principal payment, first month's interest, first total payment, start date, expected end date, and remaining balance. Payment history displayed as a reverse-chronological list of cards (date + amount primary, principal/interest split secondary). |
| **Paid off** | A loan whose remaining balance has reached zero. Displayed with a visual indicator on both the loan list and detail pages. No separate state record — derived from balance. |
| **Payment proof** | An optional image (JPEG, PNG, WebP, HEIC) or PDF attached to a payment as evidence of the transaction — typically a transfer screenshot or bank receipt. Single file per payment, max 10 MB. Displayed as a thumbnail in the payment history list. |

## Domain Rules

- A **loan cannot be deleted** if it has recorded payments. The payment history is the financial record.
- A **borrower cannot be deleted** if they have loans. Remove loans first (only possible if they have no payments).
- A **payment date** must not be in the future. Backdating is allowed (to record payments received earlier).

## Technical Notes

- **Active Storage content-type detection uses Marcel** which inspects magic bytes first, but may fall back to filename extension or declared content type when magic bytes are inconclusive. Validating `proof.content_type` is a reasonable defense layer for the allowed file types (JPEG, PNG, WebP, HEIC, PDF — all have strong magic byte signatures), but should not be treated as a guarantee against all spoofing scenarios.
