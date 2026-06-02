#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# bootstrap.sh — Provision a single Hermes agent VM
# Called by Vagrant shell provisioner with:
#   $1  agent name    (e.g. "main")
#   $2  gateway port  (e.g. "3000")
#   $3  private IP    (e.g. "192.168.56.10")
#
# This script runs as ROOT inside the VM.
# ═══════════════════════════════════════════════════════════

set -euo pipefail

AGENT_NAME="${1:?Usage: bootstrap.sh <agent-name> <port> <ip>}"
AGENT_PORT="${2:?Usage: bootstrap.sh <agent-name> <port> <ip>}"
AGENT_IP="${3:?Usage: bootstrap.sh <agent-name> <port> <ip>}"

HERMES_USER="hermes"
HERMES_HOME="/home/${HERMES_USER}"
HERMES_PROFILE="${HERMES_HOME}/.hermes"

echo "═══════════════════════════════════════════════════════════"
echo "  Bootstrapping Hermes Agent: ${AGENT_NAME}"
echo "  Port: ${AGENT_PORT}  IP: ${AGENT_IP}"
echo "═══════════════════════════════════════════════════════════"

# ────────────────────────────────────────────────────────────
# 1. System update & base packages
# ────────────────────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive

echo "[1/8] Updating system..."
apt-get update -qq
apt-get upgrade -y -qq

echo "[2/8] Installing dependencies..."
apt-get install -y -qq \
  curl wget git ca-certificates unzip jq \
  python3 python3-pip python3-venv python3-dev \
  build-essential \
  sudo \
  systemd \
  ufw \
  htop \
  tmux \
  rsync \
  >> /tmp/bootstrap.log 2>&1

# ────────────────────────────────────────────────────────────
# 2. Create hermes user (if not already via synced folder mount)
# ────────────────────────────────────────────────────────────
echo "[3/8] Setting up ${HERMES_USER} user..."
if ! id "${HERMES_USER}" &>/dev/null; then
  useradd -m -s /bin/bash "${HERMES_USER}"
  echo "${HERMES_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"${HERMES_USER}"
  chmod 0440 /etc/sudoers.d/"${HERMES_USER}"
  loginctl enable-linger "${HERMES_USER}" 2>/dev/null || true
fi

# Ensure synced folder ownership
chown -R "${HERMES_USER}:${HERMES_USER}" "${HERMES_HOME}"
chown -R "${HERMES_USER}:${HERMES_USER}" "${HERMES_PROFILE}" 2>/dev/null || true

# ────────────────────────────────────────────────────────────
# 3. Install Hermes Agent CLI
# ────────────────────────────────────────────────────────────
echo "[4/8] Installing Hermes Agent CLI..."
sudo -u "${HERMES_USER}" bash -c '
  # Install Hermes CLI via official installer
  if ! command -v hermes &>/dev/null; then
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | sh 2>&1
    # Ensure hermes is on PATH for this user
    if ! echo "$PATH" | tr ":" "\n" | grep -q ".hermes/bin"; then
      echo "export PATH=\"\$HOME/.hermes/bin:\$PATH\"" >> "$HOME/.bashrc"
    fi
  fi
' >> /tmp/bootstrap.log 2>&1

# Source hermes path for the rest of this script
export PATH="${HERMES_HOME}/.hermes/bin:${PATH}"

# ────────────────────────────────────────────────────────────
# 4. Validate synced folder contents
# ────────────────────────────────────────────────────────────
echo "[5/8] Validating agent configuration..."

# Ensure required files exist (placeholders if missing)
for required_file in SOUL.md config.yaml; do
  if [ ! -f "${HERMES_PROFILE}/${required_file}" ]; then
    echo "WARNING: ${required_file} not found in synced folder."
    echo "         Creating minimal placeholder..."
    case "${required_file}" in
      SOUL.md)
        cat > "${HERMES_PROFILE}/SOUL.md" <<SOUL
# SOUL.md — ${AGENT_NAME}

_Your agent identity goes here._

## Personality
- Define your personality traits here.

## Role
- Agent: ${AGENT_NAME}
- Port: ${AGENT_PORT}
- IP: ${AGENT_IP}
SOUL
        ;;
      config.yaml)
        cat > "${HERMES_PROFILE}/config.yaml" <<CFG
model:
  provider: openrouter
  default: openrouter/owl-alpha

gateway:
  strict: false
CFG
        ;;
    esac
    chown "${HERMES_USER}:${HERMES_USER}" "${HERMES_PROFILE}/${required_file}"
  fi
done

# Ensure required directories exist
for required_dir in skills cron memories sessions; do
  if [ ! -d "${HERMES_PROFILE}/${required_dir}" ]; then
    mkdir -p "${HERMES_PROFILE}/${required_dir}"
    chown "${HERMES_USER}:${HERMES_USER}" "${HERMES_PROFILE}/${required_dir}"
  fi
