# AGENTS.md — How This System Works

> **Edit me.** Every `<placeholder>` below is a slot for your team's reality. Replace them
> all before you ship. The structure is what's portable; the contents are yours.

## Identity

You are working inside `<repo-name>`, the codebase for `<product or domain>`.

The team is `<team name or composition>`. The primary maintainer is `<name or handle>`.
Communication is direct, terse, and code-first. Explain reasoning in 2–3 sentences;
expand only when asked.

Follow the conventions in `.claude/rules/` at all times. Those rules win over your
training defaults when they conflict.

## Stack

- **Language(s):** `<e.g. Go 1.22, TypeScript 5.4, Python 3.12>`
- **Backend:** `<framework or "n/a">`
- **Frontend:** `<framework or "n/a">`
- **Database:** `<engine + version, or "n/a">`
- **Test runners:** `<go test, vitest, pytest, etc.>`
- **CI:** `<GitHub Actions, GitLab CI, etc.>`
- **Deployment target:** `<where this runs in production>`

## Architecture (one paragraph)

`<2–3 sentences describing the shape of the system: monorepo vs polyrepo, what the
main directories are, what talks to what, what's deployed where. Keep it short — this
is orientation, not documentation.>`

## Repo layout

```
<repo-name>/
├── AGENTS.md            # This file — identity & orientation (cross-tool standard)
├── CLAUDE.md            # Mirror of AGENTS.md (kept in sync) for Claude Code
├── README.md            # Human-facing intro
├── .claude/             # Harness layer (Claude Code paths — see README "Adapting to other runtimes")
│   ├── rules/           # Must-never / must-always (auto-loaded by Claude Code)
│   ├── skills/          # Callable workflows (SKILL.md — open standard, see agentskills.io)
│   ├── hooks/           # Lifecycle scripts referenced by .claude/settings.json
│   └── settings.json    # Claude Code runtime config (wires hooks to events)
├── memory/              # Persistent knowledge between sessions
│   ├── MEMORY.md        # Curated facts (always loaded)
│   ├── ACTIVE.md        # Current work status (always loaded)
│   ├── projects/        # Per-project context (read on demand)
│   └── coding-standards/ # Per-language standards (lazy-load via README.md index)
├── cron/                # Scheduled agents (no human in the loop)
└── <your source dirs>   # Replace with the real top-level directories
```

**Path note:** the directory names above are Claude Code's. The same content
maps to other runtimes via different paths — Cursor uses `.cursor/rules/` and
`.agents/skills/` (plural), Codex CLI uses `.codex/hooks.json` and
`.agents/skills/`, Windsurf uses `.windsurf/rules/` and `.windsurf/skills/`.
See the README "Adapting to other runtimes" table for the full map. Skills are
the most portable layer — `.agents/skills/` is auto-read by Cursor, Codex CLI,
Windsurf, and others. Rules and hooks are runtime-specific.

## How to operate

1. **Read existing code first.** Don't generate code that competes with what's already
   here. Find the conventions in nearby files and follow them.
2. **Check coding standards before writing code.** Open
   `memory/coding-standards/README.md` and load only the file matching what
   you're about to write (Go → `go.md`, TypeScript / React → `typescript-react.md`,
   etc.). Don't load all of them — pull the one you need.
3. **Tests before fixes.** If a bug isn't covered by a failing test, write the test
   first. No fix without a test that proves the fix.
4. **Smallest change that works.** No drive-by refactors. If you spot rot, file an
   issue or note it in the PR description — don't bundle.
5. **Ask when stuck.** If the spec is ambiguous, pause and ask. Don't guess at intent.
6. **Stay in scope.** If the task asks for X and you find Y, ship X and report Y
   separately.

## Memory

Three files are loaded automatically on every session (via `.claude/hooks/session-start.sh`):

- `AGENTS.md` (this file) — identity
- `memory/MEMORY.md` — curated facts about the codebase, team, conventions
- `memory/ACTIVE.md` — what's in flight right now, where we left off

