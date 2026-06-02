#!/usr/bin/env bash
# add-agent.sh — Create a new agent from template
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"
AGENT_NAME="${1:?Usage: add-agent.sh <name> [port]}"
AGENT_PORT="${2:-3006}"
TEMPLATE_DIR="templates/new-agent"
AGENT_DIR="agents/$AGENT_NAME"
if [[ ! "$AGENT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then echo "Error: name must be lowercase, start with letter, use hyphens"; exit 1; fi
if [ -d "$AGENT_DIR" ]; then echo "Error: agents/$AGENT_NAME exists"; exit 1; fi
if [ ! -d "$TEMPLATE_DIR" ]; then echo "Error: $TEMPLATE_DIR/ missing"; exit 1; fi
echo "Creating agent: $AGENT_NAME (port $AGENT_PORT)"
cp -r "$TEMPLATE_DIR" "$AGENT_DIR"
for f in Dockerfile SOUL.md config.yaml; do
  [ -f "$AGENT_DIR/$f" ] && sed -e "s/AGENT_NAME/$AGENT_NAME/g" -e "s/AGENT_PORT/$AGENT_PORT/g" -i "$AGENT_DIR/$f"
done
mkdir -p "$AGENT_DIR/skills" "$AGENT_DIR/cron"
printf '%s\n' "# Secrets" ".env" "*.pem" "*.key" > "$AGENT_DIR/.gitignore"
printf '%s\n' "# Environment for $AGENT_NAME" "OPENROUTER_API_KEY=" "AGENT_PORT=$AGENT_PORT" > "$AGENT_DIR/.env.example"
echo "Created: $AGENT_DIR/"
echo "Next: edit SOUL.md, add to docker-compose.yml, docker compose up -d $AGENT_NAME"
