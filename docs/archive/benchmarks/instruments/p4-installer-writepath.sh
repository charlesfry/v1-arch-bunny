#!/usr/bin/env bash
# Break every state install.sh is supposed to create, so that ONE run exercises
# every step's write path at once.
#
# WHY THIS EXISTS. On an already-provisioned box every step reports `=` and the
# code that actually changes things never runs, which by this repo's own rule
# leaves it broken until demonstrated. Each step has been broken and re-run
# individually while it was being written; what has never been tested is all of
# them at once, which is the only shape that can surface an ORDERING problem --
# a step that only works because a later step happened to have already run.
#
# WHAT IT DELIBERATELY DOES NOT TOUCH:
#   packages      uninstalling and reinstalling 75 packages tests pacman, not us
#   /boot         `50-limine.sh` was proven by a real reboot in an earlier
#                 session; breaking the bootloader to re-prove it risks a box
#                 with no remote power control
#   the LUKS keyfile and the test-box sudoers file, which are what make this
#                 machine drivable headless at all
#
# Run it, then run `./install.sh`, then reboot. Everything below must come back.
#
# Usage: p4-installer-writepath.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
say "This DELIBERATELY breaks a provisioned machine. Ctrl-C now if that is not what you want."

# --- 15-docker-subvols ------------------------------------------------------
# Unmount and strip fstab, but leave the subvolumes: deleting @containerd would
# throw away images that a real machine would care about, and the create path is
# tested separately.
say "== docker subvolumes: unmount + strip fstab"
sudo systemctl stop docker.socket docker.service containerd.service 2>/dev/null || true
# chmod BEFORE the umount, and that order is the whole point: the mode that
# matters lives on the mounted subvolume root, and chmod-ing after unmounting
# changes the mountpoint underneath instead -- which the next mount hides, so the
# break silently does nothing and the step's mode check is never exercised. This
# instrument got that wrong on its first run.
sudo chmod 755 /var/lib/docker
sudo umount /var/lib/docker /var/lib/containerd 2>/dev/null || true
sudo cp -a /etc/fstab /etc/fstab.writepath.bak
sudo sed -i '/subvol=\/@containerd/d;/subvol=\/@dockervol/d;/BunnE: \/var\/lib\//d' /etc/fstab

# --- 30-zram ----------------------------------------------------------------
say "== zram: wrong size, wrong sysctls"
printf '[zram0]\nzram-size = 128\n' | sudo install -Dm644 /dev/stdin /etc/systemd/zram-generator.conf
sudo rm -f /etc/sysctl.d/99-zram.conf
sudo sysctl -q vm.swappiness=60 vm.page-cluster=3

# --- 35-oom-protection ------------------------------------------------------
say "== oomd: drop-ins removed, unit disabled"
sudo rm -rf /etc/systemd/system/-.slice.d /etc/systemd/system/user@.service.d
sudo systemctl disable --now systemd-oomd.service 2>/dev/null || true

# --- 40-snapshots -----------------------------------------------------------
# Template defaults, plus the timer the ledger says must never be enabled.
say "== snapper: template values back, timeline timer enabled"
for kv in SPACE_LIMIT=0.5 NUMBER_LIMIT=50 NUMBER_LIMIT_IMPORTANT=10 NUMBER_MIN_AGE=3600 TIMELINE_CREATE=yes; do
	sudo snapper -c root set-config "$kv"
done
sudo systemctl enable --now snapper-timeline.timer

# --- 60-autologin -----------------------------------------------------------
say "== autologin: drop-in removed, .bash_profile block removed"
sudo rm -rf /etc/systemd/system/getty@tty1.service.d
cp -a ~/.bash_profile ~/.bash_profile.writepath.bak
sed -i '/BunnE: autologin lands here/,/^fi$/d' ~/.bash_profile

# --- 70-dotfiles ------------------------------------------------------------
# One of each shape the step has to handle: a link replaced by an identical
# regular file (must be relinked silently), a link replaced by a DIFFERENT file
# (must be backed up), and a link simply gone.
say "== dotfiles: one identical copy, one divergent copy, one missing"
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
repo=${BUNNE_ROOT:-$HOME/.local/share/arch-bunny}
rm -f "$cfg/niri/config.kdl" && cp "$repo/config/niri/config.kdl" "$cfg/niri/config.kdl"
rm -f "$cfg/kitty/kitty.conf" && printf 'font_size 4\n' >"$cfg/kitty/kitty.conf"
rm -f "$cfg/waybar/weather"

sudo systemctl daemon-reload
say ""
say "Broken. Now: ./install.sh   then reboot, then check everything came back."
