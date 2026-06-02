# Hermes Vagrant — One VM per Agent

Full isolation. Each Hermes agent runs in its own Ubuntu 24.04 VM with its own SOUL.md, config, skills, cron jobs, and gateway port.

## Architecture

```
Host (Ubuntu VPS — VT-x required)
├── Vagrant + VirtualBox/libvirt
│
│  ┌─────────────────────────────────────────────────────────┐
│  │ Private Network: 192.168.56.0/24                       │
│  │                                                         │
│  │  hermes-main       192.168.56.10  :3000  (Slack GW)    │
│  │  hermes-research   192.168.56.11  :3001  (Evidence)    │
│  │  hermes-subconscious 192.168.56.12 :3002  (Patterns)   │
│  │  hermes-coder      192.168.56.13  :3003  (Build)      │
│  │  hermes-qa         192.168.56.14  :3004  (Quality)    │
│  │  hermes-alim       192.168.56.15  :3005  (Islamic)    │
│  │                                                         │
│  │  Shared: /data/handoffs/ — agent-to-agent messages      │
│  └─────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Clone
git clone https://github.com/bakasa/hermes-vagrant.git
cd hermes-vagrant

# 2. Install Vagrant + provider (one-time)
sudo bash scripts/install-vagrant.sh

# 3. Configure each agent
for agent in main research subconscious coder qa alim; do
  cp agents/$agent/soul/.env.example agents/$agent/soul/.env
  # Edit agents/$agent/soul/.env with your API keys
done

# 4. Start all agents
bash scripts/hermes-vm.sh up

# 5. Check health
bash scripts/hermes-vm.sh health
```

## Requirements

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 4 cores (VT-x) | 8+ cores |
| RAM | 14 GB | 32 GB |
| Disk | 30 GB free | 60+ GB free |
| OS | Ubuntu 22.04+ | Ubuntu 24.04 LTS |

## VM Specs (each Agent)

- **Base**: Ubuntu 24.04 LTS (ubuntu/noble64)
- **RAM**: 2 GB
- **CPUs**: 2 cores
- **Disk**: 10 GB (dynamically allocated)
- **Network**: Private + port forwarded

## Command Reference

```bash
# Start/Stop
bash scripts/hermes-vm.sh up              # Start all agents
bash scripts/hermes-vm.sh up main         # Start specific agent
bash scripts/hermes-vm.sh halt            # Stop all
bash scripts/hermes-vm.sh halt coder      # Stop specific

# Access
bash scripts/hermes-vm.sh ssh main        # SSH into agent VM
bash scripts/hermes-vm.sh logs research   # Tail gateway logs

# Maintenance
bash scripts/hermes-vm.sh status          # Show VM status
bash scripts/hermes-vm.sh health          # Health check all gateways
bash scripts/hermes-vm.sh doctor          # Diagnose issues
bash scripts/hermes-vm.sh provision main  # Re-provision agent
bash scripts/hermes-vm.sh destroy all     # Destroy all VMs
```

## Directory Structure

```
hermes-vagrant/
├── Vagrantfile                    # VM definitions (6 agents)
├── scripts/
│   ├── install-vagrant.sh         # One-time host setup
│   └── hermes-vm.sh               # Day-to-day control
├── agents/
│   ├── main/
│   │   ├── soul/
│   │   │   ├── SOUL.md            # Agent identity
│   │   │   ├── config.yaml        # Hermes config
│   │   │   ├── .env.example       # Secrets template
│   │   │   └── .gitignore
│   │   ├── skills/                # Agent-specific skills
│   │   ├── cron/                  # Scheduled jobs
│   │   └── scripts/               # Helper scripts
│   ├── research/
│   ├── subconscious/
│   ├── coder/
│   ├── qa/
│   └── alim/
└── README.md
```

## Agent Communication

Agents communicate via **shared filesystem** (`/data/handoffs/`), synced between all VMs:

```
/data/handoffs/
├── from-main-to-coder/       # Main assigns tasks to Coder
├── from-coder-to-qa/         # Coder submits PRs for review
├── from-qa-to-coder/         # QA sends fix feedback
├── from-qa-to-main/          # QA reports quality status
├── from-research-to-main/    # Research sends strategic signals
├── from-research-to-subconscious/  # Research flags weak patterns
├── from-subconscious-to-main/      # Subconscious sends insights
└── ...
```

## Networking

| Agent | VM IP | Host Port | Gateway URL |
|---|---|---|---|
| main | 192.168.56.10 | 3000 | http://localhost:3000 |
| research | 192.168.56.11 | 3001 | http://localhost:3001 |
| subconscious | 192.168.56.12 | 3002 | http://localhost:3002 |
| coder | 192.168.56.13 | 3003 | http://localhost:3003 |
| qa | 192.168.56.14 | 3004 | http://localhost:3004 |
| alim | 192.168.56.15 | 3005 | http://localhost:3005 |

SSH access inside VMs: `vagrant ssh hermes-<agent>`
Hermes home: `/home/hermes/.hermes/`

## Troubleshooting

```bash
# Diagnose
bash scripts/hermes-vm.sh doctor

# Check VM status
bash scripts/hermes-vm.sh status

# View gateway logs
bash scripts/hermes-vm.sh logs main

# Re-provision an agent
bash scripts/hermes-vm.sh provision main

# Common issues:
# - "VT-x not available": Ensure nested virt is enabled in BIOS
# - "vagrant up fails": Run `bash scripts/install-vagrant.sh`
# - "Gateway not starting": Check `journalctl -u hermes-gateway -n 50`
```

## Related Repos

Each agent's skills and SOUL.md are developed in their own repo:

| Agent | Repo |
|---|---|
| Main (OWL) | `github.com/bakasa/hermes-main` |
| Research | `github.com/bakasa/hermes-research` |
| Subconscious | `github.com/bakasa/hermes-subconscious` |
| Coder | `github.com/bakasa/hermes-coder` |
| QA | `github.com/bakasa/hermes-qa` |
| Alim | `github.com/bakasa/hermes-alim` |
| Crew Config | `github.com/bakasa/hermes-config` |
| Docker Deploy | `github.com/bakasa/hermes-crew` |
| Vagrant Deploy | `github.com/bakasa/hermes-vagrant` (this repo) |

## License

MIT
