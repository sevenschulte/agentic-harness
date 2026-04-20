# Memory

> **This file is auto-loaded at the start of every session.** Keep it under ~200
> lines. Curated, high-signal facts only — anything that the agent should
> remember across every conversation in this repo.
>
> The detailed stuff (per-project deep dives, research summaries, one-off
> investigations) lives elsewhere and is read on demand. See `memory/projects/`.

<!--
  Replace this template with real entries. Suggested sections below — keep,
  delete, or rename as fits your team.

  Style: facts, not narratives. Each bullet should be readable in 5 seconds
  and stand on its own. Use links and file paths instead of restating things.

  Update when:
    - A new fact emerges that the agent will need next session
    - An old fact becomes wrong (delete or correct it; do not leave stale facts)
    - You catch the agent guessing at something that should have been here
-->

## Team & roles

<!--
  Who is on the team, who maintains what, who to escalate to. Examples:

  - **Maintainer:** <name> (<github handle>) — final call on merges
  - **Backend lead:** <name> — owns `internal/` and `cmd/`
  - **Frontend lead:** <name> — owns `web/` and `mobile/`
  - **On-call rotation:** see <link>
-->

## Stack

<!--
  The actual tech stack. Examples:

  - **Backend:** Go 1.22, Echo, sqlc, PostgreSQL 16
  - **Frontend:** TypeScript 5.4, React 18, Vite, TanStack Query
  - **Mobile:** Expo 50, React Native 0.73
  - **Infra:** Fly.io (production), Docker Compose (local)
  - **CI:** GitHub Actions (`.github/workflows/`)
-->

## Conventions in this repo

<!--
  Things that are NOT obvious from reading the code. Examples:

  - All currency is stored in minor units (cents/Rappen) as `int64`
  - All timestamps are UTC; conversion happens at the API boundary
  - Multi-tenancy: every query MUST filter by `org_id`; helper in `db.SetTenantOrgID`
  - Soft-delete pattern: `deleted_at TIMESTAMPTZ`; queries filter `WHERE deleted_at IS NULL`
  - PR titles use Conventional Commits (`feat:`, `fix:`, etc.) — full rules in
    `.claude/rules/conventions.md`
-->

## Where things live

<!--
  Map common needs to file paths so the agent stops grep-roulette. Examples:

  - HTTP handlers: `internal/handlers/`
  - Business logic: `internal/services/`
  - DB access: `internal/repos/` (one repo per aggregate)
  - Generated SQL: `internal/db/queries/` (regenerate with `make sqlc`)
  - Migrations: `migrations/` (timestamped)
  - React components: `web/src/components/`
  - Generated API client: `web/src/api/` (regenerate with `make api-client`)
-->

## Things that broke before

<!--
  Real failure modes you've hit. Helps the agent skip known landmines. Examples:

  - **N+1 in `GetEmployeesWithHours`:** fixed in PR #311. If you see a similar
    pattern (loop over employees calling `GetHours(employeeID)`), batch with
    `ANY($1::uuid[])` instead.
  - **Stripe webhook retries:** the handler must be idempotent — check the event
    ID before processing. See `internal/handlers/stripe.go`.
  - **Long migrations:** anything that touches >1M rows runs as a separate job,
    not the standard migration step.
-->

## Tools & commands

<!--
  Frequently-used commands that aren't in the README. Examples:

  - Run backend with hot reload: `make dev`
  - Run tests for one package: `go test ./internal/services/payments -v -count=1`
  - Regenerate SQL: `make sqlc`
  - Regenerate API client (web): `make api-client`
  - Run mobile in dev: `cd apps/mobile && npx expo start`
  - Reset local DB: `make db-reset` (destructive — local only)
-->

## Don't change without asking

<!--
  Sensitive areas where the agent should propose, not act. Examples:

  - Authentication code (`internal/auth/`) — even small changes need human review
  - Payment processing (`internal/services/payments/`) — same
  - RLS policies on database tables — design decision, not code change
  - The deploy pipeline (`.github/workflows/deploy.yml`) — coordinate first
-->
