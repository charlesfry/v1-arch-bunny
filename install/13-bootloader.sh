#!/usr/bin/env bash
# The boot path: mkinitcpio hooks, kernel command line, Plymouth, snapper, and
# one authoritative Limine generation.
#
# This is the phase the whole repo was rebuilt around, so the shape matters:
# nothing here writes the live boot configuration without first keeping a copy of
# the one that is known to work, and every failure below restores it. A machine
# that will not boot cannot be fixed from inside itself.
#
# The single-generator rule is the other half. mkinitcpio's own UKI preset is
# commented out so `limine-update` is the only thing that builds a boot image;
# two generators racing is how an ESP ends up holding an image no kernel update
# has ever touched.

log "Configuring Limine bootloader..."

if ! command_exists limine-mkinitcpio; then
	error "limine-mkinitcpio-hook not found — 10-packages.sh should have installed it"
	return 1
fi
if ! command_exists limine-snapper-sync; then
	error "limine-snapper-sync not found — 10-packages.sh should have installed it"
	return 1
fi
if [[ ! -d /sys/firmware/efi ]]; then
	error "Not an EFI system"
	return 1
fi

# HOOKS, as a drop-in rather than an edit to the pacman-owned mkinitcpio.conf.
#
# `plymouth` sits immediately after `udev` so the splash owns the console before
# anything else can print to it, and `keyboard` before `autodetect` so every
# keyboard driver is included rather than only the ones loaded on the build
# machine — the Arch wiki's stated ordering, and the difference between a LUKS
# prompt you can type into and one you cannot.
#
# `btrfs-overlayfs` is what makes a read-only snapshot bootable, which is the
# entire point of the snapshot entries further down. No `fsck` (btrfs has no boot
# time check) and no `consolefont` (the splash covers the console).
sudo install -Dm644 /dev/stdin /etc/mkinitcpio.conf.d/bunny-hooks.conf <<'HOOKS'
HOOKS=(base udev plymouth keyboard autodetect microcode modconf kms keymap block encrypt filesystems btrfs-overlayfs)
HOOKS
success "Wrote mkinitcpio HOOKS drop-in"

# The ESP may only be readable by root, hence `sudo test`.
log "Finding limine config..."
limine_config=""
for candidate in \
	/boot/EFI/arch-limine/limine.conf \
	/boot/EFI/BOOT/limine.conf \
	/boot/EFI/limine/limine.conf \
	/boot/limine/limine.conf \
	/boot/limine.conf; do
	if sudo test -f "$candidate"; then
		limine_config="$candidate"
		break
	fi
done
if [[ -z $limine_config ]]; then
	error "Limine config not found"
	return 1
fi
success "Limine config: $limine_config"

# Read the command line out of the running configuration before overwriting it.
# cryptdevice=, root= and rootflags= are per-machine facts produced by the base
# install; guessing them is how a machine stops booting.
CMDLINE=$(sudo grep "^[[:space:]]*cmdline:" "$limine_config" 2>/dev/null |
	head -1 |
	sed 's/^[[:space:]]*cmdline:[[:space:]]*//' || true)

if [[ -z $CMDLINE ]]; then
	error "No cmdline found in $limine_config — refusing to invent one"
	error "Verify that config by hand before re-running"
	return 1
fi
log "Limine cmdline: $CMDLINE"

# Strip the arguments this repo manages before re-adding them, so repeated runs
# cannot grow the command line. The predecessor installer appended `splash`
# unconditionally and left `splash splash` behind.
#
# A token filter, not a regex substitution. The obvious
# `s/(^|[[:space:]])arg([[:space:]]|$)//g` is wrong on adjacent duplicates: the
# first match consumes the separator the second one needs to match, so exactly
# one copy of a doubled argument survives — which is the bug being fixed here,
# and it would have re-grown the line on every run.
readonly MANAGED_ARGS=(
	quiet splash nowatchdog plymouth.ignore-serial-consoles
	loglevel=3 systemd.show_status=auto rd.udev.log_level=3
)
read -r -a cmdline_tokens <<<"$CMDLINE"
kept_tokens=()
for token in "${cmdline_tokens[@]}"; do
	is_managed=false
	for managed_arg in "${MANAGED_ARGS[@]}"; do
		if [[ $token == "$managed_arg" ]]; then
			is_managed=true
			break
		fi
	done
	if ! $is_managed; then
		kept_tokens+=("$token")
	fi
done
CMDLINE="${kept_tokens[*]}"
log "Limine cmdline, managed arguments stripped: $CMDLINE"

