# Sushi Linux 🍣

The flagship of the [Food Linux](https://github.com/ishan1522/sushi-linux) family (until i find a better name than 'Food' lmao) — a personal distro ecosystem, themed after food.

Gorgeous, full-featured, daily-driver energy. Built on Arch Linux. Runs on a Framework laptop (desktop role) and homelab nodes (server role), from one shared base config.

## Philosophy

Every machine should be **reproducible from a script**, never a one-off manual setup. This repo is built in tiers:

1. **Respin** — take an existing distro, theme it, ship as an ISO
2. **Custom install script** *(current tier)* — automate a base distro's install with your own package list, dotfiles, and config
3. **Declarative (NixOS-style)** — describe the end state, let the system build itself

Sushi is being built at Tier 2 first — hand-built before it's declared, so the eventual Tier 3 (Nix flake) version reflects real lived-in decisions instead of guesses.

## Structure

```
sushi-linux/
├── base/
│   ├── provision.sh    # shared layer: networking, packages, dotfiles
│   ├── packages.txt    # base package list
│   └── dotfiles/       # stow-able configs (shell, editor, etc.)
├── desktop/            # (planned) Hyprland + desktop-role packages
└── server/             # (planned) monitoring + server-role packages
```

## Usage

Run against a freshly pacstrap'd Arch install (see `install.sh`, coming soon, for the disk-partitioning + pacstrap step):

```bash
git clone https://github.com/ishan1522/sushi-linux.git
cd sushi-linux
./base/provision.sh
```

## Status

- [x] Manual Arch install verified working (partition → pacstrap → chroot → GRUB → boot)
- [x] `base/provision.sh` — networking, packages
- [ ] `base/dotfiles/` — shell + editor configs
- [ ] Test `provision.sh` against a fresh VM snapshot
- [ ] `install.sh` — scripted partition/pacstrap/GRUB
- [ ] `desktop/` role
- [ ] `server/` role