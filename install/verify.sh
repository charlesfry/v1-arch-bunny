#!/usr/bin/env bash
# Read-only checks against an installed BunnE system.
#
# Run as the normal installation user; some boot and firewall checks ask for
# sudo. Nothing here writes anything. Exits non-zero if any check failed, so it
# is usable as a gate.
#
# The point is to catch the failures that are silent from the outside: a unit
# that is enabled but points at a missing binary, a UKI that exists but has no
# cryptsetup in it, a symlink that survived a `git clean` pointing nowhere.

set -uo pipefail

BUNNY_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readonly BUNNY_ROOT
readonly UKI=/boot/EFI/Linux/dot_linux.efi

pass_count=0 fail_count=0 skip_count=0

usage() {
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
}
[[ ${1:-} == -h || ${1:-} == --help ]] && usage

pass() {
	printf 'PASS %s\n' "$1"
	((pass_count += 1))
}
fail() {
	printf 'FAIL %s\n' "$1"
	[[ -n ${2:-} ]] && printf '     %s\n' "$2"
	((fail_count += 1))
}
skip() {
	printf 'SKIP %s\n' "$1"
	((skip_count += 1))
}
section() { printf '\n== %s ==\n' "$1"; }

check() {
	local description=$1
	shift
	if "$@" >/dev/null 2>&1; then
		pass "$description"
	else
		fail "$description" "command: $(printf '%q ' "$@")"
	fi
}
check_system_unit() { check "system unit enabled: $1" systemctl is-enabled --quiet "$1"; }
check_user_unit() { check "user unit enabled: $1" systemctl --user is-enabled --quiet "$1"; }
check_disabled_unit() {
	if systemctl is-enabled --quiet "$1" 2>/dev/null; then
		fail "system unit should be disabled: $1"
	else
		pass "system unit disabled: $1"
	fi
}

# --- predicates -----------------------------------------------------------

