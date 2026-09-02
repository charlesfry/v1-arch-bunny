# Phase-4 Neovim config — DRAFT for author review (2026-08-24, evening)

**Status: tested on `bunne-test` (Arch) under `NVIM_APPNAME=nvim-p4`; NOT
ratified, NOT in `config/`.** Built autonomously during the author's AFK
window from the ratified rows (`editor`, `jupyter-in-neovim`,
`python-pynvim`) and the 4.15 prototypes. Every file here is deployed and
exercised on the box; the author reviews line-by-line before anything ships.

## What it is

LazyVim starter + two extras imported explicitly in `config/lazy.lua`
(`lang.markdown` → render-markdown, `lang.python` → pyright + venv-selector;
explicit imports rather than `lazyvim.json` so the shipped config is
self-contained — the json is editor-managed state and its extras format
bit us during the build). Our files on top:

- `config/options.lua` — provider pin to `~/.venvs/neovim` with a loud
  warning when absent.
- `config/keymaps.lua` — the `;l` block (5 modes), plus the mapleader
  landmine note.
- `plugins/molten.lua` — the 4.15 notebook stack: molten (eager; rplugin),
  image.nvim (`magick_cli`, markdown integration),
  `molten_image_location = "virt"` (the author-reported double-plot fix),
  the expected/unexpected fail-loudly gate, S-Enter fence eval,
  `<Space>mi/mo/mh/ms`.
- `plugins/python-venv.lua` — venv-selector: global `<leader>cv` + `~/.venvs`
  search (predecessor's miniforge paths NOT ported; BunnE is uv).
- `bunne/health.lua` — `:checkhealth bunne`: kitty graphics, provider venv,
  molten commands, jupyter runtime dir. The on-demand diagnosis the
  `jupyter-in-neovim` row requires.

## Verified on the box (screenshots in this directory's session log)

`<Space>mi` picker → `bunne` kernel; S-Enter evaluated the matplotlib fence;
plot rendered inline with render-markdown decorations; `<Space>mo` float
shows ONE plot (fix confirmed under LazyVim); `:checkhealth bunne` reports
all four checks correctly, including the expected-absence warning over SSH.

## Findings for the package list / installer (author decisions, not made here)

1. **`fzf` and `lazygit` were missing on the fresh Arch install and LazyVim
   invokes both** — fzf-lua is the picker backend (without the binary the
   `<Space>mi` kernel picker silently aborts: the exact
   invokes-what-we-never-install defect class from CHOICES
   `terminal-navigation`), lazygit backs `<leader>gg`. Both installed on the
   test box during this build (pacman, recorded). The Phase-4 package list
   needs them (or their keybinds removed).
2. **Installer venv bootstrap** (done imperatively on the box, needs a
   script): `uv venv ~/.venvs/neovim` + `uv pip install pynvim
   jupyter_client ipykernel matplotlib pillow sympy`, copy our `pnglatex.py`
   into its site-packages, `python -m ipykernel install --user --name
   bunne`, `mkdir -p ~/.local/share/jupyter/runtime`.
3. **netpbm is orphaned**: `Required By: None`, explicitly installed — the
   `latex-rendering` flag confirmed; removal candidate for the Phase-4 sweep.

## Review items (author taste, deliberately not decided)

- **markdownlint noise**: the markdown extra ships markdownlint-cli2 via
  nvim-lint; notebook docs light up with MD012/no-multiple-blanks etc.
  Candidates: a `.markdownlint` config, disabling the linter, or living
  with it.
- sympy included in the provider venv, extending the author's NixOS
  go-ahead to the Arch draft — confirm.
- LazyVim ships much more than the notebook stack (blink.cmp downloaded a
  prebuilt binary during sync; fzf-lua registered vim.ui.select). The
  ~110 ms startup trade was accepted in the `editor` row; the plugin
  surface is what the line-by-line review is for.

## Startup cost of the draft — the 2a trade restated (priorities rule)

`nvim --startuptime`, headless, n=11 on the 1500-line generated .py, single
boot, load 0.2-0.3: **154-167 ms, median ~160 ms** (bare-nvim floor
11.5-12.2 ms same session). The `editor` row's accepted trade was ~110 ms
against a 126.8 ms measurement of the bare 4.15 throwaway — **the draft as
built costs ~33 ms more than the number the decision was made on**, paid by
the two extras and venv-selector. Informational (one boot, headless), but
the author should re-affirm or trim knowing it. Obvious trim candidates
live in the extras' plugin surface (markdownlint, markdown-preview).

## Known upstream behavior (mechanism pinned this session)

`:e` on a molten buffer fires `BufUnload`, which molten hooks to
`_deinit_buffer → kernel.deinit()` — it deletes every rendered output file
and shuts the kernel down. Reloading a notebook buffer therefore destroys
the session and orphans on-screen images (image.nvim then errors trying to
re-render deleted temp files). Upstream design, not our config; re-init
after any reload. Whether to report upstream is the author's call.
