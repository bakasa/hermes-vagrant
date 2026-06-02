#!/bin/bash
# install-vagrant.sh — Install Vagrant + providers on Ubuntu/Railway
# Usage: bash install-vagrant.sh [--provider virtualbox|libvirt]

set -euo pipefail

PROVIDER="${1:---auto}"
LOG="/tmp/vagrant-install.log"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

detect_provider() {
  # Check what's available
  if [ -d /proc/vz ] && [ ! -d /proc/bc ]; then
    log "OpenVZ container detected — no nested virtualization possible"
    log "Vagrant VMs won't run here. Use docker-compose fallback."
    echo "none"
    return
  fi

  if lsmod | grep -q vboxdrv 2>/dev/null; then
    echo "virtualbox"
    return
  fi

  if command -v virsh &>/dev/null && systemctl is-active libvirtd &>/dev/null; then
    echo "libvirt"
    return
  fi

  # Default: try VirtualBox first, then libvirt
  if [ "$(uname -m)" = "x86_64" ]; then
    echo "virtualbox"
  else
    echo "libvirt"
  fi
}

install_vagrant() {
  local version="2.4.7"

  if command -v vagrant &>/dev/null; then
    local current
    current=$(vagrant --version | awk '{print $2}')
    log "Vagrant ${current} already installed"
    return
  fi

  log "Installing Vagrant ${version}..."

  # Try official .deb first
  local arch="amd64"
  [ "$(uname -m)" = "aarch64" ] && arch="arm64"

  local deb_url="https://releases.hashicorp.com/vagrant/${version}/vagrant_${version}-1_${arch}.deb"

  if curl -sfI "$deb_url" &>/dev/null; then
    wget -q "$deb_url" -O /tmp/vagrant.deb
    dpkg -i /tmp/vagrant.deb || apt-get install -f -y
    rm -f /tmp/vagrant.deb
  else
    # Fallback: gem install
    log "Falling back to gem install..."
    gem install vagrant -v "$version"
  fi

  log "Vagrant $(vagrant --version) installed"
}

install_virtualbox() {
  if command -v VBoxManage &>/dev/null; then
    log "VirtualBox $(VBoxManage --version) already installed"
    return
  fi

  log "Installing VirtualBox..."

  # Add Oracle repository
  wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
  echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" \
    > /etc/apt/sources.list.d/virtualbox.list

  apt-get update -qq
  apt-get install -y -qq virtualbox-7.0

  # Load kernel modules
  modprobe vboxdrv 2>/dev/null || true
  modprobe vboxnetadp 2>/dev/null || true
  modprobe vboxnetflt 2>/dev/null || true
  modprobe vboxpci 2>/dev/null || true

  log "VirtualBox $(VBoxManage --version) installed"
}

install_libvirt() {
  if command -v virsh &>/dev/null; then
    log "libvirt already installed"
    return
  fi

  log "Installing QEMU/KVM/libvirt..."

  apt-get update -qq
  apt-get install -y -qq \
    qemu-kvm libvirt-daemon-system libvirt-clients \
    bridge-utils virtinst virt-manager

  # Add vagrant user to libvirt group
  usermod -aG libvirt vagrant 2>/dev/null || true
  usermod -aG kvm vagrant 2>/dev/null || true

  systemctl enable --now libvirtd

  # Install vagrant-libvirt plugin
  sudo -u vagrant vagrant plugin install vagrant-libvirt 2>/dev/null || true

  log "libvirt installed"
}

install_docker() {
  if command -v docker &>/dev/null; then
    log "Docker already installed"
    return
  fi

  log "Installing Docker..."

  curl -fsSL https://get.docker.com | sh
  usermod -aG docker vagrant 2>/dev/null || true
  usermod -aG docker hermes 2>/dev/null || true

  systemctl enable --now docker

  log "Docker $(docker --version) installed"
}

check_nested_virt() {
  log "Checking nested virtualization support..."

  if [ -w /dev/kvm ]; then
    log "✅ KVM available (nested virt supported)"
    return 0
  fi

  if lsmod 2>/dev/null | grep -q vboxdrv; then
    log "✅ VirtualBox kernel modules loaded"
    return 0
  fi

  if dmesg 2>/dev/null | grep -qi "vmx\|svm"; then
    log "⚠️ CPU supports VT-x/SVM but modules not loaded"
    log "   Try: sudo modprobe kvm_intel (or kvm_amd)"
    return 1
  fi

  log "❌ No virtualization support detected"
  log "   Vagrant VMs will not run in this environment"
  return 1
}

═══════════════════════════════════════════════════════════════════════════
# MAIN
═══════════════════════════════════════════════════════════════════════════

main() {
  log "═══ Hermes Vagrant Installer ═══"

  # Auto-detect provider
  if [ "$PROVIDER" = "--auto" ]; then
    PROVIDER=$(detect_provider)
    log "Auto-detected provider: $PROVIDER"
  fi

  # Install base
  install_vagrant

  # Install provider
  case "$PROVIDER" in
    virtualbox) install_virtualbox ;;
    libvirt)    install_libvirt ;;
    none)       log "Skipping provider installation (container environment") ;;
    *)          log "Unknown provider: $PROVIDER"; exit 1 ;;
  esac

  # Always install Docker (for fallback)
  install_docker

  # Check nested virt
  check_nested_virt

  # Install vagrant plugins
  log "Installing Vagrant plugins..."
  sudo -u vagrant vagrant plugin install vagrant-vbguest 2>/dev/null || true
  sudo -u vagrant vagrant plugin install vagrant-disksize 2>/dev/null || true

  log "═══ Installation Complete ═══"
  log "Vagrant:  $(vagrant --version)"
  [ "$PROVIDER" = "virtualbox" ] && log "VirtualBox: $(VBoxManage --version 2>/dev/null || echo 'loaded at runtime')"
  [ "$PROVIDER" = "libvirt" ] && log "libvirt: $(virsh version --daemon 2>/dev/null | head -1 || echo 'loaded at runtime')"
  log "Docker:   $(docker --version 2>/dev/null || echo 'not started')"
  log ""
  log "Next steps:"
  log "  1. Copy .env files to agents/<name>/.env"
  log "  2. vagrant up"
  log "  3. vagrant ssh hermes-main"

  if ! check_nested_virt 2>/dev/null; then
    log ""
    log "NOTE: No nested virtualization. Use Docker fallback:"
    log "  ./scripts/fallback-docker.sh"
  fi
}

main "$@"
