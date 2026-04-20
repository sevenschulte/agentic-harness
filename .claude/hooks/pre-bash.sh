#!/usr/bin/env bash
# pre-bash.sh — runs before every Bash tool call the agent makes.
#
# Receives the proposed command on stdin (as JSON, depending on runtime).
# Exit 0 = allow the command. Exit 2 = block it (stderr is shown to the agent).
#
# This hook is the LAST line of defence. The agent CANNOT talk around it because
# it runs at the runtime layer, not in the LLM's reasoning loop. Use it for
# patterns where "the agent should never run X" is non-negotiable.
#
# ── How to read this file ────────────────────────────────────────────────────
#
# Each block below is a guard. Each guard has three header comments:
#
#   # WHAT:     the pattern this catches, in plain English
#   # WHY:      why catching it matters
#   # DISABLE:  comment out the `if … fi` block (or whole block) to remove this guard
#
# The patterns ship as opinionated defaults. They are deliberately on the wide
# side — the cost of a false positive is "the agent retries with a more explicit
# command", which is cheap. The cost of a false negative can be a destroyed
# branch, a leaked secret, or a deleted database. Lean toward keeping guards
# enabled; comment out only when a specific guard is actively annoying on your
# codebase.
#
# ── Wire-up ──────────────────────────────────────────────────────────────────
#
#   Claude Code: .claude/settings.json
#     {
#       "hooks": {
#         "PreToolUse": [
#           {
#             "matcher": "Bash",
#             "hooks": [{ "type": "command", "command": ".claude/hooks/pre-bash.sh" }]
#           }
#         ]
#       }
#     }
#
#   Other runtimes: see their docs.
#
# Input format (Claude Code):
#   { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }

set -uo pipefail

# --- Read input --------------------------------------------------------------

INPUT=""
if [ ! -t 0 ]; then
  INPUT=$(cat)
fi

