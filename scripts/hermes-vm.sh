#!/bin/bash
# hermes-vm.sh — Control script for Hermes Vagrant VMs
# Usage:
#   hermes-vm.sh up [agent|all]
#   hermes-vm.sh halt [agent|all]
#   hermes-vm.sh status
#   hermes-vm.sh ssh <agent>
#   hermes-vm.sh provision <agent>
#   hermes-vm.sh destroy [agent|all]
#   hermes-vm.sh logs <agent>
#   hermes-vm.sh health
#   hermes-vm.sh doctor

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

AGENTS=(main research subconscious coder qa alim)
PROJECT_NAME="hermes"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
  echo -e "${BOLD}hermes-vm${NC} — Hermes Vagrant VM Control"
  echo ""
  echo "Commands:"
  echo -e "  ${CYAN}up${NC}        [agent|all]  Start VMs (default: all)"
  echo -e "  ${CYAN}halt${NC}      [agent|all]  Stop VMs gracefully"
  echo -e "  ${CYAN}status${NC}                Show VM status"
  echo -e "  ${CYAN}ssh${NC}       <agent>     SSH into agent VM"
  echo -e "  ${CYAN}provision${NC} <agent>     Re-provision agent"
  echo -e "  ${CYAN}destroy${NC}   [agent|all]  Destroy VMs"
  echo -e "  ${CYAN}logs${NC}      <agent>     Tail gateway logs"
  echo -e "  ${CYAN}health${NC}                Health check all agents"
  echo -e "  ${CYAN}doctor${NC}               Diagnose issues"
  echo ""
  echo "Agents: ${AGENTS[*]}"
  echo ""
  echo "Examples:"
  echo "  hermes-vm.sh up           # Start all agents"
  echo "  hermes-vm.sh up main      # Start only main"
  echo "  hermes-vm.sh ssh research # SSH into research VM"
  echo "  hermes-vm.sh health       # Check all gateways"
}

vagrant_cmd() {
  local cmd="$1"
  local target="${2:-}"

  local vagrant_args=("$cmd")
  [ -n "$target" ] && vagrant_args+=("${PROJECT_NAME}-${target}")

  echo -e "${BLUE}→ vagrant ${vagrant_args[*]}${NC}"
  vagrant "${vagrant_args[@]}"
}

agent_list() {
  local target="${1:-all}"
  if [ "$target" = "all" ]; then
    echo "${AGENTS[@]}"
  else
    echo "$target"
  fi
}

cmd_up() {
  local target="${1:-all}"
  for agent in $(agent_list "$target"); do
    echo -e "\n${BOLD}━━━ Starting: hermes-${agent} ━━━${NC}"
    vagrant_cmd "up" "$agent"
    echo -e "${GREEN}✓ hermes-${agent} running${NC}"
  done
}

cmd_halt() {
  local target="${1:-all}"
  for agent in $(agent_list "$target"); do
    vagrant_cmd "halt" "$agent" 2>/dev/null || true
    echo -e "${YELLOW}⊙ hermes-${agent} stopped${NC}"
  done
}

cmd_status() {
  echo -e "${BOLD}Hermes VM Status${NC}"
  echo ""

  if ! command -v vagrant &>/dev/null; then
    echo -e "${RED}✗ Vagrant not installed. Run: scripts/install-vagrant.sh${NC}"
    exit 1
  fi

  echo "  VM Name              State      IP             Port"
  echo "  ───────────────────  ─────────  ─────────────  ──────"

  for agent in "${AGENTS[@]}"; do
    local vm_name="${PROJECT_NAME}-${agent}"
    local state="not_created"
    local ip="-"
    local port="3000"

    # Try to get state from vagrant
    state=$(vagrant status "$vm_name" 2>/dev/null | grep "virtualbox\|libvirt" | awk '{print $2}' || echo "unknown")
    [ -z "$state" ] && state="not_created"

    port=$((3000 + $(echo "${AGENTS[@]}" | tr ' ' '\n' | grep -n "^${agent}$" | cut -d: -f1) - 1))

    case "$state" in
      running)      icon="✅"; color="$GREEN" ;;
      poweroff)     icon="⏻"; color="$YELLOW" ;;
      not_created)  icon="✗"; color="$RED" ;;
      *)            icon="?"; color="$NC" ;;
    esac

    printf "  ${color}%-2s %-18s${NC}  %-9s  %-14s  %s\n" \
      "$icon" "$vm_name" "$state" "$ip" ":$port"
  done
}

cmd_ssh() {
  local agent="${1:-}"
  [ -z "$agent" ] && { echo -e "${RED}Error: agent name required${NC}"; exit 1; }
  vagrant_cmd "ssh" "$agent"
}

cmd_provision() {
  local agent="${1:-}"
  [ -z "$agent" ] && { echo -e "${RED}Error: agent name required${NC}"; exit 1; }
  vagrant_cmd "provision" "$agent"
}

