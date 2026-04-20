# flaky-test-reporter

A scheduled agent that surfaces flaky tests from recent CI runs. Designed to
catch the slow rot where a few tests start failing intermittently and everyone
gets used to retrying instead of fixing.

## What it does

1. Pulls the last N runs of your main CI workflow via `gh run list`
2. Walks each failed run, extracts the failed test names from the logs
3. Counts how often each test name appears across runs
4. Anything failing in > 1 run within the window is flagged as flaky
5. Emits a Markdown report

The output is intentionally read-only. Auto-skipping flaky tests is the wrong
move — it's how test suites die. The right move is to fix them or, in extremis,
quarantine them with a tracking issue. This script makes the fixing visible.

## Why this is harder than the other crons

There's no universal CI log format. The script ships with parsers for:

- Go (`--- FAIL:` lines in `go test` output)
- Vitest / Jest (`✗` markers in JSON or text output)
- pytest (`FAILED` lines in `-v` output)

If your CI logs look different, edit `parse_failures()` in `run.sh`. The
scaffolding (fetching runs, deduping, formatting) is reusable.

## Run it

```bash
# Manually — defaults to last 50 runs of the workflow named "ci"
./run.sh

# Custom workflow + window
WORKFLOW=tests.yml RUNS=100 ./run.sh
```

## Schedule it

```cron
# Weekly, Monday 09:30
30 9 * * 1 cd /path/to/repo && ./cron/flaky-test-reporter/run.sh > /tmp/flaky.md
```

GitHub Actions (creates an issue on findings):

```yaml
on:
  schedule:
    - cron: "30 9 * * 1"
  workflow_dispatch:
jobs:
  flaky:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./cron/flaky-test-reporter/run.sh > flaky.md
      - run: |
          if grep -q "Flaky tests detected" flaky.md; then
            gh issue create --title "Flaky tests — $(date +%Y-%m-%d)" --body-file flaky.md --label flaky-tests
          fi
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Configuration

| Variable | Default | Effect |
|---|---|---|
| `WORKFLOW` | `ci` | Workflow name or filename to scan |
| `RUNS` | `50` | Number of recent runs to pull |
| `MIN_FAILURES` | `2` | Minimum failure count to call a test "flaky" |

## Requirements

- `gh` CLI (authenticated)
- `bash`, `awk`, `sort`, `uniq`

## Running unattended

`gh auth login` is interactive and won't work from server cron, launchd, or CI
runners. Set `GH_TOKEN` instead — `gh` reads it automatically:

```bash
export GH_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
./run.sh
```

The token needs `repo` scope (or workflow permissions including `actions: read`
to call `gh run list` / `gh run view --log`). In GitHub Actions, the built-in
`${{ secrets.GITHUB_TOKEN }}` is already wired into `GH_TOKEN`. Full reference:
<https://cli.github.com/manual/gh_auth_login>.

## Tuning

The default threshold (failed in 2+ runs out of the last 50) is conservative.
Lower `MIN_FAILURES` if you have a small CI volume. Raise it if you have a
high-volume monorepo where a 0.1% true-flake rate is acceptable.

If the script keeps surfacing the same test that the team has decided not to
fix, that's a signal: either the test should be deleted, or quarantined with
a tracking issue. Don't just lower the threshold to hide it.
