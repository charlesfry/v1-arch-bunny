#!/usr/bin/env bash
# Install every package the ledger claims, in the order the repos require.
#
# The list is derived from CHOICES.md, not kept beside it: a `Packages` cell is
# the decision, and a second copy here would be a second decision that silently
# disagrees. The awk parse below is docs/05-choices.md's, the same one
# scripts/check-packages.sh uses.
#
# Order is not cosmetic — the list is not installable in one command:
#
#   1. pacman repos   official + [omarchy] in one `-Syu` transaction. `[omarchy]`
#                     is last in pacman.conf, so pacman resolves the shadowing.
#   2. yay-bin        bootstrapped from the AUR by hand, because there is no AUR
#                     helper yet to install the AUR helper. Needs `base-devel`
#                     and `git`, which step 1 has just provided.
#   3. the AUR        everything pacman could not resolve.
#
# A name that resolves nowhere is a failure, not a warning (4.17 found
# `ttf-fragment-mono`, which never existed): a bad name here fails partway through
# a root install on a fresh machine.
#
# `-Syu`, not `-S`. Installing named packages against a database
# 10-omarchy-repo.sh has just `-Sy`'d is a partial upgrade, the documented way to
# break an Arch machine — and not theoretically: installing `docker-compose` also
# silently upgraded `limine`, `spotify-launcher` and `uv`, redeploying the
# bootloader's EFI binary. `pacman -Syu --needed pkg...` does both in one
# transaction, which is the only supported shape. The cost is that running this
# installer upgrades the machine.
#
# Idempotent via `--needed` throughout, and the yay bootstrap is skipped if yay is
# already on PATH. Honours BUNNY_DRY_RUN.
#
# Usage: 20-packages.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}
choices="${BUNNY_ROOT:?run me through install.sh, or set BUNNY_ROOT}/CHOICES.md"
[[ -r $choices ]] || {
	say "  ! cannot read $choices"
	exit 1
}