CMDLINE_ESCAPED=$(printf '%s\n' "$CMDLINE" | sed 's/[&\\]/\\&/g')
staged_limine_defaults=$(mktemp)
cp "$BUNNY_DEFAULTS/limine/default.conf" "$staged_limine_defaults"
sed -i "s|@@CMDLINE@@|$CMDLINE_ESCAPED|g" "$staged_limine_defaults"
sudo install -m 644 "$staged_limine_defaults" /etc/default/limine.bunny-new
sudo mv /etc/default/limine.bunny-new /etc/default/limine
rm -f "$staged_limine_defaults"
success "Wrote /etc/default/limine"

# Preserve the known-working configuration before asking Limine to update it, and
# keep the active file valid throughout — never replace it with an entry-less
# template and then generate.
last_known_limine_config=/boot/limine.conf.bunny-last-known-good
sudo cp "$limine_config" "${last_known_limine_config}.bunny-new"
sudo mv "${last_known_limine_config}.bunny-new" "$last_known_limine_config"

restore_last_known_limine_configuration() {
	sudo cp "$last_known_limine_config" /boot/limine.conf.bunny-new
	sudo mv /boot/limine.conf.bunny-new /boot/limine.conf
}

# Converge on the one path the tooling maintains. limine-common-functions
# hardcodes LIMINE_CONFIG_PATH="${ESP_PATH}/limine.conf", so limine-entry-tool,
# limine-snapper-sync and limine-mkinitcpio-hook all read and write /boot/
# limine.conf. archinstall nests its copy under EFI/arch-limine/, which then goes
# stale while snapshot and kernel entries land in the other file. The copy is
# promoted before the old path is removed, so an interruption cannot leave the
# ESP without a configuration.
if [[ $limine_config != /boot/limine.conf ]]; then
	sudo cp "$limine_config" /boot/limine.conf.bunny-new
	sudo mv /boot/limine.conf.bunny-new /boot/limine.conf
	sudo rm -f -- "$limine_config"
	limine_config=/boot/limine.conf
	success "Normalised Limine configuration to /boot/limine.conf"
fi
success "Last known-working Limine configuration retained at $last_known_limine_config"

# Snapper, for the snapshot entries the menu will carry.
if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
	run_logged "Creating snapper config: root" sudo snapper -c root create-config /
fi
if ! sudo snapper list-configs 2>/dev/null | grep -q "home"; then
	run_logged "Creating snapper config: home" sudo snapper -c home create-config /home
fi

# Quotas are what snapper's space-aware retention actually runs on.
log "Checking btrfs quota..."
if sudo btrfs quota status / | grep -qE '^[[:space:]]*Enabled:[[:space:]]+yes'; then
	success "Btrfs quota already enabled"
else
	run_logged "Enabling btrfs quota" sudo btrfs quota enable /
fi

# No timeline snapshots — snap-pac brackets each pacman transaction, which is
# when things actually break. Caps are deliberately tight; snapshot bloat filling
# the disk is one of the failures this repo exists to prevent.
sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^SPACE_LIMIT="0.5"/SPACE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}
sudo sed -i 's/^FREE_LIMIT="0.2"/FREE_LIMIT="0.3"/' /etc/snapper/configs/{root,home}
success "Snapper retention configured"

log "Blacklisting hardware watchdog modules..."
sudo install -Dm644 "$BUNNY_DEFAULTS/modprobe/nowatchdog.conf" /etc/modprobe.d/nowatchdog.conf

log "Installing Plymouth theme..."
plymouth_theme_dir=/usr/share/plymouth/themes/bunny
run_logged "Creating Plymouth theme directory" sudo install -d "$plymouth_theme_dir"
run_logged "Copying Plymouth theme contents" \
	sudo cp -a "$BUNNY_DEFAULTS/plymouth/." "$plymouth_theme_dir/"
if [[ $(plymouth-set-default-theme) != bunny ]]; then
	run_logged "Setting default Plymouth theme" sudo plymouth-set-default-theme bunny
fi
success "Plymouth theme configured"

# One generator. mkinitcpio's own UKI preset would build a second image that
# limine.conf never references and no one ever updates.
log "Disabling the default mkinitcpio UKI preset..."
preset="/etc/mkinitcpio.d/linux.preset"
if [[ -f $preset ]] && grep -q '^default_uki=' "$preset"; then
	sudo sed -i 's/^default_uki=/#default_uki=/;s/^fallback_uki=/#fallback_uki=/;s/^default_options=/#default_options=/' "$preset"
	success "Disabled the default UKI in the mkinitcpio preset"
fi

expected_uki=/boot/EFI/Linux/bunny_linux.efi
limine_output=$(mktemp)
if ! run_logged "Running authoritative Limine generation" \
	sudo limine-update | tee "$limine_output"; then
	rm -f "$limine_output"
	restore_last_known_limine_configuration
	error "Restored the last known-working Limine configuration"
	return 1
