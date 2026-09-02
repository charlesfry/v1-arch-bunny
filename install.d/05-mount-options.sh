#!/usr/bin/env bash
# btrfs mount options: `noatime,compress=zstd:1`. CHOICES.md `filesystem`.
# Level 1 rather than zstd's default of 3, which spends two to three times the CPU
# per write to buy space — and space is not a metric here while latency is.
#
# Not an archinstall `mount_options` line because archinstall cannot express
# either: `BtrfsMountOption.compress` is the literal string `compress=zstd` with
# no level (lib/models/device.py:513), and `noatime` is absent from its source.
# So it has to be applied after the fact, by editing fstab.
#
# Being an edit to /etc/fstab, it does the smallest possible thing: rewrites only
# the options field, only on btrfs lines, only when one of the two is missing, and
# keeps the original beside it.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 05-mount-options.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

readonly FSTAB=/etc/fstab
readonly WANT_COMPRESS='compress=zstd:1'

# Rewrite field 4 of every btrfs line: drop any existing compress= or atime
# setting, then append ours. Everything else in the field is preserved in place.
new=$(sudo awk -v want="$WANT_COMPRESS" '
	/^[[:space:]]*#/ || NF < 4 || $3 != "btrfs" { print; next }
	{
		n = split($4, opt, ",")
		out = ""
		for (i = 1; i <= n; i++) {
			if (opt[i] ~ /^compress(-force)?=/) continue
			if (opt[i] == "noatime" || opt[i] == "relatime" || opt[i] == "atime" || opt[i] == "strictatime") continue
			out = out (out == "" ? "" : ",") opt[i]
		}
		$4 = out (out == "" ? "" : ",") "noatime," want
		print
	}
' OFS='\t' "$FSTAB")

if [[ $(sudo cat -- "$FSTAB") == "$new" ]]; then
	say "  = every btrfs line already has noatime,$WANT_COMPRESS"
elif [[ -n $dry ]]; then
	say "  ~ would add noatime,$WANT_COMPRESS to the btrfs lines in $FSTAB"
else
	sudo cp -a -- "$FSTAB" "$FSTAB.bunny.bak"
	printf '%s\n' "$new" | sudo tee "$FSTAB" >/dev/null
	say "  + rewrote the btrfs option fields in $FSTAB (original at $FSTAB.bunny.bak)"
fi

if [[ -n $dry ]]; then exit 0; fi

# Apply now rather than at next boot. A remount cannot change compression for data
# already written, so this is only about not waiting for a reboot.
mapfile -t mounts < <(findmnt -rno TARGET -t btrfs)
for m in "${mounts[@]}"; do
	sudo mount -o remount "$m" 2>/dev/null || say "  ! could not remount $m — it will apply at next boot"
done

# Verify against the kernel rather than the file: a typo in fstab remounts fine
# and reverts at reboot.
bad=()
for m in "${mounts[@]}"; do
	opts=$(findmnt -rno OPTIONS "$m")
	[[ $opts == *noatime* && $opts == *"$WANT_COMPRESS"* ]] || bad+=("$m ($opts)")
done
if ((${#bad[@]} > 0)); then
	say "  ! these btrfs mounts do not have both options live:"
	for b in "${bad[@]}"; do say "    $b"; done
	exit 1
fi
say "  ✓ ${#mounts[@]} btrfs mount(s) with noatime,$WANT_COMPRESS"
