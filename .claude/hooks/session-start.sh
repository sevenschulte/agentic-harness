#!/usr/bin/env bash
# session-start.sh — runs at the start of every agent session.
#
# Output of this script is injected into the agent's context window BEFORE its
# first turn. Use it to dump deterministic, time-sensitive state that the agent
# would otherwise have to ask for or guess wrong:
#
#   - Today's date (LLMs hallucinate dates constantly)
#   - Current branch (so it doesn't push to the wrong one)
#   - Recent commits (orientation: "what just happened here?")
#   - Uncommitted changes (so it knows there's WIP)
#   - Auto-loaded memory files
#
# Wire this up in your runtime's settings:
#
#   Claude Code: .claude/settings.json
#     {
#       "hooks": {
#         "SessionStart": [
#           { "hooks": [{ "type": "command", "command": ".claude/hooks/session-start.sh" }] }
#         ]
#       }
#     }
#
#   Other runtimes: see their docs for the equivalent hook.
#
# Exit 0 always (this hook informs; it doesn't block).

set -uo pipefail  # NOTE: no -e — partial failures should not break the session

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR" || exit 0

echo "# Auto-loaded Session Context"
echo "# Injected by .claude/hooks/session-start.sh — read once, follow conventions throughout."
echo

# --- Time & place ------------------------------------------------------------

echo "## Environment"
echo "- Today: $(date '+%Y-%m-%d %A')"
echo "- Time: $(date '+%H:%M %Z')"
echo "- CWD: $PROJECT_DIR"
echo

# --- Git state ---------------------------------------------------------------

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "## Git"
  echo "- Branch: \`$(git branch --show-current 2>/dev/null || echo 'detached HEAD')\`"

  UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
  if [ -n "$UPSTREAM" ]; then
    AHEAD=$(git rev-list --count "$UPSTREAM"..HEAD 2>/dev/null || echo "?")
    BEHIND=$(git rev-list --count HEAD.."$UPSTREAM" 2>/dev/null || echo "?")
    echo "- Tracking: \`$UPSTREAM\` (ahead $AHEAD, behind $BEHIND)"
  fi

  DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$DIRTY" -gt 0 ]; then
    echo "- Working tree: **$DIRTY uncommitted changes**"
    echo
    echo "\`\`\`"
    git status --short 2>/dev/null | head -20
    if [ "$DIRTY" -gt 20 ]; then
      echo "... and $((DIRTY - 20)) more"
    fi
    echo "\`\`\`"
  else
    echo "- Working tree: clean"
  fi

  echo
  echo "### Recent commits"
  echo "\`\`\`"
  git log --oneline -5 2>/dev/null || echo "(no commits yet)"
  echo "\`\`\`"
  echo
fi

# --- Auto-loaded memory ------------------------------------------------------

echo "## Memory (auto-loaded)"

for FILE in AGENTS.md memory/MEMORY.md memory/ACTIVE.md; do
  if [ -f "$FILE" ] && [ -s "$FILE" ]; then
    # Skip if it's just template comments (heuristic: < 200 bytes of non-comment content)
    NONCOMMENT=$(grep -v '^\s*<!--' "$FILE" | grep -v '^\s*#' | tr -d '[:space:]' | wc -c | tr -d ' ')
    if [ "$NONCOMMENT" -gt 50 ]; then
      echo "- \`$FILE\` ($(wc -l < "$FILE" | tr -d ' ') lines)"
    fi
  fi
done

echo
echo "Read those three files now if you have not already this session."
echo
echo "Project-specific context lives under \`memory/projects/\` — read on demand."
echo
echo "# End of auto-loaded context"
exit 0
