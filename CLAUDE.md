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
- **Puma + Thruster** in production; **Railway** + Docker for deploys (`railway.toml`, `Dockerfile`).
- **rubocop-rails-omakase** for style.

No authentication, authorization, service-object framework, ViewComponent, money-handling, or pagination gems are present. Add them deliberately when a feature requires one — don't assume one is already wired up.

## Database (local development)

PostgreSQL runs in a Docker container, **never natively** on the host. The `db` service is defined in `compose.yml` and pinned to `postgres:17.5-alpine`. Data persists in the `pg_data` named volume.

- Start it: `docker compose up -d db`
- Stop it: `docker compose down` (data preserved); add `-v` to wipe the volume.
- Credentials and host/port come from `.env` (gitignored). Copy `.env.example` to bootstrap.
- `bin/setup` probes the DB and prints a helpful error if the container isn't running, instead of failing on a confusing `pg` connection error.
- `dotenv-rails` (dev/test only) auto-loads `.env` so `bin/rails ...` commands see the variables without an explicit `dotenv --` prefix.

## Commands

Development:
- `bin/setup` — install gems, ensure `.env` exists, check Postgres, run `db:prepare`. Add `--reset` to drop and recreate databases.
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

Deployment (Railway):
- Push to `main` or run `railway up` — Railway builds the Dockerfile and deploys automatically.
- Logs, shell, and console are available in the Railway dashboard or via the `railway` CLI.

## CI

`.github/workflows/ci.yml` runs on PRs and pushes to `main` with five jobs: `scan_ruby` (Brakeman + bundler-audit), `scan_js` (importmap audit), `lint` (RuboCop), `test` (Minitest on PostgreSQL), and `system-test` (Capybara — uploads screenshots on failure). `bin/ci` reproduces all of this locally.

## Internationalization

- Default locale is **`es-MX`**; fallback chain is `es-MX → es → en`. Time zone is `Mexico City`.
- `config.i18n.raise_on_missing_translations = true` is enabled in dev and test — **every user-facing string in views must use `t()`**, or the request will raise. This is the enforcement; do not disable it casually.
- New translation keys go in **both** `config/locales/en.yml` and `config/locales/es-MX.yml`. The `rails-i18n` gem already provides Spanish translations for default Rails messages (validations, dates, numbers).
- `public/404.html`, `422.html`, `500.html` are static (served before Rails boots) so `t()` is unavailable; they're written in Spanish to match the default locale. If a multilingual UI is ever added, replace them with a dynamic `ErrorsController`.

## Deployment (Railway)

Railway builds the `Dockerfile` directly. Behaviour is defined in `railway.toml`.

**Required env vars** (set in the Railway dashboard under the service's Variables tab):

| Variable | How to get it |
|---|---|
| `RAILS_MASTER_KEY` | Contents of `config/master.key` (never commit this file) |
| `DATABASE_URL` | Auto-injected by the Railway Postgres add-on |
| `SOLID_QUEUE_IN_PUMA` | Set to `true` — runs jobs inside the web Puma process |

All four Solid connections (primary, cache, queue, cable) share the **single** Railway Postgres add-on via `DATABASE_URL`. Do not provision more than one Postgres service unless traffic warrants it.

Migrations run automatically: `bin/docker-entrypoint` calls `db:prepare` on every container start.

**Active Storage warning:** the container filesystem is ephemeral — uploads stored at `:local` will be lost on each deploy. Switch to S3, Cloudflare R2, or a Railway persistent volume before shipping any upload feature.

## Notes

- The CSP initializer (`config/initializers/content_security_policy.rb`) is fully commented out; uncomment intentionally before relying on it.
- `bin/docker-entrypoint` runs `db:prepare` automatically on container start.
