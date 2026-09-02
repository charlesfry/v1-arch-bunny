# 🐰 arch-bunny

A personal Arch Linux setup: matte black, neon accents, [niri](https://github.com/YaLTeR/niri),
and a data-science workflow that treats Jupyter notebooks as a first-class thing rather than
an afterthought.

> **Disclaimer:** this is a "works on my machine" project. It is opinionated, it makes
> system-wide changes as root, and it will happily link its own dotfiles over yours.
> Read `install/` before running it.

Structure and much of the system configuration follow
[viacoffee/dotfiles](https://github.com/viacoffee/dotfiles), whose boot, session and network
setup are battle-tested on the same hardware and are treated here as authoritative.
What is different is deliberate: kitty over alacritty, bash over zsh, nftables over ufw,
Docker on its own btrfs subvolumes, and a Neovim/Jupyter environment.

## Installation

Two steps: a stock Arch install via `archinstall`, then this repo.

### 1. archinstall

Boot the [Arch ISO](https://archlinux.org/download/) and run `archinstall`.

| Prompt | Choose |
|---|---|
| Mirror region | your own |
| Disk configuration | Partitioning → **btrfs**, with subvolumes |
| Disk encryption | **LUKS**, set a passphrase |
| Bootloader | **Limine** |
| Unified kernel image | **yes** |
| Profile | **minimal** — no desktop; this repo installs it |
| Network configuration | **NetworkManager** (see the warning below) |
| Additional packages | `git` |
| Timezone / locale | your own |

**UKI must be yes.** The whole boot path here — Plymouth, the snapshot entries,
`limine-update` as the single generator — assumes one unified kernel image.

**Profile must be minimal.** Anything else installs a second desktop that fights this one.

### 2. This repo

Reboot into the new system, log in, and:

```bash
sudo pacman -S --needed git
bash <(curl -fsSL https://raw.githubusercontent.com/charlesfry/arch-bunny/main/bootstrap.sh)
```

That clones to `~/.local/share/arch-bunny`, shows what it is about to change, and runs
`install.sh` after you confirm. The repo has to stay there: dotfiles are deployed as
symlinks **into** it, so moving or deleting the clone breaks the desktop at the next login.

> ⚠️ **Join your wifi before rebooting.** The installer replaces NetworkManager with
> `iwd`, which does not read NetworkManager's saved connections. Run `impala` (or
> `iwctl`) and connect once, or you will reboot into a machine with no network and no
> way to look up the fix. The installer warns about this too.

Afterwards, check the result:

```bash
install/verify.sh
```

Read-only, and it asks the questions that are silent from the outside — whether the UKI
actually contains `cryptsetup`, whether nftables has a *ruleset* rather than just a
service, whether each user unit points at a binary that exists.

## How the installer is put together

`install.sh` only sequences. Each phase is a numbered file in `install/`, and
`ls install/` is the plan — there is no manifest to drift.

| Phase | Does |
|---|---|
| `00-preflight.sh` | Refuses to start unless the machine is what the rest assumes |
| `10-packages.sh` | `[omarchy]` repo, full upgrade, then `install/packages` |
| `12-greetd.sh` | Autologin into niri, with a bare shell as the fallback session |
| `13-bootloader.sh` | HOOKS, kernel cmdline, Plymouth, snapper, one Limine generation |
| `20-dotfiles.sh` | Symlinks `home/`, `config/` and `local/` into place |
| `30-system-services.sh` | iwd + networkd + resolved, bluetooth, power, oomd |
| `40-user-setup.sh` | Graphical-session user units, GTK theme, wallpaper, AUR |
| `50-firewall.sh` | nftables, plus the rule Docker needs to reach the network |
| `60-docker.sh` | `/var/lib/docker` on its own btrfs subvolume |
| `70-neovim.sh` | The Python environment molten talks to |
| `80-disk-alert.sh` | The disk-usage timer |
| `90-claude-code.sh` | Claude Code into `~/.local/bin` |

Phases are **sourced**, idempotent, and verify rather than assume. Re-running after a
failure is the resume story; there is no `--only` flag.

## Keyboard shortcuts

`Mod` is Super. `Mod+I` shows the full overlay on the machine itself.

### Applications

| Shortcut | Action |
|---|---|
| `Mod+Return` | Terminal (kitty) |
| `Mod+Space` | Launcher (fuzzel) |
| `Mod+Shift+N` | Editor (nvim) |
| `Mod+Shift+B` | Browser (brave) |
| `Mod+Shift+G` | Signal |
| `Mod+Shift+M` | Spotify |
| `Mod+Shift+F` | Files (Nautilus) |
| `Mod+Ctrl+V` | Clipboard history |
| `Mod+Escape` | Lock screen |
| `Mod+I` | Hotkey overlay |

### Windows and columns

| Shortcut | Action |
|---|---|
| `Mod+H/J/K/L` or arrows | Focus left/down/up/right |
| `Mod+Shift+H/J/K/L` | Move window |
| `Mod+Ctrl+H/J/K/L` | Resize |
| `Mod+BracketLeft/Right` | Consume or expel window |
| `Mod+W` | Close window |
| `Mod+F` | Maximize column |
| `Mod+M` | Maximize window to edges |
| `Mod+C` | Center column |
| `Mod+R` / `Mod+Shift+R` | Cycle preset column widths |
| `Mod+Ctrl+F` | Expand column to available width |
| `Mod+O` | Overview |
| `Alt+Tab` | Previous window |

### Workspaces

| Shortcut | Action |
|---|---|
| `Mod+Page_Down` / `Mod+Page_Up` | Focus workspace down/up |
| `Mod+1`–`9` | Switch to workspace |
| `Mod+Ctrl+U/I` | Move column to workspace down/up |
| `Mod+Shift+U/I` | Move the workspace itself |
| `Mod+WheelScroll` | Focus workspace / column |

### Screenshots

| Shortcut | Action |
|---|---|
| `Print` | Region |
| `Ctrl+Print` | Whole screen |
| `Alt+Print` | Focused window |
| `Mod+Print` | Region, then annotate in satty |
| `Mod+Shift+Print` | Pick a colour off the screen |

Media and brightness keys work as labelled, and stay live while locked.

## Commands

| Command | Description |
|---|---|
| `bunny-wallpaper` | Pick a wallpaper; swaybg follows the symlink it repoints |
| `bunny-lock` | Lock the screen — one definition, shared by the keybind and swayidle |
| `bunny-colorpick` | Pick a colour off the screen |
| `install/verify.sh` | Read-only health check of the whole install |
| `diagnose` / `diagnose_snapshots` | Where the disk went |

## Stack

| Category | Choice | Instead of his |
|---|---|---|
| Compositor | niri | same |
| Session | uwsm + greetd | same |
| Terminal | **kitty** | alacritty — kitty's graphics protocol is what makes inline plots work |
| Shell | **bash** + a hand-rolled prompt | zsh + starship |
| Editor | Neovim, with molten for notebooks | same editor, different config |
| Bar / notifications | waybar, mako | same |
| Launcher | **fuzzel** | bemenu + j4-dmenu-desktop |
| Lock / idle | **swaylock** + swayidle | hyprlock |
| Firewall | **nftables** | ufw — Docker writes straight to the kernel's tables, where ufw's chains are not |
| Network | iwd + systemd-networkd | same |
| Bootloader | Limine + UKI, snapshots via limine-snapper-sync | same |
| Snapshots | snapper + **snap-pac** | snapper alone |
| Containers | **Docker on its own btrfs subvolumes** | — |
| Browser | brave, chromium | firefox |

## Layout

```
install.sh          sequences the phases
bootstrap.sh        clone-and-run entry point
install/            the phases, packages, static config, verify.sh
home/               ~ dotfiles          (symlinked)
config/             ~/.config           (symlinked)
local/              ~/.local            (symlinked)
assets/             wallpapers, ASCII, fonts, the parked bunny Plymouth theme
scripts/            development tools — never installed on a BunnE machine
docs/archive/       the pre-2026-09-02 design record; history, not instruction
```

`shellcheck` and `shfmt` are the lint gate for everything under `install/`, `local/bin/`
and `scripts/`. Both are development dependencies and are never part of the package list.

## Licence

MIT — see [LICENSE](LICENSE).
