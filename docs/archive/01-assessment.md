# Assessment: what the current machine says

Evidence gathered from the live Omarchy host on 2026-08-17 — package log, shell
history, running services, configs, and boot timing. This is the factual base the
other docs argue from; it is not a plan.

## Hardware the new setup must handle

| | |
|---|---|
| CPU | AMD Ryzen 9 7900X (12c/24t) — `amd-ucode` |
| GPU | NVIDIA RTX 4090 (`nvidia-open-dkms`) **+** AMD Raphael iGPU |
| RAM | 64 GB, 4 GB zram swap |
| Disk | 1.8 TB NVMe, **shared with Windows** (1.2 TB NTFS + recovery) |
| Root | LUKS2 → btrfs, subvolumes `@ @home @pkg @log`, snapper + limine-snapper-sync |
| Boot | UEFI, limine at `\EFI\Limine\limine_x64.efi`, Windows Boot Manager alongside on the same ESP |
| Net | `iwd` + `systemd-networkd` + `systemd-resolved` |

Two facts drive most decisions: **NVIDIA on Wayland** (rules out some
compositors' smooth path, forces DRM modesetting + explicit sync) and **the ESP
is shared with Windows** (the installer can never claim a disk).

## Measured baseline (the numbers to beat)

```
firmware 11.5s + loader 3.5s + kernel/initramfs 12.8s + userspace 6.7s = 34.5s
graphical.target @ 5.07s into userspace
```

Where userspace time actually goes: `systemd-tmpfiles-setup` 1.43s,
`systemd-tpm2-setup*` 2.6s combined, `docker` 1.19s, `containerd` 0.67s,
plymouth 0.77s across three units. The 3.5s loader is limine's own timeout.
The 12.8s "kernel" phase is mostly initramfs — NVIDIA modules are built into it
(`MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)`) and the LUKS passphrase
prompt is counted here.

Resident daemons at idle, beyond the unavoidable (pipewire, wireplumber, dbus,
udev, logind, portals): `localsearch-3` (nautilus's file indexer), `elephant` +
`walker` (launcher daemon), `swayosd-server`, `gnome-keyring`, five `gvfs-*`
services, `playerctld`, `at-spi`, `avahi-daemon`, `cups` + `cups-browsed`,
`docker` + `containerd`, `power-profiles-daemon`, `sddm`, `limine-snapper-notify`,
`print-applet`. **That list is the single biggest lever on idle RAM.**

Actual RSS was not measurable cleanly — eight `python3` processes were holding
1.3–2.3 GB each. Re-measure on an idle login before claiming any improvement.

## What is actually used (not just installed)

Shell history, 9320 lines, top commands: `git` 3897, a project script 1407,
`ds` (conda-activate-and-cd) 629, `claude` 424, `vi`→nvim 324, `make` 304,
`gu`/`gur` (git helpers) 202, `conda` 92, `vd` (VPN alias) 72, `gh` 49,
`docker` 41, `btop` 19, `jupyter` 7, `diskcheck` 9.

Read plainly: this is a **terminal-first git/Python/Neovim/Claude Code machine**
that occasionally opens a GUI. Desktop polish matters far less than terminal,
editor, and git being instant.

Packages installed **after** the initial Omarchy bulk (i.e. deliberate personal
choices, not defaults): `bitwarden`, `brave-bin`, `direnv`, `tmux`, `ncdu`,
`pacman-contrib`, `openvpn`, `postgresql`, `opencode`, `visual-studio-code-bin`,
`flatpak`, `freerdp`, `steam`, `bolt`, `ventoy`, `tesseract`, `yq`, `socat`,
`bluetui`, `cliamp`, and **~45 `libretro-*` cores + `retroarch`**.

That emulation set is the largest deliberate install on the machine and is
completely absent from the predecessor repo's provisioning. It is a real want
that has never been captured — and an obvious candidate for an optional profile
rather than the core.

## Taste signals worth preserving

- **Vim-directional everything.** `SUPER+H/J/K/L` focus, rebound over the
  compositor's defaults. `ALT+TAB` means *last window*, not *cycle*.
- **Multi-monitor with workspace-move binds** (`SUPER+SHIFT+CTRL+←/→`).
- **Dark, near-black, single warm accent.** The `daemon` palette is
  `#0f0f0f` background / `#ff4500` accent / `#8b0000` red, `rounding = 0`,
  `border_size = 2`, `gaps 3`. The bunny palette is the same structure with a
  different accent — matte black and zero rounding are already the taste.
- **Disk anxiety is real.** A 4-hourly disk alert timer, `diskcheck`,
  `emergency-clean`, `diagnose_snapshots`, a sudoers whitelist for a read-only
  snapshot-size helper, docker moved to its own subvolume, and a
  `~/disk-space-fixes.md` playbook. The machine has run out of space before.
- **Conda, but reluctantly.** Seven envs under `~/miniforge3/envs`, plus a
  separate `~/.venvs/neovim` explicitly built *conda-independent*, plus `uv`
  already sitting in `~/.local/bin`. The move away from conda has already started.
- **Alacritty, and the cost is known.** Inline Jupyter/molten plots need the
  kitty graphics protocol, which alacritty does not implement; the nvim README
  documents this as a standing limitation. A terminal swap fixes a real gap.
- **fcitx5 is installed but unconfigured** (US keyboard only). It is Omarchy
  default cruft, not a requirement. Drop it.
- **`starship` + `PROMPT_COMMAND`** — the prompt is not plain. `dir-theme`,
  which used to hook into it, was vibe-coded and isn't worth preserving.
