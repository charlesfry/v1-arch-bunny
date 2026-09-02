#!/usr/bin/env bash
# Add the `[omarchy]` binary repo, pinned to its publisher's key. CHOICES.md
# `snapshot-boot-entries` — this exists for exactly one package,
# `limine-snapper-sync`, which Arch does not carry and which cannot be built from
# source today (Arch's `gradle` regression, still unfixed).
#
# The trust posture is narrower than upstream's. Their instructions use
# `SigLevel = Optional TrustAll` — verification off, which would let whoever
# controls pkgs.omarchy.org install arbitrary root-level packages. The repo does
# sign its packages; only its database is unsigned. So:
#
#   SigLevel = Required DatabaseOptional   packages must be signed, db need not be
#   listed LAST in pacman.conf             official repos shadow it
#
# What is trusted is Omarchy's publisher key for packages Arch lacks, not whatever
# that host serves. The key is imported the way upstream's own
# `omarchy-update-keyring` does it.
#
# Idempotent: the key, the local signature and the repo block are checked
# separately, because a machine can be in any partial combination of the three.
# Honours BUNNY_DRY_RUN.
#
# Usage: 10-omarchy-repo.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

readonly FPR=40DFB630FF42BCFFB047046CF0134EE680CAC571
readonly KEYSERVER=keys.openpgp.org
readonly CONF=/etc/pacman.conf

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

# The key.
if sudo pacman-key --list-keys "$FPR" >/dev/null 2>&1; then
	say "  = publisher key $FPR present"
elif [[ -n $dry ]]; then
	say "  ~ would import key $FPR from $KEYSERVER"
else
	sudo pacman-key --recv-keys "$FPR" --keyserver "$KEYSERVER" ||
		{
			say "  ! could not fetch $FPR from $KEYSERVER"
			say "    without it, nothing from [omarchy] can install. Import it by hand"
			say "    and re-run, or check the network."
			exit 1
		}
	say "  + imported key $FPR"
fi

# A key in the keyring is not a trusted key. `pacman-key --lsign-key` signs it
# with this machine's master key, which is what moves it to `full` trust and lets
# a package validate. `sig   L` in --list-sigs is that local signature.
if sudo pacman-key --list-sigs "$FPR" 2>/dev/null | grep -q '^sig   L'; then
	say "  = key locally signed (trusted)"
elif [[ -n $dry ]]; then
	say "  ~ would locally sign $FPR"
else
	sudo pacman-key --lsign-key "$FPR"
	say "  + locally signed $FPR"
fi

# The repo block, appended at end of file — which is what "after the official
# repos" means in practice, and is what stops it shadowing anything Arch carries.
if grep -q '^\[omarchy\]' "$CONF"; then
	say "  = [omarchy] already in $CONF"
elif [[ -n $dry ]]; then
	say "  ~ would append [omarchy] to $CONF"
else
	sudo tee -a "$CONF" >/dev/null <<'EOF'

[omarchy]
SigLevel = Required DatabaseOptional
Server = https://pkgs.omarchy.org/stable/$arch
EOF
	say "  + appended [omarchy] to $CONF"
fi

if [[ -n $dry ]]; then
	say "  ~ would sync package databases and verify the repo resolves"
	exit 0
fi

# Prove it resolves rather than assuming the config took: a typo in the Server
# line, the wrong ordering, or an unsigned key all leave a pacman.conf that looks
# perfect.
#
# A bare `-Sy` leaves the database ahead of the installed system, which is a
# partial upgrade. Safe here only because the next step is `pacman -Syu`, which
# reconciles it — see 20-packages.sh.
sudo pacman -Sy --noconfirm >/dev/null
repo=$(pacman -Si limine-snapper-sync 2>/dev/null | awk '/^Repository/{print $3; exit}')
if [[ $repo != omarchy ]]; then
	say "  ! limine-snapper-sync resolves to '${repo:-nothing}', expected 'omarchy'"
	exit 1
fi
say "  ✓ limine-snapper-sync resolves from [omarchy]"

# And that the signature policy is real rather than nominal: SigLevel is only
# doing something if pacman would actually validate. `--print` runs the whole
# resolve path without installing.
sudo pacman -S --print --noconfirm limine-snapper-sync >/dev/null
say "  ✓ signature policy accepts the package"
