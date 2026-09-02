#!/usr/bin/env bash
# zram swap, sized ram/2, with the two sysctls that make it worth having.
# CHOICES.md `swap-zram` — zram only, no disk swap, no hibernation.
#
# Why each value is here, since a config file should carry only deviations:
#
#   zram-size = ram / 2   The shipped default is `min(ram / 2, 4096)`; see
#                         /usr/share/doc/zram-generator/zram-generator.conf.example.
#                         Uncapping it gives a 16 GiB machine 8 GiB instead of 4.
#   vm.swappiness = 180   The kernel's default of 60 encodes "swap is a slow
#                         disk", which is wrong when swap is RAM.
#   vm.page-cluster = 0   Swap readahead is waste with no seek cost. Default 3
#                         reads 8 pages to use one.
#
# No `compression-algorithm` line: `CONFIG_ZRAM_DEF_COMP="zstd"` on Arch's
# `linux`, so stating zstd would be restating upstream. `zramctl` prints the
# algorithm actually in use.
#
# archinstall's swap option stays on in the JSON because it straps
# `zram-generator`, enables `systemd-zram-setup@zram0.service`, and appends
# `zswap.enabled=0` to the kernel command line (installer.py:1041, 1195) — the
# last of which is correct when swapping to zram and which nothing here would do.
# It cannot replace this step: it writes no `zram-size`, so the shipped cap stays,
# and it has no sysctl mechanism.
#
# It also writes the same file this step owns — `setup_swap` emits `[zram0]` plus
# `compression-algorithm` (installer.py:1037-1039), and `install_file` below
# replaces that file wholesale. So the JSON no longer names an algorithm; stating
# one there claimed a setting that was silently discarded.
#
# It matters beyond swap: `oom-protection` relies on systemd-oomd, whose
# swap-pressure kill path is inert on a machine with no swap.
#
# Idempotent: writes only when the content differs, and says which case it hit.
# Honours BUNNY_DRY_RUN.
#
# Usage: 30-zram.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

# Write $2 to $1 as root, but only if it is not already exactly that. The
# comparison is the idempotency: a rewritten file is a changed mtime, a diff for
# anyone auditing, and a lie in the log about what this run did.
install_file() {
	local path=$1 content=$2
	if [[ -f $path ]] && [[ $(cat -- "$path") == "$content" ]]; then
		say "  = $path already correct"
		return
	fi
	if [[ -n $dry ]]; then
		say "  ~ would write $path"
		return
	fi
	sudo install -Dm644 /dev/stdin "$path" <<<"$content"
	say "  + wrote $path"
}

# Checked, not installed: `zram-generator` is a `swap-zram` package in the ledger,
# so 20-packages.sh has already put it there. What is left is to fail loudly if it
# is somehow absent rather than write a config nothing reads.
pacman -Qq zram-generator >/dev/null 2>&1 || {
	say "  ! zram-generator is not installed -- run 20-packages.sh first"
	exit 1
}
say "  = zram-generator installed"

install_file /etc/systemd/zram-generator.conf "$(
	cat <<'EOF'
[zram0]
zram-size = ram / 2
EOF
)"

install_file /etc/sysctl.d/99-zram.conf "$(
	cat <<'EOF'
vm.swappiness = 180
vm.page-cluster = 0
EOF
)"

# zram-generator is a generator: it builds the swap unit at daemon-reload, so
# nothing here needs enabling. Applying the sysctls now rather than at next boot is
# the only active step, and both are cheap to set live.
if [[ -n $dry ]]; then
	say "  ~ would reload systemd generators and apply sysctls"
	exit 0
fi

sudo systemctl daemon-reload
sudo sysctl -q --system

# A generator that silently produced no unit, or a sysctl file shadowed by a
# higher-numbered one, both look exactly like success from here.
if ! swapon --show=NAME --noheadings | grep -q '^/dev/zram'; then
	say "  ! no /dev/zram* in swapon output — zram-generator produced no swap device"
	say "    check: systemctl status systemd-zram-setup@zram0.service"
	exit 1
fi
say "  ✓ zram active: $(swapon --show=NAME,SIZE --noheadings | tr -s ' ' ' ')"

for kv in vm.swappiness=180 vm.page-cluster=0; do
	got=$(sysctl -n "${kv%%=*}")
	if [[ $got != "${kv##*=}" ]]; then
		say "  ! ${kv%%=*} is $got, expected ${kv##*=} — something later in sysctl.d overrides it"
		exit 1
	fi
done
say "  ✓ vm.swappiness=180 vm.page-cluster=0"
