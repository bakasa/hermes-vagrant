#!/usr/bin/env bash
# setup.sh — Detect agents and validate structure
# Usage: bash scripts/setup.sh [--check] [--generate]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

AGENTS_DIR="agents"
TEMPLATE_DIR="templates/new-agent"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CHECK_ONLY=false
GENERATE=false

for arg in "$@"; do
  case "$arg" in
    --check)   CHECK_ONLY=true ;;
    --generate) GENERATE=true ;;
  esac
done

if [ "$CHECK_ONLY" = false ] && [ "$GENERATE" = false ]; then
  CHECK_ONLY=true
  GENERATE=true
fi

log()  { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*"; }

# ── Discover agents ──
echo "═══ Hermes Agent Discovery ═══"
echo ""

agents=()
for dir in "$AGENTS_DIR"/*/; do
  [ -d "$dir" ] || continue
  agent=$(basename "$dir")
  # Skip template dir if accidentally inside agents/
  [ "$agent" = "new-agent" ] && continue
  agents+=("$agent")
done

if [ ${#agents[@]} -eq 0 ]; then
  err "No agents found in $AGENTS_DIR/"
  exit 1
fi

echo "Found ${#agents[@]} agent(s): ${agents[*]}"
echo ""

# ── Validate each agent ──
all_valid=true
for agent in "${agents[@]}"; do
  dir="$AGENTS_DIR/$agent"
  echo "── $agent ──"

  # Required files
  for f in Dockerfile SOUL.md config.yaml; do
    if [ -f "$dir/$f" ]; then
      log "  $f present"
    else
      err "  $f MISSING"
      all_valid=false
    fi
  done

  # Optional dirs
  for d in skills cron; do
    if [ -d "$dir/$d" ]; then
      count=$(find "$dir/$d" -type f | wc -l)
      log "  $d/ ($count files)"
    else
      warn "  $d/ absent (optional)"
    fi
  done

  # Optional files
  for f in requirements.txt README.md; do
    [ -f "$dir/$f" ] && log "  $f present"
  done

  # Check Dockerfile has a FROM line
  if [ -f "$dir/Dockerfile" ]; then
    if grep -q "^FROM" "$dir/Dockerfile"; then
      log "  Dockerfile has FROM"
    else
      err "  Dockerfile missing FROM"
      all_valid=false
    fi
  fi

  echo ""
done

# ── Summary ──
if $all_valid; then
  echo -e "${GREEN}${all_valid} All agents valid ✓${NC}"
else
  echo -e "${RED}Some agents have issues. Fix before deploying.${NC}"
  exit 1
fi

# ── Template check ──
echo ""
echo "═══ Template ═══"
if [ -d "$TEMPLATE_DIR" ]; then
  for f in Dockerfile SOUL.md config.yaml; do
    [ -f "$TEMPLATE_DIR/$f" ] && log "  $f present"
  done
else
  err "  $TEMPLATE_DIR/ not found"
fi

# ── Files summary ──
echo ""
echo "═══ Summary ═══"
total_files=$(find "$AGENTS_DIR" -type f | wc -l)
echo "  Agents:     ${#agents[@]}"
echo "  Files:      $total_files"
echo "  Agents dir: $AGENTS_DIR/"
echo "  Deploy:     docker compose up -d"
echo "  Health:     docker compose ps"
echo "  Logs:       docker compose logs -f <agent>"
echo "  New agent:  bash scripts/add-agent.sh <name>"
