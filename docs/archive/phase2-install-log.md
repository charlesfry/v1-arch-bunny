# Phase 2 install log — reference commands

Personal reference: the exact command sequence that got Phase 2 (vanilla,
encrypted, dual-booting Arch) working on the disposable laptop, corrected to
skip the ext4-`/boot` dead end (see `CHOICES.md` bootloader row for why that
failed). Not meant to be run as a script — command by command, on purpose, per
`04-plan.md`.

Placeholders to replace: `/dev/nvme0n1` (target disk), `America/New_York`
(timezone), `bunne-test` (hostname), UUIDs (machine-specific, read them off
as you go).

## Partitioning

Free space located between the Windows C: and Recovery partitions — confirm
with `fdisk -l /dev/nvme0n1` first, never auto-partition.

```
fdisk /dev/nvme0n1
```
```
n            # new partition, first sector default, size +1G (unused after the fix below — see note at the end)
n            # new partition, first sector default, last sector default (rest of free space)
t  5  8300   # Linux filesystem
t  6  8309   # Linux LUKS
w
```
```
partprobe
lsblk -f
```

## Encryption + filesystem

```
cryptsetup luksFormat --type luks2 /dev/nvme0n1p6
cryptsetup open /dev/nvme0n1p6 cryptroot
mkfs.btrfs -L archroot /dev/mapper/cryptroot
```

## btrfs subvolumes

> **Outdated naming — do not copy from here.** The `@var_log`/`@var_pkgs` names
> below were invented during this hand install. They were renamed to
> **`@log`/`@pkg`** on 2026-08-19 to match `archinstall`'s defaults, which is
> also what the daily-driver desktop already uses (`01-assessment.md`). This
> file is left unedited because it is a transcript of what was actually typed,
> not a procedure to follow. Current names: `CHOICES.md` `filesystem`.

```
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@var_pkgs
umount /mnt
```

## Mount everything

`/boot` is the **ESP itself**, mounted directly — not the separate ext4
partition created above. Limine cannot read ext4 (see `CHOICES.md`).

```
mount -o noatime,compress=zstd:1,subvol=@ /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,.snapshots,var/log,var/cache/pacman/pkg,boot}
mount -o noatime,compress=zstd:1,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o noatime,compress=zstd:1,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount -o noatime,compress=zstd:1,subvol=@var_log /dev/mapper/cryptroot /mnt/var/log
mount -o noatime,compress=zstd:1,subvol=@var_pkgs /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
mount /dev/nvme0n1p1 /mnt/boot
```

## Base install

```
pacstrap -K /mnt base linux-zen linux linux-firmware intel-ucode btrfs-progs
genfstab -U /mnt >> /mnt/etc/fstab
```

Check `/mnt/etc/fstab`'s `/boot` line reads `UUID=<ESP-UUID> /boot vfat ...`
(the ESP's UUID, not the unused ext4 partition's). Fix by hand if `genfstab`
ran before the ESP was mounted at `/boot`.

```
arch-chroot /mnt
```

## Inside the chroot — identity

```
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "bunne-test" > /etc/hostname
```
```
cat >> /etc/hosts << 'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   bunne-test.localdomain   bunne-test
EOF
```
```
passwd
```

## Initramfs — LUKS unlock at boot

```
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
```

## Networking

```
pacman -S iwd efibootmgr limine nano
systemctl enable systemd-networkd systemd-resolved iwd
```
```
cat > /etc/systemd/network/20-wired.network << 'EOF'
[Match]
Name=en*

[Network]
DHCP=yes
EOF
```
```
cat > /etc/systemd/network/25-wireless.network << 'EOF'
[Match]
Name=wl*

[Network]
DHCP=yes
EOF
```

## Bootloader

```
mkdir -p /boot/EFI/limine
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/limine_x64.efi
```
```
cat > /boot/limine.conf << 'EOF'
timeout: 3

/Arch Linux (zen)
    protocol: linux
    kernel_path: boot():/vmlinuz-linux-zen
    module_path: boot():/intel-ucode.img
    module_path: boot():/initramfs-linux-zen.img
    cmdline: cryptdevice=UUID=<luks-uuid>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw

/Arch Linux (fallback)
    protocol: linux
    kernel_path: boot():/vmlinuz-linux
    module_path: boot():/intel-ucode.img
    module_path: boot():/initramfs-linux.img
    cmdline: cryptdevice=UUID=<luks-uuid>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw

/Windows
    protocol: efi_chainload
    image_path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
EOF
```

Register a UEFI boot entry if one doesn't already exist for this path
(`efibootmgr -v` to check first — reuse an existing "Limine" entry rather
than duplicating):

```
efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "Limine" --loader '\EFI\limine\limine_x64.efi'
```

```
exit
umount -R /mnt
reboot
```

## Note on the unused ext4 partition

The `+1G` partition created first (`p5` in this run) was the original
`/boot` attempt — ext4, which Limine cannot read. It's harmless and unused
once `/boot` moves to the ESP. Doing this fresh: skip creating it, and give
that space straight to the LUKS partition instead.
