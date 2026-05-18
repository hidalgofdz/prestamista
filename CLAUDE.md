# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tech Stack

- **Ruby 3.3.4 / Rails 8.1.3** — `config.load_defaults 8.1` is set in `config/application.rb`.
- **Ruby** 3.3, **Rails** 8.2 (edge), **MySQL** (SaaS) / **SQLite** (OSS)
- **Frontend:** Hotwire (Turbo 8 + Stimulus 3.2), Importmap (no Node.js, Do **not** propose Webpack, Vite, jsbundling-rails, or cssbundling-rails.)
- **Testing:** Minitest + Fixtures (not RSpec, not FactoryBot)
- **Auth:** Custom passwordless: passkeys (WebAuthn) + magic links (no Devise), `has_secure_password` optional
- **Background Jobs:** Solid Queue (database-backed, no Redis)
- **Caching:** Solid Cache | **WebSockets:** Solid Cable
- **IDs:** UUIDv7 everywhere (base36-encoded, 25-char strings)
- **Assets:** Propshaft + Import Maps (no Node.js, no Webpack)
- **Deployment:** Puma, Railway and Docker for deploys (`railway.toml`, `Dockerfile`).
- **PostgreSQL**, one database for`primary`, `queue`, `cache`, and `cable` databases via the Solid stack.

No authentication, authorization, service-object framework, ViewComponent, money-handling, or pagination gems are present. Add them deliberately when a feature requires one — don't assume one is already wired up.



## Architecture

```
app/
  controllers/     # Thin. Only 7 REST actions. New resource for each state change.
  models/          # Rich. Business logic, concerns, associations, validations.
  models/concerns/ # Horizontal behavior: Closeable, Assignable, Searchable.
  views/           # ERB + Turbo Frames/Streams. No JS frameworks.
  jobs/            # Shallow. Call model methods, don't contain logic.
  mailers/         # Minimal. Bundle notifications, plain-text first.
  channels/        # ActionCable channels for real-time.
```

**No `app/services/`, `app/queries/`, `app/policies/`, `app/forms/` directories.** Business logic lives in models. Authorization via roles on User model + controller concerns. Complex forms use standard Rails nested attributes.

## Core Philosophy

- **Vanilla Rails:** Rich domain models, thin controllers, avoid service objects (acceptable when justified, but not as default architecture), no Devise, no Pundit
- **Everything is CRUD:** State changes = new resources (`Closure`, `Publication`, `Archival`)
- **State as records:** No boolean flags for business state -- use `has_one` state records
- **Rich models over services:** Business logic lives in models, organized via concerns
- **Concerns for organization:** Models compose behavior via focused concerns (`Closeable`, `Assignable`)
- **No foreign key constraints:** Application enforces referential integrity
- **Multi-tenancy:** URL path-based (`/:account_id/...`), `account_id` on every table
- **Current for context:** `Current.user`, `Current.account`, `Current.session`
- **Shallow jobs:** `_later`/`_now` pattern; job calls model method, logic stays in model

## Key Commands

```bash
bin/setup                                    # Initial setup
bin/dev                                      # Start dev server
bin/rails test                               # Full test suite
bin/rails test test/models/card_test.rb      # Specific file
bin/rails test test/models/card_test.rb:14   # Specific line
bin/rails test:system                        # System tests (Capybara + Selenium)
bin/ci                                       # Full CI (rubocop + brakeman + tests)
bundle exec rubocop -a                       # Auto-fix Ruby style
bin/rails db:migrate                         # Run migrations
bin/rails db:fixtures:load                   # Load fixture data
bin/rails db:reset                           # Drop, create, load schema + fixtures
```

## Development Workflow

1. Write a failing Minitest test with fixtures
2. Implement minimal code to make it pass
3. Refactor while tests stay green

## Deployment (Railway):
- Push to `main` or run `railway up` — Railway builds the Dockerfile and deploys automatically.
- Logs, shell, and console are available in the Railway dashboard or via the `railway` CLI.


## Naming Conventions

| Layer | Pattern | Example |
|-------|---------|---------|
| Model | Singular PascalCase | `Card`, `BoardPublication` |
| Controller | Plural, nested by resource | `Cards::ClosuresController` |
| State Record | Noun describing state | `Closure`, `Publication`, `Goldness` |
| Concern | Adjective/-able | `Closeable`, `Assignable`, `Searchable` |
| Job | `Model::VerbJob` | `Event::RelayJob`, `Card::CleanupJob` |
| Test | `ModelTest` / `ControllerTest` | `CardTest`, `Cards::ClosuresControllerTest` |

## Style Guide (37signals)

- Expanded conditionals over guard clauses (exception: single-line early returns at method start)
- Method ordering: class methods > public instance (`initialize` first) > private
- Order private methods by invocation flow (call order)
- Bang methods (`!`) only when a non-bang counterpart exists
- No newline under `private`/`protected` keyword; indent content under it
- Avoid service objects -- domain logic belongs in models with concerns (services acceptable when justified)
- `belongs_to :creator, default: -> { Current.user }` for context defaults
- `touch: true` on child associations for cache invalidation

See @../docs/rails-development-principles.md for full development principles.


## Project status

`prestamista` is a freshly generated **Rails 8.1** application. The lending domain (the project name is Spanish for *moneylender*) has not been implemented yet: `config/routes.rb` is empty, no models exist beyond `ApplicationRecord`, and `db/schema.rb` has not been generated. Treat almost any file under `app/` as greenfield.

## Prerequisites (local development)

- **Docker** — PostgreSQL runs in a container (see below).
- **libvips** — Required by Active Storage for image variant processing (thumbnails). Install with `brew install vips` (macOS) or `apt-get install libvips` (Linux). The Dockerfile and CI already include it.

## Database (local development)

PostgreSQL runs in a Docker container, **never natively** on the host. The `db` service is defined in `compose.yml` and pinned to `postgres:17.5-alpine`. Data persists in the `pg_data` named volume.

- Start it: `docker compose up -d db`
- Stop it: `docker compose down` (data preserved); add `-v` to wipe the volume.
- Credentials and host/port come from `.env` (gitignored). Copy `.env.example` to bootstrap.
- `bin/setup` probes the DB and prints a helpful error if the container isn't running, instead of failing on a confusing `pg` connection error.
- `dotenv-rails` (dev/test only) auto-loads `.env` so `bin/rails ...` commands see the variables without an explicit `dotenv --` prefix.

## CI

`.github/workflows/ci.yml` runs on PRs and pushes to `main` with five jobs: `scan_ruby` (Brakeman + bundler-audit), `scan_js` (importmap audit), `lint` (RuboCop), `test` (Minitest on PostgreSQL), and `system-test` (Capybara — uploads screenshots on failure). `bin/ci` reproduces all of this locally.

## Internationalization

- Default locale is **`es-MX`**; fallback chain is `es-MX → es → en`. Time zone is `Mexico City`.
- `config.i18n.raise_on_missing_translations = true` is enabled in dev and test — **every user-facing string in views must use `t()`**, or the request will raise. This is the enforcement; do not disable it casually.
- New translation keys go in **both** `config/locales/en.yml` and `config/locales/es-MX.yml`. The `rails-i18n` gem already provides Spanish translations for default Rails messages (validations, dates, numbers).
- `public/404.html`, `422.html`, `500.html` are static (served before Rails boots) so `t()` is unavailable; they're written in Spanish to match the default locale. If a multilingual UI is ever added, replace them with a dynamic `ErrorsController`.

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
