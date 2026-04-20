# agentic-harness

A reference harness for agentic coding. Six layers, six pieces of every harness, fork-friendly.

The runnable example is configured for **Claude Code** because it's the most fully-realised harness ecosystem today (rules, skills, hooks, settings — all first-class). For Cursor / Codex CLI / Aider / Cline / Windsurf, see the *Adapting to other runtimes* table below: the layer roles are universal, the file paths are not.

Built to accompany the article: **Harness Engineering: The Third Pillar of Agentic Coding** → [svenschulte.ch/blog/harness-engineering](https://svenschulte.ch/blog/harness-engineering)

## Why this exists

Most teams pick a model (Claude, GPT, Gemini), pick a runtime (Claude Code, Cursor, Codex CLI, Aider, Windsurf), and stop. They wonder why the agent forgets things, ignores conventions, asks the same question every session, and occasionally `rm -rf`s something it shouldn't.

The missing layer is the **harness** — the configuration around the model and runtime that makes the agent behave like a member of your team instead of a fresh contractor every session.

This repo is a working reference for that layer. Six directories, each demonstrating one concern. Nothing magical. Read it in 20 minutes, adapt it in an afternoon.

## The six layers

| # | Layer | Where | What it does |
|---|---|---|---|
| 1 | **Identity** | `AGENTS.md` | Who the agent is, where things live, how this codebase works |
| 2 | **Rules** | `.claude/rules/` | Must-never and must-always — the guardrails the LLM cannot talk around |
| 3 | **Skills** | `.claude/skills/` | Callable workflows (ship a PR, review a PR, save memory, wrap up a session) — deterministic where possible, LLM where needed |
| 4 | **Hooks** | `.claude/hooks/` | Lifecycle scripts that fire on session start, before tool calls, etc. |
| 5 | **Memory** | `memory/` | Persistent knowledge between sessions (curated facts, current work status, project context, lazy-loaded coding standards). Updated explicitly via the `save-memory` and `wrap-up` skills — files don't self-update |
| 6 | **Scheduled agents** | `cron/` | Background jobs that run agents without a human in the loop |

## How to use this

1. **Use this template** (green button on GitHub) or clone it
2. **Edit `AGENTS.md`** — replace every `<placeholder>` with your team, stack, and conventions
3. **Walk `.claude/rules/`** — keep what fits, delete what doesn't, add what's missing
4. **Edit `memory/coding-standards/`** — replace the example `go.md` / `typescript-react.md` / `sql.md` with your team's actual conventions, and update the index in `memory/coding-standards/README.md` so the agent can find them
5. **Add one skill of your own** — start with the workflow you do most by hand
6. **Hooks** — for Claude Code, the shipped `.claude/settings.json` already wires `session-start.sh` and `pre-bash.sh`. For other runtimes, see the *Adapting to other runtimes* table below.
7. **Schedule one cron agent** — start with `pr-triage` or your own equivalent

That's it. There's no install step, no framework, no runtime lock-in. The files are the configuration.

## Adapting to other runtimes

The shipped layout uses Claude Code's paths (`CLAUDE.md`, `.claude/rules/`, `.claude/skills/`, `.claude/hooks/`, `.claude/settings.json`). Two open standards make parts of the harness portable across runtimes; the rest needs per-runtime translation.

### What's portable

- **Identity** — `AGENTS.md` is the [open standard](https://agents.md/) (stewarded by the Linux Foundation's Agentic AI Foundation). This repo keeps `CLAUDE.md` and `AGENTS.md` byte-identical so both Claude Code and the AGENTS.md-native runtimes (Codex CLI, Cursor, Windsurf, Cline, Jules, Junie, etc.) read the same identity file. See the sync hook below.
- **Skills** — `SKILL.md` follows the [Agent Skills](https://agentskills.io) open standard. The cross-runtime convention is `.agents/skills/` (plural) — auto-loaded by Cursor, Codex CLI, Windsurf, OpenCode, Goose, Junie, Factory, and others. Claude Code reads `.claude/skills/` (this repo's location). The two formats are identical; only the directory differs.

### What's runtime-specific

- **Rules** — every runtime has its own format. Mirror or adapt the contents of `.claude/rules/` into your runtime's path.
- **Hooks** — no cross-runtime standard exists. Each runtime registers hooks in its own config file with its own event names.

### Per-runtime adapter table

| Runtime | Identity (auto) | Skills directory | Rules directory | Hooks |
|---|---|---|---|---|
| **Claude Code** | `CLAUDE.md` *(this repo: synced from `AGENTS.md`)* | `.claude/skills/` *(shipped)* | `.claude/rules/` *(shipped)* | `.claude/settings.json` references `.claude/hooks/*.sh` *(shipped)* |
| **Cursor** | `AGENTS.md` *(shipped)* | Mirror `.claude/skills/` → `.agents/skills/` *(plural)* | Convert `.claude/rules/*.md` → `.cursor/rules/*.mdc` (add YAML frontmatter with `description` and `globs`) | None — Cursor has no hooks system |
| **Codex CLI** | `AGENTS.md` *(shipped)* | Mirror `.claude/skills/` → `.agents/skills/` | Use the conventions text in `AGENTS.md`; Codex has no separate rules path | Mirror `.claude/hooks/*.sh` → `.codex/hooks.json` registrations (5 events). Requires `[features] codex_hooks = true`. |
| **Windsurf** | `AGENTS.md` *(shipped)* | Mirror to `.windsurf/skills/` (or `.agents/skills/` — Windsurf reads both) | Mirror to `.windsurf/rules/*.md` | None |
| **Cline** | `AGENTS.md` *(shipped)* | None — Cline has no skills system | Mirror to `.clinerules/*.md` (Cline also auto-detects `.cursorrules` and `.windsurfrules`) | None |
| **Aider** | Add `read: AGENTS.md` to `.aider.conf.yml` (Aider does NOT auto-load AGENTS.md) | None | Aider supports `CONVENTIONS.md` via `--read`; reuse the rules content there | None |

A minimal mirror script for Cursor + Codex users (run from repo root):

```bash
mkdir -p .agents
ln -sfn ../.claude/skills .agents/skills    # symlink — picks up edits to .claude/skills automatically
                                            # (on Windows, copy instead of symlinking)
```

Once published, a future helper script may automate the full mirror; for now the table above is enough for anyone who's chosen their runtime.

### Claude Code note

Claude Code reads `CLAUDE.md` (not `AGENTS.md`). This repo ships **both files with identical content** so Claude Code and AGENTS.md-native runtimes both work without symlinks (which break on Windows).

**If you edit one, copy to the other.** A one-liner check:

```bash
diff AGENTS.md CLAUDE.md && echo "in sync" || echo "OUT OF SYNC — copy one to the other"
```

If drift is a real concern, this repo ships a tiny pre-commit hook at
`.claude/hooks/pre-commit-sync-check.sh`. Install it once per clone:

```bash
# Symlink (preferred — picks up future updates to the hook automatically)
ln -s ../../.claude/hooks/pre-commit-sync-check.sh .git/hooks/pre-commit

# Or copy (use this on Windows / filesystems that don't like symlinks)
cp .claude/hooks/pre-commit-sync-check.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

The hook refuses any commit where `AGENTS.md` and `CLAUDE.md` differ, and tells
you which copy command to run to resolve the drift.

## What this is NOT

This is the **harness** — the configuration. It is **not** a workflow engine.

For autonomous "dark factory" workflows (plan → build → test → review → ship, zero human in the loop), see the companion repo `agentic-coding-template` (separate article, Q2 2026). That repo builds *on top of* a harness like this one. Keep them separate so the harness stays small and copyable.

Specifically, this repo deliberately does **not** include:

- Multi-step workflow scripts (plan, build, review)
- Worktree orchestration
- Spec-driven development pipelines
- CI integration beyond a basic example
- Issue-to-PR automation

If you're looking for those, you want the template repo, not this one.

## Fork policy

This is a reference, not a maintained product. Take it, make it your own.

- **Use this template** (green button above). Clones it into your account with no fork relationship. You own the copy, do whatever you want with it.
- **PRs:** restricted to collaborators. If you want to improve something for yourself, fork the template and ship the change in your own fork.
- **Issues:** disabled. The README is the documentation; if you need more, the [article](https://svenschulte.ch/blog/harness-engineering) goes deeper.

The patterns in this repo evolve as the author uses them daily. Occasional refreshes land when something changes meaningfully. Not abandoned, not under active development either.

## License

MIT. Fork it, ship it.
