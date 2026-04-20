# pr-triage

A scheduled agent that produces a daily summary of open pull requests, sorted by
age and tagged by status. Runs without a human; outputs Markdown to stdout (or
to a file you pipe into Slack, email, a dashboard, etc.).

## What it does

1. Lists every open PR in the current repo
2. Sorts them by age (oldest first)
3. For each PR, captures: number, title, author, age, CI status, review status,
   size (lines changed), draft / ready
4. Emits a Markdown report

The output is the input for whatever you do next — a morning Slack post, an
email to the team, a row in a dashboard. The script is deliberately not coupled
to any of those.

## Why scheduled

PR rot is the silent killer of velocity. The longer a PR sits, the harder it is
to merge (rebase pain, scope drift, reviewer cold-start). A daily report makes
the rot visible. The expected outcome is that the oldest item on the list gets
picked up that day — every day.

## Run it

```bash
# Manually
./run.sh

# Pipe to a file
./run.sh > /tmp/pr-triage.md

# To Slack via webhook (example — uses curl, requires SLACK_WEBHOOK_URL env)
./run.sh | curl -X POST -H 'Content-Type: application/json' \
  -d "{\"text\": \"$(jq -Rs . </tmp/pr-triage.md)\"}" "$SLACK_WEBHOOK_URL"
```

## Schedule it

### Linux / cron

Edit `crontab -e`, add:

```cron
# Every weekday at 09:00, run the triage and email it
0 9 * * 1-5 cd /path/to/repo && ./cron/pr-triage/run.sh | mail -s "PR Triage" team@example.com
```

### macOS / launchd

Create `~/Library/LaunchAgents/local.pr-triage.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>            <string>local.pr-triage</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string>
      <string>-lc</string>
      <string>cd /path/to/repo && ./cron/pr-triage/run.sh > /tmp/pr-triage.md</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key>   <integer>9</integer>
      <key>Minute</key> <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>  <string>/tmp/pr-triage.out</string>
    <key>StandardErrorPath</key><string>/tmp/pr-triage.err</string>
  </dict>
</plist>
```

Then:

```bash
launchctl load ~/Library/LaunchAgents/local.pr-triage.plist
```

### GitHub Actions

```yaml
# .github/workflows/pr-triage.yml
on:
  schedule:
    - cron: "0 9 * * 1-5"
jobs:
  triage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./cron/pr-triage/run.sh > triage.md
      - run: gh issue comment <triage-tracking-issue> --body-file triage.md
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Requirements

- `gh` CLI (authenticated)
- `jq`
- `bash`

## Running unattended

`gh auth login` opens a browser, which doesn't work in CI runners, server cron,
or launchd. Set `GH_TOKEN` instead — `gh` reads it automatically and skips the
interactive flow:

```bash
# Personal access token (classic or fine-grained, scope: `repo` or `read:org` + `repo`)
export GH_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
./run.sh
```

In GitHub Actions the built-in `${{ secrets.GITHUB_TOKEN }}` is already wired
into `GH_TOKEN` for you (see the workflow snippet above). For launchd / cron,
put the export in the wrapping shell or the plist's `EnvironmentVariables`.
Full reference: <https://cli.github.com/manual/gh_auth_login>.

## Extending it

If you want the agent to *act* on findings (e.g. nudge stale PRs, auto-close
abandoned ones), wrap `run.sh` in a Claude Code / Codex CLI call and pass the
report as input. That graduates this from a *report* to an *agent* — and at
that point you want a human in the loop for the actions, even if the report
runs unattended. See `.claude/rules/guardrails.md` on external side effects.
