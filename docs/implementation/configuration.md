# SheetViz — Configuration Foundation

**Trace ID:** CONFIG-VALID-01  
**Phase:** Phase 1 — Configuration Foundation  
**Status:** In Progress

## Purpose

This document defines the Phase 1 configuration boundary. The configuration layer validates runtime inputs only; it does not connect to a database, create a schema, establish tenant context, authenticate users, or call third-party providers.

## Environment Variables

| Variable | Required | Example local value | Rule |
|---|---:|---|---|
| `APP_ENV` | Yes | `local` | One of `local`, `dev`, `staging`, `production` |
| `APP_DATABASE_URL` | Yes | `postgresql://sheetviz:sheetviz@localhost:5432/sheetviz` | URL reference only in Phase 1; no schema/domain access |
| `APP_REDIS_URL` | Yes | `redis://localhost:6379/0` | URL reference only in Phase 1; no worker task/domain behavior |
| `APP_LOG_LEVEL` | No | `INFO` | Standard log-level string |

## Local Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'

cd ..
cp .env.example .env
set -a
source .env
set +a

cd backend
python -m app.config.validate
pytest
```

## Security Rules

- `.env` is local-only and must never be committed.
- `.env.example` contains placeholders only; it must not contain production credentials, access tokens, refresh tokens, webhook secrets, signing keys, or private endpoints.
- Runtime secret injection is environment/secret-manager based. Provider/KMS selection remains an open implementation decision and is out of scope for Phase 1.
- Validation errors must not print configuration values or secrets.
- Missing, malformed, or unknown configuration fails fast; there is no silent fallback.

## Environment Separation

Each environment uses independently injected values. Local/dev/staging/production configurations must not share production credentials. No environment-specific secret values belong in version control.

## Phase 1 Scope Boundary

This configuration foundation does not authorize or implement database migrations, RLS, audit privileges, authentication, tenant context, Google OAuth, payment configuration, sync tasks, entitlement logic, business API endpoints, or frontend behavior.
