#!/usr/bin/env bash
# Boot splash: the neon-hare bunny behind the LUKS prompt. CHOICES.md
# `boot-splash`.
#
# archinstall does the plumbing. `bootloader_config.plymouth` is set in both
# JSONs, so `_install_plymouth` (lib/installer.py:1760-1781) has already strapped
# `plymouth`, put the hook in `HOOKS=`, added `quiet` and `splash` to the kernel
# command line and run `mkinitcpio -P`. What it cannot do is the decision:
# `PlymouthTheme` is a closed ten-value enum (lib/models/bootloader.py) and an
# unknown value calls `sys.exit(1)` on the whole installer, so `bunny` can never
# go in that field.
#
# The JSON therefore names `text`, as a placeholder this step overwrites seconds
# later. `text` over a graphical stock theme precisely because it looks wrong: if
# the bunny theme fails to install you notice, rather than getting a polished
# stock theme that looks intentional.
#
# Hook position: right after `udev`, before `autodetect`/`kms`/`block`. This
# used to be archinstall's own placement (right before `encrypt`, after
# `block`) — textbook-correct per the Arch Wiki's busybox example, and yet the
# password dialog rendered as a static image that never updated per keystroke
# (author, 2026-09-02). Reading Plymouth's own source (script plugin +
# ply-pixel-display.c) confirmed the sprite-redraw path is a hardware-agnostic
# 50Hz timer independent of hook order, so this was never proven as the root
# cause — but plymouth-debug.log showed `Needed to reset scan out buffer` the
# instant plymouthd grabbed the amdgpu device, right when `block`-then-`kms`
# had it starting late. viacoffee/dotfiles runs the identical Framework 13 AMD
# laptop with `plymouth` right after `udev` and has no such symptom, so this
# repo now matches that placement on that empirical basis, not a proven
# mechanism. If a real fix is ever found, replace this reasoning, don't just
# delete it.
#
# Four things, rebuild only if any changed: the `plymouth` mkinitcpio hook;
# `splash` on the kernel cmdline via /etc/kernel/cmdline, not the
# `KERNEL_CMDLINE[default]+=` drop-in the tool's docs suggest — that operator only
# appends to an already-set value, and this box has none, so a lone `+=splash`
# silently became the entire cmdline and dropped `cryptdevice=`/`root=`; the theme
# files (assets/plymouth/bunny/, script-module, adapted from Arch's stock
# example); and the theme selection.
#
# A broken or absent plymouth does not brick the boot:
# /usr/lib/initcpio/hooks/encrypt calls `plymouth ask-for-password` only when
# `plymouth --ping` succeeds, and falls back to its own plain prompt otherwise.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 45-plymouth.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}
root=${BUNNY_ROOT:?run me through install.sh, or set BUNNY_ROOT}
changed=false

command -v plymouth-set-default-theme >/dev/null || {
	say "  ! plymouth not installed -- run 20-packages.sh first"
	exit 1
}

# 1. HOOKS= gets plymouth, right after udev -- see header for why. Idempotent
# regardless of where (if anywhere) plymouth currently sits: strip it out and
# reinsert in the one position, rather than only handling "absent" vs.
# "already after udev".
mkconf=/etc/mkinitcpio.conf
hooks_line=$(grep '^HOOKS=' "$mkconf")
if [[ $hooks_line == *"(base udev plymouth "* ]]; then
	say "  = HOOKS= already has plymouth right after udev"
elif [[ $hooks_line != *"(base udev "* ]]; then
	say "  ! HOOKS= does not start with '(base udev ', can't place plymouth: $hooks_line"
	exit 1
elif [[ -n $dry ]]; then
	say "  ~ would move plymouth to right after udev in HOOKS="
