#!/bin/bash
set -euo pipefail

echo "== Sushi Linux: server role =="

install_packages() {
    echo "→ installing server packages"
    pacman -Syu --needed --noconfirm - < server/packages.txt
}

setup_docker() {
    echo "→ enabling Docker"
    systemctl enable --now docker
}

setup_tailscale() {
    echo "→ enabling Tailscale service"
    systemctl enable --now tailscaled
    echo "  ⚠ run 'sudo tailscale up' manually to authenticate this machine"
    echo "  (TODO: revisit auth-key automation for the Tier 3 Nix flake version)"
}

main() {
    install_packages
    setup_docker
    setup_tailscale
    echo "✓ server role complete"
}

main