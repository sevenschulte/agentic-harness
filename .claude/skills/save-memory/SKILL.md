---
name: save-memory
description: |
  Persist newly-learned facts from the current session into the memory pyramid.
  Scans the conversation for durable information, finds the right file, deduplicates,
  and writes back. Use when the user says "remember this", "save it", "for next time",
  or when a non-obvious fact surfaced that a future session would ask about again.
argument-hint: "[topic or 'all']"
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Save Memory

You are about to persist something learned in this session so it survives into future
sessions. This is the deliberate-write step that keeps `memory/` current. Without
it, the files stagnate and the agent starts every session cold.

Memory files do **not** self-update. That's the whole point of this skill.

## When to save

Save when one of these is true:

- The user explicitly says "remember X" / "save this" / "note for next time"
- A durable fact about the codebase, team, or user surfaced this session, something
  a fresh session would have to re-discover
- A preference or convention was decided (commit format, branch policy, test
  approach, naming convention) that isn't yet written down anywhere
- A project status changed (new project started, milestone hit, blocker resolved)

Do **not** save:

- Ephemeral state (current task progress, scratch directories, "where we are right
  now"). Those belong in `ACTIVE.md` via the `wrap-up` skill, not here.
- The agent's own process narrative ("I ran 5 commands then..."). Save outcomes,
  not process.
- Secrets. Ever. Even if the user asks. Redirect to `.env`.

## Step 1 — Read what exists

If the project keeps a knowledge index (`.claude/rules/knowledge-index.md` or
similar), read it. It maps topics to files.

Otherwise, read `memory/MEMORY.md` and `glob memory/**/*.md` to see what's already
there.

## Step 2 — Pick the right file

| If the fact is about... | Write it to... |
|---|---|
| Top-level identity, always-true facts about the user/product | `memory/MEMORY.md` |
| A preference or working-style rule | `memory/preferences/<topic>.md` |
| A specific project (status, decisions, architecture) | `memory/projects/<name>/context.md` |
| A research finding worth keeping | `memory/research/<topic>.md` |
| A codebase convention for a specific language/framework | `memory/coding-standards/<language>.md` |

Create new files only when the topic genuinely doesn't fit anywhere existing.
One authoritative location per fact; pointers from elsewhere, never copies.

## Step 3 — Deduplicate before writing

Read the target file. For each fact you're about to save:

- Already present and still correct → skip
- Present but outdated → update in place
- New → append a short well-structured entry

No iteration history. ("On date X we decided Y" is noise. Just state Y.) No
commentary. Save the essence, not the journey.

## Step 4 — Write

Entries should be scannable bullets or short paragraphs. Group related items.
When creating a new file, add a `## Tags` section at the bottom with
comma-separated keywords for later `grep` discoverability.

## Step 5 — Report

```
## Memory updated

**Files changed:**
- <path>: <what was added or updated>

**Skipped (already present):**
- <brief list>

Next: run the `wrap-up` skill if ending the session.
```

## What this skill will not do

- Will not save secrets, credentials, or anything matching a secret pattern
- Will not silently edit `AGENTS.md` / `CLAUDE.md` — those change system behaviour.
  Propose, don't apply.
- Will not duplicate existing entries. Read before writing.

---

Argument provided: `$ARGUMENTS`

If empty or `all`, scan the whole conversation. Otherwise, focus only on facts
matching the provided topic.

Now execute:
1. Read the knowledge index (or `memory/MEMORY.md` if none)
2. Identify durable facts from this session
3. Pick the right file for each
4. Deduplicate
5. Write
6. Report
