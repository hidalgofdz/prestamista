# ADR 0002: Railway Storage Buckets for file uploads

## Status

Accepted

## Context

Payments can optionally have a proof-of-payment file attached (image or PDF). The app is deployed on Railway with an ephemeral container filesystem, so local disk storage is not viable in production. We needed an external object store.

Options considered:

1. **AWS S3** — most documented, but requires a separate AWS account and incurs egress fees.
2. **Cloudflare R2** — S3-compatible, zero egress, but requires a separate Cloudflare account.
3. **Railway Storage Buckets** — S3-compatible, zero egress, auto-provisioned env vars, keeps the entire stack on one platform.

## Decision

Use Railway Storage Buckets for production file storage. Use Active Storage's S3 service adapter (since Railway Buckets are S3-compatible). Serve files via presigned URLs (Active Storage's default redirect behavior).

Local disk (`:local` service) for development and test environments.

## Consequences

- No separate cloud provider account needed — storage is managed alongside the app in Railway.
- Buckets are private-only; public URLs are not available. Active Storage's default blob routes use a permanent signed ID to redirect to a short-lived presigned S3 URL. The blob route itself is not time-limited or access-controlled — an authenticated proxy controller is needed to enforce app-level authorization on private files.
- If Railway Buckets ever becomes insufficient (CDN needed, public access, versioning), migrating to S3 or R2 requires changing `config/storage.yml` and moving existing files — Active Storage abstracts the rest.
- Object versioning and lifecycle policies are not supported on Railway Buckets (as of 2025).