root_is_encrypted_btrfs() {
	[[ $(findmnt -no FSTYPE /) == btrfs ]] && [[ $(findmnt -no SOURCE /) == /dev/mapper/* ]]
}
uki_contains() { sudo lsinitcpio -l "$UKI" | grep -Eq "(^|/)$1$"; }
limine_references_uki() { sudo grep -Fq "$(basename "$UKI")" /boot/limine.conf; }
limine_has_no_stale_entries() { ! sudo grep -Eq '/EFI/Linux/arch-linux(-fallback)?\.efi' /boot/limine.conf; }
plymouth_theme_is_dot() { [[ $(plymouth-set-default-theme) == dot ]]; }
hooks_dropin_is_ours() {
	grep -q '^HOOKS=(base udev plymouth keyboard autodetect' /etc/mkinitcpio.conf.d/dot_hooks.conf
}
cmdline_has_no_duplicates() {
	local dupes
	dupes=$(tr ' ' '\n' </proc/cmdline | grep -v '^$' | sort | uniq -d)
	[[ -z $dupes ]]
}
mkinitcpio_uki_preset_disabled() {
	! grep -q '^default_uki=' /etc/mkinitcpio.d/linux.preset
}
hook_override_is_gone() { ! compgen -G '/run/bunny-install/*/pacman-hooks' >/dev/null; }
resolved_owns_resolv_conf() { [[ $(readlink /etc/resolv.conf) == *stub-resolv* ]]; }
nftables_has_ruleset() { [[ -n $(sudo nft list ruleset 2>/dev/null) ]]; }
nftables_allows_docker() { sudo nft list ruleset | grep -q 'iifname "docker0" accept'; }
subvol_mounted() { [[ $(findmnt -no OPTIONS "$2" 2>/dev/null) == *"subvol=/$1"* ]]; }
links_into_repo() { [[ -L $1 && $(readlink -- "$1") == "$BUNNY_ROOT"/* ]]; }
venv_imports() { "$HOME/.venvs/neovim/bin/python" -c "import $1"; }

# --- checks ---------------------------------------------------------------

section "Boot"
check "system booted in EFI mode" test -d /sys/firmware/efi
check "root is encrypted btrfs" root_is_encrypted_btrfs
check "UKI exists and is non-empty" sudo test -s "$UKI"
for required in cryptsetup plymouth btrfs; do
	check "UKI contains $required" uki_contains "$required"
done
check "limine.conf exists and is non-empty" sudo test -s /boot/limine.conf
check "limine.conf references the expected UKI" limine_references_uki
check "limine.conf has no stale default-preset UKI entries" limine_has_no_stale_entries
check "last known-working limine.conf retained" sudo test -s /boot/limine.conf.bunny-last-known-good
check "mkinitcpio HOOKS drop-in is ours" hooks_dropin_is_ours
check "mkinitcpio's own UKI preset is disabled" mkinitcpio_uki_preset_disabled
check "Plymouth theme is 'dot'" plymouth_theme_is_dot
check "kernel cmdline has splash" grep -qw splash /proc/cmdline
check "kernel cmdline has no duplicated arguments" cmdline_has_no_duplicates
check "no pacman hook override left behind" hook_override_is_gone

section "Packages"
missing_packages=()
while read -r package; do
	pacman -Q "$package" >/dev/null 2>&1 || missing_packages+=("$package")
done < <(grep -Ev '^(#|[[:space:]]*$)' "$BUNNY_ROOT/install/packages" "$BUNNY_ROOT/install/packages-aur" 2>/dev/null | sed 's/^[^:]*://')
if ((${#missing_packages[@]} == 0)); then
	pass "every package in install/packages is installed"
else
	fail "packages not installed: ${missing_packages[*]}"
fi
check "[omarchy] repository is configured" pacman-conf --repo omarchy
check "original pacman.conf backup exists" sudo test -s /etc/pacman.conf.bunny-original
for font in noto-fonts ttf-dejavu ttf-liberation ttf-nerd-fonts-symbols-mono ttf-space-mono-nerd; do
	check "font installed: $font" pacman -Q "$font"
done

section "System services"
for unit in bluetooth.service iwd.service systemd-networkd.service systemd-resolved.service \
	greetd.service power-profiles-daemon.service limine-snapper-sync.service \
	nftables.service docker.socket systemd-oomd.service; do
	check_system_unit "$unit"
done
check_disabled_unit NetworkManager.service
check_disabled_unit snapper-timeline.timer
check_disabled_unit systemd-networkd-wait-online.service
check "resolv.conf points at the resolved stub" resolved_owns_resolv_conf

section "User session"
for unit in waybar mako swaybg swayidle swayosd cliphist polkit-agent; do
	check_user_unit "$unit.service"
done
check_user_unit disk-usage-alert.timer
check "niri.service user unit is disabled (uwsm owns the session)" \
	bash -c '! systemctl --user is-enabled --quiet niri.service'
check "greetd config names this user" sudo grep -q "user = \"$(id -un)\"" /etc/greetd/config.toml

section "Dotfiles"
for target in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile" \
	"${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl" \
	"${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf" \
	"$HOME/.local/bin/bunny-lock"; do
	check "links into the repo: ${target#"$HOME"/}" links_into_repo "$target"
done
if command -v niri >/dev/null; then
	check "niri accepts the deployed config" \
		niri validate --config "${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"
else
	skip "niri validate (niri not installed)"
fi

section "Firewall"
check "nftables has a ruleset loaded" nftables_has_ruleset
check "nftables allows docker0 forwarding" nftables_allows_docker

section "Docker storage"
check "/var/lib/docker is on @dockervol" subvol_mounted @dockervol /var/lib/docker
check "/var/lib/containerd is on @containerd" subvol_mounted @containerd /var/lib/containerd
check "$(id -un) is in the docker group" bash -c "id -nG | grep -qw docker"

section "Neovim Python environment"
if [[ -x $HOME/.venvs/neovim/bin/python ]]; then
	for module in pynvim jupyter_client ipykernel matplotlib PIL sympy pnglatex; do
		check "venv imports $module" venv_imports "$module"
	done
	check "'bunny' Jupyter kernel registered" \
		test -d "${XDG_DATA_HOME:-$HOME/.local/share}/jupyter/kernels/bunny"
else
	fail "the Neovim venv does not exist" "expected $HOME/.venvs/neovim/bin/python"
fi

section "Tools"
check "claude is installed" test -x "$HOME/.local/bin/claude"

printf '\n%d passed, %d failed, %d skipped\n' "$pass_count" "$fail_count" "$skip_count"
((fail_count == 0))
