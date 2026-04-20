# Conventions

How we write code, name branches, format commits, and structure PRs in this repo.
Follow these unless the user explicitly says otherwise. If you find code that
violates a convention, fix the code in scope; don't fix the convention without asking.

## Rules vs. standards — where things live

Not every "how we write code" item belongs in the same layer.

- **Rules** (this directory, `.claude/rules/`) are inviolable: "no `any` in
  TypeScript", "all SQL parameterised", "no `console.log` in production code",
  "no plaintext secrets", "no `--no-verify`". Violating a rule causes an
  *incident* — a broken build, a security hole, a production bug. Rules are
  loaded on every session and enforced by hooks where possible.
- **Standards** (`memory/coding-standards/`) are conventions: naming, file
  layout, idioms, the shape of a test, which formatter to run. Violating a
  standard causes *inconsistency* — the codebase feels stitched together by
  three different people. Standards are loaded on demand, only when the agent
  is actually writing code in that area.

Put each in the right layer. Rules in the wrong place get ignored (too much
noise); standards in the wrong place burn context (loaded when irrelevant).
If you're unsure: does violating it cause an incident, or does it just cause
ugliness? Incidents → rules. Ugliness → standards.

## Branch naming

```
<type>/<short-slug>
```

Examples:

```
feat/user-export
fix/login-race-condition
chore/bump-go-1.22
docs/architecture-diagram
refactor/extract-payments-service
```

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`.

Slugs are kebab-case, max ~40 chars. No usernames, no ticket numbers in the
branch name (put those in the PR description).

## Branching from / merging to

- Default base branch: `<dev or main — set yours here>`
- Feature branches always start from the latest `<base>`
- PRs always target `<base>` — never `main` directly if you have a `dev` branch
- Never push directly to `<base>` — open a PR

## Commit messages

Conventional Commits, one line subject + optional body:

```
<type>(<scope>): <imperative summary, lowercase, no trailing period>

<optional body — what changed and *why*, wrapped at ~72 cols>

<optional footer — breaking changes, issue refs>
```

Examples:

```
feat(auth): add password reset flow

Adds the POST /auth/reset endpoint plus email template. Token TTL is 1h,
single-use, stored in the password_reset_tokens table.

Closes #142
```

```
fix(payments): handle stripe webhook retry idempotency

The webhook handler was double-charging when Stripe retried after a 5xx.
Added an idempotency check against the event ID before processing.
```

Types: same as branch types (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`).

Body is optional for trivial commits. Required when the *why* isn't obvious from
the *what*.

## PR format

Title: same shape as the commit subject (`<type>(<scope>): <summary>`).

Body template:

```markdown
## What

<1–3 sentences describing what changed. The diff shows what; this section says
why anyone reading later cares.>

## Why

<The problem this PR solves. Link to the issue if there is one.>

## How

<The approach. Note any non-obvious design choices. If you considered an
alternative and rejected it, say why.>

## Test plan

- [ ] <how reviewer can verify the change>
- [ ] <edge case covered>
- [ ] <regression check>

## Screenshots / output (if relevant)

<paste here>

## Notes for reviewer

<things you want a second opinion on, deferred work, follow-up tickets>
```

Closes-keyword (`Closes #N`) goes at the bottom of the body, not in the title.

## Code style

Follow the language's standard formatter. No exceptions.

| Language | Formatter | Linter |
|---|---|---|
| Go | `gofmt`, `goimports` | `golangci-lint` |
| TypeScript / JavaScript | `prettier` | `eslint` |
| Python | `ruff format` | `ruff check` |
| Rust | `rustfmt` | `clippy` |

Set up the formatter in your editor's save-on-format. CI should fail on unformatted code.

## Tests

- New code ships with tests. New behaviour ships with a test for the behaviour
- Bug fixes ship with a test that *fails before the fix* and passes after
- Test names describe the behaviour, not the function (`Test_returns_403_when_user_is_not_owner`,
  not `TestUpdate`)
- One assertion per test where reasonable. Multiple assertions are fine if they
  describe the same behaviour
- Mocks at boundaries (HTTP, DB, external APIs). Don't mock your own code

## Comments

Code comments explain *why*, not *what*. The *what* is the code; if the *what*
needs a comment, the code is unclear and should be rewritten.

Document exported functions, public APIs, and any non-obvious design decision.
Don't document `func GetUser(id int) (*User, error)` — the signature already
documents it.

## Errors

- Errors propagate up; they don't get swallowed
- Wrap with context at the layer that has it: `fmt.Errorf("fetching user %d: %w", id, err)`
- Never `panic` in production paths. Reserve panics for truly unrecoverable
  initialisation problems
- Log at the boundary (HTTP handler, CLI entry point), not at every layer in between

## Database

- All schema changes go through migrations. No manual `ALTER TABLE` in production
- Migrations are forward-only unless you have a working backwards plan
- Index columns you query on. Don't index columns you don't
- Long-running migrations (large tables) need a separate plan — they don't run
  in the standard migration job

## Dependencies

- New dependencies need justification in the PR body. "Why this lib instead of the
  one we already have?"
- Pin major versions. Let minor/patch range float (with a lockfile)
- Audit new dependencies: license, last commit date, maintainer count, known CVEs
- Native deps (anything that compiles on install) require extra scrutiny — they're
  the most common supply-chain attack vector

## Configuration

- Environment-specific values come from `.env` (gitignored) or the deploy environment
- `.env.example` ships with the repo and lists every required variable with a
  placeholder value
- No secrets in code. Ever. Not "just for testing", not "I'll remove it before commit"
