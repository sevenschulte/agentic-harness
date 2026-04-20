# dependency-watch

A scheduled agent that scans the project's dependencies for known vulnerabilities
and outdated versions, then emits a Markdown report. Designed to run weekly so
the team sees CVE drift without anyone having to remember to look.

## What it does

1. Detects the package manager(s) in use (`npm`, `pip`, `go`, `cargo`)
2. Runs the appropriate audit command (`npm audit`, `pip-audit`, `govulncheck`, `cargo audit`)
3. Formats findings as Markdown grouped by severity
4. Optionally files a GitHub issue if any high/critical findings exist

The GitHub issue creation is **opt-in** — the script's default is "report only"
because automated issue creation can flood inboxes if you don't tune the
thresholds. See `Configuration` below.

## Run it

```bash
# Manually
./run.sh

# Pipe to a file
./run.sh > /tmp/deps.md

# With issue creation enabled
DEPWATCH_FILE_ISSUE=1 ./run.sh
```

## Schedule it

Weekly (Mondays 09:00) via cron:

```cron
0 9 * * 1 cd /path/to/repo && ./cron/dependency-watch/run.sh > /tmp/deps.md
```

Or via GitHub Actions:

```yaml
# .github/workflows/dependency-watch.yml
on:
  schedule:
    - cron: "0 9 * * 1"
  workflow_dispatch:
jobs:
  watch:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: ./cron/dependency-watch/run.sh > deps.md
      - run: gh issue create --title "Weekly dependency report — $(date +%Y-%m-%d)" --body-file deps.md
        if: success()
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Configuration

Environment variables:

| Variable | Default | Effect |
|---|---|---|
| `DEPWATCH_FILE_ISSUE` | unset | If `1`, creates a GitHub issue when high/critical findings exist |
| `DEPWATCH_THRESHOLD` | `high` | Severity floor for issue creation (`low`, `moderate`, `high`, `critical`) |
| `DEPWATCH_LABEL` | `dependencies` | Label to apply to the created issue |

## Requirements

- For Node: `npm` (audit is built in)
- For Python: `pip-audit` (`pip install pip-audit`)
- For Go: `govulncheck` (`go install golang.org/x/vuln/cmd/govulncheck@latest`)
- For Rust: `cargo-audit` (`cargo install cargo-audit`)
- For issue creation: `gh` CLI

The script skips ecosystems where the tool isn't installed, so a polyglot repo
can run partial scans without failing.

## Running unattended

Issue creation needs `gh` to be authenticated, and `gh auth login` is interactive.
For server cron, launchd, or CI, set `GH_TOKEN` instead — `gh` picks it up
automatically:

```bash
export GH_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
DEPWATCH_FILE_ISSUE=1 ./run.sh
```

In GitHub Actions, `${{ secrets.GITHUB_TOKEN }}` is already wired into
`GH_TOKEN` for you (see the workflow snippet above). The token needs `repo`
scope (or `issues: write` permission on the workflow) to create issues. Full
reference: <https://cli.github.com/manual/gh_auth_login>.

## Tuning false positives

Audit tools err on the side of noise. When a finding is a known false positive
or accepted risk, document it in `memory/MEMORY.md` (under "Things that broke
before" or a dedicated "Accepted dependency risks" section) so the next
person — or the next agent reading the report — has context.

## Going further

This script is a **report**, not an agent. To graduate it to an agent (e.g.
auto-open PRs that bump vulnerable deps), wrap the script with a Claude Code /
Codex CLI call that reads the report and acts on it. Keep a human in the loop
for the merge — see `.claude/rules/guardrails.md` on external side effects.
