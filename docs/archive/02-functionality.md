# Core functionality: what must exist, and what is optional

Derived from [01-assessment.md](01-assessment.md). This doc names *capabilities*,
not packages — which package fills each slot is the bake-off in
[03-alternatives.md](03-alternatives.md).

Bunnies are fast **and** light: the core is deliberately small, and everything
that is not needed to reach a working desktop and terminal is an optional
profile installed on demand.

## Two KPIs and one hard constraint

Both come from `CLAUDE.md` priority 2, and they are listed in the order they
break ties: **fast first, light second**, with any trade between them stated out
loud rather than made quietly.

- **KPI — fast (2a).** The time between pressing a key and the intended thing
  having happened. Concretely, along the paths this machine actually uses:
  keystroke to glyph in the terminal, keybind to window on screen, launcher open
  to first accepted keystroke, cold app launch, `nvim` to an editable buffer,
  power button to a desktop that takes input. Measure before and after.
- **KPI — light (2b).** Idle RAM, and the resident process count that drives it.
  **Not** bytes on disk — that costs nothing at runtime, and Arch is small on
  disk without help.

**Package count is a preference, not a KPI.** It was listed as a KPI here until
2026-08-21, which was wrong in one direction and then briefly deleted, which was
wrong in the other. Keeping the package list small genuinely matters — every
package is another thing to audit against the two KPIs above, another thing that
updates and can break priority 1, another set of defaults nobody has read. But it
is a *means* to fast and light, so it never outvotes a measurement, and it is not
a stand-in for disk. `CLAUDE.md`'s parsimony rule has the test that tells the two
apart.
- **Constraint — never destroy an OS that is already there.** Dual-boot is
  **optional, not mandatory**, and the common case is its absence: a new laptop
  or a friend's machine gets BunnE on the whole disk with no Windows involved.
  Where Windows *is* present the installer shares the disk and the existing ESP
  and never claims either, the bootloader chainloads
  `\EFI\Microsoft\Boot\bootmgfw.efi`, the RTC stays in UTC on both sides, and
  Windows fast-startup goes off so NTFS is safely mountable. The installer must
  detect which situation it is in rather than assume either one.

Security is held at *reasonable*, not maximal: full-disk encryption stays,
firewall stays, but nothing that costs noticeable responsiveness gets added
without flagging the tradeoff.

## Keyboard-first — a strong preference, not an absolute

Added 2026-08-19. The author dislikes laptop touchpads and wants to eliminate
mouse use wherever it is realistic. This is a **scoring criterion for every
slot**, not a hard requirement: browsers are an accepted exception, since there
is no good way around pointing at arbitrary web pages.

Where it *should* be complete: the terminal, the editor, window management, and
system configuration — including things like choosing which Bluetooth device is
connected. **Prefer a TUI to a GUI wherever a competent TUI exists.**

Much of the existing ranking already follows this without having said so —
`yazi`, `bluetui`, `btop`, `zathura`, `imv`, `qalc` and `fuzzel` are all
keyboard-driven. Stating it makes that deliberate rather than incidental, and
it should now be an explicit tiebreaker in the remaining bake-offs.

**Named pain point: reading and copying text out of terminal scrollback**
without reaching for a mouse. See `CHOICES.md` `terminal-navigation`.

---

## Core — a fresh install is broken without these

### C1. Boot and storage
- UEFI boot alongside Windows, both entries selectable, Windows chainloaded.
- LUKS2 encrypted root; one passphrase prompt at boot.
- btrfs with subvolumes; snapshots before every pacman transaction, bootable
  rollback from the boot menu.
- Microcode, zram swap, TRIM.

