#!/usr/bin/env bash
# The Jupyter/molten provider venv LazyVim's own config points at. CHOICES.md
# `editor`, `jupyter-in-neovim`, `python-pynvim`.
#
# The config files need no step: config/nvim/ lives under $XDG_CONFIG_HOME and is
# symlinked in by 70-dotfiles.sh, and lazy.nvim bootstraps its own plugins on
# first launch. What is left is the interpreter behind `vim.g.python3_host_prog`
# (config/options.lua): a venv with the packages molten/Jupyter need, a registered
# kernel, and the runtime directory molten writes to but never creates.
#
# `pnglatex` is not a pip install. The real PyPI package of that name is the
# abandoned one CHOICES.md `latex-rendering` replaced (broken on Python >= 3.13);
# assets/nvim/pnglatex.py is our own ~40-line module keeping only the import name
# molten hardcodes. A first pass at this step pip-installed it by name, which
# would have shipped the broken thing this row exists to avoid.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 75-nvim-notebook.sh [--help]
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

venv=$HOME/.venvs/neovim
py=$venv/bin/python
readonly PACKAGES=(pynvim jupyter_client ipykernel matplotlib pillow sympy)
# pillow's pip name and import name differ (PIL, kept from the library it forked
# from), caught by running the import check below rather than assuming
# pip-name == import-name.
import_name() {
	case "$1" in
	pillow) printf 'PIL' ;;
	*) printf '%s' "$1" ;;
	esac
}

# 1. The venv itself.
if [[ -x $py ]]; then
	say "  = $venv already exists"
elif [[ -n $dry ]]; then
	say "  ~ would create $venv"
else
	uv venv "$venv"
	say "  + created $venv"
fi

if [[ -n $dry ]]; then
	say "  ~ would ensure ${PACKAGES[*]} are installed"
	say "  ~ would ensure our pnglatex.py is in site-packages"
	say "  ~ would ensure the 'bunny' Jupyter kernel is registered"
	say "  ~ would ensure ~/.local/share/jupyter/runtime exists"
	exit 0
fi

# 2. The packages. One import check covers all of them; cheaper than asking uv
# every run, and it is the thing that actually has to be true — a package present
# in uv's bookkeeping but broken in the venv would still fail this.
missing=false
for pkg in "${PACKAGES[@]}"; do
	"$py" -c "import $(import_name "$pkg")" >/dev/null 2>&1 || {
		missing=true
		break
	}
done
if $missing; then
	uv pip install --python "$py" "${PACKAGES[@]}"
	say "  + installed: ${PACKAGES[*]}"
else
	say "  = packages already present: ${PACKAGES[*]}"
fi

# 3. pnglatex.py, copied not pip-installed; see the header. site-packages is
# resolved via sysconfig rather than hardcoding a python3.NN path.
pnglatex_src="$root/assets/nvim/pnglatex.py"
[[ -f $pnglatex_src ]] || {
	say "  ! $pnglatex_src not found"
	exit 1
}
site_packages=$("$py" -c 'import sysconfig; print(sysconfig.get_path("purelib"))')
pnglatex_dest="$site_packages/pnglatex.py"
if [[ -f $pnglatex_dest ]] && cmp -s "$pnglatex_src" "$pnglatex_dest"; then
	say "  = pnglatex.py already in place"
else
	install -Dm644 "$pnglatex_src" "$pnglatex_dest"
	say "  + copied pnglatex.py to $site_packages"
fi

# 4. The kernel.
kernel_dir=${XDG_DATA_HOME:-$HOME/.local/share}/jupyter/kernels/bunny
if [[ -d $kernel_dir ]]; then
	say "  = 'bunny' kernel already registered"
else
	"$py" -m ipykernel install --user --name bunny
	say "  + registered the 'bunny' Jupyter kernel"
fi

# 5. The runtime directory. molten writes here but never creates it, so without
# this MoltenInit fails with ENOENT on a machine that has never run plain Jupyter.
runtime_dir=${XDG_DATA_HOME:-$HOME/.local/share}/jupyter/runtime
if [[ -d $runtime_dir ]]; then
	say "  = $runtime_dir already exists"
else
	mkdir -p "$runtime_dir"
	say "  + created $runtime_dir"
fi

# Verify.
for pkg in "${PACKAGES[@]}"; do
	"$py" -c "import $(import_name "$pkg")" >/dev/null 2>&1 || {
		say "  ! $pkg does not import in $venv after install"
		exit 1
	}
done
"$py" -c "from pnglatex import pnglatex" >/dev/null 2>&1 || {
	say "  ! pnglatex does not import from $site_packages after copying"
	exit 1
}
[[ -d $kernel_dir ]] || {
	say "  ! $kernel_dir missing after registration"
	exit 1
}
[[ -d $runtime_dir ]] || {
	say "  ! $runtime_dir missing after creation"
	exit 1
}
say "  ✓ provider venv, kernel, and runtime dir all present"