done

# Create initial MEMORY.md and USER.md if absent
[ ! -f "${HERMES_PROFILE}/MEMORY.md" ] && \
  echo "# MEMORY.md — ${AGENT_NAME}" > "${HERMES_PROFILE}/MEMORY.md" && \
  chown "${HERMES_USER}:${HERMES_USER}" "${HERMES_PROFILE}/MEMORY.md"

[ ! -f "${HERMES_PROFILE}/USER.md" ] && \
  echo "# USER.md — ${AGENT_NAME}" > "${HERMES_PROFILE}/USER.md" && \
  chown "${HERMES_USER}:${HERMES_USER}" "${HERMES_PROFILE}/USER.md"

# ────────────────────────────────────────────────────────────
# 5. Create handoffs directory
# ────────────────────────────────────────────────────────────
echo "[6/8] Setting up handoffs directory..."
mkdir -p /data/handoffs
chown -R "${HERMES_USER}:${HERMES_USER}" /data/handoffs
chmod -R 775 /data/handoffs

# ────────────────────────────────────────────────────────────
# 6. Configure firewall (UFW)
# ────────────────────────────────────────────────────────────
echo "[7/8] Configuring firewall..."
ufw --force reset >> /tmp/bootstrap.log 2>&1
ufw default deny incoming >> /tmp/bootstrap.log 2>&1
ufw default allow outgoing >> /tmp/bootstrap.log 2>&1
ufw allow from 192.168.56.0/24 to any >> /tmp/bootstrap.log 2>&1
ufw allow ${AGENT_PORT}/tcp comment "Hermes ${AGENT_NAME} gateway" >> /tmp/bootstrap.log 2>&1
ufw --force enable >> /tmp/bootstrap.log 2>&1

# ────────────────────────────────────────────────────────────
# 7. Install systemd service for Hermes gateway
# ────────────────────────────────────────────────────────────
echo "[8/8] Installing Hermes gateway systemd service..."

# Write the systemd unit file
cat > /etc/systemd/system/hermes-gateway.service <<EOF
[Unit]
Description=Hermes Gateway — ${AGENT_NAME} (port ${AGENT_PORT})
Documentation=https://hermes-agent.nousresearch.com/docs
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${HERMES_USER}
Group=${HERMES_USER}
WorkingDirectory=${HERMES_HOME}
ExecStart=/bin/bash -c 'export PATH="${HERMES_HOME}/.hermes/bin:\${PATH}"; \\
  export HOME="${HERMES_HOME}"; \\
  export HERMES_HOME="${HERMES_PROFILE}"; \\
  exec hermes gateway start --port ${AGENT_PORT}'
ExecStop=/bin/kill -SIGTERM \$MAINPID
Restart=on-failure
RestartSec=10
StartLimitBurst=5
StartLimitIntervalSec=60
StandardOutput=journal
StandardError=journal
SyslogIdentifier=hermes-${AGENT_NAME}
# Hardening
NoNewPrivileges=false
ProtectSystem=false
PrivateTmp=false

[Install]
WantedBy=multi-user.target
EOF

# Also write a user-level loginctl linger for non-login sessions
cat > /etc/systemd/user/hermes-gateway-user.service <<EOF
[Unit]
Description=Hermes Gateway (User) — ${AGENT_NAME} (port ${AGENT_PORT})
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${HERMES_HOME}
ExecStart=/bin/bash -c 'export PATH="${HERMES_HOME}/.hermes/bin:\${PATH}"; \\
  export HOME="${HERMES_HOME}"; \\
  export HERMES_HOME="${HERMES_PROFILE}"; \\
  exec hermes gateway start --port ${AGENT_PORT}'
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload >> /tmp/bootstrap.log 2>&1
systemctl enable hermes-gateway.service >> /tmp/bootstrap.log 2>&1

# Start the gateway
systemctl start hermes-gateway.service >> /tmp/bootstrap.log 2>&1 || {
  echo "WARNING: Gateway did not start automatically."
  echo "         Check logs with: journalctl -u hermes-gateway.service"
  echo "         The synced folder may not have a valid SOUL.md/config.yaml yet."
}

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Bootstrap complete!"
echo ""
echo "  Agent:   ${AGENT_NAME}"
echo "  Port:    ${AGENT_PORT}"
echo "  IP:      ${AGENT_IP}"
echo "  Profile: ${HERMES_PROFILE}"
echo ""
echo "  Management commands (run as root or with sudo):"
echo "    systemctl status hermes-gateway    # Check status"
echo "    journalctl -u hermes-gateway -f    # Follow logs"
echo "    systemctl restart hermes-gateway   # Restart"
echo "═══════════════════════════════════════════════════════════"
