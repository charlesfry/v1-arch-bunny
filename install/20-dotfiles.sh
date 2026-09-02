#!/usr/bin/env bash
# Link the three dotfile trees into place. Symlinks, hand-rolled — no Stow.
#
#   home/   -> $HOME                              .bashrc and friends
#   config/ -> ${XDG_CONFIG_HOME:-$HOME/.config}  application config
#   local/  -> $HOME/.local                       bin/ and user systemd units
#
# Symlink rather than copy, so an edit made to ~/.config while actually using the
# machine flows back to the repo. Copying is what lets the running machine and the
# repo diverge silently.
#
# Per-file links, not per-directory. Nothing tracked here rewrites its own config
# — niri, kitty, mako and the portals all read hand-edited text at startup and
# never write it — and the directories are shared, so a directory link would
# either swallow files this repo did not create or have to move them aside. A
# deploy step that relocates files it did not create is a much larger thing to
# trust than `ln -sfn`. Revisit the day a config with a GUI settings dialog lands
# here; that is the app class that rewrites its own file.
#
# Idempotent, and it re-links a link that has been replaced by a regular file.

if [[ $HOME != "$BUNNY_HOME" ]]; then
	error "Link target does not match the home directory validated by preflight"
	return 1
fi

# The links point at wherever this repo is, so say so when that is somewhere a
# `git clean` or a tidy-up might remove.
readonly BUNNY_CANONICAL="${XDG_DATA_HOME:-$HOME/.local/share}/arch-bunny"
if [[ $BUNNY_ROOT != "$BUNNY_CANONICAL" ]]; then
	warn "This repo is at $BUNNY_ROOT, not $BUNNY_CANONICAL"
	warn "The links below point here; moving or deleting it breaks the desktop at the next login"
fi

link_tree() {
	local src=$1 dest=$2
	local file rel target bak
	local linked=0 relinked=0 same=0

	if [[ ! -d $src ]]; then
		error "No such tree: $src"
		return 1
	fi

	# -print0 / read -d '' for paths with spaces. README.md documents a directory
	# rather than being deployed from it.
	while IFS= read -r -d '' file; do
		rel=${file#"$src"/}
		if [[ $rel == README.md ]]; then continue; fi
		target=$dest/$rel

		if [[ -L $target && $(readlink -- "$target") == "$file" ]]; then
			((++same))
			continue
		fi

		mkdir -p -- "$(dirname -- "$target")"

		# Something is already there and it is not our link. If its content matches
		# the repo there is nothing to lose, so replace it quietly — that is the
		# normal state of a box the configs were harvested from. If it differs, it
		# is somebody's work: keep it, once.
		if [[ -e $target || -L $target ]]; then
			if [[ -f $target && ! -L $target ]] && cmp -s -- "$target" "$file"; then
				:
			else
				bak=$target.bunny.bak
				if [[ -e $bak ]]; then
					error "$target differs from the repo and $bak already exists — not overwriting either"
					return 1
				fi
				mv -- "$target" "$bak"
				log "Kept the existing $rel as $(basename -- "$bak")"
			fi
			((++relinked))
		else
			((++linked))
		fi

		ln -sfn -- "$file" "$target"
	done < <(find "$src" -type f -print0)

	success "$((linked + relinked + same)) file(s) linked into $dest ($same unchanged, $relinked replaced)"
}

link_tree "$BUNNY_ROOT/home" "$HOME"
link_tree "$BUNNY_ROOT/config" "${XDG_CONFIG_HOME:-$HOME/.config}"
link_tree "$BUNNY_ROOT/local" "$HOME/.local"

verify_user_ownership "$HOME/.config" "$HOME/.local"

# The one config with a validator, and the one whose failure is invisible until
# it matters: niri refuses to start on a bad config, which surfaces as a black
# screen after the next reboot rather than as an error now.
#
# It matters more since config.kdl was split: niri resolves `include` against the
# directory of the file it was handed, NOT the realpath of the link, so all four
# .kdl files have to be linked, not just config.kdl. Verified by validating
# through a symlink both ways. Per-file linking gets that right on its own, and
# this check is what would notice if it ever stopped.
niri_config="${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"
if [[ -f $niri_config ]] && command_exists niri; then
	if niri validate --config "$niri_config" >/dev/null 2>&1; then
		success "niri validate passes"
	else
		error "niri rejects $niri_config:"
		niri validate --config "$niri_config" >&2 || true
		return 1
	fi
fi

success "Dotfiles linked"
