# ═══════════════════════════════════════════════════════════════════════════
# Hermes Multi-Agent Vagrant — One VM per Agent
# ═══════════════════════════════════════════════════════════════════════════
#
# Usage:
#   vagrant up              # Start all agent VMs
#   vagrant up main         # Start specific agent
#   vagrant ssh main        # SSH into agent VM
#   vagrant halt            # Stop all VMs
#   vagrant destroy         # Destroy all VMs
#   vagrant provision main  # Re-provision agent
#
# Requirements:
#   - Vagrant 2.4+
#   - VirtualBox 7+ or libvirt/QEMU
#   - ~12GB RAM minimum for all 6 VMs
#
# Architecture:
#   ┌─────────────────────────────────────────────────────────┐
#   │ Host (Ubuntu/Railway VPS — VT-x required)               │
#   │                                                         │
#   │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
#   │  │ hermes-  │ │ hermes-  │ │ hermes-  │ │ hermes-  │  │
#   │  │ main     │ │ research │ │ subcons. │ │ coder    │  │
#   │  │ :3000    │ │ :3001    │ │ :3002    │ │ :3003    │  │
#   │  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
#   │  ┌──────────┐ ┌──────────┐                             │
#   │  │ hermes-  │ │ hermes-  │                             │
#   │  │ qa       │ │ alim     │                             │
#   │  │ :3004    │ │ :3005    │                             │
#   │  └──────────┘ └──────────┘                             │
#   └─────────────────────────────────────────────────────────┘

