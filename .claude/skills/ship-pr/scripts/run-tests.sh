#!/usr/bin/env bash
# run-tests.sh — format + test the current branch.
#
# Exit 0 = clean, ready to ship.
# Exit non-zero = something failed; do NOT push.
#
# This script is the deterministic part of the ship-pr skill. It does NOT call
# an LLM. It is meant to be predictable, fast, and impossible to talk around.
#
# Adapt the FORMAT_CMD and TEST_CMD blocks for your stack. The scaffolding
# (auto-detect, exit-on-failure, summary line) is portable.

set -euo pipefail

# --- Colour helpers (bash, no external deps) ---------------------------------

if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

step() { printf "${BLUE}==>${NC} %s\n" "$1"; }
ok()   { printf "${GREEN}✓${NC}  %s\n" "$1"; }
fail() { printf "${RED}✗${NC}  %s\n" "$1" >&2; }
warn() { printf "${YELLOW}!${NC}  %s\n" "$1"; }

# --- Detect stack ------------------------------------------------------------
#
# Add or remove detection blocks for your project. Each block sets:
#   FORMAT_CMD — command to format/lint
#   TEST_CMD   — command to run tests
#
# If your repo uses multiple languages (e.g. Go backend + TS frontend), you can
# either pick the dominant one or run both. The example below picks the first
# match.

FORMAT_CMD=""
TEST_CMD=""

if [ -f "go.mod" ]; then
  step "Detected: Go"
  FORMAT_CMD="gofmt -w . && goimports -w ."
  TEST_CMD="go test ./..."
elif [ -f "package.json" ]; then
  step "Detected: Node / TypeScript"
  # Prefer scripts the repo declares; fall back to common defaults
  if grep -q '"format"' package.json; then
    FORMAT_CMD="npm run format"
  elif command -v prettier >/dev/null 2>&1; then
    FORMAT_CMD="prettier --write ."
  fi
  if grep -q '"test"' package.json; then
    TEST_CMD="npm test --silent"
  fi
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  step "Detected: Python"
  if command -v ruff >/dev/null 2>&1; then
    FORMAT_CMD="ruff format . && ruff check --fix ."
  fi
  if [ -d "tests" ] && command -v pytest >/dev/null 2>&1; then
    TEST_CMD="pytest -q"
  fi
elif [ -f "Cargo.toml" ]; then
  step "Detected: Rust"
  FORMAT_CMD="cargo fmt"
  TEST_CMD="cargo test --quiet"
else
  warn "Could not auto-detect stack. Edit .claude/skills/ship-pr/scripts/run-tests.sh"
  warn "to add your FORMAT_CMD and TEST_CMD."
  exit 0  # Don't block — let the user proceed and configure later
fi

# --- Run format --------------------------------------------------------------

if [ -n "$FORMAT_CMD" ]; then
  step "Formatting: $FORMAT_CMD"
  if eval "$FORMAT_CMD"; then
    ok "Format clean"
  else
    fail "Format failed"
    exit 1
  fi
else
  warn "No formatter configured for this stack — skipping"
fi

# --- Check for unstaged formatting changes ----------------------------------
# If formatting modified tracked files, surface them. The caller can stage them
# in step 2 of the skill.

if [ -n "$(git status --porcelain)" ]; then
  warn "Formatting produced changes. Review and stage them before committing:"
  git status --short
fi

# --- Run tests ---------------------------------------------------------------

if [ -n "$TEST_CMD" ]; then
  step "Running tests: $TEST_CMD"
  if eval "$TEST_CMD"; then
    ok "Tests passed"
  else
    fail "Tests failed — DO NOT PUSH"
    exit 1
  fi
else
  warn "No test command configured for this stack — skipping"
  warn "If you have tests, add a TEST_CMD block in this script."
fi

# --- Summary -----------------------------------------------------------------

echo
ok "Ready to ship."
exit 0