# Extract the command. Try jq first; fall back to grep if jq is not installed.
COMMAND=""
if command -v jq >/dev/null 2>&1; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
fi
if [ -z "$COMMAND" ]; then
  # Best-effort fallback: pull the value of "command" out with grep
  COMMAND=$(echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/"command"[[:space:]]*:[[:space:]]*"(.*)"/\1/' || true)
fi

# Normalise: lowercase, collapse whitespace
NORMALISED=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ')

block() {
  local reason="$1"
  echo "BLOCKED by .claude/hooks/pre-bash.sh: $reason" >&2
  exit 2
}

# ─────────────────────────────────────────────────────────────────────────────
# Guard 1: Destructive `rm -rf` against dangerous targets
# ─────────────────────────────────────────────────────────────────────────────
#
# WHAT:    `rm -rf` (any flag order) targeting `/`, `~`, `.`, `..`, `*`, or
#          `$HOME`. Catches the classic "rm -rf /" and the only-slightly-less-
#          classic "rm -rf $UNSET_VAR/something" → "rm -rf /something" pattern.
# WHY:     These commands have destroyed laptops, clusters, and entire careers.
#          The agent has no business deleting the root filesystem.
# DISABLE: Comment out the entire `if echo "$NORMALISED" … fi` block below.
#          Don't loosen this — if you find yourself wanting to, name the
#          specific path you're trying to delete in the command instead of `*`.

if echo "$NORMALISED" | grep -qE '\brm\s+(-[a-z]*r[a-z]*f[a-z]*|-[a-z]*f[a-z]*r[a-z]*|--recursive\s+--force|--force\s+--recursive)'; then
  if echo "$NORMALISED" | grep -qE '(\s|^)(/|/\*|~|\$home|\.\.|\*|\.)(\s|$)'; then
    block "Destructive rm against a dangerous target ('/', '~', '.', '*', etc.)"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Guard 2: Force-push to a shared branch
# ─────────────────────────────────────────────────────────────────────────────
#
# WHAT:    `git push -f` or `git push --force` targeting any of `main`,
#          `master`, `dev`, `develop`, `release`. The safer cousin
#          `--force-with-lease` is allowed (it refuses to clobber commits the
#          local repo hasn't seen).
# WHY:     Force-pushing to a shared branch erases other people's work. This is
#          one of the highest-blast-radius mistakes git allows.
# DISABLE: Comment out the entire `if echo … fi` block. If your team uses
#          different branch names (e.g. `trunk`, `staging`), edit the regex
#          on the `grep -qE` line below to match your protected branches.

if echo "$NORMALISED" | grep -qE 'git\s+push\s+(-f\b|--force\b)'; then
  # Allow --force-with-lease (it's the safer cousin)
  if echo "$NORMALISED" | grep -q 'force-with-lease'; then
    : # allowed
  elif echo "$NORMALISED" | grep -qE '\b(main|master|dev|develop|release)\b'; then
    block "Force-push to a protected branch (use --force-with-lease to a feature branch only)"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Guard 3: `git reset --hard`
# ─────────────────────────────────────────────────────────────────────────────
#
# WHAT:    Any `git reset --hard` invocation, regardless of target.
# WHY:     `--hard` discards uncommitted changes silently. The agent cannot
#          tell the difference between "the user wants to throw away WIP" and
#          "there's important uncommitted work here". Block by default; the
#          user can run it directly if they really mean it.
# DISABLE: Comment out the `if … fi` block. Consider keeping it enabled and
#          training the user to run `git reset --hard` themselves when needed
#          — that single keystroke of friction has saved many hours of work.

if echo "$NORMALISED" | grep -qE 'git\s+reset\s+--hard'; then
  block "git reset --hard discards uncommitted work — confirm explicitly before running this"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Guard 4: `--no-verify` on commit or push
# ─────────────────────────────────────────────────────────────────────────────
#
# WHAT:    `git commit --no-verify` or `git push --no-verify` — flags that
#          skip pre-commit / pre-push hooks.
# WHY:     The hooks exist because real problems leaked past humans before. If
#          a hook is failing, the answer is to fix the underlying problem, not
#          to skip the check. Especially important because some hooks check
#          for secrets, lockfile integrity, or formatter compliance.
# DISABLE: Comment out the `if … fi` block. Don't. If a hook is genuinely
#          broken, fix the hook, not the workaround.

if echo "$NORMALISED" | grep -qE '(commit|push)\s+.*--no-verify'; then
  block "--no-verify skips the hooks that exist to catch real problems"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Guard 5: SQL — DROP TABLE / DROP DATABASE / DROP SCHEMA
# ─────────────────────────────────────────────────────────────────────────────
#
# WHAT:    Any shell-invocation containing `DROP TABLE`, `DROP DATABASE`, or
#          `DROP SCHEMA` (case-insensitive). Catches `psql -c "DROP TABLE …"`,
#          `mysql -e "DROP DATABASE …"`, etc.
# WHY:     Dropping tables/databases via the agent has destroyed production
#          data more than once in the wild. Even on a "dev" database, a drop
#          can blow away hours of test setup.
# DISABLE: Comment out the `if … fi` block. If you find this fires too often
#          on a deliberately-disposable local DB, consider scoping the disable
#          to your dev DB context (e.g. only when CWD contains "fixtures/").

if echo "$NORMALISED" | grep -qE 'drop\s+(table|database|schema)\b'; then
  block "DROP TABLE / DROP DATABASE — confirm explicitly via a separate, non-agent command"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Guard 6: `curl … | sh` (or wget) — piped-to-shell installers
# ─────────────────────────────────────────────────────────────────────────────
#
# WHAT:    `curl …` or `wget …` followed by a pipe into `bash`, `sh`, `zsh`,
#          or `fish`. The "blindly run code from the internet" pattern.
# WHY:     Classic supply-chain attack vector. Even when the URL is from a
#          legit project, the contents can change between the time you read
#          the README and the time the agent runs the command. Forcing a
#          download → read → run split makes the agent (and the human watching)
#          actually look at what's about to execute.
# DISABLE: Comment out the `if … fi` block. Recommended alternative: leave it
#          on, and when the agent needs to install something, it downloads the
#          script first (`curl -o install.sh …`), reads it, then runs it.

if echo "$NORMALISED" | grep -qE '(curl|wget)\s+[^|]*\|\s*(bash|sh|zsh|fish)\b'; then
  block "Piping a downloaded script directly to a shell — download, read, then run as separate steps"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Guard 7: Writing to `.env` via shell redirect
# ─────────────────────────────────────────────────────────────────────────────
#
# WHAT:    Shell redirects (`>` or `>>`) targeting a `.env` file. Catches
#          `echo "SECRET=…" >> .env` and similar.
# WHY:     Two problems. First, `.env` files routinely get accidentally
#          committed when they grow via shell redirect (because nobody
#          reviews the diff). Second, secrets pasted into the agent's command
#          stream can end up in session logs, terminal scrollback, and shell
#          history. Editing `.env` in a text editor is the safer path.
# DISABLE: Comment out the `if … fi` block. If you have a legitimate workflow
#          that writes to `.env` programmatically (e.g. a setup script), the
#          fix is to gate that script's write behind a confirmation, not to
#          remove the guard.

if echo "$NORMALISED" | grep -qE '(>|>>)\s*[^|&;]*\.env(\s|$|\.|\b)'; then
  block "Writing to .env via shell redirect — edit the file with a text editor instead"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Guard 8: Writing to a `credentials*` file via shell redirect
# ─────────────────────────────────────────────────────────────────────────────
#
# WHAT:    Shell redirects targeting a path containing `credentials` (e.g.
#          `~/.aws/credentials`, `gcp-credentials.json`).
# WHY:     Same reasoning as Guard 7 but for the broader category of
#          credential files. Catches naive append-to-credentials patterns
#          before they overwrite or merge-corrupt an existing file.
# DISABLE: Comment out the `if … fi` block.

if echo "$NORMALISED" | grep -qE '(>|>>)\s*[^|&;]*credentials(\.|\b)'; then
  block "Writing to a credentials file via shell redirect"
fi

# --- Allow ------------------------------------------------------------------
#
# Reached the end with no block triggered → command is allowed.
# Add new guards above this line, following the same WHAT / WHY / DISABLE
# comment pattern so future-you (or a fork-er) can read this file as
# documentation rather than archaeology.

exit 0
