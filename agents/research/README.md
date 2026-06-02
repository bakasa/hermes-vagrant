# Hermes Research Agent — Evidence Collector & Signal Router

**Port:** 3001 | **Model:** Claude Sonnet (OpenRouter) | **Version:** 1.0.0

The Research Agent is the crew's evidence collector. It scans RSS feeds, arXiv, and other sources, maintains an evidence vault (findings/claims/sources/dossiers), and routes signals to other agents.

## Quick Start

```bash
# Build
docker build -t hermes-research:latest .

# Run
docker run -d \
  --name hermes-research \
  -p 3001:3001 \
  -e OPENROUTER_API_KEY=$OPENROUTER_API_KEY \
  -v shared-handoffs:/data/handoffs:rw \
  -v research-data:/data/.hermes:rw \
  hermes-research:latest

# Check health
curl http://localhost:3001/health
```

## Architecture

```
hermes-research/
├── SOUL.md                          # Agent identity & operating principles
├── config.yaml                      # Provider, model, tools, research config
├── Dockerfile                       # Container definition (port 3001)
├── .gitignore                       # Excludes .env, auth.json, tokens, etc.
├── README.md                        # This file
├── skills/
│   └── research-agent/
│       ├── SKILL.md                 # Vault-based research methodology
│       └── references/
│           ├── feed-list.md         # RSS feed sources (30+ feeds)
│           └── search-queries.md    # Research query templates
└── cron/
    └── jobs.json                    # Scheduled jobs (daily scan + 6h extract)
```

## Evidence Vault

The vault is the Research Agent's primary data store:

| Directory | Purpose | File Pattern |
|-----------|---------|-------------|
| `vault/findings/` | Individual research findings | `YYYY-MM-DD-{topic}-finding-{id}.md` |
| `vault/claims/` | Evaluated claims with evidence ratings | `YYYY-MM-DD-{claim-slug}.md` |
| `vault/sources/` | Source metadata and reliability scores | `{source-id}.json` |
| `vault/dossiers/` | Topic-aggregated research dossiers | `{topic-slug}.md` |
| `vault/digests/` | Daily and weekly digests | `YYYY-MM-DD-daily-digest.md` |

## Scheduled Jobs

| Job | Schedule | Purpose |
|-----|----------|---------|
| Source Health Check | Daily 05:00 UTC | Validate all RSS feeds are responding |
| Daily Research Scan | Daily 06:00 UTC | Full scan of all sources + digest generation |
| Extract Cycle | Every 6 hours | Lightweight signal processing + claim cross-ref |
| Dossier Maintenance | Weekly (Sunday 08:00 UTC) | Update dossiers, archive stale findings |

## Handoff Protocol

The Research Agent routes signals to other agents via the shared handoff directory (`/data/handoffs/`):

| Target | Signal Types |
|--------|-------------|
| `main` (OWL) | Daily digests, urgent signals, cross-cutting research |
| `coder` | Research-backed feature requests, tech feasibility |
| `qa` | Known issues, upstream bug reports, test-relevant findings |
| `subconscious` | Raw patterns, anomalies, long-term trend data |

Handoff files are JSON with schema version 1.0, including source citations, confidence ratings, and tags.

## Confidence Levels

| Level | Criteria |
|-------|----------|
| **HIGH** | Multiple independent sources, peer-reviewed, reproducible |
| **MEDIUM** | Single credible source, consistent with known evidence |
| **LOW** | Single unverified source, preliminary findings |
| **UNVERIFIED** | Claim exists but no source found; flagged for follow-up |

## Research Sources

- **arXiv** — cs.AI, cs.CL, cs.LG, cs.CV, cs.NE, stat.ML
- **RSS Feeds** — 30+ feeds (ML blogs, AI labs, newsletters, tech news)
- **Semantic Scholar** — Paper search and citation graphs
- **Web Search** — Structured query templates by topic area

See `skills/research-agent/references/feed-list.md` for the full feed list.
See `skills/research-agent/references/search-queries.md` for query templates.

## Configuration

Key settings in `config.yaml`:

```yaml
agent:
  port: 3001

provider:
  model: "openrouter/anthropic/claude-sonnet-4-20250514"

research:
  vault_path: "/data/.hermes/research/vault"
  scan_interval_hours: 6
  daily_digest_hour: "06:00"  # UTC
  max_sources_per_finding: 10
```

## Environment Variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `OPENROUTER_API_KEY` | Yes | OpenRouter API key |
| `GATEWAY_PORT` | No | Override gateway port (default: 3001) |
| `AGENT_NAME` | No | Agent identifier (default: research) |
| `TZ` | No | Timezone (default: UTC) |

## Integration with Hermes Crew

This agent is designed to run as part of the Hermes multi-agent crew. In `docker-compose.yml`:

```yaml
hermes-research:
  build:
    context: ./hermes-research
    container_name: hermes-research
    ports:
      - "3001:3001"
    environment:
      GATEWAY_PORT: 3001
      OPENROUTER_API_KEY: ${OPENROUTER_API_KEY}
    volumes:
      - shared-handoffs:/data/handoffs:rw
      - research-data:/data/.hermes:rw
```

## Operating Principles

1. **Evidence before conclusion** — Gather, then synthesize, then report
2. **Source everything** — Every finding links to a source
3. **Tag and categorize** — All entries tagged by topic, date, confidence
4. **Route signals, not noise** — Distinguish significant findings from chatter
5. **Maintain the vault** — The evidence vault is the primary responsibility
6. **Hand off cleanly** — Structured, complete context — not raw dumps
7. **Respect scope** — Inform decisions; don't make them

## License

Part of the Hermes Agent ecosystem by Nous Research.