# `docs/05-choices.md`'s parse, verbatim.
mapfile -t want < <(
	awk -F' *[|] *' '$5=="picked" && $4!="—" && $2 !~ "/" {print $4}' "$choices" |
		tr ' ' '\n' | grep -v '^$' | sort -u
)
((${#want[@]} > 0)) || {
	say "  ! no picked packages parsed from CHOICES.md — the table format changed"
	exit 1
}
say "  ${#want[@]} distinct packages claimed by picked rows"

# The ledger and the archinstall JSONs must agree, both directions. Since
# 2026-08-28 the JSON carries the whole installable package list, so the base
# install is what puts them on the machine and this step is verifier and
# remainder. Duplication is fine; silent duplication is not.
#
# Packages that cannot be in the JSON, with the mechanism for each. archinstall
# has no AUR path — `packages` goes straight to `pacstrap`
# (lib/pacman/pacman.py:111) — and it cannot express `[omarchy]`'s
# `SigLevel = Required DatabaseOptional`: its SignOption enum offers only
# TrustedOnly and TrustAll (lib/models/mirrors.py:161-163), omarchy's database is
# genuinely unsigned, so the strictest archinstall can emit would fail to sync.
readonly NOT_IN_JSON=(
	yay-bin brave-bin gcalcli                  # AUR-only
	limine-snapper-sync limine-mkinitcpio-hook # [omarchy]-only
)

# Pure grep and awk on purpose: this runs on a fresh Arch install, where neither
# `jq` nor `python` is a dependency this repo may assume.
for j in "$BUNNY_ROOT"/archinstall-*.json; do
	[[ -e $j ]] || continue
	[[ $j == *-creds.json ]] && continue
	jpkgs=$(sed -n '/"packages"[[:space:]]*:[[:space:]]*\[/,/\]/p' "$j" |
		grep -oE '"[a-z0-9][a-z0-9@._+-]*"' | tr -d '"' | grep -v '^packages$' | sort -u)

	# 1. nothing in the JSON that no picked row claims
	for p in $jpkgs; do
		printf '%s\n' "${want[@]}" | grep -qxF "$p" && continue
		say "  ! $(basename "$j") installs '$p', which no picked CHOICES.md row claims"
		exit 1
	done

	# 2. nothing eligible that the JSON left out. Without this, adding a ledger row
	#    and forgetting the JSON silently stops the base install carrying it.
	for p in "${want[@]}"; do
		printf '%s\n' "${NOT_IN_JSON[@]}" | grep -qxF "$p" && continue
		printf '%s\n' "$jpkgs" | grep -qxF "$p" && continue
		say "  ! $(basename "$j") is missing '$p', which a picked CHOICES.md row claims"
		say "    Add it to that file's \"packages\", or to NOT_IN_JSON with a reason."
		exit 1
	done

	# 3. the exclusion list must not rot. Without this it becomes the one place a
	#    package can hide from both checks above after its row changes.
	for p in "${NOT_IN_JSON[@]}"; do
		printf '%s\n' "${want[@]}" | grep -qxF "$p" && continue
		say "  ! NOT_IN_JSON lists '$p', which no picked CHOICES.md row claims — stale"
		exit 1
	done
done
say "  ✓ ledger and archinstall JSONs agree, both directions"

# The gap between the ledger and this machine, stated before anything is done. On
# an already-provisioned box it should be empty; if it is not, the ledger grew a
# row nobody applied.
not_yet=()
for p in "${want[@]}"; do
	pacman -Qq "$p" >/dev/null 2>&1 || not_yet+=("$p")
done
if ((${#not_yet[@]} == 0)); then
	say "  = all of them already installed"
else
	say "  ${#not_yet[@]} not installed yet: ${not_yet[*]}"
fi

# Who can supply what. One `pacman -Si` for the whole list, not one per package.
# Names pacman cannot resolve produce no record, which is how they end up in
# `missing`.
declare -A repo_of=()
while read -r field _ value; do
	case "$field" in
	Repository) r=$value ;;
	Name) repo_of["$value"]=$r ;;
	esac
done < <(pacman -Si "${want[@]}" 2>/dev/null | grep -E '^(Repository|Name) ')

from_pacman=() missing=()
for p in "${want[@]}"; do
	if [[ -n ${repo_of[$p]:-} ]]; then from_pacman+=("$p"); else missing+=("$p"); fi
done
say "  ${#from_pacman[@]} from pacman repos, ${#missing[@]} unresolved (AUR or a typo)"

# 1. The pacman repos.
if ((${#from_pacman[@]} > 0)); then
	if [[ -n $dry ]]; then
		# `-Su`, not `-Syu`: `-y` writes /var/lib/pacman/sync, and a dry run that
		# writes is not a dry run. So this reports against the last-synced database.
		#
		# `--print-format '%n'` rather than bare `--print`: pacman puts its own
		# progress chatter on stdout, and a `wc -l` over `--print` counted four of
		# those as packages. The grep keeps only bare package names.
		n=$(sudo pacman -Su --needed --noconfirm --print-format '%n' "${from_pacman[@]}" 2>/dev/null |
			grep -cE '^[a-z0-9][a-z0-9@._+-]*$' || true)
		say "  ~ would install/upgrade $n package(s) via pacman, against the last-synced db"
	else
		sudo pacman -Syu --needed --noconfirm "${from_pacman[@]}"
		say "  + pacman repos done"
	fi
fi

# 2. The AUR helper, bootstrapped by hand. `makepkg` refuses to run as root, which
# is exactly why install.sh refuses to run as root.
if ((${#missing[@]} > 0)) && ! command -v yay >/dev/null; then
	if [[ -n $dry ]]; then
		say "  ~ would bootstrap yay-bin from the AUR (needed to install ${#missing[@]} package(s))"
	else
		tmp=$(mktemp -d)
		trap 'rm -rf "$tmp"' EXIT
		git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
		(cd "$tmp/yay-bin" && makepkg -si --noconfirm)
		command -v yay >/dev/null || {
			say "  ! yay-bin built but yay is not on PATH"
			exit 1
		}
		say "  + bootstrapped $(yay --version | head -1)"
	fi
elif command -v yay >/dev/null; then
	say "  = $(yay --version | head -1) already present"
fi

# 3. The AUR, and the typos. Only an AUR helper can tell an AUR package from a
# misspelling, which is why this check lives after the bootstrap.
if ((${#missing[@]} > 0)); then
	if [[ -n $dry ]] && ! command -v yay >/dev/null; then
		say "  ~ cannot classify the ${#missing[@]} unresolved name(s) in a dry run without yay:"
		say "    ${missing[*]}"
		exit 0
	fi
	aur=() unknown=()
	for p in "${missing[@]}"; do
		if yay -Si "$p" >/dev/null 2>&1; then aur+=("$p"); else unknown+=("$p"); fi
	done
	if ((${#unknown[@]} > 0)); then
		say "  ! ${#unknown[@]} package(s) exist in no repo and no AUR: ${unknown[*]}"
		say "    A wrong name in CHOICES.md fails partway through a root install."
		say "    Fix the ledger (scripts/check-packages.sh checks this outside an install)."
		exit 1
	fi
	if ((${#aur[@]} > 0)); then
		if [[ -n $dry ]]; then
			# `--needed` skips what is current, so this is install-or-upgrade, not
			# install: saying "would install" about an installed package is the kind of
			# small lie that makes a dry run useless.
			say "  ~ would install/upgrade ${#aur[@]} from the AUR: ${aur[*]}"
		else
			yay -S --needed --noconfirm --aur "${aur[@]}"
			say "  + AUR done: ${aur[*]}"
		fi
	fi
fi

if [[ -n $dry ]]; then exit 0; fi

# Prove every claimed package is actually installed. `--needed` is silent about a
# package it skipped for the wrong reason, and a partially-failed transaction
# still exits 0 in some pacman paths.
absent=()
for p in "${want[@]}"; do
	pacman -Qq "$p" >/dev/null 2>&1 || absent+=("$p")
done
if ((${#absent[@]} > 0)); then
	say "  ! claimed by CHOICES.md but not installed: ${absent[*]}"
	exit 1
fi
say "  ✓ all ${#want[@]} claimed packages installed"

# And that pacman knows they are wanted, not merely present. A package the ledger
# names can already be on the machine as another package's dependency, and
# `--needed` leaves that install reason alone. It then shows up in `pacman -Qtdq`
# the moment the thing that pulled it in goes away, so a routine orphan cleanup
# can remove a package this repo depends on. Found 2026-08-28 with seven in that
# state, `less` among them — the `man-db` lesson again.
#
# `-D --asexplicit` only rewrites the reason field, so it is safe every time.
implicit=()
for p in "${want[@]}"; do
	pacman -Qi "$p" 2>/dev/null | grep -q '^Install Reason  *: Installed as a dependency' &&
		implicit+=("$p")
done
if ((${#implicit[@]} == 0)); then
	say "  = all of them already marked explicitly installed"
else
	sudo pacman -D --asexplicit --quiet "${implicit[@]}" >/dev/null
	say "  + marked ${#implicit[@]} explicit (were dependency-owned): ${implicit[*]}"
fi
