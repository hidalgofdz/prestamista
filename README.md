# Prestamista

A Rails 8.1 application. Stack and conventions are documented in [CLAUDE.md](CLAUDE.md).

## Local development

PostgreSQL runs in a Docker container — you do not need a native install.

1. Install Docker Desktop (or another Docker engine).
2. From the project root:
   ```sh
   cp .env.example .env       # adjust if you want different credentials
   docker compose up -d db    # start Postgres 17.5-alpine
   bin/setup                  # bundle, prepare DB, then start the dev server
   ```

`bin/setup` checks that Postgres is reachable and prints a helpful message if Compose isn't up. The database container's data persists in a Docker volume named `pg_data`.

## Tests

```sh
bin/rails test         # full suite
bin/rails test:system  # system tests (Capybara)
```

See `CLAUDE.md` for the full command reference (lint, security scans, deployment).
