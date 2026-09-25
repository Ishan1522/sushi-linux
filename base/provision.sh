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

main() {
    enable_networking
    install_packages
    setup_dotfiles
    echo "✓ base provision complete"
}

main