### C2. Graphics and session
- *if* an NVIDIA GPU exists on the machine (this is true of Charles' current PC)
  NVIDIA driver with DRM modesetting and explicit sync; GUI that
  does not tear or flicker on a 4090.
- Charles' current PC has a 4090, but ideally the installer should be able to 
  work with a device with either an NVIDIA GPU or no GPU at all (i.e., a laptop with integrated graphics).
  Supporting non-NVIDIA GPUs is out of scope for now.
- Multi-monitor, correct scaling, layout overridable per machine.
- **Session start path from power-on to desktop with exactly one credential
  prompt** — not zero, and not two. Tightened from "at most one" on 2026-08-21 at
  the author's direction, because "at most" permits zero and **zero is not a fast
  login, it is no authentication**. One is also what mainstream OSes actually do:
  macOS FileVault makes the login screen *be* the disk unlock, and Windows lets
  the TPM unlock the disk silently and then asks once at login. Arch's default —
  LUKS passphrase *and* a display-manager password — is the outlier that asks
  twice, and that second prompt is what this requirement removes. Which prompt
  survives is the design choice; that one survives is not.
- **Single user is the assumption.** Nothing here requires concurrent user
  accounts, and no slot should pay for them. This is stated because it was
  silently assumed everywhere and it bears on the display-manager slot: a
  zero-prompt boot logs in one specific user by name. Multiple accounts still
  work — logging out reaches a greeter — they are just not the case being
  optimised. Note `04-plan.md` Phase 3 wants a second account as a *safety net*
  during compositor trials, which is a different thing from a multi-user desktop.

### C3. Compositor and window management
- Tiling Wayland compositor with workspaces.
- Vim-directional focus (`SUPER+H/J/K/L`), window move, fullscreen, float toggle.
- `ALT+TAB` = focus last window (not cycle).
- Move workspace between monitors.
- App-launch keybinds for the handful of apps used daily.

### C4. Desktop essentials (each of these must exist; each is a daemon candidate — justify every resident one)
- Application launcher.
- Notifications (the disk alert depends on this).
- Screen lock + idle lock.
- Screenshot to clipboard/file, region select, and annotate.
- Clipboard paste; searchable clipboard *history* is optional and costs a daemon, but will almost certainly be wanted.
- **Audio that works out of the box**, including Bluetooth output. Listed
  explicitly since 2026-08-19 because it was absent from this document: the
  volume-control line below silently presumed a working audio stack, and on the
  test laptop no such stack existed. Must handle a machine with many devices —
  the daily-driver desktop has six.
- Volume / brightness / mute control, ideally as a keybind, not a daemon.
- Wallpaper.
- Screen sharing (xdg-desktop-portal) — needed for meetings.
- Authentication agent for polkit prompts.

### C5. Terminal and shell
- Fast Wayland-native terminal. **Must support the kitty graphics protocol** —
  inline plots in Neovim are a data-science requirement that alacritty currently
  fails to meet.
- bash as login shell, with the existing helper functions.
- `direnv`, `zoxide`, and the modern coreutils replacements already in use.
- *Tentative:* directory-based terminal styling (recolor terminal background,
  optionally the Hyprland window border, when the shell enters a marked
  directory tree) — a clean rebuild of the predecessor's vibe-coded
  `dir-theme`, not a port of it. Must not fork on every prompt: a plain
  string compare against `$PWD` in `PROMPT_COMMAND` to detect a directory
  change, with any expensive call (e.g. `hyprctl`) gated behind that change,
  not run per-prompt. This is a placeholder solution — if a better mechanism
  is thought of, use that instead.

### C6. Editor
- Neovim with the data-science layer: IPython REPL, Jupyter/molten cells,
  inline images, venv selection, Claude Code integration.
- Startup time is a KPI here — it is the most-launched GUI-ish thing on the box.

### C7. Development
- git + `gh` + the `gu`/`gur` helpers + a TUI git client.
- Python environment management for data science (the single largest workflow).
- Containers (docker-compatible; `docker-compose` files are in use).
- Postgres client, `rg`/`fd`/`jq`/`yq`.
- **Claude Code on `PATH` — and no other LLM CLI.** Narrowed 2026-08-21 at the
  author's direction (`CHOICES.md` `agent-clis`): `codex`, `gemini`, `copilot`
  and `opencode` are dropped. They were Omarchy inheritances rather than
  choices, and all four are npm packages, so dropping them also removes the
  agent tooling's dependency on node.

### C8. Network
- Wired + WiFi, DNS, NTP.
- Bluetooth — pairing and audio. Promoted to core 2026-08-19; previously ranked
  in `03-alternatives.md` but required by nothing here, so it could have been
  dropped as an unjustified daemon. It costs one daemon at ~7 MB.
- OpenVPN with the generated `v<letter>` per-profile aliases.
- Firewall with sane defaults.

### C9. Ops / self-defence

Note the distinction this section rests on: **running out of disk is a priority-1
failure** — the machine stops working — and that is what everything below guards
against. It is not a licence to treat install size as a cost. The disk fills from
Docker images and snapshot retention, never from packages.

- Disk-usage alert timer + `diskcheck` + `emergency-clean` + the diagnosis
  helpers. This has saved the machine before; port it whole.
- Docker storage isolated from snapshots (its own subvolume) so pruning images
  actually frees space.
- Snapper retention limits tuned so snapshots cannot fill the disk.
- ~~An off-device backup, and a LUKS header backup stored off the machine.~~ **No longer a
  requirement here, author's word 2026-08-27** — no external disk, won't have one for a while;
  see `CHOICES.md` `backup`. Snapshots are still not backups (they live inside the volume they
  would have to survive), so this remains a real gap, just not one this repo is closing now.

### C10. Theming
- One palette file is the only place a color is written. Every app config is
  generated from it — terminal, compositor borders, notifications, launcher,
  neovim, GTK. Matte black, zero rounding, one neon accent, ASCII where possible.
- No resident process may exist solely to make things look good.

### C11. Baseline GUI
- Browser (Wayland + GPU accelerated).
- Password access.
- Image viewer, video player, PDF viewer.
- Some way to browse and move files.

---

## Optional profiles — installed on demand, never in the core

Each is a separate script that can be run or skipped. None of them may add a
process that runs at login. At a bare minimum, skip emulation, printing, vscode, and notes. Charles does not know any of the apps in the creative section so those are likely unneeded as well.


| Profile | Contents | Evidence |
|---|---|---|
| `gaming` | Steam, gamescope, gamemode, mangohud, Bolt, Heroic, GeForce NOW flatpak | `steam`, `bolt`, `heroic` config, `StardewValley` config, GeForce NOW flatpak all present. Gaming is NOT a priority on this machine and should be left out of the arch installs. |
| `emulation` | RetroArch + ~45 libretro cores, joypad autoconfig, shaders, overlays | the largest deliberate install on the machine; never captured in the predecessor repo. Confirmed that RetroArch is unneeded. |
| `creative` | kdenlive, OBS, gpu-screen-recorder, Pinta, satty, xournalpp, imagemagick | `magick` in history; all installed |
| `notes` | Obsidian, Typora | both installed; both Electron |
| `comms` | Signal, Discord (web app) | installed and bound to a key |
| `music` | whichever player wins the bake-off | `spotify` running, `cliamp` installed |
| `printing` | CUPS + drivers + PDF printer | installed; **costs 3 resident daemons** — profile, never core |
| `office` | LibreOffice, freerdp | config dirs present |
| `vscode` | VS Code | installed, but history shows `nvim` is the actual editor |

## Explicitly dropped

- **fcitx5** — installed but configured to plain US keyboard. Omarchy default, no
  input method in use.
- **Omarchy itself** — including Quickshell, walker/elephant, the theme system,
  and the whole `omarchy-*` script surface. Every capability it provided is
  re-listed above on its own merits.
- **The `omarchy-nvim` prebuilt LazyVim package** — the repo carries its own
  Neovim config.
- **Plymouth** — costs ~0.8s of boot across three units to hide text that is
  fine to look at.
- **TPM2 auto-unlock setup** — currently ~2.6s of boot for something not in use.
- **avahi / cups-browsed** — network printer discovery daemons; fold into the
  `printing` profile at most.
- **power-profiles-daemon** — a desktop on mains power.
- **`localsearch` / `gvfs` / `gnome-keyring` / `at-spi`** — pulled in by GNOME
  apps rather than chosen. If the file manager choice can avoid them, that is
  several daemons gone.