When you learn something durable, write it to one of those files. When you finish a
session with meaningful work, update `ACTIVE.md` so the next session knows where
things stand.

**Memory files do not self-update.** Two skills handle the writes:

- `save-memory` — run after learning something durable (a decision, a preference,
  a project fact). It deduplicates and writes to the right file.
- `wrap-up` — run at session end. It updates `ACTIVE.md` so the next session
  inherits current state.

Alternatively, wire a `SessionEnd` hook (Claude Code / Codex CLI) to invoke
`wrap-up` automatically. The shipped `.claude/settings.json` leaves that off by
default — it's a judgement call whether auto-wrap-up is right for your workflow.

Project-specific context (one directory per project) lives under `memory/projects/`.
Read on demand, not on every session start.

Coding standards (per-language conventions: how to lay out a Go service, how to
structure a React component, how to write SQL) live under `memory/coding-standards/`
with a `README.md` index. Read on demand — pull only the file matching the area
you're about to write code in. The `rule-vs-standard` split is documented in
`.claude/rules/conventions.md`.

## Skills

Callable workflows live under `.claude/skills/`. Each skill has a `SKILL.md` describing
what it does and when to use it, plus `scripts/` with the deterministic parts.

Four are shipped as worked examples:

- `ship-pr` — runs tests, formats, commits, pushes, opens a PR
- `review-pr` — pulls a PR diff, reviews against conventions, posts a comment
- `save-memory` — persists durable facts to the memory pyramid with deduplication
- `wrap-up` — updates `ACTIVE.md` with session state before closing

Add your own as patterns emerge. A skill is worth creating when you find yourself
typing the same sequence of steps three times.

## Rules

Read every file in `.claude/rules/` once at session start. The rules that fire most
often:

- **Guardrails** (`.claude/rules/guardrails.md`) — destructive-action blocks, secret
  hygiene, single-source-of-truth discipline
- **Conventions** (`.claude/rules/conventions.md`) — branch names, commit format, PR
  format
- **Voice boundaries** (`.claude/rules/voice-boundaries.md`) — internal vs external
  communication

The deterministic guards are also enforced by `.claude/hooks/pre-bash.sh`, which can
*block* a tool call before it runs. The LLM cannot talk around the hook.

## Hooks

- `session-start.sh` — fires when a session opens. Injects today's date, current
  branch, recent commits, and any uncommitted work into context.
- `pre-bash.sh` — fires before every Bash tool call. Pattern-matches against
  dangerous commands and blocks them.

The scripts live under `.claude/hooks/`. **Hooks are not auto-discovered by
filename** — every runtime requires explicit registration in its config. The
shipped `.claude/settings.json` wires the two scripts above to Claude Code's
`SessionStart` and `PreToolUse` events. For other runtimes:

- **Codex CLI** — register the same scripts in `.codex/hooks.json` (5 events:
  `SessionStart`, `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`).
  Requires `[features] codex_hooks = true` in Codex config.
- **Cursor / Windsurf / Cline / Aider** — no hooks system. The script logic
  needs to live elsewhere (a git pre-commit hook, a wrapper alias, or as a
  step in a skill the user invokes manually).

## Scheduled agents

`cron/` contains background jobs that run agents without a human present. Each has
a `README.md` explaining what it does, plus a `run.sh` that's the entry point.
Wire them up to `cron`, `launchd`, or your CI scheduler — examples in each
subfolder's README.

The shipped examples:

- `pr-triage` — daily report of open PRs by age and category
- `dependency-watch` — weekly scan for vulnerable or outdated dependencies
- `flaky-test-reporter` — surfaces flaky tests from CI logs

## When something is missing

Don't invent capabilities. If a tool, skill, or piece of context isn't here:

1. Note what you needed
2. Either add it (if the change is small and obviously correct), or
3. Stop and ask

The harness is supposed to grow. Discovering a gap is good. Quietly working around
it is bad.
