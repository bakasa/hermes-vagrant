# hermes-coder — Coder Agent

> A builder agent that delegates to Claude Code CLI, manages PRs, runs tests, and ships code.

The Coder Agent receives task briefs from Main Agent and build signals from Research, then turns them into working, tested, reviewed pull requests — automatically.

## Personality

- **Direct and efficient.** No fluff, no over-explanation.
- **Done is better than perfect.** Ships working code on time.
- **Always writes tests.** No green CI, no merge.
- **Always creates PRs.** Never force-pushes to main.

## What It Does

| Capability | Description |
|---|---|
| Claude Code delegation | Hands off coding tasks to `claude -p` for headless execution |
| PR workflow | Opens PRs, handles review comments, squash-merges when green |
| Test runner | Auto-detects framework, runs tests, retries on failure |
| Build/ship cycle | Full pipeline: plan → build → test → PR → review → ship |
| Cron jobs | Polls for tasks every 30min, follows up on PRs, reports health |

## Quick Start

### Run with Docker

```bash
docker build -t hermes-coder .
docker run -d \
  --name coder-agent \
  -p 3003:3003 \
  -e OPENROUTER_API_KEY=$OPENROUTER_API_KEY \
  -v coder-workspace:/data/hermes-coder/workspace \
  hermes-coder
```

### Run locally

```bash
# Install dependencies
pip install hermes-agent
npm install -g @anthropic-ai/claude-code

# Start the gateway
hermes gateway --config config.yaml --port 3003
```

### Health Check

```bash
curl http://localhost:3003/health
```

## Repository Structure

```
hermes-coder/
├── SOUL.md                      # Agent identity and principles
├── config.yaml                  # OpenRouter provider, model, tools, ports
├── Dockerfile                   # Container definition, exposes port 3003
├── README.md                    # This file
├── .gitignore                   # Ignores secrets, build artifacts
├── skills/
│   └── coder-agent/
│       └── SKILL.md             # Delegation, PR workflow, test runner, build/ship cycle
└── cron/
    └── jobs.json                # Cron jobs: task polling, PR followup, health reports
```

## Configuration

Edit `config.yaml` to customize:

| Key | Default | Description |
|---|---|---|
| `provider.model` | `sonnet` | OpenRouter model to use |
| `gateway.port` | `3003` | Gateway listen port |
| `claude_cli.max_turns` | `100` | Max turns for Claude Code sessions |
| `claude_cli.default_timeout_ms` | `600000` | Session timeout (10 min) |
| `pr_workflow.squash_merge` | `true` | Always squash-merge PRs |
| `test.fail_no_tests` | `true` | Fail task if repo has no test suite |

## Cron Jobs

| Job | Schedule | Purpose |
|---|---|---|
| `check-handoff-tasks` | Every 30 min | Poll for incoming task briefs and build signals |
| `health-report` | Every hour | Report active tasks, open PRs, blockers |
| `pr-followup` | Every 2 hours | Check PR status, handle comments, merge if green |

## Task Format

The Coder Agent expects task briefs in this structure:

```json
{
  "task_id": "task-001",
  "type": "feature",
  "repo": "git@github.com:org/repo.git",
  "description": "Implement rate limiting middleware",
  "acceptance_criteria": [
    "Token bucket algorithm",
    "Unit tests with >90% coverage",
    "Configurable rate per endpoint"
  ],
  "branch": "main",
  "reviewer": "alice"
}
```

## Signals

- **From Main Agent** → task briefs (acceptance criteria, repo, branch, deadline)
- **From Research** → build signals (tech spec, architecture notes, constraints)
- **Output** → PRs, CI status, merge confirmations

## License

MIT
