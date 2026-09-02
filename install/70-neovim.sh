#!/usr/bin/env bash
# The Python environment Neovim's Jupyter support talks to.
#
# The third of the three problems the project exists to fix: notebooks being
# painful enough to drive a fallback to PyCharm. molten-nvim needs a Python with
# pynvim and a Jupyter client in it, and it must NOT be whatever conda environment
# happens to be active -- that is the coupling that made the predecessor's setup
# fragile. So: one dedicated venv, always at the same path, referenced explicitly
# by the Neovim config.
#
# uv rather than python -m venv: it is already a dependency and it resolves this
# set in about a second.

log "Setting up the Neovim Python environment..."

readonly NVIM_VENV="$HOME/.venvs/neovim"
readonly NVIM_PY="$NVIM_VENV/bin/python"
readonly NVIM_PACKAGES=(pynvim jupyter_client ipykernel matplotlib pillow sympy)

# Import name differs from the distribution name for exactly one of these.
import_name() {
	case "$1" in
	pillow) printf 'PIL' ;;
	*) printf '%s' "$1" ;;
	esac
}

if ! command_exists uv; then
	error "uv not found — 10-packages.sh installs it"
	return 1
fi

if [[ -x $NVIM_PY ]]; then
	info "$NVIM_VENV already exists"
else
	run_logged "Creating $NVIM_VENV" uv venv "$NVIM_VENV"
fi

packages_missing=false
for package in "${NVIM_PACKAGES[@]}"; do
	if ! "$NVIM_PY" -c "import $(import_name "$package")" >/dev/null 2>&1; then
		packages_missing=true
		break
	fi
done
if $packages_missing; then
	run_logged "Installing ${NVIM_PACKAGES[*]}" \
		uv pip install --python "$NVIM_PY" "${NVIM_PACKAGES[@]}"
else
	info "Packages already present: ${NVIM_PACKAGES[*]}"
fi

# molten renders LaTeX via pnglatex, which is not on PyPI in a form that works
# here, so the repo carries it and drops it into the venv's site-packages.
pnglatex_src="$BUNNY_ROOT/assets/nvim/pnglatex.py"
if [[ ! -f $pnglatex_src ]]; then
	error "$pnglatex_src not found"
	return 1
fi
site_packages=$("$NVIM_PY" -c 'import sysconfig; print(sysconfig.get_path("purelib"))')
if [[ -f $site_packages/pnglatex.py ]] && cmp -s "$pnglatex_src" "$site_packages/pnglatex.py"; then
	info "pnglatex.py already in place"
else
	install -Dm644 "$pnglatex_src" "$site_packages/pnglatex.py"
	success "Copied pnglatex.py into $site_packages"
fi

kernel_dir="${XDG_DATA_HOME:-$HOME/.local/share}/jupyter/kernels/bunny"
if [[ -d $kernel_dir ]]; then
	info "'bunny' Jupyter kernel already registered"
else
	run_logged "Registering the 'bunny' Jupyter kernel" \
		"$NVIM_PY" -m ipykernel install --user --name bunny
fi

# jupyter_client writes connection files here and does not create the directory.
runtime_dir="${XDG_DATA_HOME:-$HOME/.local/share}/jupyter/runtime"
mkdir -p "$runtime_dir"

# Prove it imports rather than that pip exited 0. A venv that resolves but does
# not import is the failure mode that makes notebooks "just not work" with no
# error anyone sees.
for package in "${NVIM_PACKAGES[@]}"; do
	if ! "$NVIM_PY" -c "import $(import_name "$package")" >/dev/null 2>&1; then
		error "$package does not import in $NVIM_VENV after install"
		return 1
	fi
done
if ! "$NVIM_PY" -c "from pnglatex import pnglatex" >/dev/null 2>&1; then
	error "pnglatex does not import from $site_packages after copying"
	return 1
fi
success "Neovim Python environment ready at $NVIM_VENV"
