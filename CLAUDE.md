# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository.

## What this repo is

`arch-bunny` is a personal Arch Linux setup — dotfiles plus the provisioning to reproduce them
on a wiped machine. Target hardware is a Framework 13 AMD; target workload is data science.
The base install is stock `archinstall`; this repo is everything after the first reboot.

**It is a variant of [viacoffee/dotfiles](https://github.com/viacoffee/dotfiles)**, and that is
the single most important fact when changing anything here. A local clone for comparison:

```bash
git clone --depth 1 https://github.com/viacoffee/dotfiles /tmp/via
```

### The governing rule

His repo is battle-tested on the same hardware. **Where his configuration and ours differ,
his is right unless the difference is one of the three exceptions below.** This is not
deference for its own sake — it is why the repo was rebuilt in September 2026, after the
predecessor's hand-tuned boot path could not produce a working Plymouth password dialog.

The exceptions, and they are narrow:

1. **Cosmetics** — colours, animation speed, window maximization behaviour, wallpaper.
2. **Keybindings** — the author's, kept verbatim. `config/niri/bindings.kdl`.
3. **Neovim and the data-science workflow** — kitty over alacritty (its graphics protocol is
   what makes inline plots work), the molten venv, Docker on its own subvolumes.

Everything else — boot, session, network, services — follows him. When ours differs anyway,
the difference must be *marked in a comment at the point of divergence*, with the reason,
using the literal word `DEVIATION` so the full set is one grep:

```bash
grep -rn DEVIATION install/ config/
```

There are currently four: `nftables` over `ufw`, no `switch-events`, `snap-pac`, and
`systemd-oomd`.

**Anything that could bear on the Plymouth path must be byte-identical to his**, verified with
`cmp`, not by eye. That currently covers `install/default/plymouth/*`,
`install/default/limine/*`, `install/default/modprobe/nowatchdog.conf`, the mkinitcpio HOOKS
line, the drop-in filename, and **the font package list** — see the fonts note below. The
bunny theme is parked in `assets/plymouth-bunny/` with instructions for restoring it once a
real boot has been seen working. Loosen one thing at a time, and only after a successful boot.

## Design priorities

In this order; when two conflict, the lower number wins.

1. **It just works.** A fresh install boots into a usable desktop with no manual repair.
   A boring option that survives an update beats a clever one that breaks.
2. **Fast and light.** Perceived latency first, idle RAM second. No resident daemon that
   could be a keybind; Wayland-native and compiled over Electron and interpreted.
3. **Bunny themed.** Matte black, ASCII, neon accents. Achieved with config and assets,
   never with resident processes.

The old repo tracked every runtime cost in a `BUDGET.md` ledger and every decision in a
365 KB `CHOICES.md`. **Both are retired** to `docs/archive/`. They are history, not
instruction, and where they disagree with the tree, the tree wins. Do not resurrect that
machinery: it grew to the point where defending it cost more than the milliseconds it saved,
and it encoded conclusions this rebuild reverses.

## How to work here

The author wants to **understand every line** — no vibe coding. This outranks convenience,
because a line nobody has checked is where the bad choice hides.

- **Parsimony.** The best change to a file is removing lines. Prefer deleting to adding.
  No abstraction for one caller, no config knob until something needs to vary.
- **Upstream defaults that are already correct are left alone**, not restated. A config file
  should contain only deviations.
- **Verify on the machine, never from memory.** Read the shipped source, config, and package
  files before asserting behaviour. This session alone that caught: `ttf-fragment-mono` does
  exist (in the AUR — the old ledger recorded it as a name that never existed, having checked
  only the official repos); `polkit-gnome`'s agent path, read out of the package file list;
  `mesa` provides `libva-mesa-driver`; and this machine's watchdog being `sp5100_tco`.
- **Fail loudly; never degrade silently.** A feature that is off and quiet is
  indistinguishable from one that is broken. Say so at the point of failure, once, with the
  reason.
- **Never gracefully handle a condition that should never happen.** A missing subvolume, a
  package we meant to install, a file this repo ships — hard error, not a skipped step. The
  test: *could this happen on a machine built the way `README.md` describes?* If no, it is a
  bug and must stop the run.
- **Prove it, do not infer it.** Treat any safety mechanism that has never been exercised as
  broken until demonstrated, and prefer a test shaped to fail loudly if the mechanism did
  nothing at all.

### Exercise the write path, not the no-op path

On an already-provisioned machine every check reports "already correct" and the code that
actually changes things never runs. **Every defect found in this repo was found that way, and
none were visible by reading.** Break the state deliberately and re-run; write the check
before believing the step.

Defects this found, all of them silent:

- An idempotence guard keyed on a **marker comment** rather than on the rule it writes. The
  comment wording changed, the guard stopped matching rules that were already there, and
  `/etc/nftables.conf` would have grown a duplicate pair on every run.
- A cmdline argument stripper using `s/(^|space)arg(space|$)//g`, which leaves exactly one
  copy of a doubled argument because the first match consumes the separator the second needs.
  Inherited from his repo; the machine already had `splash splash`.
- `scripts/check-keybinds.sh` reporting "0 chords, no duplicates" — a clean pass — because it
  still pointed at `config.kdl` after the binds moved to `bindings.kdl`.

### Things specific to this machine that are easy to get wrong

- **niri resolves `include` against the directory of the file it is handed**, not the realpath
  of a symlink. All four `.kdl` files must be deployed, not just `config.kdl`.
- **Plymouth's initramfs font comes from `fc-match`.** `/usr/lib/initcpio/install/plymouth`
  resolves it at build time, and neither theme sets `Font =`, so *whatever font packages are
  installed decides what Plymouth gets*. This is why `install/packages` carries exactly his
  five fonts and no more; the held-back ones are listed there with the reason.
- **Phases are sourced, so a `trap ... EXIT` in one replaces `install.sh`'s own** — the trap
  that regenerates boot artifacts if the run dies with generation still deferred. Clean up
  with an explicit call instead.
- **`pacman --hookdir` replaces `/etc/pacman.d/hooks`** in the search path but never
  `/usr/share/libalpm/hooks/`. That is what makes the mkinitcpio deferral narrow and safe.

## Conventions

Unsurprising beats clever. Follow the standard where one exists.

- **`shellcheck -x` clean and `shfmt` formatted.** Both are development dependencies, never
  in the package list. Suppress a warning on the one line with a comment saying why; never
  globally — and prefer fixing it (two `SC2024`s were real).
- **Phases are sourced by `install.sh`**, so they report failure with `return 1`, never
  `exit`, and use the helpers in `install/lib/helpers.sh` for output: `log`, `info`,
  `success`, `warn`, `error`, `run_logged`.
- **Never require `sudo ./install.sh`.** Run as the user, escalate per command, so it is
  obvious from reading which steps need root.
- **Respect XDG, reading the variables rather than hardcoding their defaults**:
  `${XDG_CONFIG_HOME:-$HOME/.config}` and friends. The repo lives at
  `${XDG_DATA_HOME:-$HOME/.local/share}/arch-bunny` and dotfiles are symlinked *into* it.
- **Never hardcode a username.** `$BUNNY_USER` is whoever ran the installer, resolved from
  the passwd database in `00-preflight.sh`.
- **Employer and client work never appears in this repo, full stop.** No VPN config, no shell
  alias, no path reference, nothing naming an employer or client anywhere a stranger cloning
  this would see it. `~/.bashrc.personal` is the untracked escape hatch for anything local.

## Layout

```
install.sh          sequences the phases; owns the log, the ERR trap, and the EXIT trap
bootstrap.sh        clone-and-run entry point
install/
  00..90-*.sh       the phases; `ls install/` is the plan, no manifest to drift
  lib/helpers.sh    logging, run_logged, the pacman hook override
  packages          every pacman package, one per line
  packages-aur      AUR packages, installed after the bootloader phase
  default/          static config files the phases install
  verify.sh         read-only health check, 69 checks
home/ config/ local/   the three symlinked dotfile trees
assets/             wallpapers, ASCII, fonts, the parked bunny Plymouth theme
scripts/            development tools; never installed on a BunnE machine
docs/archive/       the pre-rebuild design record — history, not instruction
```

Each phase does three things: implement only the deviations, be idempotent, and **verify
rather than assume** at the end.

## Current state

The transplant is complete and **has never been run end-to-end.** By this repo's own standard
that means unproven. The machine is to be wiped and reinstalled from `README.md`; that is the
real test, and `install/verify.sh` is the before/after instrument.

Known outstanding:

- `archinstall-2026.08.01-creds.json` was removed but remains in history at `70b8b3b`, which
  is already on a **public** `origin/main`. The password it carried needs changing and the
  history needs rewriting.
- His `tests/*.bats` were not ported. `verify.sh` covers the runtime checks; `shellcheck` and
  `shfmt` cover the static ones.

**This section goes stale faster than anything else here.** When it disagrees with the tree,
the tree wins and this is what to fix.
