# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

`prestamista` is a freshly generated **Rails 8.1** application. The lending domain (the project name is Spanish for *moneylender*) has not been implemented yet: `config/routes.rb` is empty, no models exist beyond `ApplicationRecord`, and `db/schema.rb` has not been generated. Treat almost any file under `app/` as greenfield.

## Stack

- **Ruby 3.3.4 / Rails 8.1.3** — `config.load_defaults 8.1` is set in `config/application.rb`.
- **PostgreSQL**, multi-database — separate `primary`, `queue`, `cache`, and `cable` databases via the Solid stack.
- **Solid Queue / Solid Cache / Solid Cable** — all DB-backed. Do **not** introduce Redis, Sidekiq, or Memcached unless explicitly asked.
- **Hotwire** (Turbo + Stimulus) over **Importmap**. No Node toolchain. Do **not** propose Webpack, Vite, jsbundling-rails, or cssbundling-rails.
- **Propshaft** asset pipeline (not Sprockets).
- **Puma + Thruster** in production; **Kamal** + Docker for deploys (`config/deploy.yml`, `Dockerfile`).
- **rubocop-rails-omakase** for style.

No authentication, authorization, service-object framework, ViewComponent, money-handling, or pagination gems are present. Add them deliberately when a feature requires one — don't assume one is already wired up.

## Commands

Development:
- `bin/setup` — install gems and run `db:prepare`. Add `--reset` to drop and recreate databases.
- `bin/dev` — start the development server.
- `bin/rails console`

Tests (Minitest, parallelized by default in `test/test_helper.rb`):
- `bin/rails test` — full suite
- `bin/rails test test/models/foo_test.rb` — single file
- `bin/rails test test/models/foo_test.rb:42` — single test by line
- `bin/rails test:system` — Capybara system tests

Lint and security (all run together via `bin/ci`):
- `bin/rubocop`
- `bin/brakeman`
- `bin/bundler-audit`
- `bin/importmap audit`

Background jobs:
- `bin/jobs` — run the Solid Queue worker out-of-process. When `SOLID_QUEUE_IN_PUMA=true` it runs inside Puma instead (see `config/puma.rb`).

Deployment (Kamal):
- `bin/kamal deploy`, `bin/kamal console`, `bin/kamal logs -f`, `bin/kamal shell`

## CI

`.github/workflows/ci.yml` runs on PRs and pushes to `main` with five jobs: `scan_ruby` (Brakeman + bundler-audit), `scan_js` (importmap audit), `lint` (RuboCop), `test` (Minitest on PostgreSQL), and `system-test` (Capybara — uploads screenshots on failure). `bin/ci` reproduces all of this locally.

## Notes

- `config/deploy.yml` and `.kamal/secrets` configure production deploys — treat as sensitive.
- The CSP initializer (`config/initializers/content_security_policy.rb`) is fully commented out; uncomment intentionally before relying on it.
- `bin/docker-entrypoint` runs `db:prepare` automatically on container start.
