#!/bin/bash
set -euo pipefail

echo "== Sushi Linux: base provision =="

enable_networking() {
    echo "→ enabling NetworkManager"
    systemctl enable --now NetworkManager
}

install_packages() {
    echo "→ installing base packages"
    pacman -Syu --needed --noconfirm - < base/packages.txt
}

setup_dotfiles() {
    echo "→ linking dotfiles"
    stow -d base/dotfiles -t "$HOME" zsh
}

show_info() {
    local iface
    iface=$(ip route show default | awk '/default/ {print $5; exit}')

    echo ""
    echo "===== Sushi Linux: Machine Info ====="
    echo "Hostname:     $(hostname)"
    echo "Interface:    $iface"
    echo "MAC address:  $(cat /sys/class/net/"$iface"/address)"
    echo "IP address:   $(ip -4 addr show "$iface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
    if command -v tailscale &> /dev/null && tailscale ip -4 &> /dev/null; then
        echo "Tailscale IP: $(tailscale ip -4)"
    fi
    echo "======================================"
    echo "Register this MAC with your network's access control system if needed."
    echo ""
}

main() {
    enable_networking
    install_packages
    setup_dotfiles
    show_info
    echo "✓ base provision complete"
}

main