else
	without_plymouth=${hooks_line/plymouth /}
	new_line=${without_plymouth/(base udev /(base udev plymouth }
	sudo sed -i "s|^HOOKS=.*|$new_line|" "$mkconf"
	grep -q '^HOOKS=(base udev plymouth ' "$mkconf" || {
		say "  ! could not place plymouth after udev in HOOKS="
		exit 1
	}
	say "  + moved plymouth to right after udev in HOOKS="
	changed=true
fi

# 2. splash on the kernel cmdline, via /etc/kernel/cmdline — not the
# KERNEL_CMDLINE[default]+= drop-in, see the header. If the file does not exist
# yet, seed it from the running kernel's own cmdline, then append splash.
kcmd=/etc/kernel/cmdline
if [[ -f $kcmd ]] && grep -qw splash "$kcmd"; then
	say "  = $kcmd already has splash"
elif [[ -n $dry ]]; then
	say "  ~ would add splash to $kcmd"
else
	if [[ -f $kcmd ]]; then
		sudo sed -i 's/$/ splash/' "$kcmd"
	else
		sudo install -Dm644 /dev/stdin "$kcmd" <<<"$(cat /proc/cmdline) splash"
	fi
	grep -qw splash "$kcmd" || {
		say "  ! could not add splash to $kcmd"
		exit 1
	}
	say "  + added splash to $kcmd"
	changed=true
fi

# 3. The theme files.
theme_src="$root/assets/plymouth/bunny"
theme_dest=/usr/share/plymouth/themes/bunny
[[ -d $theme_src ]] || {
	say "  ! $theme_src not found"
	exit 1
}
theme_changed=false
while IFS= read -r -d '' f; do
	rel=${f#"$theme_src"/}
	dest="$theme_dest/$rel"
	# bunny.script carries the username label as @USER@, substituted here the same
	# way as 60-autologin.sh's getty drop-in. Everything else is binary, so it
	# goes through unmodified and is compared with cmp.
	if [[ $rel == bunny.script ]]; then
		if [[ -f $dest ]] && diff -q <(sed "s|@USER@|$USER|" "$f") "$dest" >/dev/null 2>&1; then
			continue
		fi
		if [[ -n $dry ]]; then
			say "  ~ would write $dest"
			theme_changed=true
			continue
		fi
		sed "s|@USER@|$USER|" "$f" | sudo install -Dm644 /dev/stdin "$dest"
		theme_changed=true
		continue
	fi
	if [[ -f $dest ]] && cmp -s "$f" "$dest"; then
		continue
	fi
	if [[ -n $dry ]]; then
		say "  ~ would write $dest"
		theme_changed=true
		continue
	fi
	sudo install -Dm644 "$f" "$dest"
	theme_changed=true
done < <(find "$theme_src" -type f -print0)
if $theme_changed; then
	say "  + theme files written to $theme_dest"
	changed=true
else
	say "  = theme files already match $theme_dest"
fi

# 4. Select the theme.
if [[ $(plymouth-set-default-theme 2>/dev/null || true) == bunny ]]; then
	say "  = default theme already bunny"
elif [[ -n $dry ]]; then
	say "  ~ would set default theme to bunny"
else
	sudo plymouth-set-default-theme bunny
	say "  + default theme set to bunny"
	changed=true
fi

if [[ -n $dry ]]; then exit 0; fi

# Rebuild only if something actually changed. limine-update, not mkinitcpio -P:
# limine-mkinitcpio-hook's /usr/local/bin/mkinitcpio wrapper shadows the real
# binary under sudo's PATH and, on `-P`, only *offers* (interactively) to also
# regenerate the boot entries `limine.conf` actually points at -- easy to miss
# non-interactively. limine-update is the one command that rebuilds the image
# (UKI or not, per /etc/default/limine) and updates limine.conf in one step.
if $changed; then
	sudo limine-update
	say "  ✓ initramfs rebuilt"
else
	say "  = nothing changed, initramfs not rebuilt"
fi

# Verify.
checker="$root/scripts/check-limine.sh"
if [[ -x $checker ]]; then
	sudo "$checker" >/dev/null || {
		say "  ! scripts/check-limine.sh rejected the regenerated limine.conf"
		exit 1
	}
	say "  ✓ check-limine.sh passes"
fi
grep -q '^HOOKS=(base udev plymouth ' "$mkconf" || {
	say "  ! HOOKS= does not have plymouth right after udev after the rebuild"
	exit 1
}
say "  ✓ HOOKS= has plymouth right after udev"
