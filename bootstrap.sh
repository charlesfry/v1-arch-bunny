#!/usr/bin/env bash
# Fetch this repo onto a fresh Arch install and hand off to install.sh.
#
#   sudo pacman -S --needed git
#   bash <(curl -fsSL https://raw.githubusercontent.com/charlesfry/arch-bunny/main/bootstrap.sh)
#
# The repo is cloned to $XDG_DATA_HOME/arch-bunny because the installer deploys
# dotfiles as symlinks INTO it -- moving or deleting the clone afterwards breaks
# the desktop at the next login, so it goes somewhere durable rather than
# wherever you happened to be standing.
#
# Usage: bootstrap.sh [-b BRANCH]
set -Eeuo pipefail

readonly REPO=https://github.com/charlesfry/arch-bunny.git
readonly DEST="${XDG_DATA_HOME:-$HOME/.local/share}/arch-bunny"
branch=main

while (($#)); do
	case "$1" in
	-b | --branch)
		branch=${2:?--branch needs a value}
		shift 2
		;;
	-h | --help)
		sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
		exit
		;;
	*)
		echo "unknown option: $1 (try --help)" >&2
		exit 1
		;;
	esac
done

if ((EUID == 0)); then
	echo "Error: run bootstrap.sh as a normal user, not as root or through sudo." >&2
	exit 1
fi

if ! command -v git >/dev/null; then
	echo "Error: git is not installed. Run: sudo pacman -S --needed git" >&2
	exit 1
fi

if [[ -d $DEST/.git ]]; then
	echo "==> Updating the existing clone at $DEST"
	git -C "$DEST" fetch --quiet origin "$branch"
	git -C "$DEST" checkout --quiet "$branch"
	git -C "$DEST" pull --quiet --ff-only
else
	echo "==> Cloning $REPO ($branch) to $DEST"
	mkdir -p -- "$(dirname -- "$DEST")"
	git clone --quiet --branch "$branch" "$REPO" "$DEST"
fi

cat <<WARNING

  This installer makes system-wide changes as root, one command at a time:
  it rewrites the boot configuration, replaces the network stack, installs
  a display manager, and links dotfiles over anything already in place.

  Read install/ first. It is twelve numbered files and 'ls install/' is the plan.

WARNING
read -r -p "Continue? [y/N] " reply
case "$reply" in
y | Y | yes | YES) ;;
*)
	echo "Nothing changed. The repo is at $DEST when you want it."
	exit 0
	;;
esac

cd -- "$DEST"
exec ./install.sh
