---
name: ship-pr
description: |
  Ship the current branch as a pull request. Runs tests, formats code, commits
  any uncommitted work, pushes the branch, and opens a PR against the base branch
  with a generated body following the team's PR template. Use when the user says
  "ship it", "open a PR", "send this for review", or finishes a feature and wants
  it reviewed.
argument-hint: "[base-branch]"
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# Ship PR

You are about to ship the current branch as a pull request. The user has done the
work; you are doing the handoff.

This skill is the worked example from the Harness Engineering article. It demonstrates
the deterministic-where-possible / LLM-where-needed split: the script does the
mechanical steps; you do the judgement steps (writing the PR body, deciding whether
to ship at all).

## Step 0 — Sanity checks

Before doing anything, verify:

```bash
# 1. We're in a git repo
git rev-parse --is-inside-work-tree

# 2. The current branch is not the base branch
CURRENT=$(git branch --show-current)
BASE="${1:-dev}"  # Default base from $ARGUMENTS, fallback to "dev"
# If your default base is "main", change the fallback above.
[ "$CURRENT" != "$BASE" ] || { echo "Refusing to ship: current branch is the base branch."; exit 1; }

# 3. The branch has at least one commit ahead of base
AHEAD=$(git rev-list --count "$BASE".."$CURRENT")
[ "$AHEAD" -gt 0 ] || { echo "Refusing to ship: branch has 0 commits ahead of $BASE."; exit 1; }

# 4. gh CLI is installed and authenticated
gh auth status
```

If any check fails, stop and report. Do not try to fix the underlying issue
without explicit confirmation.

## Step 1 — Run the deterministic part

```bash
.claude/skills/ship-pr/scripts/run-tests.sh
```

That script formats code, runs the test suite, and exits non-zero on any failure.
**If it exits non-zero, stop.** Read the output, report the failure, and ask the
user what to do. Do not retry, do not disable tests, do not push anyway.

This is the line you will not cross: never use `--no-verify`, never skip a failing
test, never push known-broken code.

## Step 2 — Stage and commit any uncommitted work

```bash
# Show the user what's about to be committed
git status --short
git diff --stat
```

If there are uncommitted changes:

1. Read the diff (don't just stage everything blindly)
2. Decide whether the changes belong in this PR or not. If they don't, ask
3. If they do: stage explicit files (`git add <file1> <file2>`), not `git add -A`
4. Write a commit message following `.claude/rules/conventions.md` (Conventional
   Commits format)
5. Commit

If everything is already committed, skip to Step 3.

```bash
git add <specific files>
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject>

<body explaining why, wrapped at ~72 cols>
EOF
)"
```

## Step 3 — Push the branch

```bash
git push -u origin "$CURRENT"
```

If the push is rejected (someone else pushed to your branch — rare but possible
on shared feature branches):

1. `git fetch origin "$CURRENT"`
2. `git rebase origin/$CURRENT`
3. Resolve conflicts, then `git push --force-with-lease origin "$CURRENT"`
4. Never plain `--force` — `--force-with-lease` checks you're not clobbering
   work you haven't seen

## Step 4 — Generate the PR body

Read the commits on this branch:

```bash
git log "$BASE".."$CURRENT" --oneline
git log "$BASE".."$CURRENT" --no-merges --format="%B%n---%n"
```

And the diff stats:

```bash
git diff "$BASE".."$CURRENT" --stat
```

Then draft a PR body following the template in `.claude/rules/conventions.md`:

```markdown
## What

<1–3 sentences: the actual change, not a diff summary>

## Why

<the problem this solves; link to the issue if there is one>

## How

<the approach; flag non-obvious decisions>

## Test plan

- [ ] <how the reviewer can verify>
- [ ] <edge case>
- [ ] <regression check>

## Notes for reviewer

<anything you want a second opinion on, deferred work>
```

Fill it from the commits and diff. **Do not invent intent.** If the commits
don't tell you the *why*, ask the user before writing the "Why" section.

## Step 5 — Open the PR

```bash
gh pr create \
  --base "$BASE" \
  --head "$CURRENT" \
  --title "<type>(<scope>): <subject>" \
  --body "$(cat <<'EOF'
<the body you drafted in step 4>
EOF
)"
```

The title should match the lead commit's subject. If multiple commits, use the
most-significant one's subject (or the user's own summary if they gave you one).

## Step 6 — Report back

Output to the user:

```
Shipped: <PR URL>
Title: <title>
Base: <base> ← <branch>
Commits: <count>
Changed: +<additions> / -<deletions> across <files> files

Tests: passed
Format: clean

Next: reviewer is <github handle if known, else "open">.
```

## What this skill will not do

- It will not merge the PR. Merging is a separate decision and a separate action.
- It will not request specific reviewers unless the user named them. Auto-tagging
  the wrong person is annoying.
- It will not skip any step. If the test script fails, the PR doesn't open.
- It will not commit `.env`, `*.key`, or anything matching a secret pattern. The
  pre-bash hook in `.claude/hooks/pre-bash.sh` will block it anyway.

## When to use a different skill

- You're reviewing someone else's PR → use `review-pr`
- You're not done yet, just want to push WIP → just `git push`, don't use this skill
- You want to merge an already-reviewed PR → that's a manual action; not in scope here
