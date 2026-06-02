# Hermes QA Agent

The quality gatekeeper for the Hermes project. Reviews pull requests, runs tests, scans for security vulnerabilities, and delivers clear SHIP / NO-SHIP verdicts.

## Quick Start

```bash
# Build
docker build -t hermes-qa .

# Run
docker run -p 3004:3004 --env-file .env hermes-qa

# Verify
curl http://localhost:3004/health
```

## How It Works

1. Coder Agent opens a PR → QA Agent gets notified (webhook / cron poll)
2. QA Agent checks out the branch, runs unit + integration tests
3. QA Agent performs static analysis and security scanning
4. QA Agent reviews the diff against quality gates
5. QA Agent posts a structured verdict: **SHIP** ✅ or **NO-SHIP** ❌

## Repository Structure

```
hermes-qa/
├── SOUL.md                  # Agent identity, principles, and verdict format
├── config.yaml              # OpenRouter provider, model, gateway config
├── Dockerfile               # Container build (port 3004)
├── requirements.txt         # Python dependencies
├── README.md                # This file
├── .gitignore               #
├── skills/qa-agent/
│   └── SKILL.md             # Quality gates, verdict system, feedback format
└── cron/
    └── jobs.json            # Cron: check for new PRs every 15 minutes
```

## Verdict Criteria

| Gate | Blocking? | Examples |
|------|-----------|----------|
| **Security** | ✅ Yes | Hardcoded secrets, SQLi, XSS, path traversal |
| **Tests** | ✅ Yes | Any failing test |
| **Correctness** | ✅ Yes | Logic errors, null dereferences, data loss |
| **Code Quality** | ⚠️ Warn | High complexity, missing types, no docs |
| **Functional** | ✅ Yes | Missing edge-case handling, API contract violations |
| **Style** | ❌ No | Subjective preferences never block |

## Model

Uses **Claude 3 Opus** (via OpenRouter) for thorough, nuanced code reviews.

## Port

| Service | Port |
|---------|------|
| Gateway | 3004 |
