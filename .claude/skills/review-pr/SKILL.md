---
name: review-pr
description: |
  Review an open pull request against this repo's conventions. Pulls the diff via
  `gh pr diff`, scans for common issues (missing tests, secrets, hard-coded
  config, missing error handling, conventions violations), and posts a structured
  review comment via `gh pr comment`. Use when the user says "review PR #N",
  "look at this PR", or pastes a PR URL and asks for an opinion.
argument-hint: "<pr-number-or-url>"
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# Review PR

You are reviewing a pull request. The user has pointed you at a specific PR; your
job is to read it, judge it against the conventions in `.claude/rules/`, and post
a useful review comment.

This skill is intentionally simpler than `ship-pr`. The PR review job is mostly
judgement, which means most of the work is reading and thinking, not running
scripts. The script in this skill posts the comment; you draft what it says.

## Step 0 — Resolve the PR number

```bash
# $ARGUMENTS may be a number (123) or a URL (https://github.com/org/repo/pull/123)
PR_INPUT="$ARGUMENTS"

if [[ "$PR_INPUT" =~ ^[0-9]+$ ]]; then
  PR="$PR_INPUT"
elif [[ "$PR_INPUT" =~ /pull/([0-9]+) ]]; then
  PR="${BASH_REMATCH[1]}"
else
  echo "Could not parse PR number from: $PR_INPUT" >&2
  exit 1
fi

# Confirm we're in the right repo
gh repo view --json nameWithOwner -q .nameWithOwner
```

If the PR isn't in the current repo, stop. Cross-repo review needs `--repo` and
the user should be explicit.

## Step 1 — Gather PR metadata

```bash
# Title, body, branch, base, author, state, CI
gh pr view "$PR" --json title,body,headRefName,baseRefName,author,state,statusCheckRollup,reviewDecision,additions,deletions,changedFiles,createdAt
```

Read it. Note:

- **Size** — > 500 lines changed is hard to review well. Flag it
- **CI status** — if checks are failing, that's the first thing to mention
- **Existing reviews** — has someone already reviewed? Don't repeat their points
- **Description quality** — is the *why* in the body, or just the *what*?

## Step 2 — Read the diff

```bash
gh pr diff "$PR"
```

For very large PRs, narrow:

```bash
gh pr diff "$PR" --name-only          # Just the file list
gh pr diff "$PR" -- path/to/file      # Single file
```

Read the whole diff before forming an opinion. Don't just spot-check.

## Step 3 — Run the review checklist

Walk through each category. Note specific files and line numbers for each finding
so the author can act without hunting.

### Conventions

- Branch name follows `<type>/<short-slug>` (see `.claude/rules/conventions.md`)
- Commit messages follow Conventional Commits format
- PR title matches the conventions
- PR body has What / Why / How / Test plan

### Tests

- New code has tests
- New behaviour has a test for the behaviour
- Bug fixes have a test that would have caught the bug
- Test names describe behaviour (`Test_returns_403_when_user_is_not_owner`) not
  function names (`TestUpdate`)
- No `skip`, `xtest`, `it.only`, `fdescribe`, or equivalent slipped in

### Secrets & config

- No hardcoded API keys, tokens, passwords, JWTs
- No `.env` or credentials files added
- New config values have a corresponding entry in `.env.example`
- No production hostnames, IPs, or internal URLs hardcoded

### Error handling

- Errors propagate (not swallowed with `_ = err` or empty catch blocks)
- Errors are wrapped with context (`fmt.Errorf("...: %w", err)`, `throw new Error("...", { cause })`)
- No `panic` / `process.exit` in non-init code paths

### Database (if applicable)

- Schema changes go through migrations
- Queries use parameterised statements (no string concatenation into SQL)
- Indexes added for new query patterns
- Multi-statement writes wrapped in a transaction where atomicity matters

### Security (if applicable)

- Authorization checks on mutation endpoints (caller can do this thing for that
  resource)
- Input validation at the boundary
- Output encoding for anything user-controlled rendered into HTML/SQL/shell
- No new dependencies with known CVEs

### Scope

- Changes match the PR title / linked issue
- No drive-by refactors mixed in
- No formatter churn dominating the diff (a separate PR if needed)

### Performance (if applicable)

- No N+1 queries (loops calling a repo / fetch per item)
- Pagination on list endpoints
- No synchronous external calls in hot paths

## Step 4 — Categorise findings

For each finding, assign a severity:

- **CRITICAL** — security flaw, data loss risk, auth bypass, leaked secret. Block
  the merge
- **HIGH** — broken functionality, missing tests for critical paths, breaks API
  contract. Should be fixed before merge
- **MEDIUM** — design smell that will hurt later, performance issue, incomplete
  vs spec. Fix before merge if cheap; flag and merge if not
- **LOW** — style, naming, minor refactor opportunity. Note it; author decides
- **NIT** — typo, comment polish. Author can ignore

## Step 5 — Draft the review comment

Use this structure:

```markdown
## Review

**Verdict:** APPROVE / REQUEST CHANGES / COMMENT

**TL;DR:** <1 sentence summary>

### Critical
<list — file:line — issue — suggested fix. Or "None.">

### High
<same shape>

### Medium
<same shape>

### Low / Nits
<same shape, but you can group these>

### What's good
<2–4 bullets noting things done well. Calibrates the rest of the review.>

### Open questions
<things you want the author to clarify, not necessarily change>
```

If you have zero critical/high findings, the verdict is `APPROVE`. If you have
any, it's `REQUEST CHANGES`. `COMMENT` is for cases where you have observations
but no required fixes (e.g. you read a docs PR and have a few suggestions).

**Do not** post a review with no findings and no praise — it adds noise. If
there's truly nothing to say, just `gh pr review --approve` with no comment.

## Step 6 — Post the comment

```bash
.claude/skills/review-pr/scripts/post-comment.sh "$PR" "$(cat <<'EOF'
<your drafted review here>
EOF
)"
```

The script handles the `gh` invocation. You handle the content.

## What this skill will not do

- It will not approve, request changes, or merge — it posts a comment. The
  user makes the merge call. (You can extend this skill to do `gh pr review
  --approve` or `--request-changes` if your team's culture allows; default is
  comment-only because reviewing on a delegated agent's authority is a strong
  claim.)
- It will not push fixes to the author's branch. If you can fix something
  trivially, mention the fix in the review and let the author do it
- It will not pull external context (linked tickets, RFCs) unless the PR body
  links to them and the user explicitly asks for that depth

## Calibration

Good reviews are short and specific. Three high-quality findings beat fifteen
nits. If your review is longer than the PR's diff, you're doing it wrong.
