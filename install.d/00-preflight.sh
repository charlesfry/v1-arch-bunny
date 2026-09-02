#!/usr/bin/env bash
# Refuse to start if the machine is not what the rest of the steps assume: btrfs
# root, the six subvolumes, UEFI, room on the ESP for snapshot kernels, a findable
# limine.conf, and an initramfs config that will still build.
#
# Checks only. Nothing here writes and nothing here needs root, so a dry run
# reports the machine honestly without a password prompt.
#
# install.sh checks what it needs to *run*; this checks what the steps need to
# *succeed*, and it is the file that grows as they land.
#
# Usage: 00-preflight.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
ok() { say "  ✓ $*"; }
fail=0
bad() {
	say "  ✗ $*"
	fail=1
}

# `snapshot-boot-entries`, `snapshot-bloat` and `docker-storage-quota` all assume
# btrfs subvolumes. On ext4 they are meaningless rather than degraded.
root_fs=$(findmnt -no FSTYPE /)
if [[ $root_fs == btrfs ]]; then
	ok "/ is btrfs"
else
	bad "/ is $root_fs, not btrfs — the snapshot and Docker-quota rows need btrfs subvolumes"
fi

# Checked through the mount options rather than `btrfs subvolume list`, which
# needs root. This also tests the stronger property: not that the subvolume
# exists, but that it is the one mounted here.
check_subvol() {
	local mnt=$1 want=$2 opts
	opts=$(findmnt -no OPTIONS "$mnt" 2>/dev/null || true)
	if [[ $opts == *"subvol=/$want"* ]]; then
		ok "$mnt is on subvolume $want"
	else
		bad "$mnt is not on subvolume $want — was this installed from the archinstall config?"
	fi
}
# All six. Each is entered by hand in archinstall's menu (README.md step 2), and
# a missing one degrades silently rather than failing:
#   @snapshots  snapper writes into `@` instead, so a rollback that swaps `@`
#               strands every snapshot in the retired subvolume
#   @log        journal history joins every snapshot
#   @cache      the package and font caches join every snapshot: `snapshot-bloat`
#   @tmp        persistent scratch gets rolled back with the system
#   @home       your data gets rolled back with the system
check_subvol / @
check_subvol /home @home
check_subvol /.snapshots @snapshots
check_subvol /var/log @log
check_subvol /var/cache @cache
check_subvol /var/tmp @tmp

# UEFI, because `bootloader` picked limine and limine here is UEFI-only.
if [[ -d /sys/firmware/efi ]]; then
	ok "booted UEFI"
else
	bad "not booted in UEFI mode — the limine setup in these steps is UEFI-only"
fi

# `snapshot-boot-entries` puts a kernel plus an initramfs on the ESP per snapshot.
# Running it out of space fails at boot, long after the install that caused it.
if [[ $(findmnt -no TARGET /boot 2>/dev/null) == /boot ]]; then
	esp_mb=$(df -BM --output=avail /boot | tail -1 | tr -dc '0-9')
	if ((esp_mb >= 300)); then
		ok "/boot has ${esp_mb} MiB free"
	else
		bad "/boot has only ${esp_mb} MiB free — each snapshot boot entry needs a kernel of its own"
	fi
else
	bad "/boot is not its own mount — expected the ESP mounted there"
fi

# limine.conf's path isn't fixed: archinstall nests it under
# /boot/EFI/arch-limine/, a manual install leaves it flat. CHOICES.md `bootloader`;
# scripts/find-limine-conf.sh reads limine's own search order.
#
# archinstall's ESP mount is root-only, so this step often cannot tell "no
# limine.conf" from "can't see in there" — and this file must not need root. That
# is exit 2 from the finder, an expected outcome; 50-limine.sh checks for real.
finder="${BUNNY_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}/scripts/find-limine-conf.sh"
if [[ -x $finder ]]; then
	lconf=$("$finder" 2>/dev/null) && rc=0 || rc=$?
	if ((rc == 0)); then
		ok "limine.conf found at $lconf"
	elif ((rc == 2)); then
		say "  ? cannot check limine.conf — /boot needs root to read (50-limine.sh will check for real)"
	else
		bad "no limine.conf found under /boot — is limine installed?"
	fi
