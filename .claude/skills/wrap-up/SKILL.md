---
name: wrap-up
description: |
  Update memory/ACTIVE.md with the state of the current session — what was worked
  on, what's done, what's next, what's blocked — so the next session can pick up
  without re-learning context. Run at session end or when switching to an unrelated
  task.
allowed-tools: Read, Write, Edit, Glob
---

# Wrap Up

You are closing a work session. Your job is to update `memory/ACTIVE.md` so the
*next* session has everything it needs to continue: where we were, what got done,
what's still in flight, what's next.

Without this step, `ACTIVE.md` stagnates and the next session starts cold even
though the codebase hasn't.

## When to wrap up

- User says "wrap up" / "let's stop" / "end session" / "that's it for today"
- About to stop responding after meaningful work (a deliverable shipped, a decision
  made, an investigation concluded, a PR opened)
- Switching to a completely different topic or project

Skip for purely conversational sessions with no deliverables.

## Step 1 — Read the current ACTIVE.md

You are updating, not rewriting.

```
memory/ACTIVE.md
```

Expected shape (create if missing):

```markdown
# Active Work

## Current Focus
<what we're working on right now>

## In Progress
- [ ] <task with a checkbox>
- [x] <completed task>

## Next Up
- <upcoming task>

## Parking Lot
- <idea to revisit>

## Completed
- **<title>** (<date>) — <one line>. Details: <pointer to memory/projects/...>

## Session Notes
*<date>:* <one-paragraph session summary>
```

## Step 2 — Analyse this session

Identify:

1. **Focus** — what was the main thing we worked on?
2. **Done** — what got finished? (mark `[x]`)
3. **In flight** — what's started but not finished? (`[ ]`)
4. **Next** — what's the immediate next step for whoever continues?
5. **Blockers** — what's waiting on something external?
6. **Discovered** — new tasks that came up but aren't urgent? (parking lot)

## Step 3 — Update ACTIVE.md

- **Current Focus**: rewrite to reflect today's work, including status if relevant
  (*blocked*, *in review*, *waiting on X*)
- **In Progress**: mark completed items `[x]`, add any new in-flight items
- **Next Up**: move items in/out as priorities shift
- **Parking Lot**: append anything worth remembering later
- **Completed**: one-line index entry pointing at the fuller write-up elsewhere.
  Don't inline long descriptions; details live in `memory/projects/<...>` or
  `memory/research/<...>`
- **Session Notes**: prepend one short paragraph (date in YYYY-MM-DD, one
  paragraph summarising what happened and why)

## Step 4 — Auto-archive old session notes

After adding the new entry, count entries under "Session Notes". If more than 3,
move the oldest ones into `memory/session-history.md` (create if missing). Stops
`ACTIVE.md` growing unbounded while preserving history.

## Step 5 — Update project context (if applicable)

If this session produced decisions about a specific project, update that project's
`memory/projects/<name>/context.md`. Don't move the decision from `ACTIVE.md` to
the project file; link between them.

## Step 6 — Report

```
## Session wrapped

**ACTIVE.md updated:**
- <summary of changes>

**Project files updated:** <list or "none">

**Archived session notes:** <count, or "none">

Next session's first file to read: memory/ACTIVE.md
```

## What this skill will not do

- Will not save durable facts or preferences. That's the `save-memory` skill.
  Two different jobs: `wrap-up` captures state, `save-memory` captures knowledge.
- Will not delete or overwrite existing tasks without marking them first. If a
  task is no longer relevant, move it to "Completed" with a `(skipped — reason)`
  note, don't disappear it.
- Will not inline long descriptions in `ACTIVE.md`. Keep it scannable; pointers
  to fuller detail elsewhere.

---

Now execute:
1. Read current `memory/ACTIVE.md`
2. Analyse this session
3. Update each section
4. Auto-archive session notes if more than 3
5. Update project context files if decisions were made
6. Report
