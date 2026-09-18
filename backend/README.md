# Backend (Attendance SaaS API)

FastAPI + SQLAlchemy backend. Phase 1 scope: authentication only (issue #8).

## Stack
- Python 3.12, FastAPI, SQLAlchemy 2.x
- SQLite (file-based, `backend/attendance.db`) for local development — no external DB required yet
- JWT auth (`python-jose`), password hashing (`passlib[bcrypt]`)

## Local run

```sh
docker run --rm -p 8000:8000 \
  -v "$PWD:/workspace" -w /workspace \
  -v auto-team-dev-pip-cache:/pipcache -e PIP_CACHE_DIR=/pipcache -e HOME=/tmp \
  python:3.12-slim bash -c "pip install -q -r requirements.txt -r requirements-dev.txt; uvicorn app.main:app --host 0.0.0.0 --port 8000"
```

On startup, the app creates the SQLite schema automatically and seeds two local-dev users if they
don't already exist (see below). This is **not** a migration tool — a future task should introduce
Alembic once the schema stabilizes beyond phase 1.

## Environment variables

| Variable | Default | Notes |
|---|---|---|
| `JWT_SECRET` | `dev-only-insecure-secret-change-me` | **Must** be overridden with a real secret from a secrets manager / env var in any deployed environment. Never commit a real secret to git. |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `15` | Access token lifetime. |
| `REFRESH_TOKEN_EXPIRE_MINUTES` | `10080` (7 days) | Refresh token lifetime. |
| `DATABASE_URL` | `sqlite:///./attendance.db` | SQLAlchemy connection string. |

## Seed users (local dev only — not real credentials)

Seeded automatically on app startup if not already present. For local development and other
agents/QA to use against the dev SQLite DB only.

| Role | Email | Password |
|---|---|---|
| admin | `admin@example.com` | `dev-admin-pass-123` |
| employee | `employee@example.com` | `dev-employee-pass-123` |

## API surface (issue #8)

- `POST /auth/login` — email + password, returns `{access_token, refresh_token, token_type}`
- `POST /auth/logout` — revokes the given `refresh_token`
- `POST /auth/refresh` — exchanges a valid, non-revoked `refresh_token` for a new token pair
  (rotates the refresh token; the old one is revoked on use)
- `GET /auth/me` — example protected endpoint, returns the current user resolved from the
  `Authorization: Bearer <access_token>` header (demonstrates role extraction for downstream tasks)
- `GET /health` — liveness check

## Reusable auth dependency

`app/core/security.py` exposes `get_current_user` and `require_role(*roles)` FastAPI dependencies.
Downstream backend tasks (employee CRUD, clock-in/out, leave requests, etc.) should import these
rather than reimplementing auth/role checks.

## Quality gate (run via Docker, not on host)

```sh
docker run --rm \
  -v "$PWD:/workspace" -w /workspace \
  -v auto-team-dev-pip-cache:/pipcache -e PIP_CACHE_DIR=/pipcache -e HOME=/tmp \
  --user "$(id -u):$(id -g)" \
  python:3.12-slim bash -c "pip install -q -r requirements.txt -r requirements-dev.txt 2>/dev/null; ruff check . && black --check . && isort --check-only . && pytest -q"
```
