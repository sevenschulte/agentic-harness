# Coding Standards

> **Lazy-load index.** This directory holds the per-language / per-area conventions
> the agent should follow when actually writing code. Don't load all of them on
> session start — pull only the file matching the area you're about to touch.

The split with `.claude/rules/` is intentional. Rules are inviolable safety / correctness
constraints that fire across every session (e.g. "no `--no-verify`", "no plaintext
secrets", "all SQL parameterised"). Standards are the much larger surface area of
"how we like code to look in this codebase" — naming, layout, idioms, patterns —
which only matters when the agent is writing in that area.

Loading every standard upfront would burn context for things the current task
doesn't need. Loading them on demand keeps context clean.

## Index

| If writing... | Read... |
|---|---|
| Go | `go.md` |
| TypeScript / React | `typescript-react.md` |
| SQL / database queries | `sql.md` |

Add a row whenever you add a new standards file. Keep the table the source of
truth — if the agent can't find a standards file from this index, it doesn't
exist as far as the system is concerned.

## How to add a new standards file

1. Pick a name that matches the *area* the standard governs, not a tool. Good:
   `go.md`, `typescript-react.md`, `sql.md`. Bad: `prettier.md`, `golangci.md`
   (those are tools, not areas)
2. Keep it short. 30–80 lines is plenty. If a standard needs an essay, it
   probably belongs in a longer doc that the standards file *links to*
3. Lead with the *what* and the *why* in one sentence each. The agent will
   skim. Don't bury the rule in a wall of prose
4. Add a row to the index above

## Style of these files

- Concrete examples beat abstract principles. `Use X, not Y` with two snippets
  is worth more than a paragraph
- One file per area. Don't try to make a megadoc
- Update when you catch the agent doing something the standard didn't cover

## Relationship to `.claude/rules/`

If you find yourself writing the same standard in three different files, it's
probably a rule, not a standard. Promote it. Conversely, if a "rule" is really
just "we prefer this style", demote it to a standard so it stops shouting at
the agent in unrelated contexts.
