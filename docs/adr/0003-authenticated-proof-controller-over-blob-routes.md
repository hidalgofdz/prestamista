# ADR 0003: Authenticated proof controller over default blob routes

## Status

Accepted

## Context

Payment proofs (bank transfer screenshots, receipts) contain financial PII. Active Storage's default blob routes (`/rails/active_storage/blobs/:signed_id`) are permanently valid and enforce no application-level authentication or account scoping — anyone with the URL can generate fresh presigned S3 URLs indefinitely.

ADR 0002 flagged this gap: "an authenticated proxy controller is needed to enforce app-level authorization on private files."

Railway Storage Buckets are private-only and serve files via short-lived presigned S3 URLs, so the S3 URL itself expires quickly (~5 minutes). However, the Rails blob route that redirects to it does not expire and is not access-controlled.

Options considered:

1. **Keep default blob routes, rely on URL obscurity** — Blob signed IDs are hard to guess (UUIDv7), but any leaked URL works forever. No auth enforcement.
2. **Authenticated redirect controller** — App controller verifies session + account scope, then redirects to a presigned S3 URL. Lightweight (no streaming through Puma).
3. **Authenticated proxy controller** — App controller streams file bytes through Puma. S3 URL never exposed to client, but ties up a Puma thread per download.

## Decision

Use an authenticated redirect controller (`Payments::ProofsController#show`) and disable Active Storage's default blob routes in production (`config.active_storage.draw_routes = false`).

Design:

- **Route:** `GET /payments/:payment_id/proof` (shallow, singular resource)
- **Variants:** `?variant=thumb` query param for the 64x64 thumbnail; same controller, same action
- **Disposition:** Controller decides based on content type — PDFs download (`:attachment`), images display inline (`:inline`)
- **Missing proof:** Returns 404
- **Auth chain:** Session authentication (via `Authentication` concern) → account scoping (payment's `account_id` matches `Current.account`)

Redirect over proxy because: files are max 10 MB, user base is small (one lender per account), and presigned URLs already expire in minutes — the brief exposure of a short-lived S3 URL is acceptable.

## Consequences

- Default Active Storage blob/variant/representation routes are disabled in production (`config.active_storage.draw_routes = false`). All file access goes through application controllers. Any future Active Storage attachment (not just proofs) will need its own authenticated controller.
- Views link to the proof route instead of `rails_blob_path`. The controller generates presigned URLs via `ActiveStorage::Blob#url`.
- Development and test environments keep default routes enabled — the Disk storage service requires `rails_disk_service_url` to generate file URLs, since it serves files back through a Rails controller route rather than an external service like S3.
- If the app later needs public file access (e.g., borrower-facing read-only views), a separate controller with different auth rules will be needed.
