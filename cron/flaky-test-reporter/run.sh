#!/usr/bin/env bash
# flaky-test-reporter/run.sh — surface flaky tests from recent CI runs.
#
# Pulls the last $RUNS runs of $WORKFLOW, downloads logs for failed runs,
# extracts test names, counts duplicates, flags anything failing in
# > $MIN_FAILURES runs.
#
# Output: Markdown to stdout.
#
# This is a SKELETON — the test-name extraction in parse_failures() handles
# common formats (Go, Vitest/Jest text, pytest -v). Edit it for your test runner.
#
# Exit 0 always (this is a report).

set -uo pipefail

WORKFLOW="${WORKFLOW:-ci}"
RUNS="${RUNS:-50}"
MIN_FAILURES="${MIN_FAILURES:-2}"
TODAY=$(date '+%Y-%m-%d')

# --- Preflight ---------------------------------------------------------------

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not installed. Install: https://cli.github.com/" >&2
  exit 0  # Soft fail — this is a cron report
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh CLI not authenticated. Run: gh auth login" >&2
  exit 0
fi

# --- Header ------------------------------------------------------------------

echo "# Flaky Test Report — $TODAY"
echo
echo "Workflow: \`$WORKFLOW\` · Window: last $RUNS runs · Threshold: $MIN_FAILURES+ failures"
echo

# --- Fetch failed runs -------------------------------------------------------

# Get IDs of the last $RUNS runs of $WORKFLOW that ended in failure.
FAILED_IDS=$(gh run list \
  --workflow "$WORKFLOW" \
  --limit "$RUNS" \
  --status failure \
  --json databaseId \
  --jq '.[].databaseId' 2>/dev/null || echo "")

if [ -z "$FAILED_IDS" ]; then
  echo "No failed runs in the last $RUNS — either CI is healthy or the workflow filter is wrong."
  exit 0
fi

FAILED_COUNT=$(echo "$FAILED_IDS" | wc -l | tr -d ' ')
echo "Failed runs in window: **$FAILED_COUNT**"
echo

# --- Parse failures from each run -------------------------------------------
#
# parse_failures: read CI log on stdin, emit one test name per line on stdout.
# Add patterns for the test runners you use.

parse_failures() {
  awk '
    # Go: "--- FAIL: TestSomething (0.01s)"
    /^--- FAIL: / {
      gsub(/^--- FAIL: /, ""); gsub(/ \(.*$/, ""); print "go::" $0; next
    }
    # pytest: "FAILED tests/foo.py::test_bar - AssertionError: ..."
    /^FAILED / {
      gsub(/^FAILED /, ""); gsub(/ - .*$/, ""); print "pytest::" $0; next
    }
    # Vitest / Jest text reporter: "  ✗ test name"  or "  ✕ test name"
    /^[[:space:]]*[✗✕] / {
      gsub(/^[[:space:]]*[✗✕] /, ""); print "node::" $0; next
    }
  '
}

ALL_FAILURES=$(mktemp)
trap 'rm -f "$ALL_FAILURES"' EXIT

# Loop runs, append failures.
echo "Scanning logs..." >&2
for ID in $FAILED_IDS; do
  # gh run view --log can be huge; limit per-run lines
  gh run view "$ID" --log 2>/dev/null \
    | parse_failures \
    | sort -u >> "$ALL_FAILURES"
done

# --- Tally -------------------------------------------------------------------

if [ ! -s "$ALL_FAILURES" ]; then
  echo "No test failures matched known patterns. Either no real flakes, or parse_failures() needs an update."
  echo "(Edit cron/flaky-test-reporter/run.sh — \`parse_failures\` function — to add your test runner's format.)"
  exit 0
fi

TALLY=$(sort "$ALL_FAILURES" | uniq -c | sort -rn)
FLAKY=$(echo "$TALLY" | awk -v min="$MIN_FAILURES" '$1 >= min { print }')

if [ -z "$FLAKY" ]; then
  echo "No tests failed in $MIN_FAILURES+ runs. CI is genuinely flaky-free or the window is too small."
  exit 0
fi

echo "## Flaky tests detected"
echo
echo "| Failures | Test |"
echo "|---|---|"
echo "$FLAKY" | awk '{
  count = $1
  $1 = ""
  sub(/^ /, "")
  printf "| %d | `%s` |\n", count, $0
}'
echo

# --- Recommendations --------------------------------------------------------

echo "## What to do"
echo
echo "1. Pick the highest-count test"
echo "2. Run it locally with \`-count=10\` (or your runner's equivalent) to confirm"
echo "3. Read the test — flakes are usually time-of-day, parallelism, or external dependency"
echo "4. Fix it. **Do not** add \`skip\`. If you must, file a tracking issue first"
echo
echo "_Auto-skipping flakes is how test suites die. Make the cost of skipping explicit._"
