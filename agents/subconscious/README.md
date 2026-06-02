# Subconscious Agent — Quick Reference

## What Is This?

The **Subconscious Agent** is a background pattern processor in the Hermes multi-agent architecture. It receives weak signals, incubates hypotheses over time, detects cross-domain connections, and routes insights to the Main agent.

```
Research ──signals──▶ Subconscious ──insights──▶ Main
                         │
                    Main ──overflow──▶ Subconscious
```

**Port:** 3002

## Architecture

| Component | Path | Purpose |
|-----------|------|---------|
| Identity | `SOUL.md` | Agent personality and operating principles |
| Config | `config.yaml` | OpenRouter provider, model, tools, paths |
| Skill | `skills/subconscious-agent/SKILL.md` | Full pipeline documentation |
| Cron | `cron/jobs.json` | Drift scan every 4 hours |
| Dockerfile | `Dockerfile` | Container definition, exposes port 3002 |

## The Pipeline

```
1. Signal Intake     ← From Main, Research, drift scans
        │
2. Incubation        ← Hold signals, wait for resonance (14-day half-life)
        │
3. Pattern Detection ← Cross-domain, convergence, temporal rhythms
        │
4. Handoff to Main   ← When hypothesis reaches confidence threshold
```

## Hypothesis Lifecycle

```
new → incubating → ready-to-surface → surfaced → confirmed/decayed
```

| Status | Meaning |
|--------|---------|
| `incubating` | Gathering signals, not yet ready |
| `ready-to-surface` | ≥3 signals, pattern detected, handoff prepared |
| `surfaced` | Delivered to Main |
| `confirmed` | Main validated the hypothesis |
| `decayed` | No reinforcement for 14+ days |

## Confidence Levels

| Level | Signals | Voice |
|-------|---------|-------|
| Low | 1-3, single domain | "I have a vague sense that..." |
| Medium | 4-6, possible cross-domain | "There's a pattern here that..." |
| High | 7+ cross-domain | "Multiple independent signals suggest..." |

## Directory Structure (at runtime)

```
~/.hermes/profiles/subconscious/
├── config.yaml
├── SOUL.md
├── skills/
│   └── subconscious-agent/
│       └── SKILL.md
├── cron/
│   └── jobs.json
├── memories/
│   ├── hypotheses.md          # Active hypothesis backlog
│   ├── drift-scan-log.md      # Scan history
│   └── signals/               # Individual signal files
│       └── YYYY-MM-DD-*.md
├── handoffs/
│   └── to-main/               # Insights routed to Main
│       └── YYYY-MM-DD-*.md
└── logs/
    └── agent.log
```

## Getting Started

### Run Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Run the gateway
hermes-agent gateway --config config.yaml --port 3002
```

### Run with Docker

```bash
# Build
docker build -t hermes-subconscious .

# Run
docker run -d \
  --name subconscious \
  -p 3002:3002 \
  -v ~/.hermes/profiles/subconscious:/home/agent/.hermes/profiles/subconscious \
  hermes-subconscious
```

### Verify Health

```bash
curl http://localhost:3002/health
```

## Drift Scan Schedule

The cron job fires **every 4 hours** (`0 */4 * * *`):

1. **Signal intake** — collect new signals from intake paths
2. **Incubation** — check resonance, reinforce or decay hypotheses
3. **Pattern detection** — hunt for cross-domain/convergence/temporal patterns
4. **Handoff** — promote and deliver ready hypotheses to Main
5. **Hygiene** — update backlog, archive decayed items

## Handoff Format

```markdown
# Handoff to Main — [hypothesis name]
- Type: hypothesis | pattern | question
- Confidence: low | medium | high

## Summary
[Subconscious voice — metaphorical, hedged]

## Evidence
- Signal 1: ...
- Signal 2: ...

## What If
[The speculative core — stated as a question]

## Suggested Action
[Low-pressure suggestion]
```

## Design Principles

- **Never state hypotheses as facts.** Every claim is tagged with confidence.
- **Slow and reflective.** This agent thinks in days, not seconds.
- **Comfortable with ambiguity.** Contradictory hypotheses can coexist.
- **Metaphor-first.** Analogies before abstractions.
- **Silence is okay.** If there's nothing to say, say nothing.

---

_Part of the Hermes multi-agent architecture. See the Main agent's docs for system-wide protocols._