else
	bad "scripts/find-limine-conf.sh not found at $finder"
fi

# No network check: the honest tests either need root and write (`pacman -Sy`) or
# test something other than what matters (a route is not a working mirror). pacman
# fails loudly on its own in the package step.

# The initramfs config. CHOICES.md `initramfs` + `filesystem`. This machine is
# already booted from an initramfs that works, so a broken /etc/mkinitcpio.conf
# changes nothing today — it governs the next build, which happens unattended from
# a pacman hook on the next kernel update. /boot is FAT and outside every
# snapshot, so there is no rollback for it.
#
# Checked, not written: archinstall produces this file and gets it right for a
# LUKS install, and rebuilding an initramfs unattended is not this installer's
# call. Report it and let a human act.
mkconf=/etc/mkinitcpio.conf
if [[ -r $mkconf ]]; then
	hooks=$(sed -n 's/^HOOKS=(\(.*\))$/\1/p' "$mkconf")

	# Only relevant on an encrypted root. The subvolume suffix has to come off the
	# source or lsblk cannot stat it.
	root_src=$(findmnt -no SOURCE / | sed 's/\[.*//')
	if [[ $(lsblk -no TYPE "$root_src" 2>/dev/null | head -1) == crypt ]]; then
		# Position matters as much as presence: `encrypt` needs `block` to have
		# provided the device nodes, and must run before `filesystems` mounts.
		pos() {
			local h i=0
			for h in $hooks; do
				i=$((i + 1))
				if [[ $h == "$1" ]]; then
					printf '%s\n' "$i"
					return
				fi
			done
			printf '0\n'
		}
		p_block=$(pos block) p_encrypt=$(pos encrypt) p_fs=$(pos filesystems)
		if ((p_encrypt == 0)); then
			bad "/ is on LUKS but HOOKS= has no 'encrypt' — the next kernel update builds an initramfs that cannot unlock it"
		elif ((p_block == 0 || p_block > p_encrypt || p_encrypt > p_fs)); then
			bad "HOOKS= order is wrong: needs block before encrypt before filesystems (got: $hooks)"
		else
			ok "HOOKS= has encrypt, after block and before filesystems"
		fi
	else
		ok "/ is not on LUKS — the encrypt hook is not expected"
	fi

	# A FILES= entry pointing at a missing file fails the build rather than warning
	# (add_file errors, the RETURN trap counts it, mkinitcpio exits non-zero — see
	# /usr/lib/initcpio/functions). The way to get here is a half-done
	# `benchmark-unlock` teardown: keyfile deleted, FILES= line left behind.
	files=$(sed -n 's/^FILES=(\(.*\))$/\1/p' "$mkconf")
	files_ok=true
	for f in $files; do
		if [[ ! -e $f ]]; then
			bad "FILES= lists $f, which does not exist — the next 'mkinitcpio -P' will fail"
			files_ok=false
		fi
	done
	if [[ -n $files ]] && $files_ok; then
		ok "every FILES= entry exists"
	fi
else
	bad "cannot read $mkconf"
fi

# Things that must never ship. `benchmark-unlock`'s keyfile and the test-box
# sudoers file exist so bunne-test can be driven headless; both are recorded as
# must-not-ship in docs/phase4-config-inventory.md §5. Loud but not fatal, since
# the machine being provisioned may legitimately be that box.
#
# `[[ -e ]]` on an unreadable directory is false rather than an error, so a
# rootless check of /etc/sudoers.d (mode 0750) would report "clean" for a file
# sitting right there. Report the blind spot instead.
for leak in /crypto_keyfile.bin /etc/sudoers.d/20-bunny-testbox-nopasswd; do
	if [[ -e $leak ]]; then
		say "  ! $leak present — test-box only, must not exist on a shipped machine"
	elif [[ ! -r $(dirname -- "$leak") ]]; then
		say "  ? cannot check $leak — $(dirname -- "$leak") needs root to read"
	fi
done

((fail == 0)) || {
	say ""
	say "preflight failed — nothing has been changed"
	exit 1
}
ok "preflight passed"
