# Reference: viacoffee/dotfiles

A friend's personal Arch config, surveyed 2026-08-20 from
<https://github.com/viacoffee/dotfiles>. Worth a reference doc because the
architecture matches this repo's almost exactly — **`archinstall` for the base,
then a numbered-phase `install.sh` for everything else, on niri** — so it is the
closest thing to a working example of what BunnE is trying to be.

**It is not a spec.** His tastes differ (zsh, alacritty, NvChad, ufw, Stow) and
several of his choices contradict decisions already settled in `CHOICES.md`.
Treat every item below as *evidence of a want*, the same rule `CLAUDE.md` applies
to the predecessor repo. Nothing here has been tested on `bunne-test`.

## The one that changed a `CHOICES.md` row

**`limine-snapper-sync` is available prebuilt.** He never builds it — his
`pacman.conf` adds `[omarchy] Server = https://pkgs.omarchy.org/stable/$arch`
and installs it with plain `pacman -S`. Verified on the author's Omarchy
desktop: version 1.31.0-1, 8.93 MiB download / 26.11 MiB installed, depending
only on `bash limine snapper btrfs-progs libnotify`. The gradle/GraalVM cost was
build-time only. See `CHOICES.md` `snapshot-boot-entries` for the trust tradeoff
(`SigLevel = Optional TrustAll`), which is now the deciding factor rather than
capability.

## Steal these

**The `environment {}` block in `config.kdl`.** Keeps apps off Xwayland, which
`benchmarks/3.2.compositor-idle.md` measured as the largest resident cost in a
compositor session:

```kdl
environment {
  QT_QPA_PLATFORM "wayland"
  GDK_BACKEND "wayland,x11,*"
  SDL_VIDEODRIVER "wayland"
  MOZ_ENABLE_WAYLAND "1"
  ELECTRON_OZONE_PLATFORM_HINT "wayland"
  OZONE_PLATFORM "wayland"
}
```

**Split the niri config with `include`.** He has `config.kdl` including
`bindings.kdl`, `window-rules.kdl`, `animations.kdl`, plus
`include optional=true "window-rules.laptop.kdl"` — per-machine overrides with no
conditionals and no templating. This is exactly the mechanism `CLAUDE.md` asks
for on keeping hostname/monitor layout isolated and overridable.

**Per-output `layout` blocks.** Different `default-column-width` and
`preset-column-widths` for the laptop panel vs the external monitor (his: 0.5 on
a 2256x1504 panel, 0.33 on a 3440x1440 ultrawide). Directly relevant to the
Intel-panel / NVIDIA-external split on `bunne-test`.

**Signal-driven bar updates instead of polling.** His waybar modules refresh on
`SIGRTMIN+N` rather than an `interval`, driven by a one-line helper:

```bash
signal_waybar() { [[ -n "$1" ]] && pkill "-RTMIN+$1" waybar; }
```

A script that changes state pokes the bar when it changes. No timer, no polling
loop — the priority-2 shape for anything that would otherwise wake up on an
interval. Carry this into the `bar` slot whatever bar wins.

**greetd's fallback session.** If the compositor fails to start you get a shell,
not a lockout:

```toml
[initial_session]
command = "uwsm start niri-session"
[default_session]
command = "/bin/sh"
```

He also disables the `niri.service` user unit so `uwsm` owns the session rather
than the two fighting over it. There is no login-manager row in `CHOICES.md`
yet; this is the candidate to evaluate against "just log into a TTY".

**Disabling mkinitcpio pacman hooks during bulk installs.** `00-preflight.sh`
moves `90-mkinitcpio-install.hook` and `60-mkinitcpio-remove.hook` aside,
`14-bootloader.sh` restores them, and `install.sh` carries
`trap _restore_mkinitcpio_hooks EXIT`. Given `nvidia-open-dkms` plus two kernels,
that avoids many regenerations of a 25 MB image.
**Adopt only with a loud end-of-install verification.** The failure mode is
silent and severe: killed outside the trap (power loss, SIGKILL) and the hooks
stay disabled, so every future kernel update produces no initramfs and the
machine dies weeks later at a boot that has nothing to do with the install.

**Small niri config wins**: `hotkey-overlay { skip-at-startup; hide-not-bound }`
(the second half hides binds that do not exist), `cursor { hide-when-typing }`,
`prefer-no-csd`, `warp-mouse-to-focus mode="center-xy"`,
`switch-events { lid-close { … } }`, `struts { right 51 }` to reserve bar space,
and `spawn-sh-at-startup "wl-paste --type text --watch cliphist store"` for
clipboard history.

## Do not copy — already decided against

| his choice | this repo | where |
|---|---|---|
| `ufw` | nftables, Arch's shipped ruleset, no config file | `CHOICES.md` `firewall` |
| Stow | hand-rolled `ln -sfn` — **but see the relitigation note** | `dotfile-deployment` |
| alacritty | kitty, for the graphics protocol | `terminal` |
| `plymouth` | — | boot splash: resident cost for cosmetics |
| `power-profiles-daemon` | — | laptop power management explicitly dropped |
| Nautilus, gvfs | — | arrives anyway if the GNOME portal is taken |

## Worth a closer look later

- **`uwsm`** (Universal Wayland Session Manager) — a more general session
  manager than `niri-session`. Unclear what it buys over niri's own systemd
  integration, which `benchmarks/3.2` already found to be correct.
- **`xdg-terminal-exec`** — makes "open a terminal" work for apps that ask the
  desktop to do it.
- **`swayosd`** — on-screen volume/brightness display. A resident daemon; judge
  against priority 2.
- **`wiremix`** (TUI audio mixer), **`impala`** (iwd TUI). He also uses
  `bluetui`, which this repo already picked independently.
- **`gpu-screen-recorder`** — NVIDIA-accelerated capture.
