#!/bin/bash
set -euo pipefail

echo "== Sushi Linux: desktop role =="

install_packages() {
    echo "→ installing desktop packages"
    pacman -Syu --needed --noconfirm - < desktop/packages.txt
}

setup_dotfiles() {
    echo "→ linking desktop dotfiles"
    stow -d desktop/dotfiles -t "$HOME" hypr
}

enable_sddm() {
    echo "→ enabling SDDM"
    systemctl enable sddm
}

main() {
    install_packages
    setup_dotfiles
    enable_sddm
    echo "✓ desktop role complete"
    echo "  reboot to reach the SDDM login screen"
}

main