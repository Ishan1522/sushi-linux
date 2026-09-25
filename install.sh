#!/bin/bash
set -euo pipefail

# ===== Config — edit these before running =====
DISK="/dev/sda"
HOSTNAME="sushi-base"
TIMEZONE="America/Detroit"
# ================================================

confirm_disk() {
    echo "This will COMPLETELY ERASE $DISK. All data will be lost."
    lsblk "$DISK"
    read -rp "Type the disk path exactly ($DISK) to confirm: " CONFIRM
    if [ "$CONFIRM" != "$DISK" ]; then
        echo "Confirmation did not match. Aborting."
        exit 1
    fi
}

get_password() {
    read -rsp "Enter root password: " ROOT_PASSWORD
    echo ""
    read -rsp "Confirm root password: " ROOT_PASSWORD_CONFIRM
    echo ""
    if [ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]; then
        echo "Passwords did not match. Aborting."
        exit 1
    fi
}

partition_disk() {
    echo "→ partitioning $DISK"
    parted "$DISK" -- mklabel gpt
    parted "$DISK" -- mkpart primary fat32 1MiB 513MiB
    parted "$DISK" -- set 1 esp on
    parted "$DISK" -- mkpart primary ext4 513MiB 100%
}

format_and_mount() {
    echo "→ formatting and mounting"
    mkfs.fat -F32 "${DISK}1"
    mkfs.ext4 "${DISK}2"
    mount "${DISK}2" /mnt
    mkdir /mnt/boot
    mount "${DISK}1" /mnt/boot
}

run_pacstrap() {
    echo "→ pacstrap (this takes a few minutes)"
    pacstrap /mnt base linux linux-firmware networkmanager sudo vim git zsh stow grub efibootmgr
    genfstab -U /mnt >> /mnt/etc/fstab
}

write_chroot_script() {
    echo "→ writing chroot setup script"
    cat > /mnt/root/chroot-setup.sh <<CHROOT_EOF
#!/bin/bash
set -euo pipefail

ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "${HOSTNAME}" > /etc/hostname

echo "root:${ROOT_PASSWORD}" | chpasswd

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "✓ chroot setup complete"
CHROOT_EOF
    chmod +x /mnt/root/chroot-setup.sh
}

run_chroot_script() {
    echo "→ entering chroot to finish setup"
    arch-chroot /mnt /root/chroot-setup.sh
    rm /mnt/root/chroot-setup.sh
}

cleanup() {
    echo "→ unmounting"
    umount -R /mnt
    echo "✓ install complete — you can now reboot"
    echo "  (remember to detach the ISO: qm set <vmid> --ide2 none)"
}

main() {
    confirm_disk
    get_password
    partition_disk
    format_and_mount
    run_pacstrap
    write_chroot_script
    run_chroot_script
    cleanup
}

main