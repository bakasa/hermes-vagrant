#!/usr/bin/env bash
# add-agent.sh — Create a new agent from template
# Usage: bash scripts/add-agent.sh <name> [port]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

AGENT_NAME="${1:?Usage: add-agent.sh <name> [port]}"
AGENT_PORT="${2:-3006}"
AGENT_ROLE="${AGENT_NAME^} Agent"
TEMPLATE_DIR="templates/new-agent"
AGENT_DIR="agents/$AGENT_NAME"

# Validate name (lowercase, hyphens, no spaces)
if [[ ! "$AGENT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Error: name must be lowercase, start with letter, use hyphens"
  exit 1
fi

if [ -d "$AGENT_DIR" ]; then
  echo "Error: agents/$AGENT_NAME exists"
  exit 1
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: $TEMPLATE_DIR/ missing"
  exit 1
fi

echo "Creating agent: $AGENT_NAME (port $AGENT_PORT)"

# Copy from template
cp -r "$TEMPLATE_DIR" "$AGENT_DIR"

# Replace {{PLACEHOLDER}} tokens (safe — no Docker ARG collision)
for f in Dockerfile SOUL.md config.yaml; do
  if [ -f "$AGENT_DIR/$f" ]; then
    sed -e "s/{{AGENT_NAME}}/$AGENT_NAME/g" \
        -e "s/{{AGENT_PORT}}/$AGENT_PORT/g" \
        -e "s/{{AGENT_ROLE}}/$AGENT_ROLE/g" \
        -i "$AGENT_DIR/$f"
  fi
done

# Create empty dirs
mkdir -p "$AGENT_DIR/skills" "$AGENT_DIR/cron"

# .gitignore
printf '%s\n' "# Secrets — never commit" ".env" "*.pem" "*.key" \
  "google_credentials.json" "google_token.json" > "$AGENT_DIR/.gitignore"

# .env.example
cat > "$AGENT_DIR/.env.example" <<ENVEOF
# Environment for $AGENT_NAME agent
# Copy to .env and fill in values — NEVER commit .env

OPENROUTER_API_KEY=
GITH...echo ""
echo "Agent created: $AGENT_DIR/"
echo ""
echo "Next steps:"
echo "  1. Edit $AGENT_DIR/SOUL.md — define identity and role"
echo "  2. Edit $AGENT_DIR/config.yaml — set model, tools, paths"
echo "  3. Add skills to $AGENT_DIR/skills/ (create SKILL.md)"
echo "  4. Add cron jobs to $AGENT_DIR/cron/jobs.json"
echo "  5. Add service to docker-compose.yml (copy existing block, change name/port/context)"
echo "  6. docker compose up -d $AGENT_NAME"
echo ""
echo "Docker Compose service template:"
echo ""
cat <<COMPOSE
  hermes-${AGENT_NAME}:
    build:
      context: ./agents/${AGENT_NAME}
      dockerfile: Dockerfile
    container_name: hermes-${AGENT_NAME}
    hostname: hermes-${AGENT_NAME}
    ports:
      - "${AGENT_PORT}:${AGENT_PORT}"
    environment:
      - TZ=UTC
      - AGENT_NAME=${AGENT_NAME}
      - GATEWAY_PORT=${AGENT_PORT}
      - HERMES_HOME=/data/.hermes
      - OPENROUTER_API_KEY=\${OP...-}
      - GITHUB_TOKEN=\${GI...-}
    volumes:
      - shared-handoffs:/data/handoffs:rw
      - ${AGENT_NAME}-data:/data/.hermes:rw
    networks:
      - hermes-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:${AGENT_PORT}/health || exit 0"]
      interval: 90s
      timeout: 10s
      retries: 3
COMPOSE

echo ""
echo "Then add '${AGENT_NAME}-data:' under volumes: section."
