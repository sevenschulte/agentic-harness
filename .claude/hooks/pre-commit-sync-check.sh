#!/usr/bin/env bash
# pre-commit-sync-check.sh — refuse the commit if AGENTS.md and CLAUDE.md drift.
#
# Both files exist because Claude Code historically reads CLAUDE.md and the
# newer open standard is AGENTS.md. We ship both with identical content.
# Symlinks are an option but break on Windows; this hook is the cross-platform
# guard.
#
# Install (one-time, per clone):
#
#   ln -s ../../.claude/hooks/pre-commit-sync-check.sh .git/hooks/pre-commit
#
# Or copy if your filesystem hates symlinks:
#
#   cp .claude/hooks/pre-commit-sync-check.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Exit 0 = files in sync, allow commit.
# Exit 1 = files out of sync, block commit with a fix instruction.

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

if [ ! -f AGENTS.md ] || [ ! -f CLAUDE.md ]; then
  # If one is missing, that's a bigger problem — don't block the commit on it
  # (the maintainer is presumably mid-refactor). Just warn.
  echo "warning: pre-commit-sync-check expected both AGENTS.md and CLAUDE.md; one is missing." >&2
  exit 0
fi

if ! diff -q AGENTS.md CLAUDE.md > /dev/null; then
  echo "BLOCKED: AGENTS.md and CLAUDE.md are out of sync." >&2
  echo "" >&2
  echo "Fix: copy whichever you edited over the other, then re-stage and commit:" >&2
  echo "  cp AGENTS.md CLAUDE.md   # if you edited AGENTS.md" >&2
  echo "  cp CLAUDE.md AGENTS.md   # if you edited CLAUDE.md" >&2
  echo "  git add AGENTS.md CLAUDE.md" >&2
  exit 1
fi

exit 0
