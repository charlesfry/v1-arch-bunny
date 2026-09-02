# Research: the Arch dotfiles landscape vs BunnE (2026-08-24, overnight)

Two subagent web surveys, reviewed and filed by the overnight session:

- **This file** — the repo survey (13 repos: the Hyprland mega-rices, the
  niri ecosystem, theme collections) + what it implies for BunnE.
- **[`research/ricing-cost-audit-2026-08-24.md`](research/ricing-cost-audit-2026-08-24.md)**
  — ricing techniques audited against Fast/Light with whatever numbers the
  ecosystem actually publishes (spoiler: almost none — measured claims are
  this repo's competitive advantage, not table stakes).

## The survey in one table

| Repo | ~Stars | Stack | Deploy | Palette | Residents beyond compositor |
|---|---|---|---|---|---|
| end-4/dots-hyprland | 15.8k | Hyprland + Quickshell | rsync copy, semi-idempotent | matugen | Quickshell mega-shell, hypridle, keyring, easyeffects, 2× cliphist watchers, ydotool |
| caelestia-dots/shell | 11.6k | Hyprland + Quickshell | CLI installer, copy | Material-You CLI | ONE Quickshell process = bar+notif+launcher+lock+dashboard |
| HyDE (hyprdots) | 9.5k | Hyprland + waybar | TOML manifest, sync/preserve per file | hand-rolled "wallbash" (bash+ImageMagick kmeans) | waybar, awww, hypridle, dunst/swaync, applets; bundles SDDM |
| adi1090x/rofi | 8.8k | theme layer only | cp -rf, not idempotent | hand-authored | none (on-demand) |
| ML4W | 5.0k | Hyprland + waybar/Quickshell | stage-then-symlink + diff/restore TUI, idempotent | matugen (+wallust); vendors binaries in-repo | waybar/QS, awww, swaync, hypridle, udiskie, blueman, p-p-daemon |
| gh0stzk | 4.7k | BSPWM (X11) | staged cp, backup-first | 18 hand-made themes | polybar+eww+picom+dunst+sxhkd (self-reports <600 MB "at startup") |
| JaKooLit | 4.6k | Hyprland + waybar | cp -r, backup-first | wallust | waybar, swww, hypridle, swaync |
| folke/dot | 1.3k | Hyprland AND niri (CachyOS) | **Ansible symlinks — idempotent** | hand-authored | DankMaterialShell (Quickshell), greetd; 467-package list |
| linkfrg | 1.0k | Hyprland AND niri (NixOS) | Nix flake | hand-built Material pipeline | Ignis (own GTK4 framework, one process) |
| saatvik333/niri-dotfiles | 206 | niri | install.sh, re-copies | wallust | waybar, mako, awww, vicinae |
| acaibowlz/niri-setup | 162 | niri | **whole-dir ln -sf + niri validate self-check** | hand-made palette doc | waybar, dunst, swayidle, swaylock-effects, swww+swaybg |
| YaLTeR/dotfiles | 62 | niri (author's own) | chezmoi | hand-made colors.kdl | waybar, mako, swayidle, wlsunset; **no wallpaper daemon at all**; hyprlock on demand |

## What transfers to BunnE (and what doesn't)

1. **Our deploy pick is validated by the outliers, not the crowd.** Nobody
   uses Stow; the mega-rices copy-in-place (mostly non-idempotent). The two
   cleanest mechanisms surveyed are exactly our shape: folke's Ansible
   `state=link` (a matching symlink is a no-op) and acaibowlz's whole-dir
   `ln -sf` **followed by `niri validate` as a self-check** — that
   validate-after-deploy step is worth stealing for `install.sh`.
2. **Palette pipeline: matugen and wallust are the two live engines**
   (pywal is dead/archived; HyDE hand-rolls bash+ImageMagick). Both are
   one-shot Rust template generators — exactly the C10 "one palette file,
   everything generated" requirement. BunnE's palette is hand-designed
   (cyber-bunny), not wallpaper-extracted, so we'd use only the
   *templating+reload* half: static palette in, per-app files out,
   reload hooks (`SIGUSR1` kitty, `makoctl reload`,
   `niri msg action load-config-file`). Phase-4 candidate row.
3. **Naming conventions: we already match the modal layout**
   (`config/<app>/…` mirroring `~/.config`). The genuine fork in the road
   is scripts: mega-rices bury them in app subtrees
   (`hypr/scripts/`), lean repos use `~/.local/bin`. For "unsurprising
   beats clever," `~/.local/bin` (on PATH, XDG-conventional) fits BunnE.
4. **Meta-package idea** (end-4's `illogical-impulse-*` PKGBUILD groups):
   a checked-in meta-package per install profile would make the
   `install-profile` lite/full split a pacman-native concept instead of an
   installer branch. Worth a Phase-4 look; costs a local PKGBUILD.
5. **The niri "standard stack" everyone converges on** is what we already
   run (waybar excepted — we ship no bar): mako/dunst, swayidle, swaylock,
   xwayland-satellite (we defer X11 entirely), plus the hyprlock-under-niri
   pattern (compositor-agnostic single-purpose binaries are fair game).
   YaLTeR himself runs *no wallpaper daemon* — matte-black-by-default has
   the compositor author's implicit blessing.
6. **Nobody has solved snapshot-bloat** — no surveyed repo authors
   btrfs+snapper integration (folke inherits CachyOS's). Our capped-snapper
   work has no off-the-shelf equivalent to copy *from*; it's a genuine
   differentiator of this repo.
7. **The Quickshell consolidation trend (4 of the top repos) ships zero
   numbers.** One process replacing five daemons is a plausible 2b
   argument, and not one repo measured it. If BunnE ever wants a
   shell/bar, the bake-off must produce the numbers the ecosystem hasn't.
8. **Session managers:** big rices bundle SDDM; greetd appears only in
   full-system repos; nobody does our autologin-after-LUKS. Ours remains
   justified by `disk-unlock` (the LUKS passphrase *is* the credential) —
   just know it's unusual, not conventional.
9. **fish is trending** in the newest high-star repos (end-4, caelestia,
   linkfrg). Our `shell` row (bash) is a taste pick and stands; recorded as
   ecosystem drift, not a recommendation.

## Cautions

- Star counts track eye candy and installer polish, not engineering. The
  best *mechanisms* surveyed came from low-star repos (folke's idempotent
  symlinks, acaibowlz's validate-after-deploy, YaLTeR's chezmoi-plus-
  nothing).
- Several popular repos re-copy configs on every run and rely on backup
  dirs piling up — the exact anti-pattern our idempotency convention bans.
