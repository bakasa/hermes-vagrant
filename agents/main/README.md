# Hermes Main Agent (OWL)
# =======================

The coordinator. The Slack gateway. The decision-maker.

OWL is the Main Agent in the Hermes ecosystem — the first point of contact
for the user and the orchestrator of all other agents. It runs on port 3000,
connects to Slack, and coordinates hermes-coder, hermes-research,
hermes-crew, and hermes-subconscious.

## Architecture Overview

```
                    ┌──────────┐
          Slack ──► │   OWL    │ ──► User sees me
                    │  :3000   │
                    └────┬─────┘
                         │
            ┌────────────┼────────────┐
            │            │            │
      ┌─────▼─────┐ ┌───▼───┐ ┌─────▼─────┐
      │ hermes-    │ │hermes-│ │ hermes-   │
      │ coder      │ │research│ │ crew     │
      └───────────┘ └───────┘ └───────────┘
```

## Quick Start

```bash
# Set environment variables
export OPENROUTER_API_KEY="your-key"
export SLACK_BOT_TOKEN="xoxb-your-token"
export SLACK_APP_TOKEN="xapp-your-token"

# Run with Docker
docker build -t hermes-main .
docker run -p 3000:3000 --env-file .env hermes-main

# Or run directly
python -m hermes_agent --config config.yaml
```

## Configuration

See `config.yaml` for:
- OpenRouter provider settings (model: opus)
- Slack bot/app tokens (via environment variables)
- Gateway host/port (0.0.0.0:3000)
- Handoff directory paths
- Agent registry (coder, research, crew, subconscious)

## Skills

| Skill                        | Purpose                                    |
|------------------------------|--------------------------------------------|
| `coordination`               | Orchestration, handoffs, conflict resolution |
| `dev-house-ops`              | Infrastructure, deployment, CI/CD          |
| `perp-trading-automation`    | Trading bot monitoring and control         |

## Cron Jobs

OWL monitors handoff directories every 5 minutes to route incoming
agent completions and detect stalled tasks. See `cron/jobs.json`.

## Directory Structure

```
hermes-main/
├── SOUL.md                      # OWL's identity and personality
├── config.yaml                  # Provider, Slack, and gateway config
├── Dockerfile                   # Container build definition
├── README.md                    # This file
├── .gitignore
├── cron/
│   └── jobs.json                # Scheduled job definitions
└── skills/
    ├── coordination/
    │   └── SKILL.md             # Orchestration pattern
    ├── dev-house-ops/
    │   └── SKILL.md             # Infrastructure & deployment
    └── perp-trading-automation/
        └── SKILL.md             # Trading bot operations
```

## Handoff Protocol

Agents communicate via structured handoff files in `/data/handoffs/`:
- `incoming/` — New tasks arriving at OWL
- `outgoing/` — Tasks OWL has assigned to agents
- `completed/` — Successfully finished tasks
- `failed/` — Tasks that need re-routing or retry

## License

Internal use — ZOO Company.
