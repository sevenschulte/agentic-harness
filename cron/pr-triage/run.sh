#!/usr/bin/env bash
# pr-triage/run.sh — emit a Markdown report of open pull requests, sorted by age.
#
# Output goes to stdout. Pipe wherever you need it (Slack, email, file).
#
# Requirements: gh, jq, bash, awk.
# Auth: assumes gh is already authenticated (run `gh auth login` once).
#
# Exit codes:
#   0 — success (even if there are 0 open PRs)
#   1 — gh not installed or not authenticated
#   2 — could not determine repo

set -euo pipefail

# --- Preflight ---------------------------------------------------------------

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not installed: https://cli.github.com/" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh CLI not authenticated. Run: gh auth login" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not installed (brew install jq / apt-get install jq)" >&2
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
  echo "Could not determine current repo. Run from inside a git repo with a GitHub remote." >&2
  exit 2
fi

# --- Fetch open PRs ----------------------------------------------------------

JSON=$(gh pr list \
  --state open \
  --limit 100 \
  --json number,title,author,createdAt,isDraft,additions,deletions,changedFiles,statusCheckRollup,reviewDecision,headRefName,baseRefName,labels,url \
  2>/dev/null || echo "[]")

COUNT=$(echo "$JSON" | jq 'length')
TODAY=$(date '+%Y-%m-%d')

# --- Header ------------------------------------------------------------------

cat <<EOF
# PR Triage — $REPO — $TODAY

**Open PRs:** $COUNT

EOF

if [ "$COUNT" -eq 0 ]; then
  echo "No open pull requests. Inbox zero."
  exit 0
fi

# --- Compute age in days, sort oldest first ---------------------------------
#
# We pipe through jq to add `age_days`, then sort by it descending.

ENRICHED=$(echo "$JSON" | jq --arg now "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" '
  [ .[] | . + {
      age_days: ((($now | fromdateiso8601) - (.createdAt | fromdateiso8601)) / 86400 | floor)
    }
  ] | sort_by(.age_days) | reverse
')

# --- Categorise --------------------------------------------------------------
#
# Buckets:
#   Stale       — > 14 days old
#   Aging       — 8–14 days old
#   Fresh       — < 8 days old
#   Drafts      — isDraft = true (always shown last)

echo "## Stale (> 14 days)"
echo
STALE=$(echo "$ENRICHED" | jq '[ .[] | select(.isDraft == false and .age_days > 14) ]')
if [ "$(echo "$STALE" | jq 'length')" -eq 0 ]; then
  echo "_None._"
else
  echo "$STALE" | jq -r '.[] | "- **#\(.number)** [\(.age_days)d] \(.title) — @\(.author.login)\n  CI: \(.statusCheckRollup // [] | map(.conclusion // .status) | join(",") | tostring) | Review: \(.reviewDecision // "none") | +\(.additions)/-\(.deletions) | \(.url)"'
fi
echo

echo "## Aging (8–14 days)"
echo
AGING=$(echo "$ENRICHED" | jq '[ .[] | select(.isDraft == false and .age_days >= 8 and .age_days <= 14) ]')
if [ "$(echo "$AGING" | jq 'length')" -eq 0 ]; then
  echo "_None._"
else
  echo "$AGING" | jq -r '.[] | "- **#\(.number)** [\(.age_days)d] \(.title) — @\(.author.login)\n  CI: \(.statusCheckRollup // [] | map(.conclusion // .status) | join(",") | tostring) | Review: \(.reviewDecision // "none") | +\(.additions)/-\(.deletions) | \(.url)"'
fi
echo

echo "## Fresh (< 8 days)"
echo
FRESH=$(echo "$ENRICHED" | jq '[ .[] | select(.isDraft == false and .age_days < 8) ]')
if [ "$(echo "$FRESH" | jq 'length')" -eq 0 ]; then
  echo "_None._"
else
  echo "$FRESH" | jq -r '.[] | "- **#\(.number)** [\(.age_days)d] \(.title) — @\(.author.login)\n  CI: \(.statusCheckRollup // [] | map(.conclusion // .status) | join(",") | tostring) | Review: \(.reviewDecision // "none") | +\(.additions)/-\(.deletions) | \(.url)"'
fi
echo

echo "## Drafts"
echo
DRAFTS=$(echo "$ENRICHED" | jq '[ .[] | select(.isDraft == true) ]')
if [ "$(echo "$DRAFTS" | jq 'length')" -eq 0 ]; then
  echo "_None._"
else
  echo "$DRAFTS" | jq -r '.[] | "- **#\(.number)** [\(.age_days)d] \(.title) — @\(.author.login) | +\(.additions)/-\(.deletions)"'
fi
echo

# --- Summary line -----------------------------------------------------------

STALE_N=$(echo "$STALE" | jq 'length')
AGING_N=$(echo "$AGING" | jq 'length')
FRESH_N=$(echo "$FRESH" | jq 'length')
DRAFT_N=$(echo "$DRAFTS" | jq 'length')

echo "---"
echo
echo "**Summary:** $STALE_N stale, $AGING_N aging, $FRESH_N fresh, $DRAFT_N draft."
if [ "$STALE_N" -gt 0 ]; then
  echo
  echo "_Pick one stale PR today. The longer they sit, the harder they are to merge._"
fi
