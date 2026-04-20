# Active Work

> **This file tracks current work-in-flight.** Read at session start so the agent
> knows where it left off. Update at the end of every meaningful session.
>
> Keep it short. The last 1–3 things in flight, plus a 2-line "where we left off"
> note. Older sessions get archived to `memory/session-history.md` (create on
> demand) or just deleted.

<!--
  Replace this template with real entries. Suggested shape below.
-->

## Currently in flight

<!--
  What the team is working on right now. One bullet per active workstream.
  Examples:

  - **Feature: user export to CSV** (branch: `feat/user-export`, PR: #412)
    Backend done, frontend wiring in progress. Blocked on design review of
    the download-progress UI.

  - **Bug: payment webhook retries** (issue: #418)
    Reproduced locally. Fix is to dedupe on event ID before processing.
    Working in `fix/payment-webhook-idempotency`.
-->

## Where we left off

<!--
  Short paragraph for the agent's first-session orientation. Examples:

  Last session (YYYY-MM-DD): finished the export endpoint and added integration
  tests. Frontend now fetches from `/api/users/export` and shows a spinner —
  but the spinner doesn't update because the endpoint is synchronous. Next
  step: switch to async with a job ID + polling.
-->

## Recently shipped (last 7 days)

<!--
  Brief log of what closed. Helps with weekly reviews and catches regressions
  ("we shipped X on Tuesday; the failure mode you're seeing now might be that").
  Examples:

  - 2026-04-15: PR #410 merged — bulk delete for archived users
  - 2026-04-14: PR #408 merged — Stripe webhook signature verification
  - 2026-04-12: Hotfix — i18n key collision in German translations
-->

## Up next (committed, not started)

<!--
  Things that ARE going to happen soon, ordered. Helps the agent prioritise
  when given an open-ended "what should I do?". Examples:

  1. Wire the export endpoint into the admin UI (#412)
  2. Add audit log entries for the export action (#413)
  3. Document the export feature in the user guide (#414)
-->

## Open questions

<!--
  Things waiting on a decision from outside the team. Examples:

  - Pricing for the export feature: free, or premium-only? (waiting on
    product decision)
  - Retention period for exported files: 24h, 7d, 30d? (waiting on legal)
-->
