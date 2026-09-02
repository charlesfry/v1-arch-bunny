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
# The hook position may already be archinstall's, and that is fine. It inserts
# before `encrypt` (so after `block`); the insert below puts it after
# `consolefont` (so before `block`). Both satisfy the real constraints — `kms`
# loaded already, running before `encrypt` prompts — so whichever got there first
# is left alone.
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

# 1. HOOKS= gets plymouth, after consolefont, before block.
mkconf=/etc/mkinitcpio.conf
hooks_line=$(grep '^HOOKS=' "$mkconf")
if [[ $hooks_line == *" plymouth "* || $hooks_line == *"(plymouth "* ]]; then
	say "  = HOOKS= already has plymouth"
elif [[ $hooks_line != *" consolefont "* ]]; then
	say "  ! HOOKS= has no 'consolefont' to insert plymouth after: $hooks_line"
	exit 1
elif [[ -n $dry ]]; then
	say "  ~ would add plymouth to HOOKS="
else
	sudo sed -i 's/consolefont /consolefont plymouth /' "$mkconf"
	grep -q '^HOOKS=.* plymouth ' "$mkconf" || {
		say "  ! could not insert plymouth into HOOKS="
		exit 1
	}
	say "  + added plymouth to HOOKS="
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

# Rebuild only if something actually changed.
if $changed; then
	sudo mkinitcpio -P
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
grep -q '^HOOKS=.* plymouth ' "$mkconf" || {
	say "  ! HOOKS= does not have plymouth after the rebuild"
	exit 1
}
say "  ✓ HOOKS= has plymouth"