Vagrant.configure("2") do |config|
  ═══════════════════════════════════════════════════════════════════════════
  # Base box: Ubuntu 24.04 LTS
  ═══════════════════════════════════════════════════════════════════════════
  config.vm.box = "ubuntu/noble64"
  config.vm.box_version = ">= 20240401"
  config.vm.box_check_update = true

  ═══════════════════════════════════════════════════════════════════════════
  # SSH Configuration
  ═══════════════════════════════════════════════════════════════════════════
  config.ssh.forward_agent = true
  config.ssh.insert_key = true

  ═══════════════════════════════════════════════════════════════════════════
  # Agent Definitions
  ═══════════════════════════════════════════════════════════════════════════
  AGENTS = {
    "main"          => { ip: "192.168.56.10", port: 3000, ram: 2048, cpus: 2 },
    "research"      => { ip: "192.168.56.11", port: 3001, ram: 2048, cpus: 2 },
    "subconscious"  => { ip: "192.168.56.12", port: 3002, ram: 2048, cpus: 2 },
    "coder"         => { ip: "192.168.56.13", port: 3003, ram: 2048, cpus: 2 },
    "qa"            => { ip: "192.168.56.14", port: 3004, ram: 2048, cpus: 2 },
    "alim"          => { ip: "192.168.56.15", port: 3005, ram: 2048, cpus: 2 },
  }

  AGENTS.each do |name, cfg|
    vm_name = "hermes-#{name}"

    config.vm.define vm_name do |agent|
      agent.vm.hostname = vm_name

      ── Network ──
      agent.vm.network "private_network", ip: cfg[:ip]
      agent.vm.network "forwarded_port", guest: cfg[:port], host: cfg[:port], auto_correct: true

      ── Synced folders ──
      # Agent identity & config → guest Hermes home
      agent.vm.synced_folder "./agents/#{name}/soul/", "/home/hermes/.hermes/", create: true
      # Agent skills → guest skills directory
      agent.vm.synced_folder "./agents/#{name}/skills/", "/home/hermes/.hermes/skills/", create: true
      # Agent cron jobs → guest cron directory
      agent.vm.synced_folder "./agents/#{name}/cron/", "/home/hermes/.hermes/cron/", create: true
      # Agent scripts
      agent.vm.synced_folder "./agents/#{name}/scripts/", "/home/hermes/scripts/", create: true
      # Handoff directory — shared between all VMs
      agent.vm.synced_folder "/data/handoffs", "/data/handoffs", create: true

      ── VirtualBox Provider ──
      agent.vm.provider "virtualbox" do |vb|
        vb.name = vm_name
        vb.memory = cfg[:ram]
        vb.cpus = cfg[:cpus]
        vb.gui = false
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        vb.customize ["modifyvm", :id, "--audio", "none"]
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--vram", "16"]
      end

      ── libvirt Provider (fallback) ──
      agent.vm.provider "libvirt" do |lv|
        lv.memory = cfg[:ram]
        lv.cpus = cfg[:cpus]
        lv.nested = true
        lv.cpu_mode = "host-passthrough"
        lv.disk_bus = "virtio"
        lv.nic_model_type = "virtio"
      end

      ═══════════════════════════════════════════════════════════════════════
      # Provisioning — Base
      ═══════════════════════════════════════════════════════════════════════
      agent.vm.provision "shell", inline: <<-SHELL
        set -euo pipefail

        echo "═══ [#{name}] Provisioning #{vm_name} ═══"

        # System update
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq \
          curl wget git jq unzip \
          python3 python3-pip python3-venv \
          build-essential software-properties-common \
          apt-transport-https ca-certificates gnupg \
          nginx certbot python3-certbot-nginx \
          htop tree vim

        # Create hermes user
        if ! id "hermes" &>/dev/null; then
          useradd -m -s /bin/bash hermes
          echo "hermes ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/hermes
          chmod 0440 /etc/sudoers.d/hermes
        fi

        # Setup Hermes home
        mkdir -p /home/hermes/.hermes/{skills,cron,research,memories,logs}
        cp -r /home/vagrant/Vagrantfile/soul/* /home/hermes/.hermes/ 2>/dev/null || true
        chown -R hermes:hermes /home/hermes

        echo "═══ [#{name}] Base provisioning complete ═══"
      SHELL

      ═══════════════════════════════════════════════════════════════════════
      # Provisioning — Hermes Agent
      ═══════════════════════════════════════════════════════════════════════
      agent.vm.provision "shell", inline: <<-SHELL
        set -euo pipefail
        HERMES_HOME="/home/hermes/.hermes"

        echo "═══ [#{name}] Installing Hermes Agent CLI ═══"

        # Install hermes CLI (official installer)
        if ! command -v hermes &>/dev/null; then
          sudo -u hermes bash -c 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash'
        fi

        # Write config.yaml for this agent
        sudo -u hermes bash -c "cat > #{HERMES_HOME}/config.yaml" <<EOF
agent:
  name: #{name}
  role: "#{name == 'main' ? 'Main Coordinator (OWL)' : name.capitalize + ' Agent'}"
  soul: "#{HERMES_HOME}/SOUL.md"

gateway:
  port: #{cfg[:port]}
  bind: "0.0.0.0"
  workers: 4

model:
  provider: "openrouter"
  default: "openrouter/auto"
  fallback: "openrouter/auto"

paths:
  skills: "#{HERMES_HOME}/skills/"
  cron: "#{HERMES_HOME}/cron/"
  memories: "#{HERMES_HOME}/memories/"
  research: "#{HERMES_HOME}/research/"
  handoffs: "/data/handoffs/"

logging:
  level: "info"
  file: "#{HERMES_HOME}/logs/hermes.log"

security:
  tirith_enabled: false
  approvals_mode: "off"
EOF

        # Write systemd service for gateway
        cat > /etc/systemd/system/hermes-gateway.service <<EOF
[Unit]
Description=Hermes Gateway — #{name} Agent
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=hermes
Group=hermes
WorkingDirectory=/home/hermes
ExecStart=/usr/local/bin/hermes gateway start --port #{cfg[:port]} --config #{HERMES_HOME}/config.yaml
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=hermes-#{name}

# Security hardening
NoNewPrivileges=false
ProtectSystem=false
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable hermes-gateway
        # Don't start yet — it needs API keys in .env
        # Agent owner sets up .env, then: sudo systemctl start hermes-gateway

        echo "═══ [#{name}] Hermes installation complete ═══"
      SHELL
    end
  end
end
