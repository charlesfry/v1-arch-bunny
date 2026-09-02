#!/usr/bin/env bash
# Print the packages this machine's hardware needs, one per line.
#
# Five packages in CHOICES.md are decided but conditional — right on one machine
# and wrong on the next — so they cannot live in the Packages column, which
# 20-packages.sh consumes as a flat list of things that install everywhere. The
# ledger already says the installer detects them instead (`firmware-set`,
# `microcode`, `gpu-driver`). This script is that detection, in one place.
#
#   amd-ucode / intel-ucode   `microcode` — CPU vendor, read from /proc/cpuinfo's
#                             vendor_id as the row asks. Until now nothing did:
#                             the row is `picked` with packages `—`.
#   nvidia-open nvidia-prime  `gpu-driver` — an NVIDIA display controller. Scope
#                             is settled: NVIDIA or integrated, never a competing
#                             dGPU vendor.
#   intel-media-driver        `gpu-driver` — an Intel display controller. VA-API,
#                             kept on measurement (1.8 MB PSS, 204 ms of real
#                             drm-engine-video time).
#   linux-firmware-amdgpu     `firmware-set` — an AMD display controller; the
#                             expected Framework is the AMD variant.
#                             `linux-firmware-radeon` is deliberately not here:
#                             `radeon` drives pre-GCN cards, a Ryzen iGPU is
#                             `amdgpu`.
#
# sysfs, not `lspci`. `pciutils` is a hard dependency of `base` so lspci would
# always be there, but its output is formatted for humans;
# /sys/bus/pci/devices/*/{class,vendor} is the same data as fixed-width hex and
# cannot be reshaped by a locale or a flag. Class 0x03 is "display controller";
# the vendor IDs are PCI-SIG assignments — 0x10de NVIDIA, 0x1002 AMD, 0x8086
# Intel.
#
# No firmware split is gated here beyond -amdgpu, on purpose. Gating
# `linux-firmware-intel` and friends on the wifi chip currently in the machine
# would trade a priority-1 failure — plug in a card, or boot the disk in another
# body, and there is no firmware for it — for a saving in megabytes, and disk is
# not a metric.
#
# Reads only. No root, no network, nothing installed; 20-packages.sh does the
# installing inside its single `-Syu` transaction.
#
# Package names on stdout, the reasoning on stderr, so
# `mapfile -t < <(hardware-packages.sh)` gets a clean list.
#
# Usage: hardware-packages.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
pkgs=()

# CPU: microcode. `$NF` rather than a ': ' split — the line is
# "vendor_id\t: AuthenticAMD" and the whitespace before the colon is a tab on some
# kernels and spaces on others.
vendor=$(awk '/^vendor_id/ {print $NF; exit}' /proc/cpuinfo)
case "$vendor" in
AuthenticAMD)
	pkgs+=(amd-ucode)
	say "  cpu $vendor -> amd-ucode"
	;;
GenuineIntel)
	pkgs+=(intel-ucode)
	say "  cpu $vendor -> intel-ucode"
	;;
*)
	# Not a graceful degrade. Microcode updates carry security and errata fixes,
	# and a machine silently running without them looks identical to one that has
	# them. A third x86 vendor needs a decision in CHOICES.md `microcode`.
	say "  ! unknown CPU vendor '$vendor' -- no microcode package is known for it"
	say "    CHOICES.md 'microcode' covers AuthenticAMD and GenuineIntel only."
	exit 1
	;;
esac

# GPU: driver, VA-API, firmware. nullglob so a machine with no PCI bus at all
# yields an empty loop rather than one iteration over the literal glob.
shopt -s nullglob
gpu_vendors=()
for dev in /sys/bus/pci/devices/*; do
	[[ -r $dev/class && -r $dev/vendor ]] || continue
	[[ $(<"$dev/class") == 0x03* ]] || continue
	gpu_vendors+=("$(<"$dev/vendor")")
done
shopt -u nullglob

mapfile -t gpu_vendors < <(printf '%s\n' "${gpu_vendors[@]+"${gpu_vendors[@]}"}" | sort -u)

for v in "${gpu_vendors[@]+"${gpu_vendors[@]}"}"; do
	case "$v" in
	0x10de)
		pkgs+=(nvidia-open nvidia-prime)
		say "  gpu $v NVIDIA -> nvidia-open nvidia-prime"
		;;
	0x1002)
		pkgs+=(linux-firmware-amdgpu)
		say "  gpu $v AMD -> linux-firmware-amdgpu"
		;;
	0x8086)
		pkgs+=(intel-media-driver)
		say "  gpu $v Intel -> intel-media-driver"
		;;
	*)
		# Expected on a VM (virtio-gpu is 0x1af4) and on any GPU this repo has made
		# no decision about. One quiet line, not a failure.
		say "  i gpu $v -- no BunnE row claims a package for this vendor"
		;;
	esac
done

((${#gpu_vendors[@]} > 0)) || say "  i no PCI display controller found -- no GPU packages"

printf '%s\n' "${pkgs[@]}"