cmd_destroy() {
  local target="${1:-all}"
  echo -e "${YELLOW}⚠ This will permanently destroy VM data${NC}"
  read -p "Continue? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy] ]] || { echo "Aborted."; exit 0; }

  for agent in $(agent_list "$target"); do
    vagrant_cmd "destroy" "$agent" --force 2>/dev/null || true
    echo -e "${RED}✗ hermes-${agent} destroyed${NC}"
  done
}

cmd_logs() {
  local agent="${1:-}"
  [ -z "$agent" ] && { echo -e "${RED}Error: agent name required${NC}"; exit 1; }

  local vm_name="${PROJECT_NAME}-${agent}"
  vagrant ssh "$vm_name" -c "sudo journalctl -u hermes-gateway -f --no-pager" 2>/dev/null || \
    vagrant ssh "$vm_name" -c "tail -f /home/hermes/.hermes/logs/hermes.log" 2>/dev/null || \
    echo -e "${RED}Could not get logs for ${agent}${NC}"
}

cmd_health() {
  echo -e "${BOLD}Hermes Agent Health Check${NC}"
  echo ""

  local all_ok=true
  for agent in "${AGENTS[@]}"; do
    local port=$((3000 + $(echo "${AGENTS[@]}" | tr ' ' '\n' | grep -n "^${agent}$" | cut -d: -f1) - 1))
    local status="❌ DOWN"
    local color="$RED"

    # Check gateway health
    if curl -sf "http://192.168.56.$((10 + $(echo "${AGENTS[@]}" | tr ' ' '\n' | grep -n "^${agent}$" | cut -d: -f1) - 1)):${port}/health" &>/dev/null; then
      status="✅ UP"
      color="$GREEN"
    elif curl -sf "localhost:${port}/health" &>/dev/null; then
      status="✅ UP (localhost)"
      color="$GREEN"
    else
      all_ok=false
    fi

    printf "  ${color}%-18s${NC}  port %-5s  %s\n" "hermes-${agent}" ":$port" "$status"
  done

  echo ""
  if $all_ok; then
    echo -e "${GREEN}${BOLD}All agents healthy ✓${NC}"
  else
    echo -e "${YELLOW}${BOLD}Some agents not responding — check: hermes-vm.sh doctor${NC}"
    return 1
  fi
}

cmd_doctor() {
  echo -e "${BOLD}Hermes VM Doctor${NC}"
  echo ""

  # Check Vagrant
  if command -v vagrant &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Vagrant $(vagrant --version)"
  else
    echo -e "  ${RED}✗${NC} Vagrant not installed"
    echo "    Fix: bash scripts/install-vagrant.sh"
  fi

  # Check provider
  if command -v VBoxManage &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} VirtualBox $(VBoxManage --version)"
  elif command -v virsh &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} libvirt available"
  else
    echo -e "  ${RED}✗${NC} No VM provider found"
  fi

  # Check nested virt
  if [ -w /dev/kvm ]; then
    echo -e "  ${GREEN}✓${NC} KVM available"
  else
    echo -e "  ${YELLOW}⚠${NC} /dev/kvm not available — VMs may not start"
  fi

  # Check disk space
  local free_gb
  free_gb=$(df -BG . | tail -1 | awk '{print $4}' | tr -d 'G')
  if [ "$free_gb" -gt 20 ]; then
    echo -e "  ${GREEN}✓${NC} Disk: ${free_gb}GB free"
  else
    echo -e "  ${YELLOW}⚠${NC} Disk: ${free_gb}GB free (need ~20GB for all VMs)"
  fi

  # Check RAM
  local total_ram
  total_ram=$(grep MemTotal /proc/meminfo | awk '{printf "%.0f", $2/1048576}')
  if [ "$total_ram" -gt 14 ]; then
    echo -e "  ${GREEN}✓${NC} RAM: ${total_ram}GB"
  else
    echo -e "  ${YELLOW}⚠${NC} RAM: ${total_ram}GB (14GB+ recommended)"
  fi

  # Check agent configs
  echo ""
  echo "  Agent configs:"
  for agent in "${AGENTS[@]}"; do
    if [ -f "agents/${agent}/SOUL.md" ]; then
      echo -e "    ${GREEN}✓${NC} ${agent}: SOUL.md present"
    else
      echo -e "    ${YELLOW}⚠${NC} ${agent}: no SOUL.md (will use default)"
    fi
  done
}

═══════════════════════════════════════════════════════════════════════════
# MAIN
═══════════════════════════════════════════════════════════════════════════

case "${1:-help}" in
  up)        shift; cmd_up "${1:-all}" ;;
  halt)      shift; cmd_halt "${1:-all}" ;;
  status)    cmd_status ;;
  ssh)       shift; cmd_ssh "${1:-}" ;;
  provision) shift; cmd_provision "${1:-}" ;;
  destroy)   shift; cmd_destroy "${1:-all}" ;;
  logs)      shift; cmd_logs "${1:-}" ;;
  health)    cmd_health ;;
  doctor)    cmd_doctor ;;
  help|-h|--help) usage ;;
  *)
    echo -e "${RED}Unknown: $1${NC}"
    usage
    exit 1
    ;;
esac