fi
if ! grep -Fq 'Unified kernel image generation successful' "$limine_output"; then
	rm -f "$limine_output"
	restore_last_known_limine_configuration
	error "Limine generation did not report a successful UKI build; restored the last known-working configuration"
	return 1
fi
rm -f "$limine_output"

# Everything below proves the artifacts before committing to them. `limine-update`
# exiting 0 is not the same as a bootable machine.
log "Validating Limine and UKI artifacts..."
if ! sudo test -s /boot/limine.conf; then
	restore_last_known_limine_configuration
	error "Generated Limine configuration is missing or empty; restored the last known-working configuration"
	return 1
fi
if ! sudo grep -Fq 'bunny_linux.efi' /boot/limine.conf; then
	restore_last_known_limine_configuration
	error "Generated Limine configuration does not reference the expected UKI; restored the last known-working configuration"
	return 1
fi
if ! sudo test -s "$expected_uki"; then
	restore_last_known_limine_configuration
	error "Expected UKI is missing or empty: $expected_uki; restored the last known-working configuration"
	return 1
fi

# The three things that must be inside the image for this machine to reach a
# login: the LUKS unlock, the splash that asks for the passphrase, and the
# filesystem the root subvolume lives on.
initramfs_listing=$(sudo lsinitcpio -l "$expected_uki")
for required_command in cryptsetup plymouth btrfs; do
	if ! grep -Eq "(^|/)${required_command}$" <<<"$initramfs_listing"; then
		restore_last_known_limine_configuration
		error "Generated UKI does not contain: $required_command; restored the last known-working configuration"
		return 1
	fi
done
success "UKI contains cryptsetup, plymouth and btrfs"

# Commit: the presentation header this repo owns, plus the entries limine-update
# generated. Entries pointing at the disabled default-preset UKIs are dropped
# before those files are removed.
staged_limine_config=$(mktemp)
cp "$BUNNY_DEFAULTS/limine/limine.conf" "$staged_limine_config"
if ! sudo awk '
  function flush_entry() {
    if (entry != "" && entry !~ /\/EFI\/Linux\/arch-linux(-fallback)?\.efi/) {
      printf "%s", entry
    }
    entry = ""
  }
  /^\// { flush_entry(); entry = $0 ORS; next }
  entry != "" { entry = entry $0 ORS }
  END { flush_entry() }
' /boot/limine.conf | tee -a "$staged_limine_config" >/dev/null; then
	rm -f "$staged_limine_config"
	restore_last_known_limine_configuration
	error "Failed to stage generated Limine entries; restored the last known-working configuration"
	return 1
fi
if ! grep -Fq 'bunny_linux.efi' "$staged_limine_config" ||
	grep -Eq '/EFI/Linux/arch-linux(-fallback)?\.efi' "$staged_limine_config"; then
	rm -f "$staged_limine_config"
	restore_last_known_limine_configuration
	error "Staged Limine configuration is invalid; restored the last known-working configuration"
	return 1
fi

# `default_entry: 1` in the header names the first entry in the file. Limine will
# not boot a folder: it silently forces the timeout off and waits for input
# forever, and the only symptom is a machine that never comes up. So prove the
# first entry is a bootable leaf, not a heading.
if ! awk '
  /^\/[^\/]/ { if (seen) exit; seen = 1; next }
  seen && /^\/\// { exit }
  seen && /^[[:space:]]*(protocol|path):/ { leaf = 1; exit }
  END { exit(leaf ? 0 : 1) }
' "$staged_limine_config"; then
	rm -f "$staged_limine_config"
	restore_last_known_limine_configuration
	error "First entry in the staged Limine configuration is a folder, not a bootable entry"
	error "default_entry: 1 would hang the boot menu; restored the last known-working configuration"
	return 1
fi

sudo install -m 644 "$staged_limine_config" /boot/limine.conf.bunny-new
sudo mv /boot/limine.conf.bunny-new /boot/limine.conf
rm -f "$staged_limine_config"
success "Limine configuration and UKI validated and committed"

# Only now is the new configuration the one to fall back to, and only now is it
# safe to remove images the previous configuration referenced.
sudo cp /boot/limine.conf "${last_known_limine_config}.bunny-new"
sudo mv "${last_known_limine_config}.bunny-new" "$last_known_limine_config"
if ! sudo test -s "$last_known_limine_config"; then
	error "Last known-working Limine configuration is missing or empty"
	return 1
fi

log "Cleaning stale UKIs..."
for stale in /boot/EFI/Linux/arch-linux.efi /boot/EFI/Linux/arch-linux-fallback.efi; do
	if sudo test -f "$stale"; then
		run_logged "Removing stale UKI: $stale" sudo rm "$stale"
	fi
done

# Boot generation is authoritative again from here on.
remove_pacman_generation_override
success "Bootloader configured"
