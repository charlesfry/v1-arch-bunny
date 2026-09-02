#!/usr/bin/env bash
# Link `config/` into $XDG_CONFIG_HOME. CHOICES.md `dotfile-deployment`: symlink
# via hand-rolled `ln -sfn`, no Stow, no chezmoi, no manager.
#
# Symlink rather than copy, so edits made to ~/.config while actually using the
# machine flow back to the repo. The predecessor repo copies, which is what lets
# the running machine and the repo diverge silently.
#
# Per-file links, which is a narrowing of the row. The row prefers linking whole
# directories "wherever the app allows", because a directory link survives an
# application rewriting a file inside it with write-temp-then-rename. Two reasons
# it is not what this step does:
#
#   - Nothing tracked here rewrites its own config. niri, kitty and
#     xdg-desktop-portal all read hand-edited text at startup and never write it.
#   - The directories are shared. On bunne-test other software has dropped
#     ~/.config/kitty/dank-theme.conf and ~/.config/niri/dms/ beside ours; a
#     directory link either swallows those into the repo or has to move them out
#     first, and a deploy step that relocates files it did not create is a much
#     larger thing to trust than `ln -sfn`.
#
# Revisit the day a config with a GUI settings dialog lands here — that is the app
# class that rewrites its own file.
#
# The links point at wherever this repo is. The row wants a fixed location the
# installer owns (${XDG_DATA_HOME:-$HOME/.local/share}/arch-bunny), so that a
# friend deleting their clone does not silently change their desktop. Nothing here
# moves the repo there, so it links from where it is and says so.
#
# Idempotent, and it re-links a link that has been replaced by a regular file.
# Honours BUNNY_DRY_RUN.
#
# Usage: 70-dotfiles.sh [--help]
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
src=$root/config
[[ -d $src ]] || {
	say "  ! no config/ directory at $src"
	exit 1
}

# XDG read from the variable with a spec default, never hardcoded.
dest=${XDG_CONFIG_HOME:-$HOME/.config}

canonical=${XDG_DATA_HOME:-$HOME/.local/share}/arch-bunny
if [[ $root != "$canonical" ]]; then
	say "  ! this repo is at $root, not $canonical"
	say "    The links below will point here. Moving or deleting this directory"
	say "    later breaks the desktop, silently, at the next login."
fi

linked=0 relinked=0 same=0

# `-print0` and `read -d ''` for paths with spaces. README.md documents the
# directory rather than being deployed from it.
while IFS= read -r -d '' file; do
	rel=${file#"$src"/}
	# `if`, not `[[ ... ]] && continue`: a false AND-list is a failed command, and
	# `set -e` acts on it inside a loop body.
	if [[ $rel == README.md ]]; then continue; fi
	target=$dest/$rel

	if [[ -L $target ]] && [[ $(readlink -- "$target") == "$file" ]]; then
		say "  = $rel"
		((++same))
		continue
	fi

	if [[ -n $dry ]]; then
		say "  ~ would link $rel"
		((++linked))
		continue
	fi

	mkdir -p -- "$(dirname -- "$target")"

	# Something is already there and it is not our link. If its content matches the
	# repo there is nothing to lose, so replace it quietly — that is the normal
	# state of a box the configs were harvested from. If it differs, it is
	# somebody's work: keep it.
	if [[ -e $target || -L $target ]]; then
		if [[ -f $target && ! -L $target ]] && cmp -s -- "$target" "$file"; then
			:
		else
			bak=$target.bunny.bak
			if [[ -e $bak ]]; then
				say "  ! $target differs from the repo and $bak already exists — not overwriting either"
				exit 1
			fi
			mv -- "$target" "$bak"
			say "  + kept the existing $rel as $(basename -- "$bak")"
		fi
		((++relinked))
	else
		((++linked))
	fi

	ln -sfn -- "$file" "$target"
	say "  + $rel -> $file"
done < <(find "$src" -type f -print0)

if [[ -n $dry ]]; then
	say "  ~ $linked file(s) would be linked into $dest"
	exit 0
fi

say "  ✓ $((linked + relinked + same)) file(s) linked into $dest ($same unchanged, $relinked replaced)"

# The one config that has a validator: niri refuses to start on a bad config and
# the failure surfaces as a black screen after the next reboot.
if [[ -f $dest/niri/config.kdl ]] && command -v niri >/dev/null; then
	if niri validate --config "$dest/niri/config.kdl" >/dev/null 2>&1; then
		say "  ✓ niri validate passes"
	else
		say "  ! niri rejects $dest/niri/config.kdl:"
		niri validate --config "$dest/niri/config.kdl" >&2 || true
		exit 1
	fi
fi
