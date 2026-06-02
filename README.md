# Hermes — Multi-Agent System

One repo. Each Hermes agent as a subdirectory. Docker Compose orchestrates them as separate containers that communicate via shared volumes.

## Quick Start

```bash
# 1. Clone
git clone https://github.com/bakasa/hermes-vagrant.git
cd hermes-vagrant

# 2. Configure secrets
cp .env.example .env
# Edit .env with your API keys (NEVER commit .env)

# 3. Start all agents
docker compose up -d

# 4. Check health
docker compose ps
docker compose logs -f main
```

## Structure

```
hermes-vagrant/
├── docker-compose.yml          # Orchestration (ports, volumes, networks)
├── Dockerfile.base             # Shared base image (all agents inherit)
├── .env.example                # Secrets template (copy to .env, never commit)
├── Vagrantfile                 # VM-based deploy (alternative to Docker)
│
├── agents/
│   ├── main/                   # OWL Coordinator + Slack Gateway (:3000)
│   │   ├── Dockerfile
│   │   ├── SOUL.md
│   │   ├── config.yaml
│   │   ├── skills/             # coordination, dev-house-ops, perp-trading
│   │   └── cron/               # Scheduled jobs
│   ├── research/               # Evidence Vault (:3001)
│   ├── subconscious/           # Pattern Incubator (:3002)
│   ├── coder/                  # Build & Ship via Claude Code (:3003)
│   │   └── skills/             # coder-agent
│   ├── qa/                     # Quality Gate (:3004)
│   └── alim/                   # Islamic Studies Companion (:3005)
│       └── knowledge/          # Quran, hadith, fiqh, seerah, etc.
│
├── templates/
│   └── new-agent/              # Blueprint for adding agents
│
└── scripts/
    ├── setup.sh                # Detect and validate agents
    └── add-agent.sh            # Scaffold a new agent from template
```

## Architecture

```
                        ┌──────────────────────────────────────┐
                        │         Host Machine                 │
                        │                                      │
                        │   docker compose up -d               │
                        │          │                            │
                        │   ┌──────┴──────────────────────┐    │
                        │   │     hermes-net (bridge)      │    │
                        │   │                               │    │
                        │   │  :3000  hermes-main (OWL)     │    │
                        │   │  :3001  hermes-research       │    │
                        │   │  :3002  hermes-subconscious   │    │
                        │   │  :3003  hermes-coder          │    │
                        │   │  :3004  hermes-qa             │    │
                        │   │  :3005  hermes-alim           │    │
                        │   │                               │    │
                        │   └──────────┬────────────────────┘    │
                        │              │                          │
                        │    shared-handoffs (volume)             │
                        │    /data/handoffs/                     │
                        └──────────────────────────────────────┘
```

Agents communicate via **shared volume** (`/data/handoffs/`). Each agent has its own **named volume** for persistent data (`/data/.hermes/`). Containerized isolation means no agent can see another's secrets or memory.

## Each Agent Gets

| Resource | Isolation |
|----------|-----------|
| Container | Separate process, own filesystem |
| Volume | Named volume for `/data/.hermes/` |
| Port | Dedicated gateway port (3000-3005) |
| SOUL.md | Own identity, personality, role |
| Skills | Own skill directory |
| Cron | Own scheduled jobs |
| Dockerfile | Own runtime environment |

## Adding a New Agent

```bash
# 1. Scaffold from template
bash scripts/add-agent.sh my-new-agent 3006

# 2. Customize identity
vim agents/my-new-agent/SOUL.md
vim agents/my-new-agent/config.yaml

# 3. Add skills
mkdir agents/my-new-agent/skills/my-skill/
# Create SKILL.md

# 4. Add to docker-compose.yml (copy an existing service block, change name/port/context/volumes)

# 5. Start
docker compose up -d my-new-agent
```

Existing agents are **never touched** when you add a new one.

## Deploy Options

### Docker Compose (recommended — works anywhere)
```bash
docker compose up -d              # All agents
docker compose up -d main coder   # Subset
docker compose logs -f main       # Watch logs
docker compose down               # Stop all
```

### Vagrant (full VM isolation — needs VT-x/nested virt)
```bash
vagrant up                        # Start all VMs
vagrant up main                   # Start specific
vagrant ssh main                  # SSH into agent VM
```

## Requirements

| Resource | Docker | Vagrant (all 6 VMs) |
|----------|--------|---------------------|
| CPU | 4 cores | 8+ cores + VT-x |
| RAM | 8 GB | 14+ GB |
| Disk | 10 GB | 30+ GB |
| OS | Linux/macOS/Windows | Linux + VirtualBox/libvirt |

## Port Map

| Agent | Port | Purpose |
|-------|------|---------|
| main | 3000 | OWL Coordinator, Slack Gateway |
| research | 3001 | Evidence Vault, AI scanning |
| subconscious | 3002 | Pattern incubation |
| coder | 3003 | Claude Code delegation, PRs |
| qa | 3004 | Quality gate, reviews |
| alim | 3005 | Islamic studies companion |

## Secrets

Create `.env` from `.env.example`:

```bash
cp .env.example .env
# Fill in: OPENROUTER_API_KEY, GITHUB_TOKEN, SLACK_BOT_TOKEN, SLACK_APP_TOKEN
```

**NEVER commit `.env`.** All agent secrets go into their own `.env` file at `agents/<name>/.env` (gitignored).

## License

MIT
