#!/usr/bin/env bash
# post-comment.sh — post a review comment to a pull request via gh CLI.
#
# Usage:
#   post-comment.sh <pr-number> <body>
#
# Example:
#   post-comment.sh 42 "$(cat review.md)"
#
# Exit 0 on success, non-zero on failure. Errors go to stderr.
#
# This is the deterministic part of the review-pr skill. It validates inputs,
# checks gh auth, and posts the comment. The comment body is composed by the
# LLM in the skill body — this script does NOT generate review content.

set -euo pipefail

PR="${1:-}"
BODY="${2:-}"

if [ -z "$PR" ]; then
  echo "Usage: post-comment.sh <pr-number> <body>" >&2
  exit 1
fi

if [ -z "$BODY" ]; then
  echo "Refusing to post empty review comment to PR #$PR" >&2
  exit 1
fi

if ! [[ "$PR" =~ ^[0-9]+$ ]]; then
  echo "PR must be a positive integer (got: $PR)" >&2
  exit 1
fi

# --- Verify gh auth ----------------------------------------------------------

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not installed. Install: https://cli.github.com/" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh CLI not authenticated. Run: gh auth login" >&2
  exit 1
fi

# --- Verify the PR exists ---------------------------------------------------

if ! gh pr view "$PR" --json number >/dev/null 2>&1; then
  echo "PR #$PR not found in current repo." >&2
  exit 1
fi

# --- Post the comment -------------------------------------------------------
#
# We use `gh pr comment` (issue-style comment) rather than `gh pr review`
# because review submissions APPROVE / REQUEST_CHANGES carry more weight than
# an automated tool should claim by default. If your team is comfortable with
# the agent submitting formal reviews, swap the command for:
#
#   gh pr review "$PR" --comment --body "$BODY"
#
# or, to require/approve changes:
#
#   gh pr review "$PR" --request-changes --body "$BODY"
#   gh pr review "$PR" --approve --body "$BODY"

echo "Posting review comment to PR #$PR..."
gh pr comment "$PR" --body "$BODY"

URL=$(gh pr view "$PR" --json url -q .url)
echo "Posted: $URL"
