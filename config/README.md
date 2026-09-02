# `config/` — the dotfiles themselves

What `install.sh` will symlink into place (`CHOICES.md` `dotfile-deployment`:
**symlink via `ln -sfn`, no manager**). Layout mirrors `$XDG_CONFIG_HOME`, so
`config/niri/config.kdl` → `${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl`.

**These are pulled from a working `bunne-test`, not written from scratch.** That
machine is wiped in Phase 5, and until 2026-08-21 this configuration existed
*only* there — `docs/resume.md` had carried it as a standing risk since the niri
session was built. Committing it is the fix.

| File | Lines | Status |
|---|---|---|
| `kitty/kitty.conf` | 3 | **Deviations only, as the rule wants.** Font picked by measurement (`CHOICES.md` `font`). |
| `xdg-desktop-portal/portals.conf` | 2 | Required, not cosmetic — niri appears in no backend's `UseIn` list, so without this nothing serves screen sharing (`CHOICES.md` `portal`). |
| `niri/config.kdl` | 725 | Stock default + **11 deviations**, documented in its header. See the open question below. |
| `waybar/config.jsonc` | 40 | The five things the author asked for and nothing else: day, time, date, ISO week, weather (`CHOICES.md` `status-bar`). Clock format is his Omarchy string verbatim. |
| `waybar/style.css` | 31 | **Almost empty on purpose** — one colour, `#0f0f0f`, already decided by `wallpaper`. Input to the palette generator, not a theme. |
| `waybar/weather` | 67 | Executable. One `curl` against wttr.in's plain-text endpoint; no `jq`, no icon font, no cache. Location comes from `~/.config/bunny/weather-location` if it exists, otherwise wttr.in geolocates by IP. |
| `git/config` | 22 | **Exception to the line above** — `bunne-test` has no `~/.gitconfig` to pull from, so this is the author's own desktop's settings (aliases, `pull.rebase`, `diff.algorithm=histogram`, …), taste rather than harvested state. `user.name`/`user.email`/credential helper deliberately excluded — personal, and `install.sh` never writes them. |
| `systemd/user/disk-usage-alert{,.service,.timer}` | 19 | The disk-alert (`CHOICES.md` `disk-alert`), rewritten to one `df` on the author's ask. Timer enabled by `install.d/80-disk-alert.sh`, the same way everything else here is just symlinked and nothing more. |
| `systemd/user/calendar-poll{,.service,.timer}` | 86 | Meeting alerts via `gcalcli remind` (`CHOICES.md` `notifications`), not the browser — a real test showed the browser path silently never granted notification permission. De-dups `gcalcli`'s own repeat-fires against `$XDG_STATE_HOME/bunny/calendar-notified`. Timer enabled by `install.d/88-calendar-poll.sh`; auth (`gcalcli init`) is manual, same `secrets-bootstrap` policy as everything else here. |
| `bash/prompt.bash` | 63 | The hand-rolled prompt (`CHOICES.md` `prompt`), no `starship`, no command substitution except the dirty-marker `git status`. Sourced by `~/.bashrc`, one line appended by `install.d/85-shell-prompt.sh` — `.bashrc` itself stays untracked, `shell` is still `deferred`. |
| `bash/dir-display.bash` | 51 | Directory-aware terminal title (`CHOICES.md` `dir-aware-display`), gated on a real `cd`. The mapping file it reads is deliberately **not** in this table — see below. |
| `bash/direnv.bash` | 30 | Gated `direnv` hook, same row. `direnv hook bash`'s own eval silently installs an *ungated* copy of itself into `PROMPT_COMMAND`; this file saves and restores `PROMPT_COMMAND` around the eval so only the gated wrapper survives. |
| `nvim/` | 9 files | LazyVim (`CHOICES.md` `editor`), harvested from `benchmarks/raw/p4-nvim-draft/` — decided and tested back on 2026-08-24, never actually shipped until now. `init.lua` and `lua/config/autocmds.lua` are stock LazyVim starter content, included because nothing here clones the upstream template at install time. The provider venv (`~/.venvs/neovim`) is `install.d/75-nvim-notebook.sh`'s job, not a symlink. |

## Why nothing outside `$XDG_CONFIG_HOME` is here

**Settled 2026-08-26 (open question 27).** The installer also has to produce four `/etc`
files and two in `$HOME` (`docs/phase4-config-inventory.md` §2), and none of them has a
place in this directory. Rather than widen the layout, **`install.sh` writes those settings
directly** — they are 28 bytes, or one line, or five `snapper set-config` calls, or they
contain the username and must be generated anyway. A tracked file plus a symlink plus an
entry in this table is more machinery than any of them is worth.

So this README's first line still holds exactly as written, and the question of where a
non-XDG *file* would live is **still open** — it just has nothing to decide about yet. The
likely trigger is the shell config below.

## Not here yet, deliberately

- **The rest of `~/.bashrc`.** `shell` is still `deferred` pending the author's full
  review; `prompt.bash`/`dir-display.bash`/`direnv.bash` above are the pieces that
  shipped ahead of it, each sourced by its own single appended line rather than by
  owning the file. `node-runtime`'s plain-PATH approach needs no line at all — it is
  just a package on `PATH`.
- **`$XDG_CONFIG_HOME/bunny/dirmap.conf`** — `dir-display.bash`'s mapping file.
  Deliberately not tracked here: it is exactly the file a user would fill with real
  employer/client directory names through normal use, which `secrets-bootstrap`
  now forbids reaching this repo. `install.d/86-shell-dir-aware.sh` scaffolds an
  empty template once and never overwrites it.
- **`$XDG_CONFIG_HOME/bunny/wallpaper`** — a symlink, not a file, onto whichever
  vendored wallpaper is currently active (`CHOICES.md` `wallpaper`). Deliberately
  not tracked, same shape as `dirmap.conf` above: it's user-mutable selection
  state, seeded once by `install.d/87-wallpaper.sh` (defaults to
  `15-neon-hare-by-omar-ramadan.jpg`) and repointed thereafter only by
  `scripts/bunny-wallpaper.sh`, never by a reinstall.
- **Colours.** Every config here hardcodes them (`prompt.bash` included — plain ANSI
  cyan, not a hex). `02-functionality.md` C10 says a single palette file is the only
  place a colour may be written, with app configs generated from it. `palette` is
  picked (`envsubst` templater) but the templater itself is not built yet; until it
  exists, these files are the input to it, not the finished article.

## Open question — how much of a config do we ship?

`kitty.conf` is 3 lines because kitty merges its defaults with yours. **niri has
no include or overlay mechanism** — verified: no `include` directive in
`/usr/share/doc/niri/default-config.kdl`, and `--config` takes exactly one path.
So niri cannot express "only deviations" the way kitty can, and ~94% of that file
is upstream's commented example.

Two defensible answers, and Phase 4 has to pick one:

1. **Ship it verbatim.** Keeps upstream's inline documentation next to every
   setting, which is worth something to someone learning the config format.
   Costs: a 725-line file where 42 lines are ours, and every upstream change to
   the example silently drifts from our copy.
2. **Hand-write a minimal config** carrying only the five deviations and relying
   on niri's compiled-in defaults. Truer to `CLAUDE.md` ("a config file should
   contain only deviations") and far easier to audit. Costs: the reader loses the
   inline docs, and any default we relied on changing upstream becomes invisible.

Option 2 matches the stated rule. It has not been chosen — **do not settle this
as a side effect of some other change.**
