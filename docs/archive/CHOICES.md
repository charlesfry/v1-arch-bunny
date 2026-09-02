# The choice ledger

Format and rules: [docs/05-choices.md](docs/05-choices.md). Seed order: [docs/05-choices.md](docs/05-choices.md#seeding-it).

**Read the `Measured` column knowing what is missing from it.** Every row below
predates the 2026-08-21 priority correction (`CLAUDE.md`: **2a fast, then 2b
light**; disk is not a criterion), and it shows — of the 50 rows here, one
carries a timing number. Where a row justifies itself in megabytes of RAM alone
and the slot sits in the interactive path, treat it as **half-argued rather than
wrong**: the RAM figure is real, the latency figure was never taken. New rows
put time first.

## The rows at a glance

One line per decision; the evidence and reasoning for each live in the matching
section under [The rows](#the-rows).

| Slot | Candidate | Packages | Status | Date |
|---|---|---|---|---|
| filesystem | [btrfs + LUKS2](#filesystem--btrfs--luks2) | btrfs-progs | picked | 2026-08-18 |
| initramfs | [mkinitcpio + `encrypt` hook, no `linux-firmware-nvidia`](#initramfs--mkinitcpio--encrypt-hook-no-linux-firmware-nvidia) | — | picked | 2026-08-18 |
| bootloader | [limine](#bootloader--limine) | limine efibootmgr | picked | 2026-08-18 |
| windows-coexist | [separate archinstall JSON, `parted` pre-delete, `limine-entry-tool` for the boot entry](#windows-coexist--separate-archinstall-json-parted-pre-delete-limine-entry-tool-for-the-boot-entry) | — | picked | 2026-08-27 |
| gpu-driver | [nvidia-open (prebuilt)](#gpu-driver--nvidia-open-prebuilt) | mesa | picked | 2026-08-25 |
| gpu-topology | [hybrid (Optimus), panel on iGPU](#gpu-topology--hybrid-optimus-panel-on-igpu) | — | picked | 2026-08-18 |
| aur-helper | [yay-bin](#aur-helper--yay-bin) | yay-bin base-devel git | picked | 2026-08-18 |
| makepkg-options | [`!debug` in `/etc/makepkg.conf` `OPTIONS=`](#makepkg-options--debug-in-etcmakepkgconf-options) | — | picked | 2026-08-18 |
| ssh | [`openssh` installed, `sshd.service` **disabled by default**](#ssh--openssh-installed-sshdservice-disabled-by-default) | openssh | picked | 2026-08-18 |
| documentation | [man-db (reader). `man-pages` separately, probably skip](#documentation--man-db-reader-man-pages-separately-probably-skip) | man-db less | picked | 2026-08-19 |
| rollback-method | [manual btrfs subvolume swap](#rollback-method--manual-btrfs-subvolume-swap) | — | picked | 2026-08-18 |
| snapshot-boot-entries | [limine-snapper-sync, from the omarchy binary repo](#snapshot-boot-entries--limine-snapper-sync-from-the-omarchy-binary-repo) | limine-snapper-sync | picked | 2026-08-25 |
| dotfile-deployment | [symlink, via hand-rolled `ln -sfn` in `install.sh`](#dotfile-deployment--symlink-via-hand-rolled-ln--sfn-in-installsh) | — | picked | 2026-08-19 |
| install-artifact | [stock pinned Arch ISO + this repo; no custom artifact](#install-artifact--stock-pinned-arch-iso--this-repo-no-custom-artifact) | — | picked | 2026-08-26 |
| install-profile | [lite / full split](#install-profile--lite--full-split) | — | rejected | 2026-08-27 |
| docker-storage-quota | [top-level btrfs subvolumes + qgroup **accounting only**, no limits; the `disk-alert` row is the protection](#docker-storage-quota--top-level-btrfs-subvolumes--qgroup-accounting-only-no-limits-the-disk-alert-row-is-the-protection) | — | picked | 2026-08-26 |
| snapshot-bloat | [—](#snapshot-bloat--) | — | picked | 2026-08-27 |
| python-env-manager | [uv, with pixi as the conda-only escape hatch](#python-env-manager--uv-with-pixi-as-the-conda-only-escape-hatch) | uv | picked | 2026-08-19 |
| oom-protection | [systemd-oomd](#oom-protection--systemd-oomd) | — | picked | 2026-08-25 |
| dir-aware-display | [direnv + prompt hook](#dir-aware-display--direnv--prompt-hook) | direnv | picked | 2026-08-27 |
| compositor | [Hyprland](#compositor--hyprland) | hyprland kitty xdg-desktop-portal-hyprland | rejected | 2026-08-20 |
| compositor | [niri](#compositor--niri) | niri | picked | 2026-08-20 |
| font | [Fragment Mono, `disable_ligatures always`](#font--fragment-mono-disable_ligatures-always) | — | picked | 2026-08-25 |
| emoji-font | [noto-fonts-emoji](#emoji-font--noto-fonts-emoji) | noto-fonts-emoji | picked | 2026-08-30 |
| audio | [`pipewire-audio` + `pipewire-pulse` + `wireplumber` + `realtime-privileges`](#audio--pipewire-audio--pipewire-pulse--wireplumber--realtime-privileges) | pipewire-audio pipewire-pulse wireplumber realtime-privileges | picked | 2026-08-19 |
| bluetooth | [bluez + bluez-utils + bluetui](#bluetooth--bluez--bluez-utils--bluetui) | bluez bluez-utils bluetui | picked | 2026-08-19 |
| swap-zram | [zram only, no disk swap, no hibernation](#swap-zram--zram-only-no-disk-swap-no-hibernation) | zram-generator | picked | 2026-08-19 |
| firmware-set | [named `linux-firmware-*` splits, never the metapackage, never `-nvidia`](#firmware-set--named-linux-firmware--splits-never-the-metapackage-never--nvidia) | linux-firmware-intel linux-firmware-realtek linux-firmware-atheros linux-firmware-mediatek linux-firmware-broadcom linux-firmware-other linux-firmware-whence linux-firmware-amdgpu | picked | 2026-08-25 |
| microcode | [vendor-conditional, chosen at install time](#microcode--vendor-conditional-chosen-at-install-time) | — | picked | 2026-08-25 |
| firewall | [nftables, Arch's shipped `/etc/nftables.conf` unmodified](#firewall--nftables-archs-shipped-etcnftablesconf-unmodified) | nftables | picked | 2026-08-18 |
| clipboard | [wl-clipboard + cliphist](#clipboard--wl-clipboard--cliphist) | wl-clipboard cliphist | picked | 2026-08-19 |
| shell | [bash](#shell--bash) | bash | picked | 2026-08-19 |
| luks-header-backup | [`cryptsetup luksHeaderBackup` at install + recovery key recorded off-machine](#luks-header-backup--cryptsetup-luksheaderbackup-at-install--recovery-key-recorded-off-machine) | — | picked | 2026-08-19 |
| backup | [—](#backup--) | — | deferred | 2026-08-27 |
| desktop-portals | [—](#desktop-portals--) | — | rejected | 2026-08-27 |
| secrets-bootstrap | [—](#secrets-bootstrap--) | — | picked | 2026-08-27 |
| load-protection | [systemd slice weighting + core reservation](#load-protection--systemd-slice-weighting--core-reservation) | — | picked | 2026-08-25 |
| desktop-migration | [reformat `p2` in place; Omarchy is removed, not coexisted with](#desktop-migration--reformat-p2-in-place-omarchy-is-removed-not-coexisted-with) | — | picked | 2026-08-19 |
| install-disk-mode | [`convert` is the only mode this repo implements; `archinstall` owns the rest](#install-disk-mode--convert-is-the-only-mode-this-repo-implements-archinstall-owns-the-rest) | — | picked | 2026-08-19 |
| installer-prompts | [short bounded set, asked up front, all defaulted](#installer-prompts--short-bounded-set-asked-up-front-all-defaulted) | — | picked | 2026-08-19 |
| base-install-method | [`archinstall` + a checked-in JSON config; this repo does **post-install only**](#base-install-method--archinstall--a-checked-in-json-config-this-repo-does-post-install-only) | — | picked | 2026-08-19 |
| jupyter-in-neovim | [molten-nvim + image.nvim (`magick_cli`) + jupytext](#jupyter-in-neovim--molten-nvim--imagenvim-magick_cli--jupytext) | neovim imagemagick | picked | 2026-08-25 |
| terminal | [kitty](#terminal--kitty) | kitty | picked | 2026-08-21 |
| terminal | [ghostty](#terminal--ghostty) | ghostty | rejected | 2026-08-21 |
| terminal | [foot](#terminal--foot) | foot | rejected | 2026-08-21 |
| terminal | [alacritty](#terminal--alacritty) | alacritty | rejected | 2026-08-21 |
| terminal-navigation | [kitty built-ins; deviate only on `scrollback_pager` + `scrollback_lines`](#terminal-navigation--kitty-built-ins-deviate-only-on-scrollback_pager--scrollback_lines) | — | picked | 2026-08-19 |
| ascii-bunnies | [Frame files in the repo + a fork-free bash player, invoked only by processes that already exist or that exit](#ascii-bunnies--frame-files-in-the-repo--a-fork-free-bash-player-invoked-only-by-processes-that-already-exist-or-that-exit) | — | rejected | 2026-08-27 |
| os-base | [Arch Linux](#os-base--arch-linux) | — | picked | 2026-08-20 |
| os-base | [NixOS](#os-base--nixos) | — | rejected | 2026-08-20 |
| polkit | [polkit](#polkit--polkit) | polkit | picked | 2026-08-20 |
| cursor-theme | [adwaita-cursors](#cursor-theme--adwaita-cursors) | adwaita-cursors | picked | 2026-08-20 |
| notifications | [mako (leaning), D-Bus activated not enabled](#notifications--mako-leaning-d-bus-activated-not-enabled) | mako libnotify gcalcli | picked | 2026-08-27 |
| portal | [xdg-desktop-portal-gnome + `portals.conf`](#portal--xdg-desktop-portal-gnome--portalsconf) | xdg-desktop-portal-gnome pipewire-jack | picked | 2026-08-20 |
| browser | [brave-bin](#browser--brave-bin) | brave-bin | picked | 2026-08-20 |
| browser-fallback | [chromium](#browser-fallback--chromium) | chromium | picked | 2026-08-20 |
| disk-unlock | [manual LUKS2 passphrase at boot, autologin after it](#disk-unlock--manual-luks2-passphrase-at-boot-autologin-after-it) | — | picked | 2026-08-21 |
| disk-unlock | [TPM2 auto-unlock (`systemd-cryptenroll`)](#disk-unlock--tpm2-auto-unlock-systemd-cryptenroll) | — | rejected | 2026-08-21 |
| benchmark-unlock | [random keyfile in a second LUKS keyslot, baked into the initramfs](#benchmark-unlock--random-keyfile-in-a-second-luks-keyslot-baked-into-the-initramfs) | — | picked | 2026-08-21 |
| boot-splash | [Plymouth, script module, the flower-thief bunny background](#boot-splash--plymouth-script-module-the-flower-thief-bunny-background) | plymouth | picked | 2026-08-27 |
| silent-boot | [`quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3`](#silent-boot--quiet-loglevel3-systemdshow_statusauto-rdudevlog_level3) | — | picked | 2026-08-27 |
| shell-startup | [leave `/etc/profile.d/vapoursynth.sh` alone; fix tier 2 and 3 instead](#shell-startup--leave-etcprofiledvapoursynthsh-alone-fix-tier-2-and-3-instead) | — | rejected | 2026-08-21 |
| prompt | [hand-rolled bash `PS1`, no command substitution on the prompt path](#prompt--hand-rolled-bash-ps1-no-command-substitution-on-the-prompt-path) | — | picked | 2026-08-27 |
| node-runtime | [Arch's **`nodejs`** package; **no `mise`, no shims, no version manager**](#node-runtime--archs-nodejs-package-no-mise-no-shims-no-version-manager) | nodejs npm | picked | 2026-08-27 |
| agent-clis | [**`claude` only** — drop `codex`, `gemini`, `copilot`, `opencode`](#agent-clis--claude-only--drop-codex-gemini-copilot-opencode) | — | picked | 2026-08-21 |
| polkit-agent | [**`mate-polkit`**](#polkit-agent--mate-polkit) | mate-polkit | picked | 2026-08-21 |
| lock-idle | [**`swaylock` + `swayidle`**](#lock-idle--swaylock--swayidle) | swaylock swayidle | picked | 2026-08-21 |
| config-validation | [our own checks for what upstream validators miss; `scripts/check-keybinds.sh` is the first](#config-validation--our-own-checks-for-what-upstream-validators-miss-scriptscheck-keybindssh-is-the-first) | — | picked | 2026-08-21 |
| xwayland | [**deferred** — no X11 support at all right now](#xwayland--deferred--no-x11-support-at-all-right-now) | (would be `xwayland-satellite`) | deferred | 2026-08-21 |
| remote-desktop | [not available; **niri limitation, not a packaging choice**](#remote-desktop--not-available-niri-limitation-not-a-packaging-choice) | — | picked | 2026-08-21 |
| compositor-cleanup | [remove Hyprland and its library stack from `bunne-test`](#compositor-cleanup--remove-hyprland-and-its-library-stack-from-bunne-test) | — | picked | 2026-08-21 |
| prompt-hooks | [gate every `PROMPT_COMMAND` hook on a `$PWD` change](#prompt-hooks--gate-every-prompt_command-hook-on-a-pwd-change) | — | deferred | 2026-08-21 |
| python-pynvim | [pinned python3 provider for Neovim](#python-pynvim--pinned-python3-provider-for-neovim) | python-pynvim | picked | 2026-08-21 |
| editor | [**LazyVim** (NVChad and hand-rolled minimal rejected)](#editor--lazyvim-nvchad-and-hand-rolled-minimal-rejected) | neovim python-pynvim lazygit ripgrep fd | picked | 2026-08-27 |
| latex-rendering | [TeX for notebook LaTeX output (molten `text/latex` -> pnglatex -> pdflatex/pdfcrop/pdftoppm/pnmtopng)](#latex-rendering--tex-for-notebook-latex-output-molten-textlatex---pnglatex---pdflatexpdfcroppdftoppmpnmtopng) | texlive-basic texlive-latex texlive-binextra | picked | 2026-08-27 |
| keybindings | [cascading standard: Omarchy defaults <- author's `~/.config/hypr/bindings.conf` <- non-colliding <- installed-relevant](#keybindings--cascading-standard-omarchy-defaults---authors-confighyprbindingsconf---non-colliding---installed-relevant) | — | picked | 2026-08-24 |
| keybind-apps | [apps bound by the ratified keybind set](#keybind-apps--apps-bound-by-the-ratified-keybind-set) | spotify-launcher btop lazydocker signal-desktop bitwarden playerctl nautilus | picked | 2026-08-24 |
| kernel | [linux (mainline)](#kernel--linux-mainline) | linux | picked | 2026-08-23 |
| network-stack | [NetworkManager](#network-stack--networkmanager) | networkmanager | picked | 2026-08-23 |
| snapshot-system | [snapper + snap-pac, pre/post only, qgroup byte-cap](#snapshot-system--snapper--snap-pac-prepost-only-qgroup-byte-cap) | snapper snap-pac | picked | 2026-08-23 |
| launcher | [fuzzel](#launcher--fuzzel) | fuzzel | picked | 2026-08-21 |
| wallpaper | [swaybg, solid `-c #0f0f0f`](#wallpaper--swaybg-solid--c-0f0f0f) | swaybg | picked | 2026-08-21 |
| screenshot | [niri built-in actions + satty for annotate](#screenshot--niri-built-in-actions--satty-for-annotate) | grim slurp satty | picked | 2026-08-23 |
| brightness-keys | [brightnessctl on XF86 keys](#brightness-keys--brightnessctl-on-xf86-keys) | brightnessctl | picked | 2026-08-23 |
| kernel-boot-entries | [limine-mkinitcpio-hook (same publisher as the snapshot tool)](#kernel-boot-entries--limine-mkinitcpio-hook-same-publisher-as-the-snapshot-tool) | limine-mkinitcpio-hook | picked | 2026-08-25 |
| disk-alert | [user timer, one `df`, threshold 80%](#disk-alert--user-timer-one-df-threshold-80) | — | picked | 2026-08-26 |
| display-manager | [getty-autologin; greetd driven and rejected](#display-manager--getty-autologin-greetd-driven-and-rejected) | — | picked | 2026-08-25 |
| palette | [one palette file + `envsubst` templater](#palette--one-palette-file--envsubst-templater) | — | picked | 2026-08-25 |
| docker | [docker + compose, socket-activated](#docker--docker--compose-socket-activated) | docker docker-compose | picked | 2026-08-25 |
| status-bar | [waybar — the clock is what buys the 28.4 MB](#status-bar--waybar--the-clock-is-what-buys-the-284-mb) | waybar | picked | 2026-08-26 |
| git-config | [deviations only, identity excluded](#git-config--deviations-only-identity-excluded) | — | picked | 2026-08-26 |
| media-viewers | [imv + mpv; PDF in the browser](#media-viewers--imv--mpv-pdf-in-the-browser) | imv mpv | picked | 2026-08-28 |
| git-forge-cli | [github-cli](#git-forge-cli--github-cli) | github-cli | picked | 2026-08-28 |
| shell-helpers | [harvest the predecessor's git + diagnosis functions, nothing else](#shell-helpers--harvest-the-predecessors-git--diagnosis-functions-nothing-else) | — | picked | 2026-08-28 |
| vpn | [`openvpn`, aliases generated from a directory nothing in this repo names](#vpn--openvpn-aliases-generated-from-a-directory-nothing-in-this-repo-names) | openvpn | picked | 2026-08-28 |

## The rows

### filesystem — btrfs + LUKS2

**picked** · 2026-08-18 · packages: btrfs-progs

**Measured:** —

`@`, `@home`, `@snapshots`, `@log`, `@cache`, `@tmp` subvolumes on one LUKS2 volume,
`noatime,compress=zstd:1`.

**`@pkg` became `@cache`, and `@tmp` was added, 2026-08-28 (author's ask).** The old pair
was `@pkg` → `/var/cache/pacman/pkg`, chosen because those were `archinstall`'s default
names and matching them "costs nothing". **That reasoning has expired**: `disk_config` is no
longer shipped in either JSON and *Suggest partition layout* is no longer in the
instructions, so nothing is matching archinstall's defaults any more. What replaced it is
the Arch wiki's own Snapper guidance: *"Consider creating subvolumes for other directories
that contain data you do not want to include in snapshots and rollbacks of the `@`
subvolume, such as `/var/cache`, `/var/spool`, `/var/tmp`, `/var/lib/machines`,
`/var/lib/docker`…"*

`/var/cache` is a strict superset of the pacman cache and catches `fontconfig`, `man-db`,
`ldconfig` and the rest — every one regenerable, every one pointless inside a snapshot, and
none of them version-coupled to the system, so a rollback that leaves them alone is
correct. `/var/tmp` is persistent-across-reboot scratch that would otherwise be rolled back
with the system.

**`/var/spool` is on the wiki's list and deliberately left off ours**: on a desktop with no
mail or cron spool it is empty, and every subvolume is one more line a human types by hand
into archinstall's menu. Add it if something ever puts data there. Matches `03-alternatives.md` #1. **Applied by
`install.d/05-mount-options.sh` since 2026-08-28, not by the JSON**, because `disk_config`
was dropped from both archinstall files that day and archinstall can express neither
option: `BtrfsMountOption.compress` is the literal string `compress=zstd`
(`lib/models/device.py:513`) with no way to state a level, and `noatime` does not appear
anywhere in its source. **The level is the point** — zstd defaults to 3, which spends
roughly two to three times the CPU per write to buy disk space, and disk space is
explicitly not a metric for this repo while write latency is. Taking archinstall's
`compress=zstd` would have traded the metric we optimise for against the one we do not,
silently. **Renamed 2026-08-19** from
`@var_log`/`@var_pkgs` to `@log`/`@pkg`: these are `archinstall`'s default names, and
the base install is now delegated to it (`base-install-method`), so matching costs
nothing and avoids carrying a rename through the JSON config for no gain — clarity over
creativity. Nothing depended on the old names but our own prose. Note the Phase 2
hand-install invented them; the daily-driver desktop already uses `@ @home @pkg @log`
(`01-assessment.md`), so this is a return to convention, not a new one. **`@snapshots`
is not among archinstall's defaults, so the JSON config declares it explicitly**
(author, 2026-08-19) rather than leaving it to `snapper create-config`. Reason:
`rollback-method` depends on `@snapshots` existing *as a subvolume mounted at
`/.snapshots` via fstab*, and letting snapper create it later produces a subvolume the
base install does not know about — the layout would then differ depending on whether
snapper had been configured yet, which is exactly the kind of "depends when you look"
state that made `snapper rollback` fail here in the first place. Declaring it keeps the
disk layout a single fact stated in one file.


### initramfs — mkinitcpio + `encrypt` hook, no `linux-firmware-nvidia`

**picked** · 2026-08-18 · packages: —

**Measured:** 130 MB → 25 MB per image; `/boot` 590M → 379M used

Default mkinitcpio; `encrypt` hook before `filesystems` in `HOOKS=` for LUKS2 unlock.
**The 130 MB trap, which will hit any NVIDIA machine**: the `kms` hook runs
`add_checked_modules '/drivers/gpu/drm/'`, an NVIDIA card matches `nouveau`, and
`add_module`'s `firmware)` branch then pulls in `nouveau`'s entire declared firmware set
— 661 files, every chip from Maxwell to Blackwell, ~104 MB — into the *uncompressed*
early CPIO. Blacklisting `nouveau` in `modprobe.d` stops it **loading**, not being
**packed**. There is no exclusion syntax in `MODULES=` (only a trailing `?` for
optional); the fix is `pacman -R linux-firmware linux-firmware-nvidia` — both, since the
`linux-firmware` metapackage requires the split. **Never `-Rs`**: it would sweep every
other `linux-firmware-*` including wifi. Follow with `pacman -D --asexplicit` on the
survivors or they become orphans a later `-Rns $(pacman -Qdtq)` would delete.
`nvidia-open` is unaffected — its GSP firmware lives in `nvidia-utils`' version-numbered
dir, not the chip-named ones. Kept the `kms` hook so `i915` still gives a native-res
LUKS prompt. **Gotcha**: any `pacman` transaction fires `90-mkinitcpio-install.hook`,
which rebuilds *all* presets — so `mkinitcpio -p <one>` cannot preserve a known-good
image if a pacman step precedes it, and `/boot` is FAT and outside the btrfs snapshots,
so there is no rollback for it.


### bootloader — limine

**SETTLED 2026-08-28: limine lives at `$ESP/EFI/limine/limine_x64.efi` with its config at
`$ESP/limine.conf`, and archinstall's copy is deleted.** Not a preference —
`/usr/lib/limine/limine-common-functions:399-400` hardcodes both paths:

```
LIMINE_EFI_PATH="\EFI\limine\${LIMINE_EFI_FILE}"
LIMINE_CONFIG_PATH="${ESP_PATH}/limine.conf"
```

so `limine-entry-tool`, `limine-snapper-sync` (`snapshot-boot-entries`) and
`limine-mkinitcpio-hook` (`kernel-boot-entries`) can only ever read and write there.
`archinstall` installs to `$ESP/EFI/arch-limine/` instead and **nothing ever updates that
copy again**.

**Both existing at once is what a fresh install actually produces, and it is the worst
case.** Observed on hardware: `BootCurrent` was archinstall's entry while `BootOrder` led
with the tooling's, so the *next* boot would have read a `limine.conf` no kernel update had
ever touched. Snapshot entries and new-kernel entries go to the tooling's file; archinstall's
goes stale the moment a kernel changes. A machine booting the stale one loses its rollback
menu and, after the first kernel update, points at a kernel that is no longer on disk.

**This also means `snapshot-boot-entries` was broken on every archinstall-produced machine**
and nobody noticed, because `benchmarks/4.25` passed on the hand-installed box, which had
the flat layout already. The 2026-08-27 `find-limine-conf.sh` work — teaching the finder
about `/boot/EFI/arch-limine/` — papered over the incompatibility instead of resolving it.
The finder still earns its place: after convergence the booted binary is
`EFI/limine/limine_x64.efi`, which has no config beside it, so the finder falls through to
its last candidate, `$esp/limine.conf`, and lands correctly.

`install.d/50-limine.sh` does the convergence: once `$ESP/limine.conf` and
`$ESP/EFI/limine/limine_x64.efi` both exist, it removes `EFI/arch-limine` and the firmware
entry pointing into it. Order is load-bearing — `20-packages.sh` installs
`limine-mkinitcpio-hook`, whose first run deploys the tooling's copy, so by step 50 both are
present and dropping one is safe. If the tooling's copy is missing the step **fails**
rather than continuing, per `CLAUDE.md`'s never-gracefully-handle rule.

**picked** · 2026-08-18 · packages: limine efibootmgr

**Measured:** boots zen/fallback/Windows from one menu

**Found 2026-08-26, rehearsing `archinstall-2026.08.01-wholedisk.json` in a VM — a real incompatibility,
fixed 2026-08-27.** `bunne-test`'s current layout (`/boot/limine.conf` at the ESP root,
`\EFI\LIMINE\LIMINE_X64.EFI`) is what a **manual** Phase-2 install produced, before
`base-install-method` moved to `archinstall`. `archinstall 4.4`'s own `_add_limine_bootloader`
(read from source, `lib/installer.py:1445`) does not do that at all: with
`bootloader_config.removable: false` (our setting) it writes `/boot/EFI/arch-limine/limine.conf`
and `\EFI\arch-limine\BOOTX64.EFI`, and creates the `efibootmgr` NVRAM entry pointing there —
confirmed in the VM rehearsal (`find /mnt/boot` after a clean `RUN3_EXIT:0`). `removable: true`
would use `/boot/EFI/BOOT/limine.conf` instead — still nested, never the flat path. Neither
matched what `install.d/00-preflight.sh`, `install.d/50-limine.sh` and `scripts/check-limine.sh`
hardcoded (`LCONF=/boot/limine.conf`, no subdirectory) — a friend following the documented path
(archinstall JSON → `install.sh`) would have hit `50-limine.sh` failing immediately, even though
Limine installed correctly, just one directory over.

**The fix: `scripts/find-limine-conf.sh`, reading limine's own search order** (`CONFIG.md` on the
box, "Location of the config file") rather than guessing a second path — first the directory next
to the EFI app that was actually booted (`efibootmgr -v`'s `BootCurrent` entry, needs no root:
efivars are world-readable), then limine's own four boot-drive candidates in its documented
priority order. `00-preflight.sh` now checks it resolves (a clear failure before anything writes,
not a confusing one after); `50-limine.sh` uses the discovered path instead of a constant;
`check-limine.sh` uses it as its no-args default, falling back to the old flat guess if the finder
is missing so a manual run still says something.

**First verified only against synthetic layouts, on the wrong box — and it showed.** The first
pass tested against a manually-installed desktop machine with a permissive ESP mount
(`fmask=0022,dmask=0022`) plus synthetic fake-ESP directories, and generalized "no root needed" to
this repo's actual target. Running it for real on `bunne-test` — an `archinstall`-produced box,
not the manually-installed one — failed immediately: `archinstall`'s own fstab entry for `/boot`
mounts vfat `fmask=0077,dmask=0077`, so a non-root user cannot list `/boot`'s contents at all, and
the finder's `-r` tests were silently returning false for "can't see in here" the same as they
would for "genuinely not there" — the exact false-failure this file's own "fail loudly" rule warns
against, reintroduced by trusting one sample. Fixed the same session: the finder checks the ESP
directory itself first and exits 2 (distinct from exit 1's real not-found) when it needs root;
`00-preflight.sh` reports that as "cannot check" rather than a failure, matching the existing
sudoers.d-leak check it sits next to; `50-limine.sh` now runs the finder under `sudo`, not a new
privilege since everything else in that step already escalates. **Now actually verified on
`bunne-test`**: `00-preflight.sh` reports the expected "cannot check" line, `50-limine.sh` finds
and uses the real path, `check-limine.sh`'s no-args default works under `sudo`, and a full
`./install.sh` run lands clean — 0 failed units, `disk-usage-alert.timer` genuinely scheduled, all
75 packages resolve, and the unowned-`/etc` sweep's ten paths are all already accounted for.

**Gotcha, read before repeating this install**: Limine only reads FAT\*/ISO9660 — no
ext4 driver, by design (see its own FAQ: "remove the responsibility of parsing
filesystems... aside from the bare minimum necessities"). A separate ext4 `/boot`
partition panics with "failed to open kernel" even with a perfectly correct path/UUID —
reformatting to strip `64bit`/`metadata_csum` does **not** fix it, because the
filesystem type itself is unsupported, not a feature flag. Fix: mount the ESP itself at
`/boot` (FAT32) so kernel/initramfs/config all live on a partition Limine can read; use
`boot():/path` in `limine.conf` instead of `uuid(<ext4-uuid>):/path`. Reused the
existing NVRAM "Limine" boot entry (already pointing at `\EFI\LIMINE\LIMINE_X64.EFI`
from a prior Omarchy install on this disk) rather than creating a duplicate. Windows
chainload: `protocol: efi_chainload`, `image_path:
boot():/EFI/Microsoft/Boot/bootmgfw.efi`.


### windows-coexist — separate archinstall JSON, `parted` pre-delete, `limine-entry-tool` for the boot entry

**CORRECTED 2026-08-28: share Windows' EFI system partition, do not make a second one.**
The rehearsal built a new 1 GiB ESP beside Windows', which the Arch wiki explicitly warns
against — *"An additional EFI system partition should not be created, as it may prevent
Windows from booting"*, and *"there can only be one ESP per drive"*. The instruction is
*"Simply mount the existing partition."*

**The symptom that exposed it was `51-windows-chainload.sh` finding nothing.** It looks for
`bootmgfw.efi` on `/boot`; with a separate ESP, `/boot` is ours and Windows' loader is on
its own partition, so Windows silently never reached the boot menu — a `02-functionality.md`
C1 requirement. Sharing the ESP fixes that for free rather than by teaching the step to
hunt across partitions, which is the fix I had started writing when the author pointed at
the wiki.

**The condition that comes with sharing, and it is not optional:** Windows Fast Startup and
hibernation must be off (`powercfg /H off`). A hibernated Windows assumes nothing else
touches the filesystem and can corrupt a shared ESP. The wiki's own framing is that
disabling it is *"the safest option ... You may share the same EFI system partition"*, while
keeping hibernation requires the Linux ESP on a **separate drive** — impossible on a
one-disk laptop. Now a row in `README.md`'s manual-steps table.

**Size is the thing to check first.** Windows Setup normally creates a 100 MiB ESP, which is
tight for several kernels plus `limine-snapper-sync`'s snapshot entries. `bunne-test`'s is
2 GiB, so it is comfortable there, but a stranger's may not be.

**The test laptop is currently built the wrong way** — a second ESP at `p5`, `/boot` on it,
Windows bootable only from the firmware menu. It works and Windows is intact (sha256 of all
four regions verified), so this is a correctness-of-documentation fix rather than an
emergency; redoing that box is the author's call.

**picked** · 2026-08-27 · packages: —

**Measured:** VM rehearsal under real UEFI firmware (not the BIOS-mode false
start below), 2026-08-27 — SHA256 of all four Windows regions (ESP/MSR/data/
recovery) identical before and after; `mount` shows all 5 subvolumes + new ESP
correctly mounted; ESP contains `/EFI/arch-limine/BOOTX64.EFI`,
`BOOTIA32.EFI`, `limine.conf`; `efibootmgr -v` shows the new Limine NVRAM
entry first in `BootOrder`; booting the installed disk directly (no ISO)
reaches a real `archlinux login:` prompt (screenshotted via QEMU monitor,
15s).

**Two machines, one installer, `CLAUDE.md`**: a Framework 13 (Arch-only, no
Windows) and a desktop that must keep Windows and the Limine boot menu's
3-second delay. `archinstall-2026.08.01-wholedisk.json` (`base-install-method`) covers
the first; this row is the second. Built and VM-rehearsed by a background
agent, explicitly scoped VM-only — `bunne-test`'s real disk was never
touched — reviewed and landed by the author's Claude session afterward.

**A real `archinstall` bug, found the hard way and proven around twice.**
The first design mixed `delete` entries (old OS's partitions) with `create`
entries (new ones) in one JSON. That crashes archinstall's own post-commit
cleanup: it calls `wipefs --all` on a `delete` entry's device path, which no
longer exists once the delete has already succeeded. **The partition table
change itself lands correctly despite the crash** — verified by checksum,
twice — but the crash means archinstall never reaches its own post-install
steps, so don't rely on that. **Working fix, proven twice end-to-end**: delete
the old OS's partitions with `parted`, by hand, in the live ISO shell,
*before* invoking `archinstall` — then the JSON contains only `create`
entries, and the run completes cleanly. `archinstall-2026.08.01-coexist.json`
ships in that shape: `wipe: false`, two `create` entries (new ESP, new btrfs
root), otherwise byte-identical to the base JSON (same bootloader config,
encryption, subvolume layout, packages — diffed directly, not assumed).

**A first UEFI attempt was a false start, and the methodology bug is worth
naming.** Booting archinstall via direct kernel/initrd (rather than through
the ISO's own boot entry) never engages EFI firmware at all, OVMF or not — it
silently produced a BIOS-mode Limine install (`limine-bios.sys`, no
`limine.conf`, no EFI files) that would never have booted on real UEFI
hardware. Caught by the mismatch itself, not assumed away: redone booting the
ISO through real OVMF/UEFI firmware (serial console wired in by hand-editing
the ISO's own Limine entry, screenshotted before booting to confirm the edit
landed), and that run produced the real, verified results above.

**The checked-in JSON's partition offsets are the rehearsal VM's, not the
real desktop's** — they were sized against a simulated Windows layout, not
measured from the real machine. Recompute `start`/`size` from the real disk's
actual free space (`parted print free`, after the manual pre-delete) before
ever running this against real hardware; using the shipped numbers as-is
risks overlapping a partition Windows still owns. Stated in `README.md`
directly next to the file, since JSON has no comment syntax to carry the
warning itself.

**Windows doesn't appear in the boot menu on its own — `archinstall` doesn't
detect other OSes, and neither does anything `install.d/`'s base steps did
before this row.** `install.d/51-windows-chainload.sh`, new: detects Windows
by checking for `/boot/EFI/Microsoft/Boot/bootmgfw.efi` (silent no-op if
absent — the Framework's own case, expected absence per `CLAUDE.md`'s "quiet,
once, state the reason" rule) and, if present, adds it via `limine-entry-tool
--add-efi "Windows" ... --overwrite --quiet`. **Not a hand-edit of
`limine.conf`.** `limine-entry-tool` is already on the machine — the
`kernel-boot-entries` row's `limine-mkinitcpio-hook` package `Provides` it,
same binary, zero new packages — and it's upstream's own supported mechanism
for exactly this: Omarchy's own dual-boot docs point at the same tool
(`limine-scan`, an alias for `limine-entry-tool --scan`), just used
non-interactively here. Same publisher as `limine-snapper-sync`
(`snapshot-boot-entries`), so no new trust surface, and entries it writes go
through the same tree-aware parser that tool reads, rather than being a
fragile hand-appended text block a later sync could mangle.

**Unproven, and named rather than assumed**: whether an entry
`limine-entry-tool` writes survives `limine-snapper-sync` regenerating the
menu on the next snapshot. Read upstream's own README before trusting it
(not just skimmed — the raw file, `curl`'d directly): both tools are the same
author, and `limine-snapper-sync` documents inserting snapshot entries at a
scoped `//Snapshots`/`/Snapshots` marker rather than regenerating the whole
file — `50-limine.sh`'s own header already records the same thing
independently ("rewritten by limine-entry-tool and limine-snapper-sync... but
the header directives survive that"). That's real evidence, not proof on this
machine. By this repo's own rule ("treat any safety mechanism that has never
been exercised as broken until demonstrated"), the canary test is still
owed: add the Windows entry, force a real snapshot, confirm it's still there
after. Not yet run — needs the coexist install to exist somewhere first.

**Not yet done**: the real desktop has not been installed this way — this is
a proven mechanism, not a completed migration. `desktop-migration`'s own row
still describes the pre-archinstall plan and needs revisiting against this
one before the real machine is touched.


**AND ENCRYPTION GOES WITH IT — this is the real cost of dropping `disk_config`, and it is
not optional to understand.** With no disk section, LUKS **cannot** be set from the files
at all: `lib/args.py:269-287` reads both `disk_encryption` and `encryption_password` only
inside `if disk_config:`, and `DiskEncryption.parse_arg` resolves partition `obj_id`s, so
encryption inherently names a partition that no longer exists in the file. Not a parser
quirk — a property of what encryption *is*.

So `archinstall-2026.08.01-creds.json` no longer carries `encryption_password`; it was
being silently ignored, which is exactly the defect class caught twice already today
(`swap.algorithm`, the plymouth theme). Removing it also takes a plaintext passphrase back
out of the repo. **The passphrase is now typed once in the menu**, which is better anyway:
it is the single credential the machine ever asks for (`disk-unlock`), and a default one
published in a public repo was always going to need changing immediately.

**`README.md` step 5 says this cannot be skipped**, because skipping it is silent: the
install succeeds and produces an unencrypted root with no warning at any point.

**`disk_config` is GONE from the coexist file entirely, author's word 2026-08-28** —
*"for coexist, we will always have the user choose the partition he wants. it's more work
on the end user to audit a repo that messes with his partitions, so the lower-code option
for us is also the easier implementation for them."* The file now has no `disk_config`, no
`disk_encryption` and no `/dev/CHANGEME`, which buys a property worth more than the
convenience it cost: **this config cannot touch a disk, and a stranger can confirm that in
one `grep`.** Everything it still carries — packages, services, network, Bluetooth,
bootloader, hostname, locale — is portable to any machine unchanged.

The offsets it used to ship were never usable anyway: A `plan-disk.sh` was written to compute them from `parted print free`
and was then **deleted, unbuilt**: *"i dont want it. too scary."* The objection is right
and generalises — a hundred-line script near a partition table on a machine that also
holds Windows is a trust ask no README sentence can discharge, and *"it only reads"* is
precisely the claim a stranger cannot verify without reading all hundred lines. This repo's
premise is that you check rather than trust.

So `README.md` gives the archinstall menu path instead: manual partitioning, a 1 GiB
`fat32` at `/boot`, a `btrfs` partition filling the rest, the seven subvolumes entered
under *Set subvolumes*, and LUKS selected on the btrfs one. **archinstall does the
arithmetic and the alignment itself**, which is the real reason the script was never
needed — it was reimplementing something upstream already does correctly, which is the
parsimony rule's exact failure mode.

**The safety rule survives in a form that needs no code: only ever touch free space.**
There is no list of partitions to protect, because anything not selected cannot be
affected. What the README keeps from the script's rationale is the warning, since that
part is not obvious: **archinstall does not check that the region you asked for is free,
and does not fail when it is not.** It silently creates a 1 MiB stub which installs
happily and dies much later as `cryptsetup: Requested offset is beyond real size of
device`, naming neither the partition nor the cause. That produced partitions 7 through 10
on `bunne-test` and cost two install runs on 2026-08-28.

### gpu-driver — nvidia-open (prebuilt)

**picked** · 2026-08-25 · packages: mesa

**Measured:** modules built for both kernels; `nvidia-smi` OK; idle 9W @ P8. Re-verified
2026-08-24 on the fresh 2026-08-23 install: dkms 610.57.04 on both kernels, nouveau gone
after one reboot, niri session intact, idle 9.25 W @ P8 (single sample, 45 s post-boot)

GTX 1660 Ti Mobile is **Turing**, so the open module applies — proprietary `nvidia` is
only for pre-Turing, and is *not* an open-source-philosophy choice: both ship the same
proprietary `nvidia-utils` userspace and the open module defers to proprietary GSP
firmware on the card. DKMS variant because `linux-zen` is primary; prebuilt
`nvidia-open` targets plain `linux` only, which would leave the fallback kernel as the
sole one with a GPU. **Wrote no config at all**, deliberately: `nvidia_drm.modeset`
reads `Y` from `/sys/module/nvidia_drm/parameters/modeset` with nothing in `modprobe.d`,
so it is the compiled-in upstream default and `03-alternatives.md`'s "non-negotiable
`nvidia_drm.modeset=1`" is stale advice from when it had to be set by hand. No
`MODULES=` edit and no custom pacman hook either — upstream's `60-depmod` →
`70-dkms-install` → `90-mkinitcpio-install` chain already rebuilds the module and
regenerates the initramfs in the right order on a kernel bump. **Scope confirmed
2026-08-19, permanent, not "for now"**: user does GPU-accelerated model training (4090
on the primary machine) and will only ever own CPU-only/integrated-graphics or NVIDIA
hardware — never a competing dGPU vendor. This repo intentionally never needs AMD/Intel
dGPU driver support; don't add it speculatively for the "anyone can install this"
audience. See `python-env-manager` row for the CUDA-in-Python requirement this implies.
**Package list corrected 2026-08-20, and the correction is the lesson**: this row listed
`vulkan-intel` and `intel-media-driver` as picked since 2026-08-18, but
`/var/log/pacman.log` shows **neither was ever installed** — the row recorded an
intention as a fact, and nothing caught it for two days because nothing exercised the
video path. Both were then installed and *measured* during the `browser` trial, which is
what a package list should have to survive. **`intel-media-driver` stays,
Intel-conditional** like `microcode` and `firmware-set`: `iHD_drv_video.so` is genuinely
loaded by Brave's GPU process (1.8 MB PSS), and the fixed-function decoder really runs —
**204 ms of `drm-engine-video` time** on a video, read from `/proc/<pid>/fdinfo`.
**`vulkan-intel` removed**: nothing on the machine maps `libvulkan_intel.so` — niri
renders through OpenGL ES, Chromium's Vulkan backend is off by default on Linux, and no
other candidate asks for it, so it was 42 MB and 17 packages of update surface buying a
capability with no consumer. Zero RAM, so this is a priority-1 maintenance-surface
argument, not a priority-2 one; it is one line to add back if a Vulkan consumer ever
appears, and NVIDIA's ICD ships inside `nvidia-utils` regardless.
**`libva-nvidia-driver` removed**: `nvidia_drv_video.so` is mapped by no process, and
cannot be — on this hybrid laptop the browser's VA display is on i915. It stays a live
question for the **NVIDIA-only desktop**, where it would be the only VA-API path; decide
it there with `nvidia-smi --query-gpu=utilization.decoder`, not by inheriting this row.
**`libva-utils` removed too**, deliberately, though it is only 3.2 MB and a single
binary: `vainfo` answers the weaker question ("which profiles exist") while
`/proc/<pid>/fdinfo` answers the real one ("did the decoder run") for zero packages.
Reinstall it when debugging. **2026-08-24: the row's own lesson recurred** — the fresh
2026-08-23 install shipped without any of these packages (firmware-less nouveau loaded
on the dGPU), while this row still read `picked`; a Packages column is a claim about the
machine, and reinstalls reset the machine. Closed same day: author reconfirmed the
decision with widened scope — **nvidia (open module) on both Arch and NixOS whenever an
NVIDIA GPU is present** (true of bunne-test and the RTX 4090 target), integrated-only
still supported in the final product, and **FOSS-on-principle is explicitly not a
criterion** ("i care about a fast, light, private, and functional computer"). Installed
`linux-headers linux-zen-headers nvidia-open-dkms nvidia-prime`, verified post-reboot.
nouveau's idle power was never measured before the swap, so no before/after power claim
exists. Runtime D3 gating of the idle dGPU (PCI `power/control` is `on`, driver default
DPM) deliberately left alone: laptop power management is dropped scope.

**Switched 2026-08-25 from `nvidia-open-dkms` to the prebuilt `nvidia-open`** (author's
2026-08-25 queue, `docs/open-questions.md`). The dkms choice existed only because
`linux-zen` was the primary kernel and no prebuilt module is shipped for it; zen was
removed 2026-08-24 (`kernel` row), so the reason went with it. Prebuilt drops the
`linux-headers` dependency and the module rebuild on every kernel bump — less
update-time work and one fewer step that can fail on a `-Syu`, which is priority 1
rather than a speed argument. dkms comes back only if a non-stock kernel does. **Also
2026-08-25, per the Packages-column convention:** the Intel-iGPU conditional left the
Packages cell — on machines whose iGPU is Intel the installer additionally installs
`intel-media-driver` (VA-API), keyed on detected hardware, exactly as `microcode` is.

**Applied on `bunne-test` 2026-08-25, and the machine came back** (`benchmarks/4.24`).
Same driver version on both sides — 610.57.04 — so this was a packaging swap, not a
driver change; `nvidia-open` conflicts with `nvidia-open-dkms` in practice, so pacman
does it as a replace. Post-swap `dkms`, `linux-headers` and `pahole` were orphaned
exactly as predicted and removed, leaving zero orphans. After a cold boot:
`NVRM version: … 610.57.04 Release Build (root@)` — the prebuilt build stamp, against
dkms's own. The transaction also rebuilt the initramfs through the ordinary
`90-mkinitcpio-install` chain with no intervention.

**Two claims from the first write-up are withdrawn (DA round, same day), both
control-void.** Idle power: 8.71 W here against 9.25 W on 08-24 was called "within
noise" without the noise ever being measured — two single samples, different sessions,
different boots, different post-boot ages, no interleaving, and a 5.8 % gap that happens
to flatter the change. Boot time: there is no before/after at all — `systemd-analyze`
prints the userspace figure and the `graphical.target` figure *in one output*, and the
"before" number quoted was that same pair. The metric could not have tested the
hypothesis anyway: both packaging routes produce the same `.ko`, loaded in the initramfs
phase. **Nothing here measures a runtime difference, and none was expected.**

**The trade is also one-sided as first stated.** "One fewer thing that can fail after a
kernel update" *moves* a failure mode rather than removing one: the prebuilt module is
path-pinned to a single kernel version (`/usr/lib/modules/<ver>/extramodules/`), so a
partial upgrade, an LTS kernel, or `linux` landing ahead of its matching `nvidia-open`
leaves **no module at all**, where dkms would have rebuilt. That interacts with
`snapshot-boot-entries` directly, since booting an older snapshot means booting an older
kernel. The switch still looks right for a machine that ships exactly one kernel — which
is this one, since `kernel` dropped zen — but the row should say that rather than claim a
verified win. The dkms rebuild time being traded away was never measured either.

**Corrected 2026-09-01: the Intel-conditional convention from 2026-08-25 was documented but never
actually applied to `nvidia-open`/`nvidia-prime` themselves.** The Packages cell above, and both
`archinstall-*.json` files, still carried `nvidia-open nvidia-prime` unconditionally, so a machine
with no NVIDIA GPU at all got them pacstrapped regardless — found on an AMD Strix 880M/890M laptop
(`lspci` shows no `0x10de` device anywhere on the bus, `amdgpu` the only driver in use).
`scripts/hardware-packages.sh` already does the right PCI-vendor detection and was never the
problem; it was simply never called from any `install.d` step, so the unconditional JSON entry was
the only path that ever installed these packages. Packages cell now reads `mesa` only and both
JSONs have `nvidia-open`/`nvidia-prime` removed. **`hardware-packages.sh` is still unwired** —
until some step calls it, a fresh install on an actual NVIDIA machine gets no GPU driver at all.
Flagged, not fixed here: wiring it in is a step-shaped decision (where, and whether it folds into
`20-packages.sh` or gets its own numbered step), not a one-line correction.


### gpu-topology — hybrid (Optimus), panel on iGPU

**picked** · 2026-08-18 · packages: —

**Measured:** `card0`=NVIDIA `01:00.0` → DP-1, HDMI-A-1; `card1`=Intel `00:02.0` → eDP-1

The internal panel is wired to Intel, so `i915` drives the compositor and NVIDIA is
offload (`prime-run`). **But the external DP and HDMI ports hang off the NVIDIA card**,
so attaching a monitor makes this a genuine multi-GPU Wayland session — the hard case,
and a hard constraint on the Phase 3 compositor bake-off. Test every compositor
candidate with an external display attached, not just on the laptop panel.


### aur-helper — yay-bin

**picked** · 2026-08-18 · packages: yay-bin base-devel git

**Measured:** —

`yay-bin` not `yay`: same program, but `yay` compiles from source and pulls the whole Go
toolchain in as a build dep. `base-devel` is a **meta-package** now, not a group —
`pacman -Qg base-devel` returns nothing even when it is installed; query it with `pacman
-Qi`.


### makepkg-options — `!debug` in `/etc/makepkg.conf` `OPTIONS=`

**picked** · 2026-08-18 · packages: —

**Measured:** ~8 MiB per AUR package avoided — **stale justification, see note**

Every AUR build otherwise produces a `<pkg>-debug` twin containing debug symbols, and
`makepkg -si` installs it automatically — `yay-bin` alone brought in `yay-bin-debug`.
Phase 3 builds many AUR packages, so this accumulates. No stability risk: `!debug` only
suppresses generating the symbols package, it does not change build flags or the shipped
binary; the cost is unsymbolized backtraces if an AUR package crashes, recoverable by
rebuilding that one package. **Installer must set this**; the test box was left with its
existing debug cruft deliberately, since it gets wiped and reprovisioned by the script
anyway. **Justification corrected 2026-08-21**: the `~8 MiB` was a disk argument, and
disk is not a criterion (`CLAUDE.md`). The decision stands on a different and better
footing — `makepkg -si` *installs* the debug twin, so without `!debug` every AUR build
silently adds a package nobody chose, which pollutes `pacman -Qe` and therefore the
harvest that generates the installer's package list. Cheaper to not create it. Nothing
here is a speed or RAM claim, and the row should not be read as one.


### ssh — `openssh` installed, `sshd.service` **disabled by default**

**picked** · 2026-08-18 · packages: openssh

**Measured:** one listener removed from default install

Outgoing `ssh`/`scp`/`git+ssh` need only the client binary — **no daemon**. `sshd` is
the server and matters only for *incoming* connections. Arch ships both in one `openssh`
package, so install it always and keep the *service* opt-in (`systemctl enable --now
sshd`). Enabling by default would leave a machine accepting password logins on port 22
from first boot, which is wrong for a repo other people install and is not something a
rice is expected to do. The `nftables` default ruleset already permits `tcp dport 22`,
so enabling the service is genuinely the only step needed when it is wanted. **The test
laptop deviates**: `sshd` is enabled there so this project can run diagnostics against
it — a box-specific choice, not the installer's default.


### documentation — man-db (reader). `man-pages` separately, probably skip

**picked** · 2026-08-19 · packages: man-db less

**Measured:** man-db **2.5 MiB**, man-pages 5.6 MiB, 0 RAM, `man-db.timer` **disabled by
default**

**Reversed from `rejected` on 2026-08-19 — the original row was wrong on both of its
numbers, and its evidence was an accident** (man-db had been installed only to debug
something unrelated, and the author had no view either way). Corrections, measured: (1)
the "~100 MB" is **not man-db's cost**. There are already 25,030 man page files / **120
MB** on the machine, shipped by pacman, git, systemd and everything else, whether or not
a reader exists — that cost is spent and currently buys nothing. The *reader* is 2.5
MiB. (2) `man-db.timer` is `disabled` with preset `disabled`, so the warning about a
daily reindex job does not apply on Arch and there is nothing to mask. **Why it belongs
in the build**: `CLAUDE.md` requires verifying on the machine and reading primary
sources instead of recalling, and man pages *are* that primary source — its absence
measurably slowed work, forcing `.rst` files under `/usr/share/doc` to be grepped for
kitty's defaults because `man kitty.conf` did not exist. 2.5 MB to support a rule the
repo already commits to. **`man-pages` is a separate decision**: it is the Linux
syscall/POSIX reference, valuable for C and kernel interfaces, largely dead weight on a
data-science box. Skip initially. **Note `less` is a dependency of man-db** — that is
exactly why the desktop had `less` and the test laptop did not; install `less`
explicitly anyway rather than relying on that (see `terminal-navigation`).


### rollback-method — manual btrfs subvolume swap

**picked** · 2026-08-18 · packages: —

**Measured:** proven on hardware: canary gone, root moved subvolid 256 → 287

**`snapper rollback` does not work on this layout** — it relies on `btrfs subvolume
set-default`, but both `/etc/fstab` (`subvol=/@`) and the Limine cmdline
(`rootflags=subvol=@`) pin the root subvolume by name, so `set-default` is silently
ignored and you reboot into the unchanged `@` while believing you rolled back. Chose the
manual swap over dropping the pinning: no package needed (the `snapper-rollback` AUR
tool does exactly these four commands), and the config keeps stating which subvolume
boots instead of hiding it in filesystem metadata. Procedure: `mount -o subvolid=5
/dev/mapper/cryptroot /mnt/btrfs-top` → verify the target has modules for the running
kernel (`ls @snapshots/<N>/snapshot/usr/lib/modules/`) → `mv @ @.broken` → `btrfs
subvolume snapshot @snapshots/<N>/snapshot @` → `umount` → reboot. Renaming `@` while
mounted is safe (the running mount holds it by subvolid). **Target must postdate the
running kernel**: `/boot` is FAT and never snapshotted, so rolling into a snapshot
without matching `/usr/lib/modules` black-screens the machine. `/home` is a separate
subvolume and is *not* rolled back. Recovery if it fails to boot: Arch ISO → mount
subvolid=5 → `mv @ @.failed; mv @.broken @` → reboot. **Nested subvolumes**: systemd
creates `var/lib/portables` and `var/lib/machines` as subvolumes inside `@`. Two
consequences — (1) `btrfs subvolume delete @.broken` fails until those are deleted first
(innermost first, or `-R`), and (2) **btrfs snapshots are not recursive**, so a rollback
restores them as *empty directories*. Harmless for these two, but the rule is general:
anything living in a nested subvolume is silently not covered by snapshots.


### snapshot-boot-entries — limine-snapper-sync, from the omarchy binary repo

**picked** · 2026-08-25 · packages: limine-snapper-sync

**Measured:** watcher 456 kB PSS / 4 MiB cgroup if `inotify-tools` is installed, **0
resident** without it (upstream's snapper-plugin fallback); ESP cost is one kernel +
initramfs per *distinct kernel build*, content-hash deduplicated across snapshots —
~40 MB per build for BunnE's non-UKI pair (25 MB initramfs + ~15 MB vmlinuz), against
a 2.0 GiB shared-with-Windows ESP measured 29% used. All from the author's Omarchy
desktop, 2026-08-25. **Acceptance test PASSED on `bunne-test` 2026-08-25 evening**
(`benchmarks/4.25.rollback-acceptance.md`): restoring snapshot 97 moved `@` from
subvolume ID 256 to 353 with `Parent UUID` equal to snapshot 97's UUID, the canary
written after the snapshot was gone, and `alpine:3.21` plus both capped Docker
subvolumes survived. **DA round 19 scoped this back from "closes the rollback-isolation
leg of gripes #1/#2"**: `@containerd`/`@dockervol` are top-level subvolumes mounted from
fstab, so a snapshot of `@` structurally cannot contain them — the test confirms the
wiring, it does not discover isolation. And the restored snapshot was taken *minutes
earlier* from the same `@`, so the realistic case is untested: **a snapshot from before
the ~18:00 Docker promotion has an `/etc/fstab` with no `@containerd`/`@dockervol` lines,
and restoring it would silently put Docker back inside `@`, uncapped** — gripes #1 and #2
restored by the recovery mechanism. **Checked 2026-08-26: two of 24 snapshots (1 and 75)
are in that state, but neither is in the Limine menu** (which carries 78–100, all safe), so
the boot-menu path cannot reach them; and a *fresh* install never has the problem, since
the subvolumes exist from install time. **The general shape persists regardless:** any
fstab or subvolume-layout change splits snapshot history into restorable and
restores-into-a-different-machine, and the menu shows a date and a description — nothing
that distinguishes the two. **Two further legs remain unproven**: the way back (snapshot 98 `pre-rollback` exists in the menu but was
never booted) and the GUI restore gesture, which failed silently and has never been seen
to work. Four defects in the recovery path are recorded there, all priority 1.

Wanted: bootable snapper snapshots listed in the Limine menu. **`limine-snapper-sync`
1.31.0 will not build on Arch as of 2026-08-18**: `gradle nativeCompile` dies with
`Cannot find module 'gradle-public-api-legacy' in distribution directory
'/usr/share/java/gradle'` — Arch's `gradle` 9.7.0 package is incomplete for Gradle 9.x.
Not upstream's bug, and upstream ships no `gradlew` wrapper to route around it. **The
whole Zesko family is affected** (`limine-entry-tool`, `limine-mkinitcpio-hook`,
`limine-snapper-cli` all use GraalVM + system gradle), so `limine-snapper-cli` is not an
escape hatch. Build also costs a 323 MB GraalVM download plus ~554 MB of JDK/gradle —
bad for the Ventoy installer even when it works. Non-Java alternative exists:
`limine-tool` (Rust, `makedepends=cargo`), but v1.0.0 / 0 votes / unproven, and it
rewrites bootloader config — rejected for now on priority 1. **Decision: ship without
it.** `snapper rollback` covers the common case (bad package, system still boots); an
Arch ISO covers the won't-boot case. Revisit in Phase 4. **Update 2026-08-20 — the block
is on *building* it, and a binary route exists.** Traced from a friend's niri/Arch
dotfiles (`github.com/viacoffee/dotfiles`) whose install completed ~June 2026 with
`limine-snapper-sync` working: he never builds it. His `pacman.conf` adds a third-party
binary repo, `[omarchy] Server = https://pkgs.omarchy.org/stable/$arch`, and installs it
with plain `pacman -S`. Verified on the author's Omarchy desktop, which has that repo:
`limine-snapper-sync` **1.31.0-1**, 8.93 MiB download / 26.11 MiB installed, `Depends
On: bash limine snapper btrfs-progs libnotify` — **no Java or GraalVM at runtime**,
since it ships as a native-image binary; the 877 MB toolchain was build-time only. Also
confirmed the original diagnosis still stands: Arch's `gradle` is **still 9.7.0-1**,
unchanged since the 2026-08-18 failure, so the source build would fail today exactly as
before. The friend's working machine predates the regression and is not evidence against
it. **This is now an open decision for the author, not a block — and the tradeoff is
trust, not capability.** Taking the route means adding a third-party repo pinned at
`SigLevel = Optional TrustAll`, i.e. **signature verification disabled**, granting
whoever controls `pkgs.omarchy.org` the ability to install arbitrary root-level packages
on every machine that runs this installer. That is a materially different proposition
for a repo strangers clone than for one person's laptop, and it is pointedly ironic for
a project whose premise is replacing Omarchy. Middle path worth considering: fetch the
package once with `pacman -Sw` on a machine that has the repo and install the resulting
`.pkg.tar.zst` with `pacman -U`, which takes the binary without granting a standing
unsigned repo.

**Decided 2026-08-25 — take the binary, pin the publisher's key.** The author: *"I'm
fine with trusting omarchy's site to get their compiled binary. I don't want a
half-baked snapshot system: computer recovery should be among the most reliable and
unsurprising features of my pc, not some 'pretty good, does most things a snapshot
system does' solution."* Priority 1 outranks the trust discomfort recorded above — and
the posture below narrows that trust instead of swallowing `TrustAll` whole. Everything
that follows was verified on the author's Omarchy desktop on 2026-08-25.

**The repo signs its packages, so `Optional TrustAll` was never the only option.** Every
cached `limine-snapper-sync-*.pkg.tar.zst.sig` there is signed by one key — ed25519
`40DFB630FF42BCFFB047046CF0134EE680CAC571`, `Omarchy <pkgs@omarchy.org>` (read with `gpg
--list-packets`; the key sits in that machine's pacman keyring at `full` trust) — and
`pacman -Qi` reports the installed package `Validated By: SHA-256 Sum Signature`. The
repo *database* is unsigned (no `omarchy.db.sig` in `/var/lib/pacman/sync/`). So BunnE
adds, **last in `/etc/pacman.conf`, after `core`/`extra`/`multilib`**:

```
[omarchy]
SigLevel = Required DatabaseOptional
Server = https://pkgs.omarchy.org/stable/$arch
```

importing the key exactly the way upstream's own `omarchy-update-keyring` does:
`pacman-key --recv-keys 40DFB630FF42BCFFB047046CF0134EE680CAC571 --keyserver
keys.openpgp.org`, then `pacman-key --lsign-key` on the same fingerprint. Two
consequences, both wanted: a package must be signed **by that key** to install, so a
compromised host, a hijacked DNS answer, or a MITM cannot serve an unsigned or
differently-signed package the way `TrustAll` would have accepted; and because
`[omarchy]` is listed last, the official repos shadow it for every package Arch also
carries, leaving it able to supply only what Arch does not have. What is being trusted
is *Omarchy's publisher key, for packages Arch lacks* — not *whatever `pkgs.omarchy.org`
serves*. The `pacman -Sw` + `pacman -U` middle path floated above is dropped on the same
sentence that unblocked this row: a one-shot binary silently goes stale against `limine`
and `snapper` bumps and has no upgrade path, which is the half-baked recovery system the
author just refused.

**Zero resident cost, via upstream's own fallback branch — not a hack.** The package
ships `limine-snapper-sync.service`, which runs `/usr/bin/limine-snapper-watcher` (a
bash script, read on the box). It clears a stale `pacman db.lck` — the one a pre/post
snapshot inevitably contains, because snap-pac takes it *mid-transaction* — and then, if
`inotifywait` is not on `PATH`, prints "Falling back to Snapper plugin integration" and
`exit 0`s. The fallback is snapper's own plugin hook,
`/usr/lib/snapper/plugins/10-limine-snapper-sync` (`/usr/lib/snapper/plugins/` is
snapper's directory, not the package's), which handles `create-snapshot-post`,
`delete-snapshot-post` and `modify-snapshot-post` and explicitly skips itself when the
watcher is running — the two paths are mutually exclusive by design. **So BunnE enables
the service and does not install `inotify-tools`** (an optdep, not a dependency): the
unit becomes a boot-time one-shot that cleans the lock and exits, entry sync rides
snapper's plugin call, and nothing stays resident. Installing `inotify-tools` later buys
live inotify sync for 456 kB PSS — a supported, reversible knob, not a fork.

**What it buys — including a hazard `rollback-method` documented and could not fix.**
`/boot` is FAT and outside the snapshots, so a manual rollback into a snapshot whose
kernel differs from the one in `/boot` black-screens the machine; that row's answer was
"target must postdate the running kernel", i.e. a rule the human has to remember at the
worst possible moment. limine-snapper-sync copies **each snapshot's own kernel and
initramfs** into the ESP beside its menu entry, so the pairing is structural rather than
remembered. It also adds a "backup" entry after a restore (the restore itself is
undoable), repairs a corrupted bootable file from a matching healthy one, and exposes
`limine-snapper-list` / `limine-snapper-info` — a state command that can be run, which
is what the "fail loudly" rule asks for.

**Config (`/etc/limine-snapper-sync.conf`) — deviations only, defaults left alone.**
`RESTORE_METHOD=replace` is upstream's recommendation for a root-subvolume Arch layout
and is *the same operation* `rollback-method` already performs by hand (new subvolume
from the snapshot, replacing `@`), so it keeps working with `subvol=@` pinned by name in
both `/etc/fstab` and the Limine cmdline. `SET_SNAPSHOT_AS_DEFAULT=no` (the default) for
the same reason: BunnE names the subvolume, so `btrfs subvolume set-default` is
irrelevant here — the very fact that broke `snapper rollback`. `LIMIT_USAGE_PERCENT=85`
and `MAX_SNAPSHOT_ENTRIES=auto` (both defaults) make ESP usage self-limiting: oldest
snapshot entries are dropped rather than the partition filling. Two levers left unset
and named here so nobody re-derives them: `EXCLUDE_SNAPSHOT_TYPES="post"` (boot the
*pre* snapshot to undo a bad update; the post one is the broken state) and
`EXCLUDE_SNAPSHOT_ENTRIES="*fallback"` each roughly halve ESP usage if the shared
Windows ESP ever gets tight.

**`limine.conf` has to be restructured, and it is supported.** Today's hand-written file
(bottom of this document) lists `/Arch Linux (zen)` and `/Arch Linux (fallback)` as
sibling top-level entries; the tool needs one OS block with `//Kernel` children plus a
`//Snapshots` line inside it, which is upstream README "Example 1" — written for exactly
BunnE's non-UKI `protocol: linux` + `kernel_path` + `module_path` shape. Not a UKI
requirement, not a Secure Boot requirement. The desktop's own entry is a UKI and its
snapshot entry shares one 277 MB file by content hash, which is where the "per kernel
build, not per snapshot" number above comes from.

**Docker stays out of the snapshots — but the rollback path needs one amendment.** This
row does not change *what* a snapshot contains: `snapshot-system` and `snapshot-bloat`
govern that, and Docker's bytes are already outside every snapshot of `@` (proven,
`benchmarks/4.5.docker-quota.md`). The amendment is about what a *restore* does, and it
is recorded in `docker-storage-quota` — in short, the two Docker subvolumes are nested
inside `@`, so any rollback (this tool's or the manual swap) produces an `@` with empty
directories at those paths and re-enables the exact bloat gripes #1/#2 exist to kill.
Fix is one line of layout, stated in that row; it wants the author's ratification.

**Not yet exercised, and that is the gate.** Every number above was read off the Omarchy
desktop, which is a different machine with a different layout. Nothing is installed on
`bunne-test`. Per this repo's own rule — a safety mechanism that has never been
exercised is broken until demonstrated — the acceptance test before this row can be
called proven is: install from the pinned repo, restructure `limine.conf`, take a
snapshot, drop a canary file, restore the snapshot from the Limine menu, and confirm on
reboot that the canary is gone, that `/var/lib/containerd` still holds its images, and
that the "backup" entry can put the machine back.

**Installed on `bunne-test` 2026-08-25; the acceptance test is still the gate**
(`benchmarks/4.24`). What is now proven on this machine rather than read off the
desktop:

- **The trust posture works as written.** `[omarchy]` appended last with `SigLevel =
  Required DatabaseOptional`; key `40DFB630FF42BCFFB047046CF0134EE680CAC571` received
  from `keys.openpgp.org` and `--lsign-key`ed; `pacman-key --list-sigs` shows it at
  `[ full ]` carrying this machine's own local signature. `limine-snapper-sync
  1.31.0-1` and `limine-mkinitcpio-hook 1.37.1-1` both installed signature-validated.
  Nothing needed `TrustAll`.
- **The zero-resident claim replicates here, not just on the desktop.** With
  `inotify-tools` absent the unit logs *"inotifywait is not installed. Falling back to
  Snapper plugin integration."* and exits: `MainPID=0`, `MemoryCurrent=[not set]`.
  Enabled as a boot-time one-shot, as the row specifies.
- **The menu tree is real.** `limine-list` renders `Arch Linux → {linux, Snapshots →
  77 │ 2026-08-25 17:28:39}`, and the snapshot entry carries its **own** kernel and
  initramfs out of `limine_history/` with `rootflags=subvol=/@snapshots/77/snapshot` —
  the structural kernel/rootfs pairing this row was picked for, visible in the file.
- **The sync path itself is now demonstrated, not assumed.** Later that evening a burst
  of package transactions took the menu from **1 snapshot entry to 18** with no
  intervention — so the plugin route (`/usr/lib/snapper/plugins/10-limine-snapper-sync`,
  chosen over the inotify watcher precisely so nothing stays resident) really does fire
  on snapshot creation. Previously only the install-time entry had ever been observed.
- **And the ESP arithmetic holds on this machine, rather than on the desktop it was read
  from.** Those **18 snapshot entries cost 4 files / 41 MB** in `limine_history/`, with
  `/boot` at **14 % of 1022 MB**. That is the "one kernel + initramfs per *distinct
  build*, content-hash deduplicated across snapshots" claim behaving exactly as written:
  every one of those snapshots shares a kernel, so they share the files. A worst case
  still exists — snapshots spanning several kernel builds each pin their own pair — but
  the ordinary case is now measured, not inherited.
- **Knock-on worth knowing: `NUMBER_MIN_AGE=1800` means a burst does not clean up
  promptly.** `snapper cleanup number` left 20 subvolumes standing against a
  `NUMBER_LIMIT` of `2-15`, because none had reached 30 minutes. Correct behaviour, and
  the reason a machine can briefly carry far more snapshot entries than the limit
  suggests — which matters only for menu length, since the ESP cost is deduplicated.

**And the restructure took the box off the network, which is the finding.** Making
`/Arch Linux` a clean directory (the shape this row asks for) is only half the change:
`default_entry` defaults to `1`, entry 1 is then the **folder**, and — read from
`common/menu.c` at limine's `v12.5.2` tag, not inferred — a directory as the selected
entry *forces the timeout off*, so the menu waits indefinitely rather than eventually
booting anything. `Enter` on a folder only expands it. **Recovery is three keys, not
one:** `Enter`, `↓`, `Enter`.

**The repair is one line, and it is not the obvious one.** `find_entry_by_path()` — the
non-numeric form of `default_entry` — expands every directory along the path and matches
only entries with no children, so **`default_entry: Arch Linux/linux` cannot select a
folder and cannot be renumbered** by `limine-entry-tool` reordering entries (which this
session watched it do). The numeric form works too, but only *together with* `/+Arch
Linux`: `print_tree()` counts a directory's children only when it is expanded, so
`default_entry: 2` without the `+` is out of range. A two-part repair where forgetting
half produces a different failure is the same trap again; the path form has no second
half.

**Resolved and reboot-verified the same evening.** The box was returned to the network by
a human at the menu, and the journal then settled the diagnosis better than any reasoning
had: `journalctl --list-boots` shows a **56-minute hole with no kernel start** (17:31:49 →
18:27:30). The journal clock starts when the kernel does, so a LUKS prompt would have
opened that boot record at the prompt, not an hour later — the machine was **pre-kernel**
the whole time, which is the bootloader, and which also rules out a panic loop. Repair
applied as `default_entry: 2` + `/+Arch Linux` — deliberately the index-plus-expanded
spelling the author's desktop already demonstrates on this limine version, rather than the
path form this row prefers on paper, because a machine whose recovery had just been done
by hand is the wrong place to debut an untested spelling. `limine-update` re-run
afterwards preserved both lines. Result: **shutdown 18:29:38 → next kernel start 18:29:54,
16 seconds, unattended, zero failed units** — against 56 minutes for the same machine two
config lines earlier. **The path form is still what the installer should default to, once
someone has watched it boot once.**

**A competing hypothesis this row carried, now excluded for this incident but not for the
design, because the known-good reference names it and nobody looked.** `limine-entry-tool` ships `ENABLE_VERIFICATION=yes` and writes a
`#<blake2>` onto every path; **`hash_mismatch_panic` defaults to panic**. `bunne-test`
does not set it; the author's desktop config *does* set `hash_mismatch_panic: no`. So a
stale hash produces a bootloader panic, not a menu — a different symptom needing a
different fix. Whether BunnE should follow the desktop and disable the panic, or keep the
stricter default and accept that a mid-transaction interruption can require a live-system
repair, is an open question rather than a detail. Full account in `benchmarks/4.24`.

**Second-order lesson for the installer, worth more than the mistake.** The mitigation
that was in place — NixOS on a separate ESP, so a bad Arch bootloader config falls
through to the other OS — does not cover a bootloader that is *waiting* rather than
failing. `panic=30` reboots a kernel that panics; nothing reboots a menu. Any
unattended boot-path change needs a fallback that triggers on a **hang**, not only on
an error.

**Open, and worth deciding with the acceptance run:** `timeout: 1` leaves a
one-second window to reach the snapshot menu. That is the right number for every
ordinary boot and the wrong one for the single moment this feature exists to serve;
the desktop ships `timeout: 60`. Limine also offers `remember_last_entry`. Currently
unset, i.e. chosen by nobody.



**Two boot-menu directives set 2026-08-25 (open questions 22 and 24).** Both live as
plain Limine directives at the top of `/boot/limine.conf`; `limine-entry-tool` and
`limine-snapper-sync` add and remove *entries* and leave the global header alone, which
is why `timeout` and `default_entry` survived an accidental sync earlier the same day.
Neither is expressible in `/etc/default/limine` or `/etc/limine-entry-tool.conf`.

- **`timeout: 3`** (was `1`). The author's call: one second is the right number for every
  ordinary boot and the wrong one for the single moment the menu exists to serve, and
  priority 1 outranks the 2a cost of two extra seconds. From limine's `CONFIG.md`:
  decimals such as `0.25` are legal, `timeout: no` disables automatic boot, and `0` boots
  the default instantly — so there is genuinely no window at `0`.
- **`hash_mismatch_panic: no`**, matching the author's desktop. An interrupted pacman
  transaction between writing the ESP files and writing the config leaves exactly the
  mismatch the strict default panics on, and an unbootable machine from a routine
  interruption is the priority-1 failure; snapshots already cover tampering.
  **`CONFIG.md` line 119 says this option is forced to `yes` when Secure Boot is active**,
  so the decision is conditional on Secure Boot staying off — `bootctl status` reports it
  **disabled** on `bunne-test`, checked rather than assumed. Enabling Secure Boot later
  silently reverts this.

`scripts/check-limine.sh` passes on the edited file (`default_entry 2` resolves, 40
`boot()` files present) and the previous config is at
`/boot/limine.conf.pre-2026-08-25-decisions.bak`.

**What is actually verified: the file parses and the box boots** — three Arch boots
through the edited config, header read back from the live file. **DA round 19 cut the
stronger "reboot-verified" claim**, because neither directive was shown to *do* anything:

- **`timeout: 3` is now timed and confirmed** (`benchmarks/4.28`): shutdown → next kernel
  start is **16 s median at `timeout: 1` and 18 s at `timeout: 3`**, n=3 per arm,
  non-overlapping, Δ **2 s** — exactly the config difference. The recovery window really is
  three seconds and the 2 s is paid on every boot, which is the priority-2a charge the
  author accepted. **Do not try to see this with `systemd-analyze`**: its `loader` figure
  moved 3.355 s → 3.359 s across the same change, i.e. it does not include the menu wait.
- **`hash_mismatch_panic: no` is wholly unexercised.** It acts only when there *is* a hash
  mismatch, and there has never been one on this machine. By this repo's own rule — a
  safety mechanism never exercised is broken until demonstrated — **this setting is
  unproven.** It is testable: corrupt one byte of a `boot():` file on the ESP and observe
  warn-instead-of-panic. That test has not been run.

**SETTLED 2026-08-26 — `default_entry` is the path form, and it is reboot-proven.** The
discrepancy noted here (numeric `2` against a rule saying path form) went to the author,
who chose the path form. `/boot/limine.conf` now carries `default_entry: Arch Linux/linux`
and `install.d/50-limine.sh` **sets** it rather than warning about it.

The argument, from limine's own `CONFIG.md` read on the machine — *"Can be a 1-based entry
index (e.g. `1`), or an entry path (e.g. `OSes/Arch Linux`)"* — plus the source reading
already in this row: the menu is regenerated by `limine-entry-tool` on every kernel change
and by `limine-snapper-sync` on every snapshot, so an index survives only while nothing
reorders it, whereas `find_entry_by_path()` matches only where `sub == NULL` and therefore
**cannot resolve to a directory even in principle**. That is the 4.24 failure mode removed
structurally rather than avoided by luck.

Proven in this order, deliberately, because this is the boot path:

1. **`CONFIG.md` on the box** for the escaping rules (`/`, `\`, `#` must be escaped in
   entry names; neither `Arch Linux` nor `linux` contains any, and both are unique among
   their siblings — the only level-1 and level-2 entries in the file).
2. **`check-limine.sh --self-test` first**, to establish the validator is sound before
   trusting its verdict. It passes, and it already carried `default_entry: Arch Linux/linux`
   in its own fixtures as the *correct repair*.
3. **The validator on the live file:** *"default_entry path \"Arch Linux/linux\" ends at a
   bootable entry"*.
4. **A reboot through Limine.** Back up on `subvol=/@` — the evidence that it selected the
   live kernel and not a snapshot — kernel `7.1.9-arch1-2`, 0 failed units, niri and zram
   up, 17.4 s to userspace.
5. **Then the write path**, since an unexercised install path is unproven: reverted to
   `default_entry: 2`, re-ran `install.sh`, and it rewrote the header to the path form with
   `check-limine.sh` passing.

**Scoped honestly:** the two menu regenerations observed afterwards added snapshots *inside
the collapsed `Snapshots` directory*, which does **not** change the visible index. So
nothing here demonstrates the numeric form actually breaking. What is demonstrated is that
the path form boots, resolves to the live kernel, and survives the menu being rewritten
twice. The fragility removed is a *class* of failure — a second kernel package, or that
directory being expanded — not one that has occurred on this machine.

### dotfile-deployment — symlink, via hand-rolled `ln -sfn` in `install.sh`

**picked** · 2026-08-19 · packages: —

**Measured:** —

Symlink over the predecessor's copy: edits made to `~/.config` while actually using the
machine **flow back to the repo**, which is what keeps the repo honest — copying lets
the running machine and the repo diverge silently, and this project's premise is that
the repo reproduces the machine. **Do not read the predecessor's copy-in-place as a
considered preference**: the author adopted it only because he was not yet comfortable
with symlinks when that repo was built (confirmed 2026-08-19). **No manager.** `stow`,
`chezmoi` and `yadm` are all in `extra` and none are installed; community practice
splits by repo *type* — pure dotfile repos favour a bare git repo or Stow, while
distro-provisioning repos (Omarchy, LARBS, ML4W) almost all copy — and this repo is
both. `stow` would be a dependency for what `ln -sfn` already does inside an installer
being written anyway, exactly the abstraction `CLAUDE.md` rejects. **Correction to the
rationale first recorded here**: the risk is *not* "a package update clobbers the link"
— verified on the machine that the only `/home` path owned by any package is `/home/`
itself, from `filesystem`, so **pacman never writes inside `$HOME`**. That concern
belongs to `/etc`. The real mechanism is **applications rewriting their own config**
with write-temp-then-rename, which replaces a symlink with a regular file — anything
with a GUI settings dialog does this. Two consequences: **symlink whole directories
rather than individual files** wherever the app allows, since a directory symlink
survives an app rewriting a file inside it (this is the shape that makes Stow robust,
worth stealing without the dependency); and the deploy step must be **re-runnable and
must detect a link that has been replaced**, rather than assuming its links persist. The
repo is cloned to a **fixed permanent location the installer owns**, not wherever the
user happened to clone it — otherwise a friend deleting the clone, or a `git pull`,
silently changes their desktop. Location, chosen 2026-08-19:
**`${XDG_DATA_HOME:-$HOME/.local/share}/arch-bunny`**. Written that way, not hardcoded
to `~/.local/share` — respecting the XDG variable with a spec-default fallback is what a
reader will expect, and hardcoding it is the kind of detail that reads as careless. The
author is content committing from there.

**Renamed 2026-08-30, author's word, twice in the same day.** First pass moved the
canonical name from `bunne-arch` to `arch-bunne`, matching the GitHub repo name at the
time. Same day, the author picked `arch-bunny` instead and asked for every instance of
either older spelling replaced, this file's own historical narrative included — so unlike
most rows here, the mentions of `bunne-arch`/`arch-bunne` earlier in this document are not
preserved as a record of what was literally typed at the time; they now read `arch-bunny`
too. `70-dotfiles.sh`'s `canonical=`, every config that hardcodes the path for runtime
shell expansion (`scripts/bunny-wallpaper.sh`, `config/mako/config`, the niri colorpick
bind), and the local clone's directory name were all updated to match.
**The GitHub remote was deliberately left as `github.com/charlesfry/arch-bunne`** — the
author asked for the directory rename but explicitly not the GitHub repo, so that name and
the canonical local path now differ on purpose.

**RELITIGATE THIS — flagged by the author
2026-08-20.** The row above rejects Stow, but the author has never actually used it and
did not know what it does when the decision was made, so "rejected" here records a
preference he was not yet equipped to hold. A friend's Arch/niri config
(`docs/reference-viacoffee.md`) uses Stow successfully, which is the prompt. **What a
fair re-examination has to cover**, since the original rejection was argued on cost
rather than mechanics: what `stow` actually does (symlink farm from a package directory,
folding and unfolding directories automatically), what `--adopt`, `--restow` and
`.stow-local-ignore` buy, and whether its directory-folding behaviour is *better* than
hand-rolled `ln -sfn` at the specific failure this repo already identified — an
application rewriting its own config with write-temp-then-rename, which replaces a
symlink with a regular file. The original row concedes that directory-level symlinking
"is the shape that makes Stow robust, worth stealing without the dependency", which is
an argument for understanding Stow properly before deciding it is not needed. Do not
re-decide this from the existing text; the author wants to learn the tool first. **The
fair examination, done 2026-08-24 (evening), on the author's phone prompt "if stow is
mostly unused we can go back to the symlink strat".** First the facts: stow is installed
on no machine here (desktop, test box both checked), nothing in either repo or the
predecessor invokes it, and the current pick already *is* symlinks — there is nothing to
"go back" to, only this flag to close. What stow actually is: a symlink-farm manager
(`extra`, 645 KiB, depends only on perl) — you keep per-app package dirs under one stow
dir and it links them into `$HOME`, **folding** directories (links the whole dir when it
can, automatically **unfolding** into per-file links when a second package needs the
same directory). `--restow` re-links and prunes stale links (= a re-runnable deploy
step); `--adopt` moves pre-existing target files into the repo before linking (a
migration tool — and a footgun on re-runs, since it silently overwrites repo content
with whatever is on disk); `.stow-local-ignore` excludes files. Against this repo's one
identified failure — an app rewriting its config via write-temp-then-rename, which
converts a *file* symlink into a divergent regular file — stow's folding gives
directory-level links *when packages don't overlap*, which is exactly what the row
already planned to do by hand ("symlink whole directories"). The difference: stow
decides fold-vs-unfold implicitly at run time; hand-rolled `ln -sfn` states it
explicitly in lines the author can read, which is what "understand every line" is for.
**What most people do**, by repo type: pure-dotfile repos → bare git repo, stow, or
chezmoi; distro-provisioning installers (Omarchy, LARBS, ML4W) → scripted copy or
scripted symlinks. This repo is an installer, so scripted `ln -sfn` *is* the mainstream
shape for its category — stow would replace ~a dozen explicit, auditable lines with a
dependency whose folding behavior has to be learned to be predicted. **Recommendation:
keep the symlink pick; close the relitigation flag on the author's word.** Stow is a
good tool being asked to do too little here; nothing in its feature set (--adopt aside,
which we don't want) beats explicit directory links written in the installer we are
writing anyway. Awaiting the author's one-word confirm.


### install-artifact — stock pinned Arch ISO + this repo; no custom artifact

**picked** · 2026-08-26 · packages: —

**Measured:** VM rehearsal, `benchmarks/` (2026-08-26) — see below.

**Said out loud 2026-08-26, closing the `CLAUDE.md` "Deferred decisions" flag.** Author:
*"let's have them boot a stock arch iso and run archinstall with a JSON config we give them."*
Candidate B, the one `base-install-method` already made the default. `archinstall-2026.08.01-wholedisk.json`
is now checked in at the repo root, written against `archinstall`'s **actual** schema for the
version shipped on `archlinux-2026.08.01-x86_64.iso` (sha256 `4e82dced1c4fd3e498b22a853f8db2a4d262d32b97e7e07d97390d9e425ffe5e`) —
extracted from that ISO's own airootfs and read (`lib/models/device.py`, `lib/args.py`,
`scripts/guided.py`), not guessed from the GitHub examples, which turned out to disagree with each
other across two different schema generations. Manual partitioning, LUKS2, the five subvolumes
(`@ @home @snapshots @log @pkg`), `noatime,compress=zstd:1`, bootloader `Limine`, `packages:
["git"]` so the repo can be cloned before `install.sh` needs anything else.

**Rehearsed the same night in a local qemu VM**, not merely written: `archinstall --config
archinstall-2026.08.01-wholedisk.json --creds <local, gitignored> --silent` against a throwaway 20 GiB
virtio disk, booted via direct kernel boot (`-kernel`/`-initrd`, `console=ttyS0`) with OVMF. Disk
wipe, LUKS2 format, subvolume creation and `pacstrap` all completed exactly as configured. One real
bug found and fixed by the rehearsal, not by reading: `services: ["sshd"]` fails —
`Unit sshd.service does not exist` — because `openssh` isn't part of archinstall's own base
install; the box-specific override for a remote-managed rehearsal (documented in `README.md`, never
committed) needs `"openssh"` in `packages` too. General shared config intentionally omits `services`
and `hostname`/`users`/`timezone`/`locale_config`/disk target specifics — `installer-prompts` wants
those asked interactively, not baked into a file every friend runs unmodified; the config is meant
to be run without `--silent` precisely so the guided menu still asks them, pre-filled with our
values, before the confirmation screen.

**Largely dissolved by `base-install-method`, same day.** Once the base install is
`archinstall` from a *pinned stock Arch ISO* named in `README.md`, there is nothing left
to build a custom artifact out of — the "single file" is the official ISO the author
already keeps on his Ventoy stick, and BunnE is a repo you clone and a script you run.
That collapses this to candidate B below by default: stock ISO on the stick, repo beside
it (or cloned after first boot, since `archinstall` leaves a networked machine).
Candidate C, a custom `archiso` build, is now clearly not worth its permanent
maintenance cost for a project whose install is two commands. **Consequence for
`CLAUDE.md`**: its headline goal, "a single file droppable onto a Ventoy USB that
installs the full setup onto a new PC", no longer describes the plan and needs rewording
— flagged, not silently changed. Candidate analysis retained below since it is what
produced this answer. **Was: the last foundational decision still open** (`04-plan.md`
Phase 5, `CLAUDE.md`). What single thing goes on the Ventoy USB. Candidates laid out
2026-08-19, **not ranked — the author decides.** Ventoy 1.1.17 is installed here, so its
behaviour was read from the shipped package rather than recalled. **A. Stock Arch ISO +
script fetched over the network** (piping `curl` into `bash` at the live prompt). Zero
build, zero maintenance, always-current ISO and keyring. Costs: needs network *before
you can start*, so a wifi-only machine means hand-running `iwctl` first — a real
priority-1 hit; the USB is not self-contained; and piping `curl` into `bash` is the
pattern this repo's audience distrusts. Requires publishing at a stable URL. **B. Stock
Arch ISO + the repo as a second file on the same USB.** Ventoy's data partition is
ordinary exFAT, so arbitrary files sit beside the ISOs. Zero build, zero maintenance,
always-current ISO, *and* self-contained — no network needed to begin, no
`curl`-into-`bash`. Cost is one step to find and mount the stick, which is **smaller
than it looks**: verified in `/opt/ventoy/tool/*.sh` that the data partition is labelled
`Ventoy` by default (`VTNEW_LABEL='Ventoy'`; the EFI partition is `VTOYEFI`), so the
script can self-locate via `/dev/disk/by-label/Ventoy` instead of asking. **C. Custom
ISO built with `archiso`** (`extra/archiso` 89-1). The real product answer: one file,
fully self-contained, can autostart the installer and brand the boot menu. Costs: it
must be built and *re*built forever, ~1 GB, and a stale custom ISO is a classic failure
— an out-of-date `archlinux-keyring` makes `pacstrap` fail with signature errors that
read as mysterious. That maintenance burden argues against it under parsimony and
priority 1. **D. Ventoy plugins.** `auto_install` is confirmed present in the shipped
`/opt/ventoy/plugin/ventoy/ventoy.json`, but it feeds an answer file to an ISO's *own*
installer and Arch's ISO has none, so it is a poor fit. Ventoy also has an injection
plugin that would extract a tarball into the live environment at boot — that would give
B's self-containment with no mount step at all — but **it could not be confirmed from
the installed files** (no `injection` string under `/opt/ventoy`; the logic would live
inside the compressed boot payload). Verify against Ventoy's docs before relying on it.
**Note that every option needs network eventually**, because `pacstrap` fetches
packages; the only question is whether network is needed *before the installer can
start*. Decide once the installer is proven to work — packaging something that does not
yet work is wasted effort.


### install-profile — lite / full split

**rejected** · 2026-08-27 · packages: —

**Decided against, author's word 2026-08-27: ship one profile only.** This machine is primarily
the author's own workstation, friends secondary (`CLAUDE.md`) — every friend gets the same full
data-science box, no `--full` flag, no critical-vs-extra tagging. Raised 2026-08-19 while Phase 4
was still hypothetical; now that `install.sh` is eleven real steps, the split would be pure added
surface with no user asking for the lighter one. Revisit only if a friend actually wants it.


### docker-storage-quota — top-level btrfs subvolumes + qgroup **accounting only**, no limits; the `disk-alert` row is the protection

**picked** · 2026-08-26 · packages: —

**Measured:** **2026-08-26: the limits are gone.** Quota accounting alone does not deny a
write — `--accounting` arm 3/3 verity-enabled and `rw` against the tight-limit control's
1/1 forced-readonly, same box, same session (`benchmarks/4.27`) — and it accounts to the
byte (209731584 for a 200 MiB file; a real `docker pull` moved `@containerd` 292 KiB →
103.05 MiB). Earlier, while the caps existed: **2026-08-24: `cap_enforced=1` — a write was refused** ("disk quota
exceeded" through Docker's own error path) on `arch-bunny`, after two traps; see
`benchmarks/4.5.docker-quota.md`. 2026-08-21: `cap_enforced=0` — 39 containers, zero
write refusals; but that test could not have worked (see note)

Raised 2026-08-19: user has previously exhausted the entire disk via unbounded Docker
image/layer growth, crashing unrelated processes (browser) — wants a hard cap so Docker
fails loudly instead. Only relevant to the full install. Candidates to bake off: (1)
`overlay2.size=` in `/etc/docker/daemon.json` — needs to be checked against a
btrfs-backed overlay2, xfs is the commonly-documented backing fs; (2) size-capped btrfs
subvolume + qgroup for `/var/lib/docker`, consistent with the predecessor repo's
docker-on-its-own-subvolume approach and with this repo's existing btrfs/LUKS2
filesystem pick. Test both for whether the cap is actually enforced before picking.
**Doubles as the fix for `snapshot-bloat` below** — a nested btrfs subvolume is excluded
from parent-subvolume snapshots (proven mechanism, see `rollback-method` row's
nested-subvolume note re: `var/lib/portables`/`var/lib/machines`), so putting docker on
its own subvolume removes it from snapshots automatically, without a snapper filter.
Confirm this holds for `/var/lib/docker` specifically once trialed — don't assume,
verify with `btrfs subvolume list` after a snapshot. **Tested 2026-08-21, and the test
failed to test anything — see
[`benchmarks/3.11.docker-quota.md`](benchmarks/3.11.docker-quota.md).** Two things came
out of it. **(a) The harness could not reach the cap.** It filled with `docker run
--rm`, so each 256 MiB blob was destroyed with its container before the next was
written; peak usage was 256 MiB against a 2 GiB limit. `cap_enforced=0` is a null
result, not a refutation of qgroups. **(b) The cap was on the wrong directory.** Docker
on Arch is now 29.7.2 running `containerd-snapshotter=true` as the stock default — there
is no `/etc/docker/daemon.json` on the machine — and containerd logs its own root as
`containerdRootDir: /var/lib/containerd`. So `/var/lib/docker` holds the per-container
*merged* overlay mount (`var-lib-docker-rootfs-overlayfs-<id>.mount`) while the image
layers those mounts are built from sit under `/var/lib/containerd`, on `@`: uncapped,
and inside every snapshot of `@`. That also puts candidate (1) in doubt — under the
containerd snapshotter the `overlay2` driver is not in use at all, so `overlay2.size=`
has nothing to size. Next step is `~/t-docker-quota2.sh` on `bunne-test` (written,
`shellcheck`/`shfmt`-clean, **not yet run — needs root**): it *measures* which directory
grows before choosing what to cap, then fills with retained image layers of
incompressible random data so nothing is freed between iterations. **Do not settle this
row until a write is actually refused** — the byte location is confirmed from the
daemons' own logs, but that the bytes follow the configuration is still inferred, not
measured. **2026-08-24 (`benchmarks/4.5.docker-quota.md`): refusal achieved on
`arch-bunny`.** Measured: the bytes go to `/var/lib/containerd` (537 MB per retained 256
MiB image — blob stored twice: content store + unpacked snapshot; `/var/lib/docker`
never moved, though *volumes* would land there and were not exercised). Candidate (2)
works **only with a rescan**: a fresh subvolume marks qgroups inconsistent (`dmesg:
qgroup inherit needs a rescan`) and an inconsistent qgroup enforces nothing — the naive
setup shipped a silent no-op cap, 12 imports blew through a 2 GiB limit. After `btrfs
quota rescan -w`: import refused at the arithmetic point, loudly, fs 237 GiB free. New
trap: **at the cap, containerd wedges** (image *deletion* also needs to write its bolt
meta.db → also refused); recovery proven = bump limit, clean, re-limit. Candidate (1)
(`overlay2.size=`) is dead as predicted — the overlay2 driver is not in use. The row
stays with the author for: cap size, whether `/var/lib/docker` gets its own subvolume
too, headroom-vs-recovery-doc, and whether docker stays on the test box (left
socket-activated, 0 resident). **All settled by the author 2026-08-24** (full pros/cons
round in session; gripe #1 closed): (a) **images capped at 100 GiB** — holds a
multi-project DS working set (PyTorch-class images run 5-15 GiB) with slack for the
measured GC residue growth, fails a runaway pull at ~17% of the desktop partition; (b)
**`/var/lib/docker` gets its own subvolume, capped 50 GiB** — the author chose
completeness knowing the trade (a containerized DB hitting hard ENOSPC freezes until
recovery, tail-risk corruption; explained and accepted; the 50 GiB figure is Claude's
stated default at half the images cap, vetoable); (c) **80%-of-cap alert + recovery
doc** — port the predecessor's disk-usage-alert timer and teach it qgroups (Phase 4
implementation; periodic oneshot, zero resident RAM), recovery = the proven
bump-clean-relimit dance; (d) applied live on the test box,
`benchmarks/raw/4.11.apply-decisions.log`: both subvols created, **the mandatory `btrfs
quota rescan -w` run (the silent-no-op trap — this line must be in the installer)**,
canary write refused at the arithmetic point (300 MiB requested, 199.98 MiB landed at a
200 MiB test limit; dd's ENOSPC line clipped by `tail -2`, byte arithmetic is the
proof), production limits applied, docker restarted clean on the containerd-snapshotter.

**Amendment ratified 2026-08-25 (author's 2026-08-25 queue, `docs/open-questions.md`) — nest them at the top level, not inside
`@`.** Both subvolumes were created *inside* `@` (`@/var/lib/containerd`,
`@/var/lib/docker`), which is enough to keep their bytes out of every snapshot (proven,
4.5) but breaks the moment a rollback happens. `rollback-method` already states the
general rule — btrfs snapshots are not recursive, so a nested subvolume comes back as an
**empty directory** — and now that Docker lives in one, that rule has teeth: after any
restore (the manual swap, or `limine-snapper-sync`'s `replace`), the new `@` has plain
empty directories at both paths. Docker sees no images and no volumes, the old data is
stranded inside the retired `@` still consuming its gigabytes, and — the part that
actually matters — Docker starts writing into an **ordinary directory on `@`**, with no
qgroup cap and inside every future snapshot. Gripes #1 and #2 silently re-open, on the
day the machine was recovered and nobody is looking. Fix is layout, not code: create
them as **top-level subvolumes mounted by `/etc/fstab`**, exactly like `@home` — e.g.
`@containerd` → `/var/lib/containerd` and `@dockervol` → `/var/lib/docker`,
`noatime,compress=zstd:1`, qgroup limits unchanged and unaffected (a qgroup follows the
subvolume, not its path). They then sit outside `@` entirely: still absent from every
snapshot, and untouched by any rollback. Costs two fstab lines and moving the existing
data once; buys a rollback that leaves Docker exactly as it was. Applied to the design today; the data move itself is a
hands-on task on `bunne-test`, not done yet.

**Done on the box 2026-08-25, reboot-verified** (`benchmarks/4.24`, instrument
`benchmarks/instruments/4.24-docker-subvol-promote.sh`). `@containerd` (ID 329) and
`@dockervol` (ID 330) are now `top level 5`, mounted from `/etc/fstab` with the same
`noatime,compress=zstd:1` as `@home`; caps re-applied at 100 GiB / 50 GiB and `btrfs
quota rescan -w` run, which also cleared the standing "qgroup data inconsistent"
warning. Both mounts came back from a cold boot with zero failed units and
`docker.socket` active. **The move copies no bytes**: a `btrfs subvolume snapshot`
taken at the top level *is* a subvolume, so promotion is one snapshot plus one delete
per subvolume — worth knowing for the installer, which creates them empty anyway, and
for anyone migrating a box that already has images.

**Canary-design trap, found while re-proving the cap.** The first check wrote 32 MiB
of `/dev/zero` against a temporarily-lowered 8 MiB cap and **passed** — the filesystem
is `compress=zstd:1`, so 32 MiB of zeros referenced 1.18 MiB and never approached the
limit. **A byte-cap canary on a compressed filesystem must use incompressible data or
it silently tests nothing.** Redone with `/dev/urandom`: `dd: error writing …: Disk
quota exceeded` at 7.98 MiB against the 8.00 MiB cap. The 4.5 instruments already used
`/dev/urandom`; this is recorded because the obvious reach is `/dev/zero`, and a canary
that always passes is worse than no canary. Any installer-side verification of these
caps inherits the rule.

**That first canary also settles a unit question this row never stated: a qgroup limit
counts compressed on-disk bytes.** So "100 GiB" and "50 GiB" are caps on *disk*, and the
volume of image content they permit is unbounded above that. That is the correct unit for
a disk-full gripe — but "a 50 GiB cap on Docker" naturally reads as a cap on images, and
it is not.

**Scope of what the promotion actually demonstrates (DA round, 2026-08-25).** The layout,
the fstab mounts and their survival across a cold boot are proven. The cap is re-proven
for **`@dockervol` only**, at a synthetically lowered 8 MiB, through `dd` — not through
docker. `@containerd`'s 100 GiB cap is a different qgroup on a different subvolume at a
different mount and has **no evidence on the new layout**. And the reason the move was
made — that a rollback of `@` now leaves these subvolumes intact — is **unexercised**,
which by this repo's own rule makes it broken until demonstrated:
`benchmarks/instruments/4.25-rollback-acceptance.sh` does the two halves around the
keyboard step. **Gripes #1 and #2 are not closed by the promotion; they are closed by that
test passing.** Also worth carrying forward: every qgroup figure taken before the rescan
was read while btrfs itself was reporting "qgroup data inconsistent" (1019 MiB claimed
against `du`'s 400K), so earlier numbers taken under that warning deserve a second look.

**Migration hazard the instrument now refuses.** `btrfs subvolume snapshot` does not
recurse into nested subvolumes, and docker's btrfs storage driver creates one per image
layer. `bunne-test` had zero images, which is exactly why the hazard could not surface
there — the migration was validated in the one state where its central failure mode
cannot occur. On a populated machine an unguarded promotion yields a `@dockervol` that
looks migrated and holds no layers. The instrument aborts when either source has nested
children.



**Exercised on `@containerd` for the first time 2026-08-25 — and the row now has a
priority-1 problem** (`benchmarks/4.27.containerd-cap.md`). Every earlier proof on this
row tested **`@dockervol`**, which 4.25 showed **holds no images**: this Docker uses the
containerd image store (`driver-type: io.containerd.snapshotter.v1`), so image bytes go
to `/var/lib/containerd`. The cap gripe #1 is actually about is the 100 GiB one, and it
had never been hit.

At a synthetic 200 MiB cap:

- **The first overflow is exactly what the row wants.** `docker pull` fails with
  `disk quota exceeded`, exits **1**, both daemons stay `active`, existing images stay
  listed, and usage pins to the byte at 200.00 MiB. (Check the exit status without a
  pipe — piping to `tail` reports `tail`'s status and looks like success.)
- **A subsequent overflow forced the entire filesystem read-only.** btrfs failed to roll
  back fs-verity items for want of quota'd metadata space, which is not a recoverable
  error, so it aborted: `BTRFS info (device dm-0 state E): forced readonly`.
  `mount -o remount,rw` was refused; **only a reboot cleared it.**

**The structural point, and it is not incidental:** a qgroup limit is scoped to a
*subvolume*, but forced-readonly is scoped to the whole *filesystem*. `@`, `@home`,
`@containerd` and the rest are one btrfs on `/dev/mapper/cryptroot`, so a cap meant to
contain Docker took `/` and `/home` with it — verified by `touch` failing under both.
That inverts the row's premise: the cap converts "Docker fills the disk" into "the
machine goes read-only at a threshold you chose", which is a worse `it just works`
failure, not a better one.

**Reproduced, deterministically, and the qgroup is the trigger.**
`benchmarks/instruments/4.27-verity-quota-repro.sh` reproduces it 4/4 inside a loopback
btrfs with the identical kernel signature (`rollback_verity:459`, errno -122), so 4.26's
reproduce-before-recording rule is satisfied and the blast radius stays on a loop device.
**DA round 19 rejected the comparison this was first written up with.** With 10 MiB of
quota headroom verity succeeds and the filesystem stays `rw`. With no quota and the
filesystem 100% full, verity **also succeeds** — meaning the Merkle write was never
refused in that arm, so it establishes nothing about how btrfs handles an ENOSPC-denied
verity write. The defensible statement is only that **a qgroup limit produces the denial
trivially while I could not construct one via ENOSPC**; that is a claim about
reachability, not about handling, and it does **not** settle the "just accept it" option.
Equally unestablished: whether ordinary Docker use against the shipped **100 GiB** cap
reaches this state at all — the real event used a 200 MiB synthetic cap and the loopback
used 64 KiB of headroom chosen to be smaller than the tree. The trigger is fs-verity specifically, which
containerd supplies; a rollback that cannot fail cleanly under the kernel's own quota
looks like an upstream btrfs bug, and the harness reproduces it from a clean image in
about a minute.

**This wants a decision (open question 26), not a tweak.** Four options are laid out in
4.27: accept it, give Docker its own *filesystem* rather than its own subvolume, cap
below the danger zone and let the C9 alert fire first, or drop the cap for monitoring
alone. **Nothing has been changed** — `@containerd` is back at 100 GiB and `@dockervol`
at 50 GiB, as before.

**ANSWERED 2026-08-26 — open question 26, author's call: option 4. The caps are dropped;
the qgroups stay for accounting.** `btrfs qgroup limit none` on both `0/329` (`@containerd`,
was 100 GiB) and `0/330` (`@dockervol`, was 50 GiB). The subvolumes, their top-level
placement and their fstab mounts are all unchanged, so nothing `snapshot-bloat` depends on
moves — keeping Docker out of every snapshot of `@` was always the subvolume's doing, not
the limit's.

**Why this is a priority-1 win and not a retreat.** Gripe #1's real shape is *slow* growth,
a disk filling across weeks of project work, and against that a 6×/day alert is a good
instrument. What the limit added on top was not protection against the gripe — it was a
*new* priority-1 failure mode the gripe never had. An unbounded disk gives ENOSPC to the
process filling it; a qgroup limit can give the whole filesystem forced-readonly until a
reboot. Trading the second away for the first is the right direction.

**The answer rests on a claim, so the claim was run** (`benchmarks/4.27`, arm
`--accounting`). If quota *accounting* could also deny the Merkle write, dropping the
limits would fix nothing. Paired on `bunne-test`, same kernel and session: quota on with
64 KiB of headroom → `errno=122`, `rollback_verity:459`, loop fs **ro** (1/1, on top of the
earlier 4/4); quota on with **no limit** → verity **ENABLED**, fs **rw** (3/3). The limit is
the trigger. Accounting is also exact — 209731584 bytes read back for a 200 MiB file — which
is what makes the alert's numbers possible at all.

**Live check on the real subvolume:** `docker pull python:3.12-slim` exits 0 and
`@containerd` moves 292 KiB → 103.05 MiB with `/` still `rw` and no failed units. The image
was **left in place on purpose**: every prior test of this layout ran against an empty
`@containerd`, the one state in which the migration's nested-per-layer-subvolume hazard
cannot surface.

**A qgroup read needs a `sync` first, and this is now a rule for the installer.** The first
accounting read reported **16 KiB** for a subvolume holding 200 MiB, because qgroup figures
count *committed* extents. Wrong by four orders of magnitude, silently. The 6×/day alert
does not care (btrfs commits every 30 s), but anything verifying bytes it just wrote does —
and installer-side verification of these subvolumes is exactly that.

**What now protects gripe #1 is the `disk-alert` row, alone**, and that row had to change
to survive this decision: its meter 2 selected qgroups *carrying a `max_referenced` cap*,
so the moment the limits went it would have matched nothing and monitored Docker silently
not at all — the exact failure `CLAUDE.md` names. The 100 GiB / 50 GiB figures now live in
that script as **thresholds** rather than walls, and a watched subvolume missing from the
qgroup output is itself a breach. See that row.

**Cost this leaves behind — measured the same day, `benchmarks/4.29`.** Keeping the qgroups
is not free: `btrfs subvolume delete` costs **0.355 s per snapshot with quotas against
0.008 s without** (46×, n=9 per arm, no overlap), `subvolume snapshot` +0.022 s, `rm -rf` of
6457 files +0.035 s, and **writing** those files shows no measurable effect at all. Recorded
in `BUDGET.md` as a new bucket — *per snapshot deletion* — since none of the existing ones
fits. Nothing waits on it at the keyboard, but btrfs commits are filesystem-wide, so a
cleanup retiring several snapshots stalls every other writer to `/` for ~1.8 s.

**And the framing above is wrong, which 4.29 found by chasing the cost.** The qgroups do
*not* buy one number in a notification. `man 5 snapper-configs`: `QGROUP` is "the btrfs quota
group used for **space aware cleanup algorithms**", and `/etc/snapper/configs/root` carries
`SPACE_LIMIT="0.08"` and `FREE_LIMIT="0.2"` — both space-aware, both running on it. Turning
quotas off would silently switch off snapper's space-based retention, which is part of gripe
#2's fix. **Open question 28** now asks only for ratification of a cost, not for a decision:
recommended **keep**.

### snapshot-bloat — —

**picked** · 2026-08-27 · packages: —

**Measured:** —

Raised 2026-08-19: on the current machine, snapshots have grown to hundreds of GB — user
wants snapshots kept minimal on this build, not an afterthought. Two parts: (1) **Docker
must never land in a snapshot** — solved by the `docker-storage-quota` subvolume
approach above, verify on hardware. (2) **Retention limits** — Phase 2 plan
(`04-plan.md`) already calls for setting snapper retention limits at snapshot setup time
rather than leaving Arch/snapper defaults (which keep a large number of
hourly/daily/monthly snapshots indefinitely and are a likely source of the current
bloat) — treat that as non-optional, not just "set them at some point." (3) User
confirmed 2026-08-19: conda envs/package cache, pip cache, and browser cache should also
be excluded from snapshots — each is large and regenerable/non-critical, not worth the
snapshot space. Mechanism is the same nested-subvolume trick as Docker: candidate paths
are `~/.cache` (covers pip cache and most browser cache in one shot — verify
per-browser, some cache elsewhere) and wherever conda envs land (`~/miniforge3/envs` or
similar, per predecessor repo's Miniforge setup — confirm exact path in Phase 3). One
subvolume per path, or one shared `~/.cache`-rooted subvolume if everything regenerable
nests under it — decide once Phase 3 shows the actual layout. Don't nest a subvolume
inside a directory that's also inside another candidate subvolume; verify with `btrfs
subvolume list` after creating each. **Update 2026-08-21, from
`benchmarks/3.11.docker-quota.md`:** part (1) is *worse* than assumed and cannot be
closed by the nested-subvolume trick yet. The bytes that matter are Docker's image
layers, and under Docker 29's default containerd snapshotter those live in
`/var/lib/containerd` — on `@`, so they are in every snapshot of `@`. A subvolume at
`/var/lib/docker` would exclude the merged mount and leave the images behind. Settle
`docker-storage-quota` first; this row inherits whichever directory that one ends up
capping. **2026-08-24: part (1)'s mechanism is now proven on the real layout**
(`benchmarks/4.5.docker-quota.md`): with `/var/lib/containerd` as a nested subvolume
holding gigabytes, a snapper snapshot of `@` shows that path as an **empty directory — 0
entries**. Docker bytes stay out of snapshots the moment the subvolume design lands.
**2026-08-24: part (1) fully closed** — both Docker paths are now nested subvolumes on
the test box (`raw/4.11.apply-decisions.log`): images (`/var/lib/containerd`) and volumes
(`/var/lib/docker`) are outside every snapshot of `@`. **The 100 GiB / 50 GiB qgroup caps
those paths also carried were dropped 2026-08-26** (`docker-storage-quota`, open question
26) — irrelevant to this row either way, because what keeps Docker out of a snapshot is
the subvolume boundary and never the limit. **Part (2) is closed too** —
`install.d/40-snapshots.sh` sets snapper's retention limits (`SPACE_LIMIT=0.08`,
`NUMBER_LIMIT=2-15`, etc.), reboot-verified.

**Part (3): approved 2026-08-27, then found already closed — verified on `bunne-test`, no
new subvolumes needed.** The nested-subvolume trick was the plan because the row was
written 2026-08-19, before `filesystem`'s `@ @home @snapshots @log @pkg` layout existed.
That layout already puts `~/.cache` (and everything else under `$HOME`) on `@home`, a
**separate top-level subvolume from `@`** — the identical mechanism that keeps Docker out
of every snapshot, just already in place for the whole home directory, not something to
build. Checked directly rather than assumed: `snapper list-configs` shows exactly one
config, `root`, with `SUBVOLUME="/"` — snapper only ever snapshots `@`. A live snapshot's
own `/home` is empty (no `bunne` directory inside it at all), and the actual snapshot sizes
confirm it — **196 KiB** for a post-snapshot after installing packages including `nodejs`,
which would be gigabytes if `~/.cache/uv`'s real 4.7 GB were anywhere inside it. `python-env-manager`
also updates the original text: it's `uv`, not conda, so there is no `~/miniforge3/envs`
path to find — `~/.cache/uv` is the one large regenerable directory that actually exists
on the box, and it's already excluded, for free. Nothing to build for part (3); it was
solved by the filesystem layout the day `@home` became its own subvolume, and nobody had
re-checked since. **All three parts closed.**


### python-env-manager — uv, with pixi as the conda-only escape hatch

**picked** · 2026-08-19 · packages: uv

**Measured:** **empty venv → verified CUDA in 52.0 s wall** on `arch-bunny` 2026-08-25
(2.3 GB cold download dominates; resolve 0.6 s, install 1.3 s)

**The CUDA confirmation this row asked for is done (2026-08-25, overnight): uv stands
alone.** `uv venv` + plain-index `uv pip install torch` → torch 2.13.0+cu130 does
verified GPU work on the 1660 Ti (matmul+conv2d `allclose` vs CPU, autograd backward,
nvidia-smi shows the process) with **zero env configuration** — stock PyPI wheels carry
the CUDA runtime; no conda needed for the CUDA case. Raw in nix-bunne
`benchmarks/raw/pytorch-cuda-arch-2026-08-25.log` (run as the bake-off's Arch leg). The
Jupyter-kernel acceptance test remains the standing falsifier. **Reconciled, not newly
decided**: this row was opened `deferred` without noticing that `03-alternatives.md`
already ranked `uv` #1 with full rationale, so the "open question" duplicated an
existing decision. The CUDA objection below is largely stale — conda was required back
when the CUDA toolkit had to be installed *as a conda package*, but PyTorch has shipped
the CUDA runtime inside its wheels for years, so `uv pip install torch --index-url
<current pytorch cuXXX index>` is a complete answer. That is a five-minute confirmation
(`torch.cuda.is_available()` in a scratch venv), not a Phase 3 bake-off. `pixi` stays
documented for a genuinely conda-only package. The **acceptance test is unchanged and
remains the falsifier**: whatever wins must register a Jupyter kernel that
molten/venv-selector can find. Original reasoning follows. Predecessor repo uses
Miniforge conda, needed for non-Python deps (CUDA/MKL/etc.) in a data-science workflow.
`uv` (Astral, Rust) raised 2026-08-19 as a faster alternative — real speed win for pure
Python (pip/venv/Python-version management) but not a full conda replacement if
non-Python native deps are actually depended on. **Confirmed 2026-08-19: CUDA support is
a hard requirement, not optional** — user routinely trains models on a 4090 and any
future machine is either CPU-only/integrated-graphics or NVIDIA, never a competing dGPU
vendor (this is also why the repo never needs AMD/Intel dGPU driver support — see
`gpu-driver` row's scope note). So whichever env manager is picked must have a proven
path to CUDA-enabled PyTorch/etc. (conda-forge channels and `nvidia-open`/`nvidia-utils`
already cover this; `uv` can also install CUDA wheels via `pip`-compatible index URLs —
verify in Phase 3 whether it needs conda alongside it for anything, or can stand alone
for the CUDA case too). Full install only — irrelevant to lite.


### oom-protection — systemd-oomd

**picked** · 2026-08-25 · packages: —

**Measured:** swap-kill canary **PASS** (`benchmarks/4.18`): killed exactly the hog
cgroup at >90% swap (13.7 GB RAM + 7.3 GB zram peak), the kernel OOM-killer never fired,
the 5 s probe loop never stretched, recovery was immediate. Resident cost **1.4 MB**
(cgroup `MemoryCurrent`) / 5.7 MB `VmRSS`.

Raised 2026-08-19, same incident as `docker-storage-quota`: disk+memory both exhausted
simultaneously, no graceful degradation. `systemd-oomd` ships with systemd already (no
new resident daemon to justify) and kills the worst cgroup under memory/swap pressure
before the kernel OOM-killer thrashes the whole system. Needs a canary-style test per
this repo's "prove it" rule — deliberately induce pressure and confirm oomd intervenes —
before being trusted, not just enabled and assumed working. Pair with zram/swap sizing
decision.

**Ratified 2026-08-25 (author's 2026-08-25 queue, `docs/open-questions.md`), mechanism
exercised.** Config: enable `systemd-oomd`, plus two drop-ins — `ManagedOOMSwap=kill` on
`-.slice`, and `ManagedOOMSwap=kill` with `ManagedOOMMemoryPressure=kill` on
`user@.service`. Ships with systemd, so no package and no new daemon class; the 1.4 MB
is systemd's own manager overhead, not a program we added. The canary this row demanded
has now been run and passed — that is what moved it off `deferred`. **Named
limitation:** the *pressure*-kill path is configured but unexercised, because the test
ramp allocated too fast to build sustained PSI; a slow-leak canary would exercise it.
Left enabled on `bunne-test` as a live soak since 2026-08-24.

**Filenames fixed 2026-08-26.** Both drop-ins were called `10-oomd-test.conf` — a name from
when this was an experiment, still in place after the row was ratified, and one that invites
a future reader to delete this row's entire mechanism as leftover debris. They are now
`10-oomd.conf`. **Verified, not assumed**: `systemctl show` reports the same effective
`ManagedOOMSwap=kill` / `ManagedOOMMemoryPressure=kill` before and after the reload, and
`oomctl` lists both `/` and `/user.slice/user-1000.slice/user@1000.service` as monitored —
which proves oomd loaded them rather than merely that the files parse. Found by
`scripts/check-unowned-etc.sh`, which also showed these two files were **absent from
`docs/phase4-config-inventory.md` entirely**, so the installer would not have created them
at all.


### dir-aware-display — direnv + prompt hook

**picked** · 2026-08-27 · packages: direnv

**Measured:** **prototype measured 2026-08-25 (4.20): hot path 9.3 µs/prompt (0.1% of
the shipped prompt), 33–37 µs on cd only, zero forks**

**Shipped, both halves, author's word 2026-08-27.** The display half is built and proven free —
`benchmarks/instruments/4.20-diraware.sh` (~25 shippable lines, bash builtins only:
changed-dir gate → prefix map → OSC-2 title + prompt color). Tab *color* specifically
would need kitty `allow_remote_control` + a kitten fork per cd — optional, author's
call, not decided here. direnv ships too, gated the same way (`prompt-hooks`'s rule: stock
`_direnv_hook` is 15 ms/prompt ungated, ~0.23 ms gated). Raised 2026-08-19: user wants `.envrc`-driven
per-project env vars (already their workflow — kept generic in every write-up since, per
`secrets-bootstrap`, no specific employer/client directory names ship in this repo) plus a
visual cue — terminal display changing based on directory — to tell at a glance which
context they're in. `direnv` itself (`extra/direnv`) is a single static binary hooked
via one `.bashrc` line, not Omarchy-specific, cheap per priority 2. Design: keep real
env vars in per-project `.envrc` as-is; add a *separate* small user-editable mapping
file (path-prefix → display profile: tab color, prompt color, etc.) read by a
`$PROMPT_COMMAND` hook that fires only on directory change, not every prompt. Must stay
easily adjustable — which paths trigger it and what changes are made — not hardcoded.

**What actually shipped, 2026-08-27:** `config/bash/dir-display.bash` (the OSC-2 title cue;
tab/prompt *color* stayed out, per the "optional, not decided" note above) and
`config/bash/direnv.bash` (the gated hook), both symlinked like every other file in
`config/` — no special-casing. `install.d/86-shell-dir-aware.sh` appends both source lines
to `~/.bashrc`, same shape as `85-shell-prompt.sh`.

**The mapping file (`$XDG_CONFIG_HOME/bunny/dirmap.conf`) is deliberately NOT in `config/`.**
It is exactly the file that would accumulate real employer/client paths through normal use —
the thing `secrets-bootstrap` now forbids reaching this repo. The install step scaffolds an
empty, comment-only template **once** and never touches it again; a user's real entries never
sync back, because the file was never tracked to begin with.

**A real bug found by testing the composition, not each file alone:** `direnv hook bash`'s
own `eval` doesn't just define `_direnv_hook`, it silently *prepends the ungated call itself*
into `PROMPT_COMMAND` — confirmed by running `direnv hook bash` directly and reading its
output. Sourcing it and then appending the gated wrapper on top left **both** installed, so
the expensive ungated hook still fired every prompt — the exact failure `prompt-hooks` exists
to prevent, reintroduced by the tool meant to be gated. Fixed by saving and restoring
`PROMPT_COMMAND` around the eval, so only the function definition survives. Verified: sourcing
all three files (`prompt.bash`, `dir-display.bash`, `direnv.bash`) together produces
`PROMPT_COMMAND=_bunne_prompt; _bunne_dirhook; _bunne_direnv` with `_direnv_hook` appearing
nowhere unwrapped, and a stubbed hook body ran exactly once across three same-directory
prompts rather than three times.


### compositor — Hyprland

**rejected** · 2026-08-20 · packages: hyprland kitty xdg-desktop-portal-hyprland

**Measured:** both monitors correct: `eDP-1` 1920x1080 (Intel panel) + `HDMI-A-1`
1920x1080 (NVIDIA port) live simultaneously. **Idle session +266.6 MB stock / +214.0 MB
with wallpaper and Xwayland disabled**, vs niri's +87.7 MB on the same boot — i.e.
**2.4x niri even like-for-like**, so the gap is not explained by Hyprland shipping more
desktop ([`benchmarks/3.2.compositor-idle.md`](benchmarks/3.2.compositor-idle.md))

**Launch with `start-hyprland`, never the bare `Hyprland` binary.** Running `Hyprland`
directly loads and runs fine — config parses, both outputs come up, `hyprctl binds`
shows keybinds registered correctly, libinput enumerates and reads the keyboard/touchpad
fine — but every keypress still lands on the raw VT as literal text instead of reaching
the compositor (`SUPER+Q` typed a literal "q"), and `hyprland.log` carries `WARNING:
Hyprland is being launched without start-hyprland. This is highly advised against.`
`start-hyprland` is the actual entrypoint package-provided at `/usr/bin/start-hyprland`;
running that instead fixed it immediately (confirmed: `Hyprland --watchdog-fd 4` running
as its child). **Measured against niri 2026-08-20 and it loses on the headline metric**
— see the Measured column. **Two structural findings from that run.** (1) *Hyprland
starts Xwayland eagerly*: 246 MB RSS resident with zero X11 clients, killable only via
`xwayland { enabled = false }`. This inverts the usual framing of built-in Xwayland as
an advantage over niri's separate `xwayland-satellite` — Hyprland's is always paid,
niri's is on-demand. (2) *Hyprland's session is not systemd-managed*: `start-hyprland`
execs the binary directly and registers no user unit, where `niri-session` runs
`systemctl --user --wait start niri.service` with `graphical-session.target` bound
properly. That matters for ordering idle/lock/portal/bar against the session later.
**Also note `hyprctl dispatch` now evaluates Lua** (0.56's config migration): `hyprctl
dispatch exit` fails with `hl.dispatch: expected a dispatcher`, and the working form is
`hyprctl -i 0 dispatch 'hl.dsp.exit()'`. Every `hyprctl dispatch` line inherited from
the predecessor repo is now wrong syntax and needs a sweep in Phase 4.


### compositor — niri

**picked** · 2026-08-20 · packages: niri

**Measured:** **passes the hard multi-GPU case**: `eDP-1` (Intel panel) at logical 0,0
and `HDMI-A-1` (NVIDIA port) at 1920,0 — different positions, so a genuine extended
desktop, not a mirror. **idle session +87.7 MB** over a no-compositor baseline (691.3 vs
603.6 MB used), niri RSS 205 MB plus a 43 MB copy-on-write `Command Spawner` child —
measured 2026-08-20, empty session, >120s idle,
[`benchmarks/3.2.compositor-idle.md`](benchmarks/3.2.compositor-idle.md)

Second candidate in the Phase 3 bake-off, installed 2026-08-20. **6.37 MiB, and zero new
dependencies** — its only unusual one, `xdg-desktop-portal-impl`, was already satisfied
by `xdg-desktop-portal-hyprland`. **Picked the right GPU unprompted**: primary render
node `renderD128` = `0000:00:02.0` = the Intel iGPU, with NVIDIA (`renderD129`)
secondary driving the HDMI output — the sane arrangement for a panel-on-Intel machine,
needing no `debug { render-drm-device }` override. **Launch with `niri-session`, and
unlike Hyprland's `start-hyprland` this one is conventional**: a `/bin/sh` script that
imports the login environment into systemd and D-Bus then runs `systemctl --user --wait
start niri.service`, so the session is genuinely systemd-managed with
`graphical-session.target` bound properly. **There is no `/usr/share/niri`** — the
default config is compiled into the binary and written to `~/.config/niri/config.kdl` on
first launch; `niri validate` errors rather than creating one. That default binds
`Mod+T` to alacritty and `Mod+D` to fuzzel, neither installed, so out of the box you get
a compositor with no way to open a terminal (`~/t-niri-kitty` repoints it; `Mod+Shift+E`
then `Enter` always exits). **Two differences from Hyprland that are real functional
deltas, not polish**: (1) *no built-in Xwayland* — it needs the separate
`xwayland-satellite` process, and warns loudly when absent, which is the behaviour
`CLAUDE.md` asks for; (2) *no portal backend applies* — the box's only implementation
declares `UseIn=wlroots;Hyprland;sway;Wayfire;river;` and niri is not in that list, so
portal screencast and file pickers are dead while niri's own `Print` screenshot still
works. **Its default config contains a live example of the failure this repo exists to
prevent**: line 271 is an uncommented `spawn-at-startup "waybar"`, waybar is not
installed, the spawn failed, and the journal mentions waybar **zero** times — a
configured startup process failing in total silence, shipped by upstream. **Keybinds,
author's preference 2026-08-20**: `Mod` is Super and `Mod+H/J/K/L` is already bound
three ways (plain = focus, `+Ctrl` = move, `+Shift` = across monitors); the author
wanted HJKL to also replace `Page_Up`/`Page_Down`, so the config's own commented
alternatives on lines 423-426 were swapped in — `focus-window-or-workspace-down/up` and
`move-window-down-or-to-workspace-down/up`, which fall through to the next workspace at
the top or bottom of a column. It is a swap, not an addition: leaving both sets active
is a duplicate bind. **Carry this into the Phase 4 config; it currently exists only on
`bunne-test`, which Phase 5 wipes.** **PICKED 2026-08-20**, by the author after running
both on the same machine. Three reasons, in his order: (1) he likes using it — the
scrollable-tiling model suited him immediately; (2) **Hyprland's Lua migration is
actively breaking his existing Omarchy configs**, which is the priority-1 argument made
concrete — a substrate churning under you is the opposite of "boring option that
survives an update"; (3) it is measurably leaner, **2.4x** on idle session cost. Note
the honest counterweight, recorded so it is not forgotten: Hyprland wins on priority 3,
since its custom GLSL shader pipeline is more capable than niri's, and it hands you a
wallpaper and cursor out of the box where niri needs `swaybg` and a cursor theme. That
was judged not to outweigh 1-3.


### font — Fragment Mono, `disable_ligatures always`

**picked** · 2026-08-18 · packages: —

**Measured:** ligatures on 231ms vs off 194ms vs no-ligature-table font 195ms, `time
cat` a 200k-line/14MB file with 6 ligature triggers/line inside kitty (real code will
never be this dense)

**Packages cell corrected by the 4.17 audit (2026-08-25): `ttf-fragment-mono` does not
exist** — not in the repos, nothing in the AUR (`yay -Ss`), and the working font on
`arch-bunny` turns out to be **hand-dropped, package-unowned TTFs in
`~/.local/share/fonts/`** (`pacman -Qo` owns none). The font itself is fine (`fc-match
"Fragment Mono"` resolves; kitty renders it, no silent fallback) but the provenance is
invisible and the installer cannot reproduce it. **Delivery mechanism is an open author
decision**; recommended: vendor the TTFs in this repo (SIL OFL permits it; ship the
license file alongside) — alternatives are a Google-Fonts megapackage (huge for one
font) or curl-at-install (network, unpinned). Ironically this row's own Note already
warned "never assume the package name matches the font's display name." Picked on taste
after a live side-by-side against Iosevka, Monaspace Neon NF, Departure Mono, JuliaMono,
B612, 0xProto, Recursive, Terminus (`kitty -o font_family="<name>" -o font_size=22` per
candidate, tiled, compared on `0O 1lI apple WWW -> != <= 0xDEAD`). A monospaced
Helvetica cut — stark, unusual for a code font, still legible. **Ligatures measured, not
assumed**: `disable_ligatures always` cost ~37ms (16%) worst-case over that flood, and
setting it fully eliminates the cost rather than partially mitigating it — off lands
within noise of a font with no ligature table at all (194 vs 195ms). Kept them off: user
preference, and it's free. Measuring this required writing the timed command's own `2>`
redirect to a file from *inside* the kitty-spawned shell — redirecting `kitty ... &>
file` only captures kitty's own startup stderr, not what the inner pty displays, since
the terminal's shown text is a separate stream from kitty's own process stdout. Two more
gotchas hit along the way, worth not repeating: (1) **`kitty` cannot render bitmap
fonts.** Requesting `font_family="Terminus"` (a `.otb` bitmap font) silently falls back
to whatever `monospace` resolves to instead of erroring — confirmed with `kitty
--debug-font-fallback`, which showed it substituting Iosevka with zero warning. No
box-drawing bitmap font will ever visibly differ in kitty; don't re-test one. (2) The
`pacman -S ttf-jetbrains-mono-nerd`-style guess-the-package-name approach failed twice
(`ttf-monaspace`/`ttf-departure-mono` don't exist; correct names were
`otf-monaspace-nerdfonts`/`otf-departure-mono`, found via `yay -Ss`) — always `yay -Ss
<name>` before handing over an install command, never assume the AUR/`extra` package
name matches the font's display name. No `fontconfig` default existed before this
(`fc-list` returned 0 entries), which is also why the very first `kitty` launch showed
tofu boxes — that was a missing-font symptom, not a Hyprland bug.

**Delivery settled 2026-08-25 (author's 2026-08-25 queue, `docs/open-questions.md`):
vendor the TTFs in this repo.** `ttf-fragment-mono` is not a package and never was
(4.17); the working font on the box is two package-unowned files. The installer
therefore symlinks `assets/fonts/*.ttf` into `~/.local/share/fonts/` and runs `fc-cache
-f`, matching the repo's symlink deployment. The family is Regular + Italic only, so two
files are the whole family — kitty synthesizes bold exactly as it does today. Rejected:
the `google-fonts` megapackage (hundreds of families of audit surface to obtain one font
— the complexity test, not disk) and fetching at install time (a network dependency on a
step that otherwise has none; priority 1). **Vendored 2026-08-25**, and the licence question is now answered from
the bytes rather than assumed: the TTFs' own `name` table records *"This Font Software is
licensed under the SIL Open Font License, Version 1.1"* (name ID 13) and *"Copyright 2022
The Fragment-Mono Project Authors"* (ID 0) — OFL 1.1 explicitly permits redistribution
with the licence file alongside, shipped as `assets/fonts/OFL.txt`.

**Provenance, checked rather than trusted.** The box's two package-unowned files are
**byte-identical to the Google Fonts release** (`google/fonts` `ofl/fragmentmono/`), so
the mystery files the 4.17 audit found are the ordinary upstream binaries and vendoring
them changes nothing that was measured:

| File | sha256 |
|---|---|
| `FragmentMono-Regular.ttf` | `0fe011f425873c2e0fc73a189e394e340ad48d2b9a99a576bdeec75cee000460` |
| `FragmentMono-Italic.ttf` | `c9dd3c7b24c11ba05ab1a6ec3a659c823f0e14fb26c14df0e93e82ebb60f3a25` |

Version 1.011 (`ttfautohint v1.8.4.7`). `OFL.txt` is Google Fonts' copy for this family,
whose header carries the same 2022 copyright line as the binaries. Note the *upstream
project repo* (`weiweihuanghuang/fragment-mono`) currently ships a **different, newer
build** — 162,688 bytes, copyright 2024 — so "get it from upstream" and "get it from
Google Fonts" are not the same font. What was measured, picked, and is running on the box
is the Google Fonts build, and that is what is vendored; a future refresh to the 2024 cut
is a re-measure, not a file swap.


### emoji-font — noto-fonts-emoji

**picked** · 2026-08-30 · packages: noto-fonts-emoji

**Measured:** —

Author noticed emoji rendering as tofu/fallback glyphs on bunne.net; `fc-list | grep -i
emoji` came back empty and no `/etc/fonts/conf.d/*emoji*` config existed either, so this
was never installed rather than misconfigured. Google's Color Emoji is the standard pick
on Arch and needs no separate fontconfig rule — the package's own conf
(`/etc/fonts/conf.d/`) makes it the default emoji fallback for every font on the system,
confirmed with `fc-match ":charset=1f600"` resolving to `NotoColorEmoji.ttf` immediately
after install. **Trap found while verifying:** the fix didn't show up in Brave at first —
not a fontconfig problem, Chromium-derived browsers enumerate the system font list once at
launch, so a font installed after the browser is already running is invisible to it until
a full restart (`pkill brave` if any process lingers). Killed and relaunched Brave;
bunne.net renders emoji correctly.


### audio — `pipewire-audio` + `pipewire-pulse` + `wireplumber` + `realtime-privileges`

**picked** · 2026-08-19 · packages: pipewire-audio pipewire-pulse wireplumber realtime-privileges

**Measured:** **`bunne-test`: 0 MB cold** (socket-activated, nothing runs until a client
connects), **34.9 MB warm** (wireplumber 22.9 + pipewire 12.0); idle RAM 583 → 597 MB.
Desktop, permanently warm: 76 MB / 3 procs. `data-loop.0` runs `SCHED_FIFO` prio **88**

Not a bake-off — `pipewire-media-session` is dead upstream, so wireplumber is the only
session manager, and PipeWire **without** one routes nothing. The test laptop is the
proof: it has `pipewire` and no session manager (pulled in as an
`xdg-desktop-portal-hyprland` dependency, chosen by nobody) and therefore cannot play a
sound. **Take the `pipewire-audio` metapackage, not a hand-picked
`pipewire`+`pipewire-pulse` "lean" set**: read its `Depends On` — it carries
`bluez-libs`, `sbc`, `libldac`, `libfreeaptx`, `liblc3`, `libfdk-aac`, i.e. the
Bluetooth codec set. Hand-picking the subset silently downgrades every BT headset to
SBC. Skip `pipewire-jack` (pro-audio only); probably skip `pipewire-alsa`
(Spotify/Brave/mpv all speak PulseAudio) but verify before dropping it. **Realtime
scheduling — add `realtime-privileges`, not `rtkit`.** Found 2026-08-19 when the test
laptop logged `RTKit error: org.freedesktop.DBus.Error.ServiceUnknown` from `module-rt`;
audio still worked, because PipeWire falls back to priority 1 / nice 0, but it was
running without real RT priority. `pipewire` lists both packages as optdeps for the same
job. `rtkit` is a D-Bus-activated daemon — measured **3.1 MB resident** on the Omarchy
desktop, which has it. `realtime-privileges` (`extra/5-1`, **`Depends On: None`**) is
only a `realtime` group plus an `/etc/security/limits.d` drop-in, letting PipeWire's
`rt` module take RT priority directly via rlimits with **no resident process at all**.
Priority 2 picks the second — another Omarchy default that is not the lean one.
**Verified on hardware 2026-08-19, and it is not even a compromise: the lean option
performs *better*.** Comparing the actual worker thread on each machine, the desktop
under `rtkit` runs `data-loop.0` as `SCHED_RR` priority **20**, because rtkit applies
its own policy cap; the laptop under `realtime-privileges` runs it as `SCHED_FIFO`
priority **88**, which is PipeWire's own preferred `rt.prio` default. Note also that
rtkit grants priority **per thread over D-Bus**, so the *process* `RLIMIT_RTPRIO` stays
0 and `/proc/<pid>/limits` looks unchanged — do not read that as rtkit having failed.
After the fix the laptop shows `Max realtime priority 98` and no `RTKit error` lines.
Tradeoff stated rather than hidden: rtkit's watchdog exists to stop a runaway RT thread
hogging a core and `realtime-privileges` has no equivalent, which is acceptable on a
single-user workstation. Requires the user to be in the `realtime` group, effective **on
next login**, so the installer must either say so or the group must be set before first
login. **Option, and the recommended one — override `memlock` to a bounded value instead
of the package's `unlimited`.** Raised 2026-08-19 after the author asked why there is no
safeguard at all. There are two distinct risks and they cost very different amounts to
mitigate. (1) *RT starvation*: a runaway `SCHED_FIFO` thread at priority 98. **Already
mitigated by the kernel, for free** — verified `kernel.sched_rt_runtime_us=950000` /
`kernel.sched_rt_period_us=1000000`, so RT tasks are capped at 95% of CPU and 5% is
permanently reserved for normal tasks. The machine crawls but stays recoverable via a
TTY; the "realtime can hard-lock your box" warning predates this throttle. `rtkit`'s
watchdog would improve on it but costs a resident daemon, which is the trade we already
rejected. (2) *Memory locking*: `memlock unlimited` lets a group member `mlock()`
arbitrary RAM, which is unswappable and **cannot be reclaimed under pressure — so
`systemd-oomd` cannot free it** (see `oom-protection`). That matters here specifically,
because the author has been burned twice by memory exhaustion. **Bounding it costs
nothing at runtime**: `limits.d` is read by `pam_limits` at login, which then exits, and
enforcement lives in the kernel's `mlock()` syscall path — there is no process involved
either way, so this is purely a different number in a file already being read. Default
without the group is 8192 KB; PipeWire realistically locks single-digit MB of audio
buffers. **Measured 2026-08-19, and the answer is to grant no elevated memlock at all —
keep the 8 MB default.** `VmLck` is **0 kB** for `pipewire`, `wireplumber` and
`pipewire-pulse` on *both* machines: the desktop has been running audio for hours on the
plain 8 MB default (`rtkit` grants realtime *priority*, not memlock — its `Max locked
memory` reads the default 8388608), and the laptop locks nothing even with `unlimited`
available. PipeWire does not use it. This also disposes of the question of scaling the
value by system RAM: there is nothing to scale, since 8 MB is the default everywhere and
a *ceiling* rather than a reservation — identical on a 4 GB machine and a 64 GB one,
costing nothing on either. `realtime-privileges` ships `unlimited` for pro-audio (JACK
locking large sample buffers); this repo explicitly skips `pipewire-jack`, so revisit
only if that changes. **Implementation** — the package ships
`/etc/security/limits.d/99-realtime-privileges.conf`. Prefer shipping our own single
file with just `rtprio 98` and `nice -11` plus a `groupadd realtime` in the installer,
over layering a later-sorting drop-in to override it: `pam_limits` resolves duplicates
by "last file read wins" in ASCII collation order, which is exactly the kind of implicit
behaviour that breaks silently and cannot be justified line by line. Neither risk is
privilege escalation — nothing here grants root or crosses a user boundary; both are
denial-of-service surfaces reachable only by code already running as this user. Write no
config: upstream defaults handle routing, and the desktop is the hard case with 6 cards
(Yeti X, Brio 101, Arctis 7, NVIDIA HDMI, 2× onboard HDA). **`sof-firmware` is a
separate package that neither current machine needs** — the desktop is AMD, the test
laptop is legacy `HDA Intel PCH` — but modern ThinkPads and Frameworks use SOF, so the
installer must carry it for the *future* daily driver. Neither box in hand will ever
surface this; do not conclude from their silence that it is unnecessary.


### bluetooth — bluez + bluez-utils + bluetui

**picked** · 2026-08-19 · packages: bluez bluez-utils bluetui

**Measured:** `bluetoothd` 6.2 MB RSS on `bunne-test`, 6.8 MB on the desktop; 1 daemon;
8.85 MiB installed

Promoted to a **core requirement** 2026-08-19 at the user's request.
`02-functionality.md` C8 previously listed only wired/WiFi/DNS/NTP, so nothing required
Bluetooth and it could have been dropped as an unjustified daemon. 6.8 MB for one daemon
is cheap and both desktop adapters (`hci0`, `hci1`) are real hardware. **Gotcha found on
the Omarchy desktop: `bluez` alone does not give you `bluetoothctl`** — that box has
`bluez` + `bluetui` and `bluetoothctl: command not found`, which is precisely the tool
wanted when a pairing fails. `bluez-utils` is a separate package (`extra/5.87-2`).
**Verified on hardware 2026-08-19**: installing it does provide `bluetoothctl` (5.87),
so the desktop's missing binary is simply the absence of this package, exactly as
suspected — verification closed. **Gotcha worth not re-diagnosing**: immediately after
`systemctl enable --now bluetooth.service`, `bluetoothctl list` prints *nothing* even on
a machine with a working adapter, because `bluetoothd` has only just started and the
controller has not registered yet. Seconds later it shows correctly (`Powered: yes`,
`PowerState: on`). Do not read that empty list as a missing adapter. No `blueman` — a
GTK applet plus its own daemon for what `bluetui` does on demand. BT audio codecs come
from `pipewire-audio` (see `audio` row); do **not** install
`sbc`/`libldac`/`libfreeaptx` explicitly, they are already its dependencies.
**Acceptance passed 2026-08-24, author-performed:** a real Bluetooth keyboard paired and
connected on `arch-bunny`; verified opening/closing terminals and typing into them via
the new keybinds.


### swap-zram — zram only, no disk swap, no hibernation

**picked** · 2026-08-19 · packages: zram-generator

**Measured:** **2026-08-26 on `bunne-test`, verified by `install.d/10-zram.sh` itself:**
`/dev/zram0` 7.7 GiB active, `vm.swappiness=180`, `vm.page-cluster=0`. Earlier: test laptop
had **zero** swap and no zram; desktop has 4 GiB zram at `vm.swappiness=60` — the 4 GiB
being the shipped cap this row exists to remove

**Was an unfinished Phase 2 item; now the first thing the installer does.**
`install.d/10-zram.sh` installs `zram-generator`, writes both files and **verifies the
result** rather than assuming it — a generator that silently produced no swap unit, and a
sysctl shadowed by a higher-numbered file, both look exactly like success otherwise. When
this row was written, `04-plan.md` Phase 2 step 2 listed zram and `swapon --show` on the
test laptop returned nothing — the step had never been executed. This matters beyond swap: `systemd-oomd`'s swap-pressure kill path is inert
with no swap, so the `oom-protection` row silently loses half its mechanism until this
is fixed. Settings: `zram-size = ram / 2` written **explicitly** — the shipped default
is `min(ram / 2, 4096)` (confirmed in
`/usr/share/doc/zram-generator/zram-generator.conf.example`), and that 4 GiB cap is what
the desktop inherited; uncapping it is what gives a 16 GiB laptop 8 GiB instead of 4.
Plus `vm.swappiness = 180` and `vm.page-cluster = 0`: zram is random-access RAM, so the
kernel's conservative "swap is slow" defaults (60 / 3, still in place on the desktop)
are actively wrong for it — swappiness must be raised *toward* zram, and readahead is
pure waste. **No hibernation**, assumed from the user's "I expect to use laptops in
places with outlets" — suspend-to-RAM covers the case. This is the one item here that is
a one-way door at install time: hibernation needs disk swap sized ≥ RAM plus a `resume=`
cmdline, which on the 64 GiB desktop means 64 GiB of otherwise-dead disk. Reverse it
before writing the installer, not after.


### firmware-set — named `linux-firmware-*` splits, never the metapackage, never `-nvidia`

**picked** · 2026-08-25 · packages: linux-firmware-intel linux-firmware-realtek linux-firmware-atheros linux-firmware-mediatek linux-firmware-broadcom linux-firmware-other linux-firmware-whence

**Measured:** laptop runs correctly on 10 splits; initramfs stayed 25 MB

Falls directly out of the `initramfs` row: that fix removes the `linux-firmware`
metapackage, so the installer must now **name** the splits it wants or a fresh machine
gets none. The failure mode is a priority-1 one — an Intel AX card with no firmware
means no wifi *during the install itself*, on the "any Arch-compatible PC" lite target.
Arch splits this 18 ways (`pacman -Ss '^linux-firmware'`); the set above is the sane
default. `-nvidia` is excluded permanently and deliberately, see the `initramfs` row for
the 104 MB reason. `-amdgpu`/`-radeon` are needed for the expected Framework, and
`sof-firmware` is a *separate* package — see the `audio` row.

**The Framework is the AMD variant — author's word, 2026-08-28** — so
`linux-firmware-amdgpu` is added to the list above, closing a gap this row's own text
had named since 2026-08-25 while its package cell omitted it. `linux-firmware-radeon` is
deliberately **not** added: `radeon` is the legacy driver for pre-GCN cards, and a Ryzen
integrated GPU is driven by `amdgpu`. Raised rather than assumed — say so if a Framework
needs it and it goes in.

**AND archinstall REINSTALLS the metapackage this row exists to remove.** Found
2026-08-28 while migrating packages into the JSON: `__packages__ = ['base', 'sudo',
'linux-firmware', 'mkinitcpio']` is hardcoded in `lib/installer.py:69` and pacstrapped
unconditionally, with no JSON key to prevent it. So every `archinstall`-produced box has
silently carried the metapackage — and therefore `linux-firmware-nvidia` — since the
`base-install-method` decision. `install.d/27-firmware.sh` removes both afterwards, which
is the `initramfs` row's own prescribed fix (`pacman -R`, **never** `-Rs`) applied at the
one point it can be: after `20-packages.sh` has named and explicitly-marked the splits
that must survive.

**This matters on the desktop, not on the Framework, and the difference is worth
stating.** The 104 MB comes from mkinitcpio's `kms` hook packing `nouveau`'s entire
firmware set because an NVIDIA card matches it. An AMD machine has no NVIDIA card, so
`nouveau` is never autodetected and the trap never fires there — the removal is still
right (unused firmware for a GPU that is not present) but it is not load-bearing. On the
4090 desktop it is the difference between a 25 MB and a 130 MB initramfs, in a 1 GiB FAT
`/boot` that must also hold snapshot kernels.

**2026-08-25, Packages-column convention** (author's 2026-08-25 queue,
`docs/open-questions.md`): the `plus -amdgpu/-radeon on AMD` tail left the cell. The
Packages column now lists only what installs on every BunnE machine; the installer adds
`linux-firmware-amdgpu` and `linux-firmware-radeon` when it detects an AMD GPU. Same
rule as `microcode` and `gpu-driver`.

**Brace list expanded to seven names 2026-08-25, because it was a latent installer
bug.** The cell read `linux-firmware-{intel,realtek,…}`, which reads as shorthand to a
human and is broken as data: **brace expansion happens before command substitution**, so
the documented `pacman -S $(awk … CHOICES.md)` hands pacman that string *literally* and
the install dies on "target not found" — for the one row whose failure mode is "no wifi
during the install itself". Caught by running the documented awk over the whole ledger
rather than reading the cell. All seven names verified to be real packages
(`pacman -Si`). The lesson is the format's own: a cell that is only correct when a human
re-reads it is not machine-readable, and `docs/05-choices.md`'s promise is that **the doc
is the data**.


### microcode — vendor-conditional, chosen at install time

**picked** · 2026-08-25 · packages: —

**Measured:** desktop `AuthenticAMD` + `/boot/amd-ucode.img`; laptop Intel +
`intel-ucode.img`

Proven necessary rather than assumed: the two machines in this project genuinely differ,
and the future daily driver set (this AMD desktop, plus a ThinkPad or an AMD Framework)
spans both vendors. `04-plan.md` Phase 2 step 2 hardcodes `amd-ucode`; the installer
must instead read `/proc/cpuinfo`'s `vendor_id` and pick. The `module_path:` line in
`limine.conf` has to follow the same branch.

**2026-08-25, Packages-column convention** (author's 2026-08-25 queue,
`docs/open-questions.md`): the cell is now `—` rather than `amd-ucode **or**
intel-ucode`. The column's job is to be a flat list of packages that install
unconditionally, because that is what the installer's one-line `awk` consumes; prose in
it silently emitted `**or**` as a package name. The conditional lives where it has to
live anyway — installer logic reading `/proc/cpuinfo`'s `vendor_id` — and is described
here instead.


### firewall — nftables, Arch's shipped `/etc/nftables.conf` unmodified

**picked** · 2026-08-18 · packages: nftables

**Measured:** one `oneshot` unit, no resident process

Recorded 2026-08-19 to close a **stale contradiction**: `03-alternatives.md` still
ranked `ufw` #1 with "plain nftables (leaner, no Python)" second, but Phase 2 had
already enabled nftables on hardware and found the shipped ruleset exactly right. `ufw`
is `rejected` — it is a Python wrapper generating what the default file already
contains. No config file is carried by this repo.

**Amended 2026-09-02:** "exactly right" needed a footnote. The shipped ruleset's
`chain forward` is `policy drop` with zero rules, which blocks every routed
packet — including all Docker container traffic past its own gateway, silently
and without a trace on the wire. `ping` to the docker0 gateway address still
works (that's `input`, which explicitly allows icmp), so the failure reads as a
DNS or VPN problem, not a firewall one — it took a live `image_builder.py` build
failure, a wrong OpenVPN red herring, and a walk through iptables/nftables
base-chain ordering to find. The ArchWiki's own Docker page documents the same
conflict. `26-docker-nftables.sh` now patches two `accept` rules for the docker0
interface into `chain forward` post-install — appended to the shipped file, not a
replacement of it, so "no config file is carried by this repo" still holds in
spirit; the diff against stock is two lines. Docker's own NAT (`iptables: true`,
unchanged) was never the problem — only the parallel filter-table gap was.


### clipboard — wl-clipboard + cliphist

**picked** · 2026-08-19 · packages: wl-clipboard cliphist

**Measured:** the resident cost is **one `wl-paste --watch` at 2.1 MB**

`02-functionality.md` C4 called history "optional and costs a daemon" and
`03-alternatives.md` held it back for the same reason. Measured on the desktop, that
framing is wrong: `cliphist` is not a daemon, it is a store invoked by `wl-paste
--watch`, and the watcher is 2.1 MB. At that price the priority-2 objection does not
survive, and C4 already predicted history "will almost certainly be wanted". Decided
without a bake-off; no hardware evidence would change a 2 MB number.


### shell — bash

**picked** · 2026-08-19 · packages: bash

**Measured:** —

Reconciled from `03-alternatives.md`, which already ranked it #1 and gave the reason: it
is the login shell, every helper function and the VPN alias generation are written in
it, and it starts faster than fish/zsh. Nothing Phase 3 produces can change this, so it
does not need to occupy bake-off time.


### luks-header-backup — `cryptsetup luksHeaderBackup` at install + recovery key recorded off-machine

**picked** · 2026-08-19 · packages: —

**Measured:** —

No new package — `cryptsetup` is already in the base. A corrupted LUKS2 header is
**total, unrecoverable loss of the whole volume** — the passphrase is irrelevant without
it. One command at install time removes a single point of failure that no snapshot, and
no btrfs mechanism, can protect against, because they all live inside the volume the
header unlocks. The header backup must be stored **off the machine**; a copy on the
encrypted root is worthless for the case it exists to cover. Distinct from the `backup`
row: this protects access, that protects data.


### backup — —

**deferred** · 2026-08-27 · packages: —

**Measured:** —

**No longer a gate, author's word 2026-08-27: "remove backup verification from our checklist
entirely. i dont have an external disk and will not have one for a while."** The Phase 6 blocking
language (`04-plan.md`) and the C9 requirement framing (`02-functionality.md`) are both removed —
see those files' own history for what stood there before. The design reasoning below survives as
the leading candidate *if and when this reopens*, but nothing here blocks any other phase, and
there is no plan to build it while there is no external disk. Snapshots living on the same LUKS
volume as the data they protect remains a real gap (a dead NVMe takes every snapshot with it), just
not one this repo is solving right now.

**Design, kept for whenever this reopens:** incremental `btrfs send`/`receive` to an external disk,
reusing the snapshots snapper already takes, triggered by a command plus a `systemd` mount/path
unit that only fires when the disk is present — no resident process, no new tool, no second copy on
the same disk. `restic`/`borg` to cloud is the alternative if offsite matters more than simplicity.
Per this repo's "prove it, do not infer it" rule, **an unrestored backup is not a backup** — the
acceptance test would be restoring it somewhere and booting it, not seeing the job exit 0.


### desktop-portals — —

**rejected** · 2026-08-27 · packages: —

**Found stale 2026-08-27: this is a duplicate of the `portal` row, which already answers it.**
Raised 2026-08-19 while `compositor` was still open, naming the exact risk the `portal` row (picked
2026-08-20, `xdg-desktop-portal-gnome` + `portals.conf`) exists to close — including the
file-chooser-portal trap this row worried about, which `portal`'s own measurements addressed
directly (`AvailableSourceTypes`/`AvailableCursorModes` re-probed after dropping the `;gtk`
fallback). Text below is 2026-08-19's, kept for the history; the `xdg-desktop-portal-hyprland`
it names never shipped — Hyprland was rejected the next day. No decision needed here; see `portal`.

`02-functionality.md` C4 makes screen sharing core ("needed for meetings") but no row
ranks the portals, so the choice would be made by whatever gets pulled in as a
dependency — which is exactly how the `audio` row's broken laptop state happened.
`xdg-desktop-portal-hyprland` is already installed with Hyprland. The trap: it does not
implement the **file-chooser** portal, so browsers fall back to `xdg-desktop-portal-gtk`
and the GTK stack arrives anyway. Decide deliberately whether to accept that, and test
with a real meeting rather than by reading the portal list.


### secrets-bootstrap — —

**picked** · 2026-08-27 · packages: —

**Measured:** —

`rbw` covers passwords, but nothing decides how agent-CLI API keys and per-project `.env`
values reach a new machine — and this repo is installed by other people, so anything
committed leaks. Entangled with both `dotfile-deployment` and `dir-aware-display`.

**Decided, author's word 2026-08-27: manual copy, and a hard line drawn wider than the
mechanism.** No `rbw`-fetch automation, no templated `.envrc` shipped — the author copies
secrets in by hand after install. The stronger part of the answer: *"leave everything
tradeswell-related OUT of the repo. no tradeswell vpn or .bashrc shorthand for it. i dont
want tradeswell to have anything to do with code that i share with the world."* Not just
secret **values** — no VPN config, no shell alias, no path reference naming that employer
or any other client work, anywhere a friend installing this repo would see it. `CLAUDE.md`
now states this as a standing rule next to the personal-details-isolation one it extends.
Nothing to build for this row; it is a thing to keep *not* doing.


### load-protection — systemd slice weighting + core reservation

**picked** · 2026-08-25 · packages: —

**Measured:** `benchmarks/4.18`, kitty spawn under a 12-spinner hog: baseline 141.6 ms →
**504 ms** unprotected → **330 ms** with `CPUWeight=1` on the hog → **149.2 ms** with
`CPUWeight=1` plus `AllowedCPUs` reserving 2 cores, i.e. back to baseline within noise.
The residual at 330 ms was identified as SMT sibling pollution, not frequency scaling.

The other half of `oom-protection`, and arguably the higher-value half. oomd stops the
*crash*; nothing yet stops the far more frequent event — a training run or a Docker
build making the compositor and terminal crawl. systemd-native fix, no package and no
resident process: protect the session slice with `CPUWeight`/`IOWeight`/`MemoryLow` and
launch heavy jobs into a deliberately deprioritized slice (`systemd-run --user
--slice=…`). Directly serves the user's stated top priority (speed) against their stated
top pain (resource exhaustion). Canary test per this repo's rule: pin CPU, allocate into
swap, hammer disk, and measure input-to-pixel latency with and without the weights — a
test that must visibly fail when the protection is absent. Subsumes the oomd canary at
the extreme end.

**Ratified 2026-08-25 (author's 2026-08-25 queue, `docs/open-questions.md`), mechanism
exercised.** The recipe: launch heavy jobs into a deprioritized slice — `systemd-run
--user -p CPUWeight=<low> -p AllowedCPUs=<all-but-N> …` — rather than protecting the
session slice after the fact. Zero packages, zero resident, pure systemd. This is the
row that most directly serves priority 2a against the author's stated top pain, and the
canary it asked for has been run: the protection visibly fails when absent (504 ms) and
visibly works when present (149 ms). **Named limitations:** n=5, one hog shape (CPU
spinners), IO contention untested, and the core reservation is a fixed 2 cores rather
than a proportion.


### desktop-migration — reformat `p2` in place; Omarchy is removed, not coexisted with

**picked** · 2026-08-19 · packages: —

**Measured:** desktop disk is **100% allocated** — 1 MiB trailing free, no gaps

How the daily-driver desktop becomes a BunnE machine (`04-plan.md` Phase 6). Layout:
`p1` ESP 2 GiB (587 MiB used, shared with Windows), `p2` LUKS/btrfs Omarchy 591 GiB (209
GiB used), `p3` MSR, `p4` NTFS 1268 GiB, `p5` recovery. **Reformat `p2` and install
BunnE into it.** It is already Linux, already 591 GiB, already correctly placed between
the ESP and Windows — it *is* the final size, so there is no shrink, no merge, and no
third step. Consequences: **zero partition-table operations**, and NTFS is never written
to, so the Unreal work on the Windows side is reachable only via ESP damage — and the
ESP is 2 GiB, imageable with `dd` in seconds. Since Omarchy is removed rather than run
alongside, the only bootloader question is Windows vs. BunnE, and BunnE owns `/boot` and
`limine.conf` at ESP root exactly as on the laptop; no namespacing, no anti-clobber
machinery. **Two alternatives were considered and rejected — do not re-litigate.** (1)
*Shrink NTFS, install alongside, merge later*: geometrically impossible, because Omarchy
sits at the front of the disk and any new partition lands at the back with 1.2 TB of
Windows between them; growing backwards would mean moving a partition start offset,
hours of data movement where a power cut is unrecoverable. It also requires a shrink,
the most dangerous operation available. (2) *Wipe the disk and reinstall Windows too*:
days of Unreal/Fab/licence rework for no benefit. **The cost of this plan is that there
is no side-by-side test drive** — reformatting `p2` is the point of no return. What
replaces it: a boring VM rehearsal (Phase 5), and a *proven* laptop fallback — the
user's own gate, 2026-08-19: before `p2` is touched, the laptop's BunnE must be
confirmed adequate as an emergency data-science machine by working a full day on it with
the desktop powered off. Assumption until exercised, per this repo's rule. If 591 GiB
later proves small, shrink NTFS *then*, with nothing at stake, and `btrfs device add`
the freed space — btrfs is multi-device and needs no contiguity.


### install-disk-mode — `convert` is the only mode this repo implements; `archinstall` owns the rest

**picked** · 2026-08-19 · packages: —

**Measured:** —

**Superseded in part, same day, by `base-install-method`.** Once the base install is
delegated to `archinstall`, `whole-disk` and `alongside` stop being modes *this repo*
implements — they are choices made in the archinstall config, on someone else's tested
code. What remains here is `convert`, which was written up as the third mode below and
is now simply what `install.sh` *is*. The disk-half requirements this row and
`04-plan.md` used to carry (explicit target partition, never touch the partition table,
never format the ESP, dry-run of destructive operations) go with it: **this repo no
longer performs a destructive disk operation at all.** The two-halves framing below
survives and is why the change was cheap — the split already existed, so delegating one
half was a deletion rather than a redesign. Original wording follows. **`convert`, added
2026-08-19 on the author's suggestion**: clone the repo onto an already-running Arch
machine, run `./install.sh`, and it becomes BunnE — no disk operations at all. This
falls out of the hand-rolled-script approach for free and implies a structural rule
worth stating: **the installer is two separable halves**, disk provisioning (partition,
format, bootstrap) and system provisioning (packages, configs, dotfiles, services).
`whole-disk` and `alongside` differ *only* in the first half; `convert` runs the second
half alone. Keep them separable when writing Phase 4 scripts. The payoff is that the
second half — the large, config-heavy, bug-prone half — gets exercised constantly,
because re-running it idempotently on the author's own working machine is the normal way
to apply a change. That is far better coverage than any VM run. Rest of the row: raised
by the author 2026-08-19 to correct a drift in the plan: the docs had begun treating
"dual-boot with Windows on a fully allocated disk" as *the* case, when it describes
exactly one machine. **Windows is optional and usually absent.** A new ThinkPad or
Framework gets BunnE and nothing else, and so does a friend installing this to see the
rice — so `whole-disk` is the default and the path that must just work with no questions
asked: the installer partitions the target disk, creates the ESP, owns everything.
`alongside` is the option: Windows already present, so reuse its ESP and **never format
it**, take an explicit target partition, refuse to touch the partition table, chainload
`\EFI\Microsoft\Boot\bootmgfw.efi`. The installer detects which case it is in rather
than assuming either. **The installer must never expect an existing Linux partition** —
that is a one-off belonging to the desktop migration, not a supported input shape
(`desktop-migration`). Same for an existing limine install: this desktop is likely the
only machine that will ever have both Windows *and* limine already on it, so handle it
in that migration rather than designing the installer around it. Distinct axis from
`install-profile`, which is about the package set (lite vs. full); the two are
independent and either combination is valid.


### installer-prompts — short bounded set, asked up front, all defaulted

**picked** · 2026-08-19 · packages: —

**Measured:** —

Raised by the author 2026-08-19 to correct an over-strict phrasing in `04-plan.md` ("no
questions to answer"), which conflated two different things. **Questions about the user
and their machine are legitimate**: username and password (default user `bunne`, per
`CLAUDE.md`), hostname, timezone, keyboard/locale, disk mode and target
(`install-disk-mode`), encryption and its passphrase (see the still-open
encryption-as-a-variable item), lite vs. full (`install-profile`), and wifi credentials
where there is no ethernet — without which nothing can be installed at all. **Questions
about this repo's internals are not**: which compositor, which bar, which init hook.
Those are settled in this ledger and are deliberately not toggles — `CLAUDE.md`,
"opinionated tastes need no justification or config toggles." The distinction is the
test to apply when tempted to add a prompt. Two design rules: **ask everything before
the first destructive operation**, then run unattended — a prompt appearing forty
minutes in, after the disk is written, is what makes an installer feel like babysitting;
and **every question carries a sensible default**, so the common path is pressing enter
rather than composing answers. "It just works" means no manual repair afterwards, not
zero prompts.


### base-install-method — `archinstall` + a checked-in JSON config; this repo does **post-install only**

**picked** · 2026-08-19 · packages: —

**Measured:** —

Not a target package — `archinstall` runs from the live ISO and is never installed to
the machine. **The largest scope reduction in the project**, decided 2026-08-19. This
repo stops owning the base install entirely: `archinstall` partitions, encrypts, creates
subvolumes, `pacstrap`s and installs the bootloader; `install.sh` then turns that
vanilla Arch into BunnE. Author's reasoning, and it is the right one: hand-rolled
partitioning **worked on the test laptop but is unproven on any other hardware**, which
is exactly the priority-1 risk — and any friend willing to try this repo can already
install vanilla Arch, so the base install is not where the value is. It is also the
pattern the most popular projects in this space (Omarchy, LARBS, ML4W, ArchTitus) all
use: they deliberately decline to own disk partitioning. **Verified 2026-08-19 by
extracting `archinstall 4.4-1` and reading it** rather than trusting reputation — the
prerequisites this repo's other rows depend on are all supported: `Bootloader.Limine`
exists and installs limine *and* creates the `efibootmgr` NVRAM entry; the
**ESP-mounted-at-`/boot` layout** the `bootloader` row requires is handled explicitly
(`efi_partition.mountpoint == Path('/boot')`); and a `validate_bootloader_layout()`
check refuses an incompatible layout instead of silently producing an unbootable system.
There is also a `NO_BOOTLOADER` option if the split ever needs to move. **Two deltas to
encode in the JSON config**: archinstall's default subvolumes are `@`, `@home`, `@log`,
`@pkg` — the `filesystem` row says `@var_log`/`@var_pkgs`, so either rename in config or
adopt archinstall's names (cheaper — nothing depends on them but our own prose); and
**`@snapshots` is not in its defaults**, which snapper needs, so decide whether the
config declares it or `snapper create-config` makes it. **Schema churn is handled by
pinning, not by hoping** (author, 2026-08-19): the checked-in JSON targets a *specific*
archinstall version, and `README.md` names the exact Arch ISO release to install from
and links it. A reader is then never guessing which schema their ISO speaks. This
converts archinstall's one genuine weakness — a config format that changes between
releases — from an ongoing risk into an occasional, bounded chore: test against a newer
ISO, update the JSON, bump the version named in the README. Record the tested ISO date
in both the README and the config's filename, since JSON cannot carry a comment. The
author also keeps a known-good Arch ISO on his Ventoy stick, so his own path never
depends on the pin being current. **What this repo must now build instead**: (1) the
archinstall JSON config, checked in — declarative, reviewable, and the replacement for
all the deleted partitioning code; (2) **prerequisite checks at the top of
`install.sh`**, because post-install-only means we no longer control the base — verify
btrfs, the subvolume layout, LUKS, limine, and the ESP mountpoint, and fail loudly per
`CLAUDE.md`'s "fail loudly and early" rather than half-configuring a machine that was
set up differently.


### jupyter-in-neovim — molten-nvim + image.nvim (`magick_cli`) + jupytext

**picked** · 2026-08-25 · packages: neovim imagemagick

**Measured:** **Proven end to end on hardware**: inline plot rendered inside Neovim in
kitty, and further ad-hoc expressions evaluated correctly on other lines

**The gripe is closed.** Stage 3 of the Jupyter test, after `terminal` proved the layers
beneath it. The author confirmed 2026-08-19 that the plot rendered inline and that
arbitrary maths typed on other lines evaluated correctly — so PyCharm has no remaining
job on this machine, which was the point (`CLAUDE.md`: no JetBrains products in this
install). What remains is Phase 4 work — writing the real config — not a choice about
what to use. **The predecessor's `jupyter.lua` was never broken** — it self-disabled, by
design: its `image_terminal()` gate sets `molten_image_provider` to `"none"` and skips
`image.nvim` entirely unless the terminal is kitty/ghostty. Under alacritty that is
silent graceful degradation, experienced as "Jupyter is a pain". So the config is worth
porting, not rewriting. **Two gotchas found on hardware, both of the "fresh machine has
nothing" class.** (1) **Molten writes the kernel connection file into the Jupyter
runtime dir but does not create it.** On a box that has never run Jupyter,
`~/.local/share/jupyter/runtime/` is absent and `MoltenInit` dies with `[Errno 2] No
such file or directory: .../kernel-<uuid>.json`. Confusingly, starting the same kernel
by hand *works*, because `jupyter_client`'s `KernelManager` creates the directory itself
— so the failure looks like a kernelspec problem when the kernelspec is fine. Fix:
`mkdir -p "$(python -c 'import jupyter_core.paths as p;
print(p.jupyter_runtime_dir())')"` in the installer. (2) **Molten must load eagerly.**
Its commands come from the rplugin manifest at startup, and lazy-loading deletes the
command stubs, producing `Not an editor command: MoltenInit` — the predecessor repo
already carries this note; keep it. **Design change the author asked for, 2026-08-19 —
the gate must announce itself.** Keep `image_terminal()`: opening nvim in a TTY or over
SSH must not throw. But **silent** degradation is what made this gripe undiagnosable for
so long, so the port must distinguish two cases. *Expected* absence — a TTY, an SSH
session, a terminal knowingly chosen without the protocol — gets one quiet `vim.notify`
at INFO stating the reason and the detected `TERM`, so the state is never a mystery.
*Unexpected* absence — `image_terminal()` returns true but `image.nvim` fails to load,
or molten reports no image provider — is a broken hard requirement
(`02-functionality.md` C5/C6) and should warn loudly. Add a status command or
`:checkhealth` entry too: the failure mode here was not knowing, and a diagnosis nobody
can run is not a diagnosis. General rule now in `CLAUDE.md` under *fail loudly; do not
degrade silently*. **Version note, watch this**: molten 1.9.2 against ipykernel
**7.3.0**, a major upstream break (the kernelspec now carries `supported_encryption:
curve` and `kernel_protocol_version: 5.5`). Not implicated in the failure above, but the
first place to look if rendering misbehaves; pinning ipykernel to 6.x is the fallback.
`uv venv` installs no `pip`, so query versions with `importlib.metadata`, not `pip
list`. **AUTHOR ACCEPTANCE, 2026-08-24, after hands-on use of the full markdown-notebook
stack (4.15: molten + image.nvim + render-markdown + themed LaTeX on LazyVim/kitty):
"as-is, this looks like it can completely replace my current pycharm workflow."** The
PyCharm fallback this gripe forced is the exact thing CLAUDE.md chartered the project
against; remaining before the row is fully closed: fresh-boot first-try repeatability
(in progress), Phase-4 port into shipped config, venv-selector.

**2026-08-25, Packages-column convention** (author's 2026-08-25 queue,
`docs/open-questions.md`): the `; venv: pynvim jupyter_client ipykernel` tail left the
cell — those are pip packages installed into the project venv by `python-env-manager`'s
`uv`, not pacman packages, and the installer's `awk` was emitting them to `pacman -S`.
The pacman half is `neovim imagemagick`; the venv half is recorded here.


### terminal — kitty

**picked** · 2026-08-21 · packages: kitty

**Measured:** **kitty graphics protocol confirmed working** on hardware: `kitten icat`
rendered a PNG, and a `uv`-built matplotlib plot rendered inline, both under Hyprland on
the hybrid-graphics panel

**Latency measured 2026-08-21 in a live niri session**
([`benchmarks/3.6`](benchmarks/3.6.session-residents.md)): spawn → shell running in the
new window is **178.9 ms cold**, and **15.6 ms with `--single-instance`**, which reuses
the running process. 11.5x, and it crosses the perception threshold for the machine's
most-used application. **The cost is kitty, not our config** — `--config NONE` (213.5
ms) and `shell_integration=disabled` (216.5 ms) are indistinguishable from default
(215.4 ms) end-to-end, so there is nothing to tune; the only lever is not starting a new
process. **The 178.9 ms was challenged by the author as implausible and then
investigated rather than accepted.** Two findings. (1) **Not this machine**: restricting
EGL to Intel — the NVIDIA-dlopen trap the `browser` row found on this same hybrid laptop
— moved it only 216.1 → 205.5 ms, so that is 10 ms of 216, not the cause. (2)
**Architectural**: kitty's maps show a full **CPython 3.14 interpreter** (`_bisect`,
`_bz2`, `_ctypes`, `_json`, `_lzma`, `_socket`, … all `.cpython-314-*.so`) across **100
shared objects**, 304 MB RSS. Cross-checked against published numbers because one
machine proves nothing: upstream issue **kovidgoyal/kitty#4292** reports **kitty 0.251 s
vs alacritty 0.165 s**, and attributes it to `load_all_shaders` recompiling GPU shaders
at every start on top of the interpreter. Our 0.215 s sits inside that range — **this is
kitty's normal behaviour.** **So this row must not close on kitty by default.**
`extra/ghostty 1.3.1-2` is Zig, has **no Python in its dependency list**, and implements
the kitty graphics protocol — the only reason kitty won C5 at all. `03-alternatives.md`
ranked it candidate 2 to "win on latency, and only then on weight". **Tested 2026-08-21,
and kitty wins — but not on the axis anyone expected.** ghostty was installed and
measured the same way, twice, in both orders, with 4 warmups discarded (the author noted
an open kitty window could have kept its libraries page-cache-warm; re-running with
warmups in both orders moved nothing — under 1 ms between passes). **Cold start: kitty
177.4/177.9 ms vs ghostty 280.5/281.3 ms.** ghostty is Zig with no Python, which is why
it was expected to win — but **on Linux it is a GTK4 + libadwaita application**
(`runtime=.gtk`, GTK 4.22, libadwaita 1.9) and pays that init instead: 170 shared
objects to kitty's 100, 320 MB RSS to kitty's 304. **Render throughput: kitty 199 ms vs
ghostty 312 ms** on a 200k-line flood. **ghostty does pass C5** — `kitten icat
--detect-support` returns `memory`, exit 0 — so it loses on merit, not capability. **The
one axis ghostty wins, decisively: input round-trip.** `ESC[6n` → parse → reply is
**3.54 ms mean for kitty and 0.198 ms for ghostty, an 18x difference.** It does not
change the verdict, because **both are far below one 60 Hz frame (16.7 ms)** and so
cannot be felt, whereas the 103 ms cold-start gap is squarely perceptible. **Caveat on
that number**: a DSR round-trip measures the terminal's escape-sequence loop, *not*
keystroke-to-photon — real key latency adds compositor, protocol and presentation, and
needs a high-speed camera (`04-plan.md` Phase 1 step 4). **`--single-instance` REJECTED
by the author 2026-08-21**, despite cutting a new window from 177 ms to **14.7 ms**:
*"one window crashing could screw my workday. not worth it."* One process serving every
window means a single crash takes every terminal, and priority 1 (it just works)
outranks 2a. **So 177 ms stands, and there is nothing left to tune.** Everything
testable was tested: `--config NONE` 213.1 ms, `font_family=monospace` 210.6 ms, our
config 214.8 ms — all within noise; EGL restricted to Intel saved 10 ms of 216; kitty's
Python is **already precompiled** (546 `.pyc` shipped) and mesa **already caches
shaders** (3.2 MB cache present), so the two obvious culprits are already handled. The
residue is font-atlas construction and EGL/Wayland setup inside kitty, fixable only
upstream — kitty#4292 proposes sprite-map caching and Nuitka, neither released. **The
only remaining lever is a terminal that fails C5**, i.e. `foot`; see that row. **Open**:
single-instance puts every window in one process, so a crash takes them all, and the
first window still costs 178.9 ms; it also needs adding to niri's `Mod+T` binding to
have any effect. **This settles the "Jupyter notebooks are a pain" gripe at the terminal
layer** (`CLAUDE.md`). Tested with `~/t-jupyter`, deliberately staged to isolate three
independently-failing layers — terminal protocol, python→PNG, then Neovim — *before*
building any editor config, because all three look identical from the outside and
debugging Neovim for a terminal fault is the expensive mistake. Stages 1 and 2 both
rendered. **Consequences.** (1) The predecessor's broken notebook workflow was
**alacritty**, confirmed by elimination — it implements no graphics protocol at all. (2)
`03-alternatives.md` ranked **ghostty #1 specifically to fix this gap**; that
justification is now spent, since kitty is the protocol's reference implementation, is
already installed, and works. ghostty must now win on other merits (weight, latency) or
not at all. (3) **`foot` is effectively eliminated** — it is the leanest Wayland
terminal and would otherwise be the priority-2 answer, but it does Sixel only, so
choosing it means giving up inline plots, and `02-functionality.md` C5 makes the
graphics protocol a hard requirement. (4) All remaining Jupyter risk is **inside
Neovim** (molten / image.nvim), not below it. Status is `trying`, not `picked`: kitty is
proven on the requirement that mattered, but has not been measured against ghostty on
startup or memory. **kitty.conf line 4, author 2026-08-24: `confirm_os_window_close 0`**
— "i click close because i'm sure"; trade stated in the file: closing an OS window kills
running processes without asking. Incidental: this run was also the first end-to-end
exercise of `python-env-manager` — `uv` 0.12.5 built the venv and installed matplotlib
without complaint. **Two config candidates declined by the author 2026-08-24, both
measured first:** (1) `input_delay 0` — input round-trip 3.6 → 0.53 ms
(`benchmarks/4.6.inputrt.md`), the largest 2a lever found to date; author kept
upstream's default 3, so kitty.conf stays 3 lines and the 4.6 data stands in evidence if
revisited. (2) the mesa-ICD pin (`__EGL_VENDOR_LIBRARY_FILENAMES`) — declined
everywhere; it would buy 7-10 ms/launch only on nvidia-hybrid machines (`4.8b`/`4.9`),
the 4090 desktop provably pays ~0 for ICD enumeration (`4.10`), and no nvidia-hybrid
machine is in the hardware plan.


### terminal — ghostty

**rejected** · 2026-08-21 · packages: ghostty

**Measured:** cold start **280.5 / 281.3 ms** vs kitty's **177.4 / 177.9 ms** (both
orders, 4 warmups discarded); throughput **312 ms** vs kitty's 199 ms on a 200k-line
flood; **320 MB** RSS and **170** shared objects vs kitty's 304 MB / 100. Input
round-trip **0.198 ms**, an 18x win over kitty's 3.54 ms

**Rejected on measurement, and must not reach the final product** (author, 2026-08-21).
Expected to win — Zig, no Python in its dependency list — but **on Linux it is a GTK4 +
libadwaita application** (`runtime=.gtk`, GTK 4.22, libadwaita 1.9) and pays that init
instead. **It passes C5** (`kitten icat --detect-support` → `memory`, exit 0), so it
loses on merit, not capability. **The one axis it wins is real but imperceptible**: its
18x faster input round-trip is 0.198 ms against 3.54 ms, and **both sit far below one 60
Hz frame (16.7 ms)** — while the 103 ms cold-start gap is squarely visible. Choosing on
the invisible axis over the visible one is exactly what `BUDGET.md` rule 6 forbids.
**Uninstall from `bunne-test`** per Phase 3's "`pacman -Rns` the loser", and keep it out
of the package list.


### terminal — foot

**rejected** · 2026-08-21 · packages: foot

**Measured:** **cold start 12.2 ms — 14.6x faster than kitty's 177.6 ms — and 23 MB RSS
against kitty's 297 MB, 13x lighter. Fastest on throughput too (166 ms vs 220 ms).**
Input round-trip 0.660 ms

**The fastest terminal by a wide margin on every axis except the one that matters, and
rejected only for that.** Measured at the author's request to quantify what C5 costs
([`benchmarks/3.7`](benchmarks/3.7.terminal-bakeoff.md)); the answer is **~165 ms per
window and ~274 MB**, which is a steep price and was worth knowing rather than assuming.
**Sixel only, no kitty graphics protocol.** The rejection was re-examined rather than
inherited, because `image.nvim` does ship a Sixel backend that explicitly lists foot as
supported — **but its own README calls that backend "pretty crap performance, although
very usable with `only_render_image_at_cursor=true`", against "best in class... very
snappy" for the Kitty backend.** That is decisive here: *"Jupyter notebooks are a pain"*
is one of the three headline gripes this whole project exists to fix,
`jupyter-in-neovim` was only just proven working **on kitty**, and adopting a degraded
image path would risk re-creating the exact problem. **The two-terminal split (foot
daily, kitty for notebooks) was considered and dismissed by the author**: *"needing 2
terminals for different tasks is expensive."* Two configs, two themes, two keybind sets
and a "which one am I in?" problem is a priority-1 cost against a 2a gain. **Condition
set by the author 2026-08-21, and it is now a gate rather than a preference**: *"I've
decided I'm not going to use 2 terminals, so foot has to work with jupyter or it cannot
be accepted."* So foot is not revisitable on speed at all — 12.2 ms against 177.6 ms is
**not** a reason to reopen this. The only thing that reopens it is **`image.nvim`'s
Sixel backend becoming good enough to run notebooks daily**, judged by actually
rendering plots in a real session, not by a changelog. Until then kitty is settled and
the 165 ms is a known, accepted cost carried in [`BUDGET.md`](BUDGET.md).


### terminal — alacritty

**rejected** · 2026-08-21 · packages: alacritty

**Measured:** cold start 78.3 ms, RSS 254 MB, throughput 233 ms, input round-trip 0.673
ms; **no graphics protocol at all**

**Rejected on the same requirement as foot, but with a far weaker case for
reconsidering.** Tested alongside the others at the author's request since both were
dropped for the same reason. **foot beats it on every single axis** — 12.2 vs 78.3 ms
cold, 23 vs 254 MB, 166 vs 233 ms throughput — so alacritty is not even the best of the
non-compliant options, and unlike foot it has **no image path whatsoever**, not even a
degraded one. This is the predecessor's terminal and the direct cause of its broken
notebook workflow (`03-alternatives.md`). Nothing here argues for revisiting it.


### terminal-navigation — kitty built-ins; deviate only on `scrollback_pager` + `scrollback_lines`

**picked** · 2026-08-19 · packages: —

**Measured:** verified against kitty 0.48.2's shipped reference config on `bunne-test`

**The author's suspicion was right: the capability already exists and is purely
undiscoverable.** kitty ships all of this by default, no packages, no resident process
(`kitty_mod` = `ctrl+shift`): `ctrl+shift+h` `show_scrollback` (whole buffer into a
pager), **`ctrl+shift+g` `show_last_command_output`** (just the previous command's
output — the one that most directly answers the gripe), `ctrl+shift+z`/`x`
`scroll_to_prompt -1`/`1` (jump between shell prompts), `ctrl+shift+/`
`search_scrollback`, `ctrl+shift+e` `open_url_with_hints`, and the **hints kitten** at
`ctrl+shift+p` followed by `l`/`w`/`f`/`n` to label every line/word/path/line-number on
screen and select one by typing its label — the direct mouse-free copy mechanism.
`ctrl+shift+f3` opens a **command palette**, which matters because an undiscoverable
feature is not a feature. **BUG FOUND BY ACTUALLY PRESSING THE KEY, 2026-08-19 — and it
is a second-order consequence of another ledger decision.** `ctrl+shift+g` on
`bunne-test` fails with `failed to launch child: less — No such file or directory`.
**`less` is not in Arch's `base`**; the Omarchy desktop has it only because `man-db`
pulled it in as a dependency, and the `documentation` row had (wrongly) rejected man-db
— so BunnE would have shipped with kitty's default `scrollback_pager less` pointing at a
binary that does not exist, on every fresh install. A priority-1 failure that no amount
of reading the config would have revealed. Two lessons recorded: **install `less`
explicitly** (330 KiB, `core`) rather than inheriting it transitively, and more
generally **never let the installer depend on a tool arriving as somebody else's
dependency**. **Confirmed fixed on hardware 2026-08-19**: after `pacman -S --needed less
man-db`, both `ctrl+shift+g` (last command's output) and `ctrl+shift+h` (whole
scrollback) work. This incident is the origin of the "lean toward tiny,
zero-runtime-cost, commonly-assumed packages" rule now in `CLAUDE.md`. The laptop has
`more` and `vim` but no `less`, no `nvim` and no `bat`, with `PAGER` unset. (Alacritty
ignoring `ctrl+shift+g` is not a bug — the binding is kitty's.) **Two deviations worth
making, everything else is upstream default.** (1) `scrollback_pager` — kitty's own
reference config documents the neovim recipe verbatim at line 527, `nvim --cmd 'set
eventignore=FileType' +'nnoremap q ZQ' +'call nvim_open_term(0, {})' +'set nomodified
nolist' +'$' -`, giving vim motions, search and yank over terminal history and reusing
existing muscle memory; default is `less --chop-long-lines --RAW-CONTROL-CHARS
+INPUT_LINE_NUMBER`. **Test before committing** — the nvim pager is upstream-documented
but unexercised here. (2) `scrollback_lines` defaults to **2000**, which is low for
reading back a long build; raise it, noting kitty warns that very large values cost
memory and that `scrollback_pager_history_size` is the separate knob for pager-only
history. **`show_last_command_output` and `scroll_to_prompt` require shell integration**
to know where prompts are — `shell_integration` is enabled by default and works with
bash, but confirm it is active rather than assuming. **Consequence for the `terminal`
row**: this is now a real point for kitty in the unresolved kitty-vs-ghostty comparison,
since the graphics-protocol gap that used to separate them is closed. Original framing
follows. Raised by the author 2026-08-19 as a named pain point: **reading and copying
text out of terminal scrollback is painful and currently needs a mouse.** Context is the
keyboard-first preference now recorded in `02-functionality.md` — touchpads are
disliked, and terminal/editor/system-config should be fully keyboard-drivable even
though browsers are an accepted exception. The author suspects the capability may
already exist and simply not be discoverable, which is itself the finding: an
undiscoverable feature is not a feature, so whatever wins must end up in a documented
keybind. **Candidates to test, all needing verification on the box before being asserted
— do not take these from memory.** (1) kitty's `scrollback_pager`, pointed at `nvim` or
`less`, which hands the entire scrollback to an editor the author already knows, giving
search, visual selection and yank with no resident process. (2) kitty shell integration,
which enables jumping between shell prompts and selecting a single command's output. (3)
kitty's `hints` kitten, which overlays labels on paths/URLs/lines on screen so one can
be selected by typing. (4) `tmux` copy-mode, which gives vi motions over scrollback but
adds a layer and is already listed in `03-alternatives.md` under dev tooling. Option 1
is the most promising on priority 2 — zero resident cost and reuses existing muscle
memory. **This also becomes a tiebreaker in the unresolved kitty-vs-ghostty question**
(`terminal` row): with the graphics-protocol gap closed, scrollback ergonomics is now
one of the few axes left that actually differ.


### ascii-bunnies — Frame files in the repo + a fork-free bash player, invoked only by processes that already exist or that exit

**rejected** · 2026-08-27 · packages: —

**Measured:** —

**Dropped, author's word 2026-08-27: "forget using the ascii bunnies. they turned out to have
low quality so i'll add them later if i fix them."** The mechanism design below (frames, the
fork-free player, the "never own a process that outlives it" rule) stays as a record of the
answer if the *frames themselves* improve — the thing that failed was the hand-drawn art, not
this row's engineering. Reopens the day new frames exist worth shipping.

Author's want, raised 2026-08-19: little ASCII-rabbit flip-books. Cheap, because the
frames are a few KB of text and the player is builtins only — `printf` per frame and
`read -t <delay>` on a dead fd instead of forking `sleep`, so a 12fps loop costs no
processes beyond the one bash. **The whole cost is whatever holds a surface open to show
them, so the rule is: an animation may never own a process that outlives it.** That
admits, in order of coolness per byte: (a) a shell greeter — a bunny hops across on
new-terminal spawn, ~1s, then the prompt, exits, 0 MB at idle, seen dozens of times a
day; (b) an idle screensaver launched by hypridle a few minutes before it blanks and
killed on wake — free until you walk away, and the literal "pops up in the background"
version; (c) a `hyprlock` `label` with `text = cmd[update:N]`, which re-forks the
command every poll, so 2-5fps only and verify the fork cost before committing; (d) a
keybind / `bunny` command. It rules out `mpvpaper` and `swww` — an animated wallpaper is
a resident decoder on the background layer, which is exactly what priority 2 and
`03-alternatives.md`'s theming table already reject. Frames stay uncolored; the player
wraps them in the accent read from the generated palette, so C10's one-source-of-color
rule holds. **Frames are sprite-sized, never terminal-sized** (author, 2026-08-19): a
window can be anything from a narrow split to full screen, so a bunny hopping *across*
the screen is the player's job at runtime from `$COLUMNS`, and the standard box is 12x6
— small enough to fit anywhere, with anything larger required to declare a minimum size
so the player can fall back. Hand-draw the hero bunny; `chafa` can convert a GIF to
frames at authoring time if needed, committed as text so nothing is needed at runtime.
Phase 4 step 5 work, and **gated on the idle-RAM floor being measured with a live
desktop first** — this is the reward for hitting the number, not a thing to spend before
it.


### os-base — Arch Linux

**picked** · 2026-08-20 · packages: —

**Measured:** —

**Raised by the author 2026-08-20**, unprompted and correctly: given that priority 1 is
"it just works", is NixOS the better substrate? Answer: stay on Arch, and the reasoning
is recorded here so it is not re-litigated at 2am in Phase 5. Two factors decide it.
**(1) NixOS's weakest axis is exactly this machine's workload.** There is no FHS, so
prebuilt binaries linked against `/lib64/ld-linux` do not run without `nix-ld` or an FHS
wrapper — and that describes a large share of data-science tooling: pip/uv wheels with
vendored `.so` files, the CUDA runtime shipped inside PyTorch wheels (the exact
mechanism the `python-env-manager` row depends on), and anything installed by a
curl-to-shell script. Solvable, but a permanent tax levied on the 4090 box where it
hurts most. **(2) It contradicts this repo's core process rule.** `CLAUDE.md` says the
author wants to understand every line, and that this outranks convenience. Nix is a lazy
functional language whose module system merges options by priority through overlays and
overrides, with thin mid-tier documentation; adopting it means months of not
understanding your own config, against the Arch Wiki being the best Linux documentation
in existence and literally about this system. **Sunk cost was not a factor** and should
not be cited as one: of ~40 slots the taste decisions (`compositor`, `terminal`, `font`,
`audio`, `clipboard`, `shell`) survive as wants either way, and the substrate rows that
would evaporate — `initramfs`, `bootloader`, `aur-helper`, `makepkg-options`,
`dotfile-deployment`, `base-install-method`, `luks-header-backup` — represent days of
writing, not months. The reasoning in this ledger outlives the platform.


### os-base — NixOS

**rejected** · 2026-08-20 · packages: —

**Measured:** —

**Rejected on argument, not on measurement — the author has never run it, and nothing
here was verified on a machine**, which is a real weakness of this row by `CLAUDE.md`'s
"verify on the machine" and "prove it, do not infer it" rules. Treat it as provisional
until exercised: **a VM afternoon after Phase 3 settles the compositor slot** is enough,
because the two things that decide it — the Nix language and the binary-compatibility
wall — both show up in a VM. Do not wipe `bunne-test` for it; that box is mid-bake-off.
**What it would genuinely have won**, so the loss is on the record: the whole repo
collapses into one evaluated expression (disko for partitioning, home-manager for
dotfiles, `nixos-install --flake .#bunne` replacing `install.sh`), and config errors
fail at evaluation instead of half way through a disk write — the tool enforcing what
`CLAUDE.md` currently asks discipline to enforce. It would close `rollback-method` and
unblock `snapshot-boot-entries` outright, with rollback exercised on **every** boot
rather than needing the canary-file test that `snapper rollback` earned.
`install-profile` (lite/full) and the microcode/GPU variance across the desktop, the
laptop and a future Framework become a `hosts/` directory instead of conditionals in
bash. Priority 3 also likes it: one `colors.nix` attrset feeding every config is the
cleanest possible "one shared palette source". **Priority 2 is a wash** — no added
resident processes, far more disk, and disk is explicitly not the metric. **It fixes
none of the three gripes**: Docker's disk cap and snapshot bloat are btrfs/Docker
problems, untouched; and gripe 3 gets *worse*, since molten-nvim needs a Python provider
carrying `pynvim` and image.nvim needs ImageMagick plus luarocks, which is a known sharp
edge under a Nix-managed Neovim — the `jupyter-in-neovim` stack is already proven on
Arch. **The one idea worth stealing**: NixOS's rollback is better than ours because it
is visible in the boot menu and used constantly, not because the underlying mechanism is
cleverer. That makes `snapshot-boot-entries` the slot worth unblocking — limine can
point entries at snapshot subvolumes.


### polkit — polkit

**picked** · 2026-08-20 · packages: polkit

**Measured:** `polkitd` **9.9 MB RSS** on the Omarchy desktop; D-Bus activated, not
started at boot

**Found by the niri trial on 2026-08-20, and it is not a niri problem — it is a hole in
the Phase 2 base.** Symptom: inside a running compositor, `Ctrl+Alt+F2` did nothing.
niri was handling the key and failing: `WARN niri::backend::tty: error changing VT:
Failed to change vt: Permission denied (os error 13)`, once per keypress. Mechanism: VT
switching goes through logind's `org.freedesktop.login1.Seat.SwitchTo`, gated on the
polkit action `org.freedesktop.login1.chvt`; with no polkit on the bus, systemd's
`bus_verify_polkit_async` denies every non-root caller. The same missing package
produced a second startup warning, `error inhibiting power key: AccessDenied`, gated on
`inhibit-handle-power-key`. Confirmed not a session-setup fault: `loginctl` showed
session 1 correct in every respect — `Seat=seat0`, `VTNr=1`, `Type=wayland`,
`Active=yes`. **The mechanism is compositor-independent, so Hyprland is expected to fail
identically; that is untested** — the Hyprland trial never tried a VT switch, which is
how `04-plan.md`'s Phase 3 guardrail "keep a second TTY reachable" was false for both
candidates without anyone noticing. Verify it under Hyprland before treating this row as
closed. **Why it is worth a resident daemon**, against priority 2: priority 1 wins,
because an unreachable TTY *is* the "manual repair required" failure — it is the escape
hatch when a session wedges, and losing it costs a hard power cycle. The cost is
bounded: `polkitd` is D-Bus-activated rather than boot-started, so it costs nothing on a
machine that never asks. It is also the `man-db`/`less` pattern a second time — a
commonly-assumed package whose absence breaks *unrelated* things (a compositor keybind,
a power button) and reports it as `AccessDenied` far from the cause. **Proven on
hardware 2026-08-20, not inferred.** Canary run via `~/t-polkit`: with polkit installed,
`Ctrl+Alt+F2` switched to a text login prompt and `Ctrl+Alt+F1` returned to the live
niri session. The journal is the hard evidence — across three niri starts, the two
before polkit (PIDs 1279, 1386) each logged `error inhibiting power key: AccessDenied`,
and 1386 logged `error changing VT: Permission denied` once per keypress; the run after
polkit (PID 1885) logged **neither**. Note both symptoms cleared together, which is the
confirmation that the cause was the missing polkit and not something VT-specific. Its
two surviving warnings are unrelated and expected: `xwayland-satellite` (deliberately
not installed) and `error loading xcursor default@24: no default icon` — **a separate
gap, no xcursor theme is installed on this machine**, which needs its own row before
Phase 4.


### cursor-theme — adwaita-cursors

**picked** · 2026-08-20 · packages: adwaita-cursors

**Measured:** 11.4 MB on disk / 360 KiB download, `Depends On: None`; **2.2 KB decoded
per shape at 24px**, ~77 KB if all 35 shapes loaded at once; **0 at boot, 0 resident —
and measured: installing it moved a live compositor's RSS by exactly 0 kB**
(`~/t-cursor`, Hyprland pid 2738, `VmRSS` 349588 kB / `RssAnon` 91988 kB / `RssFile`
257592 kB, byte-identical before and after)

**Found in the niri trial log, 2026-08-20**: every niri start warns `error loading
xcursor default@24: no default icon`. The machine is not merely missing a theme, it
**ships a dangling pointer to one** — `/usr/share/icons/default/index.theme` contains
exactly `Inherits=Adwaita` and is owned by `default-cursors`, which *is* installed,
while `adwaita-cursors` is not. So the system declares a default cursor and then fails
to provide it, which is why the error names `default`. **Cost is near zero and the RAM
figure is measured, not assumed**: Xcursor is a file format, not a process — no daemon,
no service, no timer. Parsing `/usr/share/icons/Adwaita/cursors/left_ptr` on the desktop
shows one 80 KB file packing six nominal sizes (24/30/36/48/72/96); the compositor
decodes only the size in use, so at the laptop's scale=1 that is 24x24 RGBA = 2.2 KB per
shape. Disk is 11.4 MB, of which **4.5 MB (40%) is the single animated `watch` cursor**
— every static shape is 80 KB. By `CLAUDE.md`'s parsimony rule this is the low-bar case
explicitly described: nothing at boot, nothing at idle, disk is not the metric. It is
also the `man-db`/`less` pattern again — a commonly-assumed package whose absence breaks
something unrelated — except here the breakage was already visible in a log, on a
machine that ships the reference to it. **Alternatives rejected**: `xcursor-themes` (3.6
MB, the classic X.org `redglass`/`whiteglass` set) is cheaper but does not satisfy the
`Inherits=Adwaita` pointer without also editing `default/index.theme`, trading 8 MB for
a second file to maintain; `breeze` is 41 MB and drags in a dozen KDE framework
packages. **Not a final aesthetic choice.** Priority 3 will likely want a neon/cyber
cursor (bibata and similar live in the AUR), and swapping is one theme name in niri's
`cursor { xcursor-theme }` block or `XCURSOR_THEME` — this row picks the boring default
that makes the existing pointer resolve, and marks the rice as a separate later
decision. **Installed and verified 2026-08-20** (`adwaita-cursors` 50.0-1):
`/usr/share/icons/Adwaita/cursors` now exists so the `default` pointer resolves, and the
zero-delta measurement above is the expected result rather than a null one — a
compositor decodes a cursor when it first *draws* one and does not re-read the theme
without a restart, so the live delta being 0 is the point. **Still open**: the closing
canary is a *fresh* niri run with no `error loading xcursor default@24` line in
`journalctl --user -u niri.service`.


### notifications — mako (leaning), D-Bus activated not enabled

**picked** · 2026-08-27 · packages: mako gcalcli

**Measured:** **Mechanism finding 2026-08-25 (overnight): the D-Bus-activation laziness
never materializes on this desktop — kitty's startup notification integration activates
mako via a D-Bus name lookup on every session's first terminal, with zero notifications
posted** (proven: pkill mako → one kitty spawn → mako running again, `makoctl history`
empty). So mako is effectively resident from first terminal open; BUDGET's marginal
table already counts it (9.1 MB), and this explains why. No action needed — just stop
crediting activation-on-demand as a saving. **31.6 MB resident on the Omarchy desktop**
when running; ships both `mako.service` and
`/usr/share/dbus-1/services/fr.emersion.mako.service`, so **0 MB until the first
notification** if left D-Bus activated

**Raised by the author 2026-08-20 as a requirement, not a nicety**: he actively uses
notifications for **Slack alerts and upcoming Google Meet meetings**, so this is a
`02-functionality.md`-class capability and the "fail loudly, do not degrade silently"
rule applies — a notification system that is quietly not running is indistinguishable
from having no meetings. **The requirement is not the daemon, it is the whole path.** A
daemon only draws what apps send it over `org.freedesktop.Notifications`; the sources
here are Slack (Electron) and browser notifications (Google Calendar / Meet), so the
acceptance test is *those two specifically*, not `notify-send hello`. Electron and
browsers additionally need the Wayland env vars in `docs/reference-viacoffee.md` to
avoid falling back to Xwayland. **Do not `systemctl --user enable mako`** — it ships a
D-Bus service file, so leaving it activated on demand costs nothing at idle and starts
on the first notification, the same pattern the `audio` row uses for pipewire's socket
activation. Verify the first notification is not *lost* to the activation delay before
committing to that. **Config ideas already proven in the friend's setup**:
`[urgency=critical] default-timeout=0` so critical notifications never auto-dismiss —
directly serves the meeting-alert case; `[app-name=Spotify] invisible=1` for per-app
suppression; `[mode=dnd] invisible=1` driven by `makoctl mode -s dnd` for a
do-not-disturb toggle; `max-history=10` so `makoctl restore` can bring back something
dismissed by accident. **Alternatives not yet examined**: `dunst` (X11-era, widely used,
Wayland-capable), `swaync` (has a notification centre panel, heavier), or niri's own —
niri has *no* built-in notification support, so something must be installed.

**`config/mako/config` landed 2026-08-30, first line only: `on-notify=exec mpv ...`
playing a sound on every notification** — the author's own request, no new package
(`mpv` was already in the list). The `[urgency=critical]`/`[mode=dnd]`/`max-history`
ideas above are still just ideas, not yet in the file. Sound file is
`assets/sounds/notify.mp3`, checked in — a 1.3 s clip fetched with a one-off `yt-dlp`
(installed, used, then removed; the same "not part of BunnE" category as `shellcheck`).

**Debugged 2026-08-30, same day: "no sound" turned out not to be mako at all.**
Two real bugs surfaced first — mako was already running (D-Bus-activated at login)
*before* `config/mako/config` existed, so it had no `on-notify` loaded until
`makoctl reload`; this is a one-time ordering issue, not a standing one, since mako
gets D-Bus-activated fresh at every future login. Once that was fixed, `mpv` was
spawning correctly (confirmed by catching the process mid-exec and by mako's own
notification history) with **still no audible sound** — the actual cause was the
default sink, `Built-in Audio Analog Stereo`, sitting **MUTED** (`wpctl status`),
unrelated to anything this row built. `wpctl set-mute @DEFAULT_AUDIO_SINK@ 0` fixed
it. **Lesson for next time this gets "debugged": check `wpctl status` for MUTED
before suspecting mako, the config, or the sound file** — the exec pipeline can be
completely correct and still produce silence.

**Meeting alerts: a calendar poller, author's word 2026-08-27.** Not the browser — a
browser-sourced alert only fires while the browser is open, which is exactly the silent-failure
mode `02-functionality.md` warns against for this row. Mechanism not yet built: a small script
polling the calendar on a timer, firing `notify-send` (through mako, `[urgency=critical]
default-timeout=0` per the config ideas above) regardless of browser state. Still needed before
this ships for real: pick a calendar API/auth path (Google Calendar), decide the poll interval,
and write the systemd user timer — same shape as `disk-alert`.

**The browser path was tried first and confirmed broken, same day.** Author logged into a
dummy Google account on `bunne-test` and created a real Calendar event with a reminder;
nothing reached mako. Diagnosed rather than assumed: Brave's own
`content_settings.exceptions.notifications` was `{}` in `Preferences` — no site has ever been
granted notification permission in that profile. Chrome/Brave's "quiet" permission UI shows a
small address-bar icon instead of a prompt on most sites, easy to miss entirely — exactly the
silent-failure shape this row already worried about, now demonstrated rather than theorized.
Confirmed the mako half of the pipeline is fine independent of that: `notify-send -u critical`
over ssh landed in `makoctl list` immediately and the author saw both test notifications live.

**Calendar poller built and shipped, same day.** Two real architectures were on the table —
a plain ICS "secret address" URL (zero auth ceremony, `curl`+bash) vs. `gcalcli` against the
real Calendar API (one-time interactive OAuth, `gcalcli init`) — and the author picked
`gcalcli`. The deciding fact, read from Google's own ICS export behaviour: it ships recurring
events as a raw, unexpanded `RRULE`, and correctly expanding that ourselves is exactly the
fragile, fights-upstream-intent logic `CLAUDE.md`'s no-hacky-solutions rule warns against —
most real meetings recur, so a hand-rolled parser would misfire on the majority case.
`gcalcli`'s API calls return already-expanded instances.

**`gcalcli remind` is the upstream-designed integration point for this exact use case** — its
own default command is a `notify-send` invocation. Read from `gcal.py`'s `Remind()` before
trusting it: `--use-reminders` honors each event's *own* configured lead time (matching what
the browser would have shown) instead of one fixed window, but the function has **no de-dup of
its own** — once an event's reminder threshold passes, every subsequent poll re-matches it
until the event starts. So `config/systemd/user/calendar-poll` (the executable, same
no-extension convention as `disk-usage-alert`) re-invokes itself as the `remind` callback
(`--notify`) and does the de-dup there, keyed on the event's own `"time  title"` text — stable
and unique per instance, since a recurring event's occurrences differ in start time even when
the title repeats. State lives at `$XDG_STATE_HOME/bunne/calendar-notified` (a plain
tab-separated file, pruned to the last 2h on every run so it never grows). The search window is
1440 minutes (24h) — that argument only bounds how far ahead candidate events are fetched, not
the firing threshold, and needs to be at least as large as the longest popup reminder lead time
anyone might set. Polls every minute (`OnCalendar=minutely`) — cheap since it's `Type=oneshot`
(zero resident RAM between polls) and de-dup means a tight interval only affects *latency*
between a reminder threshold passing and the notification actually firing, not correctness.

**Auth is deliberately manual, same `secrets-bootstrap` policy as everything else here**: the
author runs `gcalcli init` once, interactively (opens a browser, OAuth flow, token cached at
`$XDG_DATA_HOME/gcalcli/oauth`) — nothing in this repo automates fetching or storing that
token. `install.d/88-calendar-poll.sh` enables the timer unconditionally and only warns, once,
if that file is missing — expected absence on a fresh install, not a failure (`CLAUDE.md`'s
"quiet, once, state the reason" rule); the script's own auth check does the same at every poll
via a stderr line, visible in `journalctl --user -u calendar-poll` rather than spamming a
notification for a state that's expected right after install.

**Verified on `bunne-test`, not just read**: the no-auth path exits 0 with the one-line stderr
message (checked directly and via a real scheduled timer tick, not just a manual invocation);
the `--notify` de-dup path was driven with two simulated events — both landed in `makoctl list`
as `app-name=gcalcli, urgency=critical`, both got written to the state file, and an identical
rerun produced zero new notifications and zero new state-file lines. `gcalcli` itself is
installed (AUR, `python-google-api-python-client` + friends) and `calendar-poll.timer` is
enabled and scheduled. **Confirmed genuinely unattended, same day**: `journalctl --user -u
calendar-poll.service` shows real minute-by-minute ticks logging the auth message on their
own, and — because the check happened to span a reboot (an unrelated network blip on
`bunne-test`) — confirmed the timer re-arms itself via `Persistent=true` with zero manual
intervention: ticks resumed within a minute of boot without re-running `88-calendar-poll.sh`.
**Not yet verified**: a real event actually firing through `gcalcli remind` end-to-end, since
that needs `gcalcli init`'s interactive OAuth step, which is the author's to run.

**Deferred, author's word 2026-08-27: "this seems like a lot of effort... I don't want to debug
the google developer account secret issue."** Before deferring, chased down whether there was a
genuine middle ground — the author's own observation that Omarchy delivers Calendar-style
notifications without visibly being on `calendar.google.com` — via an Opus subagent doing
primary-source research rather than guessing. **Refuted, not confirmed**: Google's own
troubleshooting docs say outright "To display notifications, open Google Calendar" and Gmail's
say the same ("after you sign in to Gmail *and open it in your browser*") — both use plain
in-page `Notifications` API calls, not a Service Worker push subscription, so there is no
zero-setup path through the browser. The Omarchy behavior is almost certainly a pinned/background
Calendar or Gmail tab that's been open since login, which Google's docs confirm works unfocused
or minimized — not evidence of push. **Two side-findings worth keeping**: the earlier failed
browser test had a second, independent cause beyond the missing permission grant — Brave ships
"Use Google services for push messaging" off by default, so even a genuine push site would have
failed the same way; and the XWayland worry from `jupyter-in-neovim`-adjacent reasoning doesn't
apply here — Chromium's Linux notification path (`notification_platform_bridge_linux.cc`) talks
straight to `org.freedesktop.Notifications`, the same interface `notify-send` already proved
reaches mako, no X11 involved. **A no-OAuth alternative exists and was deliberately not built**:
Calendar's "Secret address in iCal format" needs no Google Cloud project at all, only a private
URL kept out of the repo — but it inherits this row's own original objection to hand-rolled ICS
parsing (`RRULE` expansion for recurring events) and has three unverified caveats (possible
server-side cache latency on fetch, `VALARM` often absent for a calendar's *default* reminder
time rather than a per-event one, Workspace admins can disable the secret address) that would
need resolving before it's worth building. **Current state: the mechanism ships, dormant.**
`calendar-poll.timer` stays enabled — `gcalcli`'s own auth check exits 0 with a quiet log line
every minute, costing nothing (`Type=oneshot`) — and needs only `gcalcli init` to switch on if
the author changes his mind. Slack alerts, the row's other named requirement, are unaffected:
Slack's own Electron notifications go through the same already-proven D-Bus path directly,
no poller involved.

**Un-deferred 2026-08-27, and it costs nothing: the Omarchy hypothesis above is now confirmed
by direct evidence, so bunne gets meeting alerts through the browser with no OAuth at all.**
Read straight out of the Omarchy desktop's own Brave profile
(`Default/Preferences` → `profile.content_settings.exceptions.notifications`):
`"https://calendar.google.com:443,*": {"setting": 1}`, and `Default/Sessions/Session_*`
contains a live `calendar.google.com` tab. That is the whole mechanism — a granted permission
plus an open tab — exactly as the research predicted, and it is why the author sees alerts on
that machine and not on `bunne-test`, whose profile reads `notifications: {}`, no session
restore, no pinned tabs. **So the shipped answer for meeting alerts is three manual browser
steps, not a poller**: open `calendar.google.com` in Brave and click *Allow* on the permission
prompt; pin the tab; set *Settings → Get started → On startup → Continue where you left off*.
All three are supported Brave settings a person clicks — nothing here writes them, because
Chromium validates its own prefs and a permission grant is a consent action by design, so
scripting it would be exactly the against-the-grain hack `no-hacky-solutions` rejects. Same
category as `gcalcli init` and the wifi credentials: manual by policy, documented here.
**The honest cost, stated because this row originally rejected the browser path for it**: no
Brave running, or the tab closed, means no alert and no warning — the silent failure
`02-functionality.md` names. The poller is the fix for that and still needs the Google Cloud
OAuth client the author declined, so it stays enabled and dormant as before. The trade the
author took is a browser tab against a developer account.


### portal — xdg-desktop-portal-gnome + `portals.conf`

**picked** · 2026-08-20 · packages: xdg-desktop-portal-gnome pipewire-jack

**Measured:** **`AvailableSourceTypes` = 7** (MONITOR+WINDOW+VIRTUAL),
`AvailableCursorModes` = 7; **idle cost +46.8 MB** (niri session 738.1 MB with it vs
691.3 MB without, same machine, same boot conditions); the portal processes themselves
are **0 MB at idle** — **WRONG, corrected 2026-08-21**: in a live session they are
**96.1 MB across three processes** (`xdg-desktop-portal` 19.2, `-gnome` 45.9, `-gtk`
31.0). The original figure was taken before anything had *used* a portal; once activated
they stay resident. **`-gtk` was the `;gtk` fallback in our own `portals.conf` and
nobody chose it — dropped 2026-08-21, `portals.conf` is now `default=gnome`.** Re-probed
after the change: `AvailableSourceTypes` and `AvailableCursorModes` both still **7**,
and `xdg-desktop-portal-gtk` is gone — **30.1 MB freed**. **CORRECTED SAME DAY — the 30
MB is not recoverable and the config change does not do what it looked like it did.**
`xdg-desktop-portal-gtk` **restarted 12 minutes later** at 32.2 MB. `[preferred]
default=` sets *priority*, not exclusivity: when any app requests an interface GNOME
does not implement, the frontend starts whichever backend does. And it **cannot be
uninstalled** — `pacman -Rp` fails because `gtk4`, **`niri` itself**, and
`xdg-desktop-portal-gnome` all require it. The config change is still correct (GNOME
should be preferred) but it frees nothing. Interfaces GTK uniquely provides: `Email`
(nothing here uses it) and **`Inhibit`** (prevents idle/sleep) — the latter still worth
re-testing once lock/idle is decided. Native Wayland apps use
`zwp_idle_inhibit_manager_v1` directly, but sandboxed ones use the portal — **untestable
until the lock/idle slot is decided; re-test then by playing a video and confirming the
screen does not blank**. See [`benchmarks/3.6`](benchmarks/3.6.session-residents.md)

niri implements `org.gnome.Mutter.ScreenCast` natively, so the GNOME portal is its
backend of choice. **Needs `~/.config/xdg-desktop-portal/portals.conf` with `[preferred]
default=gnome;gtk;`** — niri sets `XDG_CURRENT_DESKTOP=niri` and appears in *no*
backend's `UseIn` list, so without this nothing serves it. **Measured, not argued**
(`~/t-portal`, 2026-08-20): the D-Bus probe returns source-types bitmask **7**, i.e.
whole-monitor, **per-window** and virtual capture all work. That is what kills the lean
alternative — `xdg-desktop-portal-wlr` is 122 KiB and 3 packages but works over
`zwlr_screencopy`, which is **output-only**, so it would trade away window capture and
niri's dynamic-cast for disk that this repo explicitly does not count. **The 464 MiB /
147-package figure is real but is the wrong objection.** What actually stays resident
after a fresh niri restart is: `pipewire` 11.9 + `wireplumber` 23.8 = **35.7 MB**, and
`at-spi2-core` **~14 MB** across two processes. The portal binaries are **not resident
at all** — D-Bus activated, they exit after serving. Of that, **only at-spi is genuinely
new**: the audio stack would have warmed on first sound anyway (the `audio` row measured
warm audio at 34.9 MB, versus 35.7 MB here — the same number). **But note the real
regression the `audio` row should cross-reference: the portal makes audio warm from
login instead of socket-activated-on-demand**, so the "0 MB cold" property that row
celebrates no longer holds on a desktop session. at-spi arrives by **D-Bus activation,
not autostart** — its `/etc/xdg/autostart/at-spi-dbus-bus.desktop` is gated
`OnlyShowIn=GNOME;Unity;` and correctly does not fire under niri; the GTK portal
requests the a11y bus during GTK init and it then stays. **`localsearch`, the file
indexer at the bottom of the dependency chain, never runs** — same `OnlyShowIn` gate —
so `ffmpeg` and everything beneath it is inert disk. **The dependency chain is genuinely
absurd and worth stating**: portal -> `nautilus` (file picker) -> `localsearch`
(indexer) -> `ffmpeg` (video metadata) -> `jack` (ffmpeg links `libjack.so`). **That
forces `pipewire-jack`, reversing the `audio` row's "skip pipewire-jack"** — the choice
is between `jack2` (a second, standalone sound server next to PipeWire) and
`pipewire-jack` (shim libraries `/usr/lib/libjack.so.0` routing into the PipeWire
already running, no daemon). Take `pipewire-jack`. **Installer note: this appears as an
interactive provider prompt**, so a `--noconfirm` install would silently take provider 1
and could land `jack2`; the installer must pass the provider explicitly. **The residual
argument against this row is priority 1, not priority 2**: 147 packages is 147 things
that update and can break, which is maintenance surface rather than RAM. Accepted
because screen sharing is a stated requirement and the idle cost is ~14 MB.


### browser — brave-bin

**picked** · 2026-08-20 · packages: brave-bin

**Measured:** **540 MB PSS across 9 processes** (one window, two tabs, scratch profile)
**plus 74 MB of i915 GEM buffers**; the GPU process alone is 130 MB. **Hardware
accelerated — proven, not read off a status page**: `/proc/<gpu-pid>/fdinfo/<renderD128
fd>` reports `drm-driver: i915` and `drm-engine-render: 34.2 ms` of real GPU time.
**Hardware video decode confirmed separately: 204 ms of `drm-engine-video`** on a played
video

**The author's stated favourite and a hard requirement** (2026-08-20): no bake-off, no
measurement, and `03-alternatives.md` already ranked it first. Take **`brave-bin` from
the AUR**, not the predecessor's `curl dl.brave.com/install.sh` + `sudo ./install.sh`
route in `scripts/brave-with-gpu.sh` — that script predates the AUR package the desktop
actually runs today (`brave-bin 1:1.93.136-1`), and piping a vendor script to root puts
a 448 MiB payload outside pacman's knowledge. **Zero idle cost**, verified: everything
`pacman -Ql brave-bin` installs outside `/opt` is one launcher, one `.desktop` and icons
— no service, no autostart, no cron entry (the `cron/brave-browser` file it ships stays
inside `/opt` and is never wired into `/etc/cron.*`). **The
`/usr/local/bin/brave-wayland` wrapper is dead code and is not ported** — verified by
reading `/usr/bin/brave` on the desktop: the launcher already sources
`${XDG_CONFIG_HOME}/brave-flags.conf` and appends every non-comment line, and the
shipped `.desktop` execs plain `brave`, so the wrapper has not been on the path of a
single launch. This confirms `03-alternatives.md`'s suspicion by reading the source
rather than assuming it. **The GPU question is closed, and the answer is that no flags
are needed at all** (measured on `bunne-test` under niri, 2026-08-20, `~/t-brave`, with
**no `brave-flags.conf` present**): Brave passes **`--ozone-platform=wayland` to its own
child processes unprompted** and comes up as a native Wayland client (`niri msg windows`
shows App ID `brave-browser`; no Xwayland process exists even though `xorg-xwayland` is
installed, so it chose Wayland rather than falling back to it). It also picks its render
node by itself — `--render-node-override=/dev/dri/renderD128`. **So the Omarchy hack is
dead: it was `--ozone-platform=wayland`, and upstream now does that by itself.
`~/.config/brave-flags.conf` ships empty/absent** — the repo restates no correct
default. Acceleration is proven at the kernel interface rather than from
`chrome://gpu`'s self-report: the GPU process holds six fds on `/dev/dri/renderD128`,
whose `fdinfo` reports `drm-driver: i915` and non-zero `drm-engine-render`. **Note
`renderD128` is the *Intel* iGPU** (`0000:00:02.0`) — render-node numbering is the
reverse of card numbering here (`card0`=NVIDIA, `renderD128`=Intel), which is worth
knowing before reading any of these numbers. Brave never opens `/dev/nvidia*` on this
hybrid laptop, so `nvidia-smi` correctly lists no brave process. **One cost that finding
exposes**: the GPU process still maps `libnvidia-gpucomp` (24.8 MB) +
`libnvidia-eglcore` (8.1 MB) = **32.9 MB of PSS for a GPU it never touches**, because
glvnd dlopens every vendor in `/usr/share/glvnd/egl_vendor.d/` (`10_nvidia.json`,
`50_mesa.json`) during EGL init. That is a hybrid-laptop artifact only — on the
NVIDIA-only daily driver those libraries are the ones actually doing the work — so it is
recorded, not fixed.


### browser-fallback — chromium

**picked** · 2026-08-20 · packages: chromium

**Measured:** — (author's choice; 0 daemons, 0 autostart, no shared deps with brave-bin)

**Author's choice, 2026-08-20**: a second browser exists only for sites Brave cannot
load, so the requirement is "basic and small", not "different engine". `extra/chromium`
is the plain upstream build Brave forks, so a page that misbehaves under Brave's shields
renders in the same engine without them — the usual cause. Costs nothing until launched.
Its own slot rather than a second `picked` row under `browser`, so the ledger keeps one
winner per slot and the installer's `awk` still yields both packages. Firefox was
`03-alternatives.md`'s #3 and is not installed; a genuinely different engine would be
the stronger backup on paper, but it is a second stack to configure and theme for
something opened a handful of times a year. The risk that buys: a site broken by
*Chromium* rather than by Brave is broken in both. Revisit only if that happens.


### disk-unlock — manual LUKS2 passphrase at boot, autologin after it

**picked** · 2026-08-21 · packages: —

**Measured:** — (author's decision; the security difference is categorical, not a
measurement)

No packages — `cryptsetup` is already present. **Settled by the author 2026-08-21, and
it fixes the auth model for the whole machine.** `02-functionality.md` C2 was tightened
the same day to require **exactly one** credential prompt — not zero, not two — on the
author's reasoning that *zero prompts is not a fast login, it is no authentication*.
This row spends that one prompt on the **LUKS passphrase**, which means the disk never
decrypts without a human present. Everything after it is unattended: the display manager
may log straight in, and the second password Arch asks for by default is the one C2
removes. Note this is not a lax setup by mainstream standards but a match for it — macOS
FileVault makes the login screen *be* the disk unlock, and Windows lets the TPM unlock
silently and asks once at login; both total one prompt. Arch's LUKS-plus-DM default is
the outlier that asks twice. **Consequence for other slots**: `display-manager` may take
a zero-prompt login (both its top two candidates do) *only* because this row holds the
prompt — if this row ever changes, that one has to be reopened with it.


### disk-unlock — TPM2 auto-unlock (`systemd-cryptenroll`)

**rejected** · 2026-08-21 · packages: —

**Measured:** —

**Rejected by the author 2026-08-21**, closing an item that had been open since
2026-08-19 as a way to make boot faster *and* benchmarkable. In his words: he will not
take *a permanent security hole to save 15 seconds of dev time on the OS*. The mechanism
is sound and is what Windows BitLocker does — the key is sealed to TPM PCR state, so
pulling the drive is useless — but it changes what the remaining password protects:
**the disk then decrypts on any power-on**, so the prompt guards the session rather than
the data, and evil-maid and cold-boot attacks come back into scope. **The only thing it
genuinely buys is unattended reboot**, since manual LUKS stops a remote or SSH-initiated
reboot dead at the passphrase prompt. Dismissed on the facts of this project rather than
in principle: the test laptop is physically next to the author, and `bunne-test` is
reachable by hand. **Do not re-derive this from the boot numbers.** TPM2 will keep
looking attractive every time boot time is measured, because it removes the one
unbenchmarkable wait in the boot path (`resume.md`: the `kernel` phase measured 30.026s
and 5.988s on consecutive boots purely from passphrase-typing variance). That is a
measurement inconvenience, not an argument — use `userspace`/`graphical.target` and
leave this alone. **Also forbidden in combination**: TPM2 plus the autologin in the
picked row above would leave a cold, stolen machine booting straight into an unlocked
desktop with no authentication anywhere, which C2 rules out outright. Revisit only if
unattended remote reboot becomes a stated requirement, and argue it against the
comparison table in `03-alternatives.md`'s display-manager section.


### benchmark-unlock — random keyfile in a second LUKS keyslot, baked into the initramfs

**picked** · 2026-08-21 · packages: —

**Measured:** **first honest total boot number in the project: 17.406s** (4.820 firmware
+ 1.300 loader + **6.477 kernel** + 4.807 userspace), against a `kernel` phase that read
30.026s and 5.988s on consecutive passphrase boots — i.e. the metric went from unusable
to comparable. **Round trip exercised on hardware the same day**: keyslots 1→2, key
verified inside *both* initramfs images, reboot silent; then `remove`, reboot,
**passphrase prompt returned**

**`bunne-test` only, temporary, and it must be removed — see the deadline below.** The
problem it solves: the LUKS passphrase wait sits inside the `kernel` phase, so total
boot time is human typing speed (30.026s and 5.988s on consecutive boots, `resume.md`).
**Rejected the obvious fix of removing encryption for the build**, because dm-crypt is
in the I/O path for everything downstream — initramfs, kernel load, userspace start, app
cold starts — so an unencrypted test box would produce numbers that describe a machine
BunnE never ships, and the gap would not surface until Phase 5 put LUKS back. A keyfile
keeps every number representative while removing only the typing. **Mechanism, read from
`/usr/lib/initcpio/hooks/encrypt` rather than recalled**: `ckeyfile` defaults to
`/crypto_keyfile.bin`, so a keyfile at that path in `FILES=` is used with no kernel
parameter; if it cannot be opened the hook prints `Keyfile could not be opened.
Reverting to passphrase.` (line 38), so **this cannot lock the machine out**; and the
hook `rm -f`s the keyfile from the initramfs tmpfs after unlocking (line 168). Setup:
`cryptsetup luksAddKey` a `dd if=/dev/urandom` keyfile, add it to `FILES=`, `mkinitcpio
-P`. **Accepted cost, stated plainly: the disk is effectively unencrypted at rest while
this is in place.** `/boot` *is* the ESP on this layout (see the `bootloader` row's
limine/ext4 finding), so the initramfs is on unencrypted FAT32 and anyone holding the
laptop can read the key. The author accepted this explicitly for a disposable test box
at home. **It buys nothing on the desktop and must never reach it.** **The removal path
is proven, not assumed** — exercised end to end on 2026-08-21 (add → silent boot →
remove → passphrase boot), which is the whole reason it was written as one script with
an explicit `remove` subcommand rather than improvised at Phase 6. This repo's own rule
is that an unexercised safety mechanism is broken until demonstrated (`snapper rollback`
is the cautionary case); this one has now been demonstrated while the laptop was still
disposable, which is the only time the test is cheap. The script lives at `~/t-keyfile`
on `bunne-test` with `status`/`add`/`remove`, is `shellcheck`-clean, and asserts the key
is inside **each** initramfs image rather than trusting the keyslot count — the two come
apart, and when they do the keyslot check passes while boot still prompts. **The canary
is always the boot itself, never the config.**



**Operational consequence, spelled out 2026-08-25 because a whole session missed it:**
this row is what makes **`ssh bunne-test sudo reboot` a free, unattended action**. Re-proved
rather than assumed on 2026-08-25 — `crypto_keyfile.bin` is present in the deployed
initramfs, `cryptsetup luksOpen --test-passphrase --key-file` succeeds against
`/dev/nvme0n1p7`, `luksDump` shows two keyslots, and the boot's whole kernel phase is
5.3 s with no typing in it. The 2026-08-25 evening session instead believed the box needed
the author at the keyboard to unlock, and that belief shaped real decisions: boot-path
edits recorded as "not reboot-verified" when verification was one ssh command away, and
`benchmarks/4.27` justifying its loopback reproduction partly on a constraint that did not
exist. **The kernel cmdline is not the tell** — it reads `cryptdevice=UUID=...` exactly as
a passphrase setup would; the keyfile in the initramfs is the whole difference.

The only thing on this box that still genuinely needs a human is the **Limine menu
keypress**, since selecting a snapshot happens before any OS is running.

### boot-splash — Plymouth, script module, the flower-thief bunny background

**picked** · 2026-08-27 · packages: plymouth

**Measured:** genuine reboot-to-ssh wall time, boot-`id`-verified so a stale ssh connection
can't be mistaken for a real reboot: baseline (no Plymouth) **27.6s, 27.6s** (n=2);
Plymouth+`splash` active **27.6s, 28.6s** (n=2). Delta ~0–1s, inside this method's own
measurement noise (~2s polling granularity). `systemd-analyze blame`: Plymouth's four units
sum to **476ms total** (206+206+38+26ms), and none of it dominates the boot.

**Author asked for a graphic on the login screen and lock screen ("it's fine if you use some
of the wallpaper rabbits"), 2026-08-27.** On a getty-autologin machine (`display-manager`)
there is no separate username/password screen — the only pre-desktop moment is the LUKS
passphrase prompt, which is what this row themes. (The lock screen half shipped separately,
same day — see `lock-idle`.)

**The original objection to Plymouth (`docs/02-functionality.md`, `docs/03-alternatives.md`:
"~0.8s... to hide text that is fine to look at") turned out to be `systemd-analyze`-derived
from a completely different machine** (the old SDDM-based Omarchy box, `docs/01-assessment.md`)
— exactly the kind of unit-time-sum this repo has already been burned by elsewhere
(`timeout`'s own boot-menu measurement: "systemd-analyze cannot see the menu wait at all").
Author's own instinct, stated before the retest: *"i dont believe it would be that
expensive."* Retested properly on `bunne-test` with real wall-clock A/B reboots rather than
trusting the old number, and it wasn't.

**How it's wired**: `plymouth` added to `HOOKS=` in `/etc/mkinitcpio.conf` (after
`consolefont`, before `block` — needs `kms` already loaded, needs to be running before
`encrypt` prompts, confirmed by reading `/usr/lib/initcpio/hooks/encrypt` on the box: it
calls `plymouth ask-for-password` whenever `plymouth --ping` succeeds, and falls back to a
plain prompt otherwise — so a broken or absent Plymouth degrades to today's behavior, not to
an unbootable machine). `splash` added to the kernel cmdline via `/etc/kernel/cmdline` (the
higher-priority fallback `limine-entry-tool` reads before `/proc/cmdline` — **not** the
`KERNEL_CMDLINE[default]+=` drop-in mechanism the tool's own docs suggest, which turned out
to be a real trap: `+=` only appends to an *already-set* `KERNEL_CMDLINE[default]`, and since
this box relies entirely on the `/proc/cmdline` auto-detect fallback, a lone `+=splash` drop-in
silently became the **entire** cmdline — dropping `cryptdevice=`/`root=`/`rootflags=`
outright. Caught by reading the regenerated `limine.conf` before rebooting, never actually
booted; `scripts/check-limine.sh` still passed on the broken file since it only checks
`default_entry` resolution and `boot()` file existence, not cmdline sanity, which this row's
mistake is why that gap is worth naming).

**The theme**: `assets/plymouth/bunne/`, `ModuleName=script` (Plymouth's own scriptable
module, `/usr/lib/plymouth/script.so`) — adapted from Arch's stock example theme at
`/usr/share/plymouth/themes/script/script.script`, with the pulsing-logo animation and
progress bar dropped, keeping only a full-screen background image and the password dialog.
`box.png`/`lock.png`/`entry.png`/`bullet.png` are Arch's own stock UI-chrome assets, copied
verbatim, not hand-drawn. Deployed to `/usr/share/plymouth/themes/bunny/` — **not**
`/usr/local/share`, despite that being the more FHS-correct place for non-package content:
`plymouthd`'s theme search path is hardcoded to `/usr/share/plymouth/themes/` (`strings` on
the binary confirms no `/usr/local` variant), so `/usr/local/share` silently finds nothing.

**Background image changed 2026-08-27, author's word** ("i prefer neon-hare for the default
background, and flower-thief as the login screen" — the desktop-wallpaper half of that request
is `wallpaper`'s job, this row is the "login screen" half): was `15-neon-hare-by-omar-ramadan.jpg`
(the same image `lock-idle`'s swaylock still uses), now `04-flower-thief-by-gary-bendig.jpg`,
straight `magick` format conversion (both are already the target 1920x1080, no resize) to
`assets/plymouth/bunne/background.png` — Plymouth's image loader is not confirmed to support
JPEG. Redeployed to `bunne-test` via `install.d/45-plymouth.sh`'s existing `cmp`-checked copy;
no logic change needed, only the source file. Not yet reboot-verified visually — that needs the
author's own eyes on the real LUKS prompt.

**Verified, not just assumed**: `scripts/check-limine.sh` passed on the regenerated
`limine.conf` before every reboot; `plymouth-debug.log` (kernel param `plymouth.debug`, one
test boot only, removed from the shipped cmdline) shows `parsing script file` →
`executing script file` with no error between them; zero failed units on every boot; the
`encrypt` hook's own Plymouth integration ran (`plymouth ask-for-password`, LUKS auto-unlocked
via `benchmark-unlock`'s keyfile as normal).

**Pixel rendering verified by the author, 2026-08-27 — the thing ssh cannot check.** A live
preview (`plymouthd --tty=tty3`, no reboot) confirmed the background image renders; that alone
wasn't proof the password dialog worked, since nothing was actually asking for a password. The
real test: `benchmark-unlock`'s keyfile was temporarily removed from `FILES=` (not the keyslot
itself — fully reversible) to force a genuine interactive LUKS prompt, and the author typed
their real passphrase against the themed screen. **It worked** — background, box, lock icon,
entry field, all legible. A username label was added the same session (`Image.Text`, `@USER@`
templated at install time by this step, same convention as `60-autologin.sh` — never a
hardcoded name) and verified the same way, on a second real passphrase entry.

**One real bug caught in the process, worth remembering:** the first "it's just black" report
turned out to be `benchmark-unlock` itself — the keyfile auto-unlocks LUKS near-instantly, so
the whole splash-to-quit window was too brief to register before the screen flipped to desktop.
Not a rendering bug; a property of the test box's own unattended-reboot mechanism, which won't
exist on a real install with a real passphrase.

**`bootloader_config.plymouth` is now set in both archinstall JSONs, 2026-08-28, author's
ask.** archinstall's own option does the plumbing — straps `plymouth`, inserts the hook,
adds `quiet` and `splash` to the kernel command line, runs `mkinitcpio -P`
(`lib/installer.py:1760-1781`) — and `45-plymouth.sh` is left doing only the part that is
actually a decision: the bunny theme files and `plymouth-set-default-theme bunny`.

**The real gain is the first boot.** Until now the splash appeared only after `install.sh`
had run, so the very first boot of a fresh machine — the one where you sit through a LUKS
prompt on a machine you have never seen work — was unthemed. Now it is themed before this
repo has executed a single line.

**The JSON names `text`, which is not the theme this machine runs, and that needs saying
out loud** because a config file stating a value it does not use is normally a defect.
`PlymouthTheme` is a closed ten-value enum and an unknown value `sys.exit(1)`s the whole
installer, so `bunny` cannot go in that field at all — any value there is a placeholder
overwritten seconds later. `text` was picked over the graphical stock themes for a
specific reason: it is the one that *looks wrong*. If the bunny theme ever fails to
install, a plain text splash is noticed immediately, where `spinner` or `bgrt` would look
deliberate and hide the failure. Fail loudly, do not degrade silently.

**The hook may land in a different place than this repo chose, and it is left there.**
archinstall inserts `plymouth` before `encrypt` (after `block`); `45-plymouth.sh` inserts
after `consolefont` (before `block`). Both satisfy the only two constraints that matter —
`kms` already loaded, and running before `encrypt` prompts — so whichever ran first wins
rather than the step fighting it. archinstall's five-anchor fallback is in fact sturdier
than this repo's single `consolefont` sed, which hard-requires a hook Arch could rename.

**The one cost, stated:** archinstall runs `plymouth-set-default-theme text` and a full
`mkinitcpio -P` for a theme that is replaced minutes later, so a fresh install rebuilds the
initramfs once more than strictly needed. Seconds, once, at install time only.

### silent-boot — `quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3`

**picked** · 2026-08-27 · packages: —

**Measured:** none of the four `systemd-analyze` phases (firmware/loader/kernel/userspace) do
any less *work* with these set — confirmed by reading what each parameter does before shipping
it, not assumed. This is a text-volume change, not a work change, so it does not close the
`boot-splash` black-screen gap; it just stops that gap looking like a wall of kernel/systemd log
lines. The Arch wiki's own **Silent boot** article claims a real (if system-dependent) speedup
too — *"the slow performance of the TTY is actually a bottleneck, and so less output means
faster booting"* — unquantified here, not the reason this shipped.

**Raised 2026-08-27**, during the `boot-splash` verification: the author watched the actual gap
between Plymouth quitting and niri painting and called it "ugly" — raw console text on a screen
that had just shown a themed splash. Rather than closing the gap (a real boot-sequencing change,
proposed and **declined** — see below), this suppresses what's visible during it.

**Investigated as part of the same question: is there a boot speedup we're leaving on the
table?** Read the Arch wiki's **Improving performance/Boot process** article in full (the
author pasted it after the wiki's Anubis anti-bot layer blocked every fetch attempt) and checked
every technique against this box's actual configuration rather than applying any of it on
faith:

- **`quiet`/loglevel params — shipped.** The only zero-risk, zero-cost item on the list.
- **lz4 instead of zstd compression** — built a real lz4 image to compare: **35.75 MB vs the
  current zstd's 28.6 MB, 25% bigger**, not "slightly" as the article undersells it. The
  `kernel` boot phase here is dominated by LUKS-unlock/typing wait, not decompression, so any
  win would likely sit inside measurement noise — the same story as `boot-splash`'s own cost
  question. Not pursued.
- **Omit mkinitcpio's `base` hook** — already checked and rejected (`/usr/lib/initcpio/install/base`'s
  own help text: *"DO NOT remove this hook unless you know what you're doing"* — it provides
  `busybox`, `kmod`, `blkid`, `mount`/`switch_root`, and the initramfs's own `/init`).
- **Btrfs root doesn't need fsck; drop the `fsck` hook** — checked and found already a non-issue:
  `systemd-fsck-root.service` is `inactive (dead)`, root was never being fscked in the first
  place. The initramfs `fsck` hook itself has no runtime script at all
  (`/usr/lib/initcpio/hooks/fsck` doesn't exist) — it only bundles the `fsck` binary at build
  time. The one real fsck cost (37ms) is `systemd-fsck@...` on the small vfat ESP, unrelated to
  either hook, and worth keeping.
- **`rootflags=rw` + drop the fstab root entry, to skip `systemd-remount-fs.service`** — `rw` is
  already in both the cmdline and fstab; the service still runs as a 52ms formality regardless.
  Removing the fstab entry to chase that trades away a single source of truth for mount options,
  for under a tenth of a second. Not pursued.
- **Staggered spin-up (`libahci.ignore_sss=1`)** — `dmesg | grep SSS` is empty on this box (NVMe,
  not SATA/AHCI spinning disks the feature targets). Nothing to disable.
- **`/home` as `noauto,x-systemd.automount`** — the article's own caveat: "may not be worth it."
  `@home` is already its own top-level btrfs subvolume, not the separate-physical-disk case this
  targets.
- **Running without an initramfs entirely** — ruled out on two independent, unrelated grounds:
  LUKS needs initramfs userspace tooling regardless of kernel version, and NVMe isn't in the
  built-in-driver list a no-initramfs boot would need (only virtio/SATA/AHCI are).
- **A different bootloader (systemd-boot, EFI stub)** — would mean losing Limine's
  snapshot-boot-menu integration (`snapshot-boot-entries`), which the whole recovery story
  depends on. Not a real option here.
- **Custom kernel compile, Booster, microcode minimization** — all gated behind "running without
  initramfs" or a from-scratch kernel build (`Booster` also isn't `limine-mkinitcpio-hook`-integrated,
  which this repo's entire boot-menu/snapshot toolchain assumes); none apply without a much
  bigger architectural change than the boot-time question justifies.

**Declined, on the author's own word: keeping Plymouth up until niri actually paints, instead of
quitting at `graphical.target`.** Explained clearly as a pure cosmetic change (same total
wall-clock either way, done as an event-driven trigger rather than a polling loop) with a real
*correctness* risk instead of a speed one — un-gating `getty@tty1.service` from
`plymouth-quit-wait.service` and adding an independent trigger to quit Plymouth once niri is
ready means a failed trigger leaves Plymouth hanging forever rather than quitting. `CLAUDE.md`'s
own priority order (fast beats pretty when they conflict) plus that risk profile was reason
enough not to build it today.

### shell-startup — leave `/etc/profile.d/vapoursynth.sh` alone; fix tier 2 and 3 instead

**rejected** · 2026-08-21 · packages: —

**Measured:** `/etc/profile` **571.4 ms** desktop / 75.2 ms laptop, of which
**`vapoursynth.sh` is 460.1 ms** / 63.8 ms. **Paid once per session login, not per
terminal** — corrected after checking alacritty's shell children (`argv[0]` has no
leading `-`) and kitty's source

**`rejected` — the author's call, and he was right to push back.** The candidate was
`NoExtract = etc/profile.d/vapoursynth.sh` in `/etc/pacman.conf`; the mechanism works
and was tested, but shipping it does not survive scrutiny. **(1) It violates this repo's
own rules**: `CLAUDE.md` says unsurprising beats clever and forbids silent degradation,
and NoExtract leaves a file absent from a package that still claims to own it, with the
cause in a config nobody would think to check — anyone debugging `VSSCRIPT_PATH` later
has no thread to pull, and `pacman -Qkk` will report phantom corruption. **(2) The
headline 460 ms is the worst case on the oldest machine.** A fresh install — what BunnE
actually produces — pays **64 ms**; the desktop's 460 ms comes from years of accumulated
`site-packages`. The installer would ship a permanent system-wide hack to save 64 ms at
install time. **(3) The arithmetic is against it**: ~64 ms once per login is ~25 s/year,
against `starship` at 33.8 ms × every prompt (~40 min/year) and `mise` at 117 ms × every
terminal (~14 min/year) — both in files BunnE writes from scratch, needing no hack at
all. **The dramatic finding was the least valuable one and the only one demanding
cleverness.** **Uninstalling is not the alternative**, though it was the obvious
question: `pacman -Rp vapoursynth` fails — hard dependency of both `ffmpeg` and `mpv` —
and `-Rdd` would leave a knowingly broken dependency graph, which is worse than the
thing it replaces. Curiously **nothing links `libvapoursynth`** (not ffmpeg, not
libavformat, not mpv), so this is an over-declared dependency, which is a packaging bug
rather than ours to route around. **The durable fix is upstream**: a `profile.d` script
that forks a Python interpreter on every login to print a constant belongs in an Arch
bug report, where fixing it helps everyone instead of one machine. **Left as-is
deliberately, with the measurement recorded** so nobody re-derives it. Original
reasoning follows.
([`benchmarks/3.4.shell-startup.md`](benchmarks/3.4.shell-startup.md)). **The project's
first real priority-2a finding, and RAM-invisible**: it costs nothing at idle, so no
measurement this project had ever taken could see it. **Severity corrected the same day
— this is per *login*, not per terminal.** Graphical terminals start interactive
*non-login* shells, which never read `/etc/profile`: verified on the running desktop
(alacritty's bash children have `argv[0] = /usr/bin/bash`, no leading hyphen, and
inherit `VSSCRIPT_PATH` from the session) and in kitty's own `child.py`, where the
login-shell prefix is gated `is_macos and self.is_default_shell` — **so the alacritty →
kitty swap adds no regression here**. It still costs 571 ms of C2's `power-on → usable
desktop` path, which is worth one config line. `/etc/profile.d/vapoursynth.sh` is 49
bytes — `export VSSCRIPT_PATH=$(vapoursynth get-vsscript)` — which forks a
**Python-backed binary on every login shell** to print a constant path. It gets *worse*
on a well-used data-science box, because the desktop's larger `site-packages` is exactly
why it costs 465 ms there and 64 ms on the fresh laptop. **BunnE ships this by default
unless stopped**: `vapoursynth` is `Install Reason: dependency`, `Required By: ffmpeg
mpv`, and **mpv is the picked video player**, so the chain is mpv → ffmpeg →
vapoursynth, three levels below anything anyone chose. **Reassessing ffmpeg is not the
answer** (author's question, 2026-08-21): ffmpeg is not a ledger choice and is not
avoidable — on `bunne-test` it arrived by a completely separate route already recorded
in the `portal` row (portal → nautilus → localsearch → ffmpeg), so dropping mpv would
not remove it. An AUR ffmpeg rebuilt without `--enable-vapoursynth` would mean owning a
large, frequently-updated build in order to delete one 49-byte file. Delete the file.
**Fix verified against `man pacman.conf`**: NoExtract files are never extracted, paths
are archive-relative without a leading slash, globs allowed; declarative, survives
upgrades, no hook, zero runtime cost, and neither machine currently sets any NoExtract
line. **Cost stated rather than hidden**: `VSSCRIPT_PATH` goes unset, so ffmpeg's
VapourSynth demuxer could not locate `libvsscript.so` — reachable only by running
VapourSynth scripts, which is a thing this workflow has never done. **Rejected**:
hardcoding the value in `/etc/environment`, because it embeds `python3.14` and would rot
silently at the next Python bump — a wrong value is worse than an absent one. **Also on
the audit but undecided**: `debuginfod.sh` (~13 ms, two `find|xargs|cat|tr` pipelines to
read one 33-byte file, benefits only `gdb`) and `gpm.sh`. **General rule this implies
for Phase 4**: `/etc/profile.d` is an unaudited latency surface that no package list
reveals — the installer should enumerate and time it rather than assume a curated
package list means a fast shell.


### prompt — hand-rolled bash `PS1`, no command substitution on the prompt path

**picked, shipped** · 2026-08-27 · packages: —

**Measured:** **65.7 ms → 1.5 ms per prompt** (branch only) or **12.5 ms** (with a dirty
marker), against `starship` 35–43 ms + `_direnv_hook` 15.0 ms. Branch detection is
**0.58–0.65 ms regardless of repo size** (244 vs 1719 files) because it reads
`.git/HEAD` directly

**Shipped 2026-08-27** — measured and prototyped first
([`benchmarks/3.5.prompt-and-shell.md`](benchmarks/3.5.prompt-and-shell.md) carries the
original candidate code), because it is product code and needed the author's review before
landing. Answers `03-alternatives.md`'s standing request to measure starship's
per-prompt cost. **The design rule that produced the win: no `$( )` anywhere on the
prompt path** — one bare subshell measures **2.98 ms** on the desktop (a 226-variable
environment inflates it), which is more than the entire rest of the prompt; helpers
assign to globals instead of echoing. A first prototype used two command substitutions
and cost 6 ms, which is how the rule was found. **Verified correct** at repo root, in a
subdirectory and outside any repo, with detached HEAD and `.git`-as-a-file. **Design
corrected the same day — the first version used `git diff-index --quiet` to avoid a
subshell, and that was wrong on both counts.** Measured idle: `git status --porcelain`
is **8.19 ms** against `diff-index`'s **13.84 ms**, *and* it detects untracked files,
which `diff-index` cannot. The subshell being avoided costs ~1 ms; `diff-index`
re-checks content that `git status` short-circuits via the index stat cache. The no-`$(
)` rule still holds for the rest of the prompt path, but it does not justify a slower
git call. **A claim that untracked scanning scales with repo size was also withdrawn**:
it rested on `walls` at 98.7 ms, which was a cold-cache first run — warm, same machine,
same load, it is 20.8 ms, and `walls` has zero untracked entries and no `.gitignore`.
The real curve is **flat** (50 dirs → 2.48 ms, 3200 dirs / 16000 files → 4.65 ms)
because git collapses a wholly-untracked directory without descending. **What does cost
is `.gitignore` style**: on identical trees, a directory pattern (`junk/`) is 4.03 ms
and a file pattern (`*.tmp`) is **36.30 ms**, because the latter forces a descent into
every directory — 9x, and worth knowing for repos generally. **Settled by the author
2026-08-21 — the dirty marker stays on**: **0.10 ms without, 8.2 ms with**, i.e. ~80x
the rest of the prompt, and he took it anyway ("8ms is worth it"). It is still ~2x
cheaper than the starship it replaces, and seeing uncommitted work at a glance is worth
more than 8 ms of a 20 ms per-prompt budget. **Decided, not shipped as a toggle**, per
`CLAUDE.md` — `BUNNY_PROMPT_GIT_STATUS` existed in the prototype for measurement and does
not appear in the shipped version; the dirty-marker `git status` call always runs.
**Counted in [`BUDGET.md`](BUDGET.md)**, where it is 98% of the per-prompt bucket and
therefore the first thing to re-examine if that bucket is ever breached.

**What actually shipped:** `config/bash/prompt.bash`, symlinked into `$XDG_CONFIG_HOME/bash/`
like every other file in `config/` — no special-casing. `install.d/85-shell-prompt.sh`
appends one `source` line to `~/.bashrc` (which stays otherwise untracked; `shell` is still
`deferred`, same shape as `60-autologin.sh`'s `.bash_profile` block) and verifies it by
sourcing the file in a throwaway `bash -c` and checking `PS1` actually changed — a source
that runs without error but never sets `PS1` would look identical to success without that
check. **Colors are plain ANSI cyan, not palette-templated** — `palette` is picked but has
no templater built yet (same situation `waybar/style.css` is in); revisit the day that
mechanism exists. Verified all four prompt states by hand (clean repo, dirty repo, outside
any repo, nonzero exit code) plus the write path (missing symlink refused, first write,
idempotent re-run). `OPINIONS.md` carries the high-level why alongside this repo's other
distinctive choices.


### node-runtime — Arch's **`nodejs`** package; **no `mise`, no shims, no version manager**

**picked** · 2026-08-27 · packages: nodejs npm

**Shipped as designed, author's word 2026-08-27.** The editor bake-off landed on LazyVim with
`pyright` (`docs/resume.md`), which is `#!/usr/bin/env node` — node was never actually optional
once that landed, so this row's own "decide it on merit, at the editor slot" resolved itself.
Arch's plain `nodejs` package, no version manager.

**Measured:** **143.5 ms → 0 ms per terminal.** `mise activate` 143.5 ms; mise shims
0.75 ms; **Arch `nodejs` 0 ms** — it is simply on `PATH` with no shell integration at
all. `pyright` needs `>=14.0.0`, Arch ships 26.7.0

**Revised 2026-08-21 after the author said he never uses node explicitly and asked
whether `mise` could go — he was right about `mise` and wrong about `node`, and the
resulting answer beats both earlier proposals.** First proposal was `mise activate`
(143.5 ms/terminal); second was mise shims (0.75 ms); **this is Arch's `nodejs` package
at `/usr/bin/node`, which costs 0 ms** — no shims, no `PATH` manipulation, no version
manager to understand. **Node cannot be removed — two hard dependencies, both
load-bearing.** (1) **`pyright-langserver` is `#!/usr/bin/env node`** — the Python LSP
in Neovim is a Node application, so dropping node silently kills completion,
go-to-definition and find-references on the machine's single largest workflow. (2)
**Four of the five agent CLIs are npm packages**: `codex` (`@openai/codex`), `opencode`
(`opencode-ai`), `gemini` (`@google/gemini-cli`) and `copilot` (`@github/copilot`) are
bash wrappers that call `mise where node@latest`. Only `claude` is exempt — it is a
native ELF binary. **But `mise` itself buys nothing here**: it pins `node = "25.1.0"`
while `pyright` declares `"node": ">=14.0.0"` and Arch ships **26.7.0**, so the pinned
version is precision nobody asked for. Per-project node pinning is `mise`'s reason to
exist and the author does not use node per-project — or at all, deliberately. **The
`mise where node@latest` coupling dies with the wrappers**, which are Omarchy's and are
being rewritten for BunnE anyway (`agent-clis`). **Also found: `aws-cdk@2.1106.1` is
installed globally under node and has zero uses in shell history** — drop it and do not
carry it forward. **Narrowed further 2026-08-21 by `agent-clis`**: with
`codex`/`gemini`/`copilot`/`opencode` dropped, node's consumers are now **only three
Neovim tools** — `pyright`/`pyright-langserver`, `sql-formatter` and
`vscode-json-language-server`, all `#!/usr/bin/env node` (`ruff`, `shfmt`, `stylua` are
native; `sqlfluff` is Python). **So "does BunnE need node at all?" is now an editor-slot
question**, and the author's original instinct — that node is not worth carrying — may
yet be right. Do **not** pre-empt the editor bake-off to get there: `pyright` is the
strongest Python type checker and its usual alternatives are either also Node
(`basedpyright`) or very new and unproven (`ty`, `pyrefly`); `sqlfluff` is already
installed and can likely replace `sql-formatter`; a JSON LSP may simply not be needed.
Decide it there, on merit, and treat dropping node as a *bonus if it falls out*, not a
goal that distorts the editor choice. **This corrects `03-alternatives.md`'s "keep
as-is, all cheap and all in use"** — that was an assumption, and for `mise` and `direnv`
it was measured wrong. **This corrects `03-alternatives.md`'s "keep as-is, all cheap and
all in use"** — that was an assumption, and for `mise` and `direnv` it was measured
wrong.


### agent-clis — **`claude` only** — drop `codex`, `gemini`, `copilot`, `opencode`

**picked** · 2026-08-21 · packages: —

**Measured:** removes **all four npm-based** agent CLIs; `claude` is a native ELF binary
and needs no node

`claude` installs via its native installer, outside pacman — hence no package listed.
**Author's decision 2026-08-21: "I don't want any LLM applications other than claude."**
`codex` is OpenAI's, `gemini` is Google's, `copilot` is GitHub's. **`opencode` goes
too** — it is `opencode-ai`, an open-source provider-agnostic coding agent, i.e. a
Claude Code alternative rather than a complement; the author did not recognise it, which
is itself the answer for a tool that would otherwise be installed and maintained
forever. All four are Omarchy inheritances, not choices. **Consequence worth
following**: those four were the *only* npm-package agent CLIs — the wrappers `mise use
-g node@latest` on first run — so dropping them removes the last reason the agent
tooling needs node at all. `claude` is unaffected: `file` reports a native ELF binary.
**What this hands to the editor slot**: node's only remaining consumers are three Neovim
tools (see `node-runtime`), so whether BunnE needs node *at all* is now an editor
bake-off question.


### polkit-agent — **`mate-polkit`**

**picked** · 2026-08-21 · packages: mate-polkit

**Measured:** **adds exactly 1 package** (gtk3 already present); `hyprpolkitagent` adds
4 incl. `qt6-declarative`, `lxqt-policykit` adds 6. **Resident cost 31.2 MB, measured in
a live session** — not free, and third-largest process on the box. **Acceptance test
passed 2026-08-21**: `pkexec` produced a GTK dialog and accepted the password

**Closes a priority-1 silent failure**: `polkit` is installed and proven on
`bunne-test`, but **no agent runs**, so a GUI app requesting privilege gets no prompt
and simply fails — exactly the degradation `CLAUDE.md` forbids. **`03-alternatives.md`'s
ranking was void, not merely stale**: it put `hyprpolkitagent` first *because it
integrates with Hyprland*, which is `rejected`. **Re-decided on measured cost**: `gtk3`,
`gtk4` and `qt6-base` are already on the machine but `polkit-qt6` and
`hyprland-qt-support` are not, so the Qt agents drag in a QML runtime while the GTK ones
add one package. **`polkit-gnome` was the intended pick and was rejected by the author,
correctly**: its Arch URL is `gitlab.gnome.org/**Archive**/policykit-gnome` and upstream
is **0.105**, a 2012 release carried by 12 downstream rebuilds. Priority 1 says prefer
the boring option that survives an update — an archived upstream is not that, and
`mate-polkit` costs identically while MATE actively maintains its GNOME-2-lineage forks
(1.28.1). **Unlike `polkitd` this is a resident process**, not D-Bus activated, so it
needs `spawn-at-startup` in the niri config and **a `BUDGET.md` row once its RSS is
measured** — do not leave it uncounted. **Gotcha, found by reading the package before
installing it**: the shipped
`/etc/xdg/autostart/polkit-mate-authentication-agent-1.desktop` is gated
`OnlyShowIn=MATE;`, so under niri it **will not autostart** and installing the package
alone changes nothing — the same silent no-op the `portal` row documented for `at-spi`.
It must be launched explicitly: `spawn-at-startup
"/usr/lib/mate-polkit/polkit-mate-authentication-agent-1"`. Note the binary lives under
`/usr/lib/mate-polkit/`, not on `PATH`. **Acceptance test is a real privilege prompt** —
e.g. a GUI app calling `pkexec` — not merely `pgrep`ing the agent.


### lock-idle — **`swaylock` + `swayidle`**

**picked** · 2026-08-21 · packages: swaylock swayidle

**Measured:** **123 KiB total and zero new dependencies** — every dep (`cairo`,
`gdk-pixbuf2`, `libxkbcommon`, `pam`, `systemd`, `wayland`) is already present.
`hyprlock`+`hypridle` are 1119 KiB **and pull 5 new hypr-ecosystem packages** on a fresh
niri box: `hyprgraphics`, `hyprlang`, `hyprutils`, `hyprwayland-scanner`, `sdbus-cpp`

**Closes the last slot ranked on a void justification.** `03-alternatives.md` put
`hyprlock + hypridle` first for being *"tiny, integrates with Hyprland"* — and Hyprland
is `rejected`, so the stated reason evaporated. This is the third slot with that defect
after `polkit-agent` and `portal`; the author asked for a systematic sweep and it is
recorded below. **The measurement nearly went wrong**: on `bunne-test` both pairs report
"2 new packages", which made hyprlock look free — **because the entire hypr library
stack is still installed from the Hyprland trial** (see `compositor-cleanup`). On a
machine that never ran Hyprland, hyprlock costs 5 extra packages and 9x the install size
for a lock screen. **Compatibility is not the differentiator** — niri advertises
`ext_session_lock_manager_v1` and `ext_idle_notifier_v1`, so both pairs work; the sway
pair simply costs less. Fancier hyprlock visuals are not a reason here: `CLAUDE.md` says
rice with config, not with processes. **`swayidle` is a resident daemon** and needs a
`BUDGET.md` row once measured. **All three acceptance tests passed 2026-08-21**: lock on
demand (`Mod+Escape`), lock on idle, and **a playing video correctly prevents
blanking**. That last one **resolves the `Inhibit` worry left open when the GTK portal
was deprioritised** — native Wayland apps use `zwp_idle_inhibit_manager_v1` directly,
which niri advertises, so they never needed the portal's `Inhibit` interface at all.
Only sandboxed apps would, and none are in use. **Cost: `swayidle` 3.3 MB resident;
`swaylock` 0 MB until the screen is actually locked.**

**Re-checked 2026-08-30, author's word ("let's try another lock screen... check
viacoffee/dotfiles"), this time with the number the 2026-08-21 entry above never
took: RAM while actually locked, not install size.** `viacoffee/dotfiles`
(`config/hypr/hyprlock.conf`) turned out to have no Arch logo — that lives in his
Plymouth boot theme, not his lock screen — but its `input-field` does show a real
box that fills with dots per keystroke, closer to the author's ask than swaylock's
segmented ring. Installed `hyprlock` clean (no leftover Hyprland library stack this
time, unlike the tainted 2026-08-21 measurement) and measured both locked, same
box: **swaylock 18.2 MB** (two-process pair, `awk VmRSS`) **vs hyprlock 272 MB** —
about 15x, almost certainly its real-time GPU blur (`blur_passes`) and full-screen
dmabuf capture against swaylock's static blit. Confirmed compatible with niri
either way (`Running on niri` in its own debug log — `ext_session_lock_manager_v1`
again). **Rejected on the RAM alone**; the dots-vs-ring difference was never enough
to justify it even before the number came in. `hyprlock` removed from the machine.
**Process-name trap hit while measuring**: `pkill -x Hyprlock` (capitalized, matching
the startup banner text) silently matched nothing — the actual process name is
lowercase `hyprlock` — so the session sat locked at the PAM prompt for longer than
intended until caught by `pgrep -a -i hyprlock` and killed correctly. Case-sensitive
process matching is the thing to get right before ever re-testing a locker live.

**Lock-screen image added 2026-08-27, author's word**: `-i` points `swaylock` at
`assets/wallpaper/1920x1080/15-neon-hare-by-omar-ramadan.jpg` — a light-painted neon bunny
silhouette, matte-black background, matches the accent family already established by niri's
`#7fc8ff` (`config/niri`). `-c 0f0f0f` stays as the fallback fill for whatever the image's
scaling mode doesn't cover. All three invocations (the `Mod+Escape` bind, `swayidle`'s
`timeout` and `before-sleep` actions) use `spawn-sh`/swayidle's own `sh -c`, not niri's
literal-argument `spawn`, because the path is `${XDG_DATA_HOME:-$HOME/.local/share}/arch-bunny/...`
and needs shell expansion at lock time — same canonical-install-location assumption
`70-dotfiles.sh` already makes. Verified on `bunne-test`: `niri validate` passes, and
`swaylock -f -i <path> -c 0f0f0f` was invoked directly over ssh (then `pkill swaylock`,
confirmed clear) — accepts the image with no error and daemonizes normally. This is not
`wallpaper`'s solid `#0f0f0f` reconsidered — the desktop background stays a solid fill; the
lock screen is the one surface that gets a photo.

**Lock-screen image REVERSED 2026-08-28, author's word — it was confusing, and it was
confusing for a reason the row got wrong.** All three invocations are now
`swaylock -f --indicator-idle-visible`, upstream's own defaults plus one flag. The photo
above looked right in a screenshot and wrong on a locked machine: a full-screen bunny with
no field, no prompt and no cursor does not read as "type your password", it reads as a
machine that has hung. Priority 1 outranks priority 3, and a lock screen's entire job is to
say what it wants.

**The flag is the half that matters, and a bare `swaylock -f` would not have fixed
anything.** Upstream's `indicator_idle_visible` defaults to false, so stock swaylock draws
the ring only *once a key is pressed* — the default look is a blank screen too, just a white
one instead of a bunny. `--indicator-idle-visible` puts the ring up the moment it locks.
That is a documented option, not a workaround, and it is the whole change: no theming
flags, no colors, no font — the defaults are already correct and `CLAUDE.md` says not to
restate them.

Two things fall out. The `Mod+Escape` bind is a plain `spawn` again rather than `spawn-sh`,
since there is no longer a path needing shell expansion. And `swaylock` no longer reads a
2 MB JPEG at lock time, which is a small win on the one path where latency is felt from a
cold screen.


### config-validation — our own checks for what upstream validators miss; `scripts/check-keybinds.sh` is the first

**picked** · 2026-08-21 · packages: —

**Measured:** catches a collision `niri validate` **passes**; canary-tested both ways,
exit 1 on a broken config and 0 on a good one

**Author's suggestion, generalised one step.** His rule was "don't use `Super` and `Mod`
in the same config to mean one key" — correct, and the underlying defect is broader:
**`niri validate` compares keybinds as literal strings**, so `Super+Ctrl+L` and
`Mod+Ctrl+L` look distinct while being one chord (`Mod` *is* Super on a TTY, per niri's
own shipped text). The check therefore **normalises `Super`→`Mod` and sorts modifiers**,
catching ordering variants too, and reports the line number of every collision. His
literal rule survives as a secondary *warning*, because mixing spellings is what makes a
collision invisible to a reader even when nothing clashes yet — it currently fires on
stock niri's one `Super+Alt+S` orca binding against 108 `Mod+` ones. **Proven, not
assumed**: fed the exact config that got past `niri validate` earlier the same day, it
fails and names lines 434 and 486. `04-plan.md` Phase 4 carries the general rule — *for
every config we ship, ask what the upstream validator does not check, and write that
check ourselves* — with the known gaps listed (binaries referenced but not installed,
`spawn-at-startup` entries that never run, hardcoded colours once the palette generator
exists).

**Second check written 2026-08-25: `scripts/check-limine.sh`, and it was earned rather
than anticipated.** Limine ships **no validator at all**, and that evening a
structurally *correct* restructure of `/boot/limine.conf` — the one-OS-block shape
`snapshot-boot-entries` requires — took `bunne-test` off the network. Nothing in the
file was invalid: it parsed, `limine-list` rendered the tree correctly, and the machine
simply reached the menu and waited, because `default_entry` defaults to `1`, entry 1 had
become the OS *directory*, and a directory does not boot. The check catches exactly
that (FAIL — including the out-of-range case, since a collapsed directory hides its
children from the numbering), plus an entry booting a file that is not on the ESP (FAIL
— the black-screen case `rollback-method` warns about). `--self-test` builds the failing
config and three near-misses and asserts each is rejected while both correct repairs
pass.

**Its behaviour is read from limine's source, not from `CONFIG.md`, which does not
describe it** — `common/menu.c` at the `v12.5.2` tag shows a directory as the selected
entry forcing `skip_timeout = true` (the menu waits indefinitely), `Enter` on a folder
only toggling `expanded`, `print_tree()` counting children **only when the directory is
expanded** (so the `+` is load-bearing for a numeric `default_entry`, not decoration),
and `find_entry_by_path()` expanding as it goes and matching only leaves — which makes
the **path form** of `default_entry` structurally incapable of selecting a folder and
immune to a tool renumbering entries. The check recommends that form.

**A first draft of this script had to be rejected and rewritten, and the reason belongs
in this row.** It printed *"default_entry N is bootable, all booted files present"* on
two configurations it never inspected: a non-numeric `default_entry` (check 1 skipped
wholesale, the assurance printed anyway) and any `path:` not using `boot():` — of which
the author's own desktop config has one. **A validator that emits false assurance is
worse than no validator**, and it was this repo's own "fail loudly, do not degrade
silently" rule being broken by the script written to enforce it. The pass line now
enumerates what was actually checked, including what it skipped. Verified green against
the author's working Omarchy `limine.conf`, which is also **the only real-world config
it has been run against** — and the same one the model was checked against, so that is
one machine, not an independent sample.

**The pattern worth extracting: the two checks in this row were both written after a
failure, and both catch a config that the tool of record calls fine.** `niri validate`
passed a shadowed keybind; limine has no validator to pass. The rule the plan states
generally — ask what upstream does not check — is cheap to state and apparently only
gets *acted* on once something breaks. Worth writing the check for a config **when it is
first shipped**, not after it costs a boot.


### xwayland — **deferred** — no X11 support at all right now

**deferred** · 2026-08-21 · packages: (would be `xwayland-satellite`)

**Measured:** `Xwayland` binary **gone**, `xwayland-satellite` never installed, zero
mentions in the niri config

**Surfaced 2026-08-21 by the Hyprland removal, which took `xorg-xwayland` with it — but
this is a gap that was always there, not a regression.** niri has **no built-in
XWayland**; it requires the separate `xwayland-satellite`, which has never been
installed or configured. So X11 apps could not run under niri *before* the removal
either — Xwayland was present only as a Hyprland dependency and niri would not have used
it. **The open question is whether BunnE needs X11 support at all.** Most of the app
list is Wayland-native (kitty, brave, mpv, fuzzel, imv, zathura). The risk is long-tail:
an Electron app without Wayland flags, an installer, a game, a work tool. **Do not
decide this from the app list alone** — decide it the first time something fails to
start, and record what it was.


### remote-desktop — not available; **niri limitation, not a packaging choice**

**picked** · 2026-08-21 · packages: —

**Measured:** `RemoteDesktop AvailableDeviceTypes` = **0**; `ScreenCast
AvailableSourceTypes` = **7**

**Investigated because it looked like collateral damage from removing `libei` with
Hyprland — it is not.** Checked the compositor binary directly: niri contains **10**
references to `org.gnome.Mutter.ScreenCast` and **0** to
`org.gnome.Mutter.RemoteDesktop`, which is what `xdg-desktop-portal-gnome` needs to
offer remote input. So this was **always 0** and no removal caused it. **What still
works is what C4 actually requires**: screen *sharing* for meetings, source types 7
(monitor, window, virtual). **What does not**: letting a remote participant take control
of the machine — the "request control" button in Meet or Teams. Recorded as `picked`
because there is nothing to choose; it is a property of the compositor. Reopening it
means reopening `compositor`.


### compositor-cleanup — remove Hyprland and its library stack from `bunne-test`

**picked** · 2026-08-21 · packages: —

**Measured:** `hyprland` **64.54 MiB**, `Install Reason: Explicitly installed`,
`Required By: None`, plus `hyprutils`, `hyprlang`, `hyprgraphics`,
`hyprwayland-scanner`, `hyprcursor`, `aquamarine`

**A ledger-versus-machine divergence, found 2026-08-21 while comparing lock screens.**
The `compositor` row records Hyprland as `rejected` on 2026-08-20, and `04-plan.md`
Phase 3 step 5 says **"`pacman -Rns` the loser"** — it was never done. Two costs, one of
them subtle. (1) It is dead weight on the test box. (2) **It silently corrupts
measurements**: the `lock-idle` comparison initially showed hyprlock adding "2 packages"
because its whole dependency stack was already there, which would have made the wrong
answer look free. This is the same class of error as the `gpu-driver` row claiming
packages that were never installed (session 6) — **a ledger row is a claim about the
machine, in both directions**. **DONE the same day**: `pacman -Rns hyprland` removed
**23 packages, 76.47 MiB**, and the session survived intact — every running process was
verified afterwards. Two of the packages it dragged out looked alarming and neither was:
**`xorg-xwayland`**, but niri has no built-in XWayland and needs `xwayland-satellite`,
never installed, so X11 apps could not run before the removal either (see `xwayland`);
and **`libei`**, which made `RemoteDesktop` look broken until the compositor binary
showed it never implemented `Mutter.RemoteDesktop` at all (see `remote-desktop`). **Both
were checked rather than assumed**, which is the point. **Worth a Phase 4 sweep**: diff
`pacman -Qe` against the `picked` rows and reconcile.


### prompt-hooks — gate every `PROMPT_COMMAND` hook on a `$PWD` change

**deferred** · 2026-08-21 · packages: —

**Measured:** `_direnv_hook` **15.0 ms every prompt → 0.23 ms** when gated; still fires
on `cd`, verified

**`deferred` pending review.** direnv was invisible until measured: `PROMPT_COMMAND` on
the desktop is `_direnv_hook` and nothing else, so it forks `direnv export bash` after
*every command*. **`02-functionality.md` C5 already prescribes exactly this fix** — "a
plain string compare against `$PWD` in `PROMPT_COMMAND`... with any expensive call gated
behind that change" — written for dir-aware display, but it generalises to every prompt
hook, and should be a **rule for the shell config rather than a one-off**. **Tradeoff
stated**: a gated hook will not notice an edited `.envrc` until the next `cd`; `direnv
reload` covers it, and editing `.envrc` is rare next to running commands. **Related
rejection — `core.fsmonitor`**: marginally faster git status, but it starts a resident
`git fsmonitor--daemon` **per repository**, which is what priority 2b exists to refuse.
Confirmed running on test, then stopped. `core.untrackedCache` is the daemon-free
alternative and recovers ~20%.


### python-pynvim — pinned python3 provider for Neovim

**picked** · 2026-08-21 · packages: python-pynvim

**Measured:** 52.4 -> 12.0 ms on every `.py` open (`benchmarks/3.9`): ~34 ms of each
open was a *failing* python3 provider probe

**Approved by the author 2026-08-21** ("if we need it for jupyter, include it in the
list") — this row was owed since then (`docs/resume.md` queue item 2) and is written
2026-08-24. Config half: `vim.g.python3_host_prog` pinned to the system python in
whatever editor config ships (Phase 4). Required by molten/Jupyter (gripe #3), which
NVChad's default `loaded_python3_provider = 0` would silently break — the bake-off must
check that.


### editor — **LazyVim** (NVChad and hand-rolled minimal rejected)

**picked, shipped** · 2026-08-27 · packages: neovim python-pynvim lazygit ripgrep fd

**Measured:** old-install numbers, different box/config, context only: LazyVim 208.8 ms
vs NVChad 20.5 ms to a 1500-line `.py` (13 vs 4 plugins — not like-for-like); bare nvim
floor 11 ms; hand-rolled 3-plugin contender hit 34.3 ms

The last headline gripe's home (`jupyter-in-neovim` proves the layers below; the editor
carries molten). Bake-off phases pre-registered in `benchmarks/4.15.editor-bakeoff.md`:
(1) startup to a real 1500-line `.py`, n=10/candidate, fresh box, pynvim provider
pinned; (2) `gr` correctness+latency with a `pyrightconfig.json` (the 3.12 lesson:
measure the answer's *correctness*, not just speed); (3) molten inline-render acceptance
— the gripe itself, and the phase where NVChad's disabled python3 provider either bites
or is fixed per the `python-pynvim` row. Throwaway configs under `NVIM_APPNAME`, never
product config; the author reviews whatever wins line-by-line in Phase 4. **DECIDED by
the author 2026-08-24, all three phases in evidence (`4.15`): LazyVim.** The 2a trade is
stated out loud per the priorities rule: **~110 ms per editor launch accepted** (126.8
ms vs NVChad's 16.3 on a 1500-line .py) in exchange for: molten/gripe-#3 machinery
working FIRST TRY with zero against-the-grain reverts (NVChad requires permanently
reverting its disabled python3 provider AND its disabled rplugin — exactly the
brittleness the author's same-day doctrine forbids relying on), his existing
daily-driver muscle memory, and a maintained distro he already knows how to extend. gr
correctness/latency was a three-way tie (25/25 at ~12 ms warm) and did not discriminate.
Phase 4 ports: the molten+image.nvim wiring proven in `4.15` (venv provider,
`magick_cli`, the fail-loudly kitty gate), the jupyter runtime-dir creation, and the
predecessor's venv-selector functionality (pyright-vs-kernel venv mismatch was visible
in the render test — a real requirement). **Author-flagged reference 2026-08-24:
github.com/dubrayn/nvim_dotfiles** (markdown-as-notebook on molten+kitty). Assessed
against the doctrine; the port list it adds, all supported-config-shaped: (1)
`render-markdown.nvim` for in-terminal markdown rendering — LazyVim's markdown extra
already ships it, likely zero new deps; (2) `image.nvim` `integrations.markdown.enabled
= true` — one opts flag on a plugin we already carry, renders `![]()` inline; (3) the
`<S-Enter>` fence-evaluate binding — REVISED 2026-08-24 after the author's test drive
hit a deprecation warning in various-textobjs: now ~12 lines of plain treesitter +
`vim.fn.MoltenEvaluateRange` (molten's own integration API), no extra plugin, no
deprecated calls; (4) try their `molten_output_virt_lines`-style vim.g output options.
Explicitly NOT ported: their personal `dubrayn/molten-nvim` fork (upstream proven here
twice; one-person forks are the banned brittleness class), the luarocks `magick` rock
(we use `magick_cli`), and the unrelated 30-plugin surround. Kernel-routed LaTeX
rendering already works on our stack; their kernel-free LaTeX preview is unsolved even
for them.

**2026-08-25 (author's 2026-08-25 queue, `docs/open-questions.md`) — three answers in
one row.** (a) **`lazygit`, `ripgrep` and `fd` join the Packages cell.** All three are
system-PATH binaries LazyVim shells out to and nothing in the Neovim runtime provides:
`lazygit` backs `<leader>gg`, a LazyVim default that ships as a broken keybind without
it, and `ripgrep`/`fd` are what snacks.picker and `gr` execute — absent, find-in-files
and the file picker degrade **silently** on a fresh machine, which is the
`man-db`→`less` failure shape this repo has already been bitten by (4.21 Finding 2). (b)
**`fzf` is not one of them.** Verified headless: snacks.picker is the only picker
installed, `fzf-lua` is an unenabled LazyVim extra, and snacks is pure-Lua and never
spawns the `fzf` binary. `fzf` for bash `Ctrl-R` history was raised as the separate
shell decision and **declined by the author 2026-08-25**, so `fzf` is not in BunnE at
all. (c) **The draft's +33 ms is re-affirmed** — the Phase-4 nvim
draft starts in ~160 ms against the 126.8 ms the LazyVim pick was measured at
(`benchmarks/4.23`), the delta being two extras plus venv-selector. Accepted
deliberately: the extras buy the Jupyter workflow that gripe #3 chartered this project
to fix, and the cost is a per-launch 33 ms, not a resident one. `markdownlint` and
`markdown-preview` stay the named trim candidates if the number ever matters more than
they do. **`pyright` deliberately stays rowless** — pacman package versus Mason-managed
is a Phase-4 nvim-config decision, not a package-list one.

**Shipped 2026-08-27** — found not shipped at all: `~/.config/nvim` didn't exist on
`bunne-test`, so a stock `neovim` invocation with zero configuration is what "regular
neovim, not LazyVim" actually was. The right packages were installed (`20-packages.sh`
correctly derives from this row); the config itself — decided, prototyped, and tested
under `NVIM_APPNAME=nvim-p4` back on 2026-08-24 — had never been harvested from
`benchmarks/raw/p4-nvim-draft/` into `config/`. `70-dotfiles.sh`'s existing generic
walk deploys the whole `config/nvim/` tree with no special-casing; the one thing that
genuinely needed a step was the provider venv (`install.d/75-nvim-notebook.sh`:
`~/.venvs/neovim`, the six pip packages `vim.g.python3_host_prog` needs, our own
`pnglatex.py` copied in (never pip-installed — see `latex-rendering` for why), the
`bunne` Jupyter kernel, the runtime dir molten writes to but never creates).

**A real bug the write path caught that the draft's own author-facing testing didn't:**
`pillow`'s pip name and its import name (`PIL`, kept for compatibility with the
library it forked from) differ, and the step's own "did the install actually work"
verification used the pip name for both `uv pip install` and the import check —
passing the install, failing the check, on the very first from-scratch run. Fixed by a
small pip-name → import-name map (`pillow` → `PIL`, everything else passes through);
re-run from scratch confirmed clean afterward.

**The draft's own claim that `fzf` is required (`<Space>mi`'s kernel picker uses
fzf-lua) does not survive re-verification** — this directly contradicted the row's own
2026-08-25 finding that `fzf` is declined and not in BunnE at all, so it was checked
rather than trusted either way: `require("fzf-lua")` fails on the actual deployed
plugin set (not loaded), and nothing in the python/markdown extras or `venv-selector`
references it as a hard dependency (`venv-selector` ships an *optional* fzf-lua
backend file, unused here). The 2026-08-25 decision stands; `fzf` is not a package
this row needs. (It remains installed on `bunne-test` itself as leftover debris from
the original draft-building session — not a requirement, just untidied.)

**`.markdownlint.jsonc` needed an explicit `--config` path, not a dotfile at
`$HOME`** — the review item's own author decision ("add a config, tune the specific
rule"). markdownlint-cli2's upward directory-tree config search does not apply to
nvim-lint's stdin invocation; verified on the box, a config at `$HOME` was silently
ignored linting a file in a subdirectory, and the identical file worked immediately
once passed via `--config`. `config/nvim/lua/plugins/markdown-lint.lua` overrides
nvim-lint's linter args accordingly — via the hyphenated registry key
(`"markdownlint-cli2"`), confirmed by reading `nvim-lint`'s own `__index` metatable
(a literal `require('lint.linters.' .. key)`, no underscore/hyphen normalization) —
an underscore key would have silently created a dead, never-referenced entry. Tested
headless: a file with 3 consecutive blank lines reports 0 diagnostics with the
override in place.

**sympy and the startup-cost trade were both re-affirmed, not re-litigated**, per the
author's word. `benchmarks/raw/p4-nvim-draft/` is kept as the historical record; the
molten upstream `BufUnload`-destroys-the-kernel behavior is documented there and left
unfiled, also per the author's word.


### latex-rendering — TeX for notebook LaTeX output (molten `text/latex` -> pnglatex -> pdflatex/pdfcrop/pdftoppm/pnmtopng)

**picked, shipped** · 2026-08-27 · packages: texlive-basic texlive-latex texlive-binextra

**Measured:** `Math(r'$...$')` renders as a typeset inline equation, `Out[1] Done
0.16s`, pixel-proven (`benchmarks/raw/4.15.math-render.png`)

**Author approved after seeing the size** (~230 MiB + netpbm 11 MiB): zero
boot/idle/daemon cost, pure on-demand binaries; the recurring wall (usetex, `Math()`
objects — hit three times in one afternoon of real notebook use) justified it.
Corrections vs the initial pitch, from reading pnglatex's source rather than its docs:
the chain is **pdflatex+pdfcrop** (binextra provides pdfcrop, not dvipng) **+pdftoppm**
(poppler, already present) **+pnmtopng** (netpbm, added). **The abandoned pnglatex is
GONE (author instruction, same day)**: uninstalled and replaced by a ~40-line owned
module (`benchmarks/raw/4.15.pnglatex-replacement.py`) keeping only the import name
molten hardcodes — latex + `dvipng -T tight -bg Transparent -fg <light>`, failures
raised as the ValueError molten catches. This also delivered the **theme fix**:
equations now render transparent-bg/light-fg on the dark terminal (pixel-proven,
`raw/4.15.math-render-themed.png`) — which turns out to be the entire reason the
reference repo forked molten; we got it with zero molten changes. The foreground is
kitty's default light gray for now; wiring it to the shared palette is Phase 4 theming.
netpbm is now unneeded by this chain (our module uses dvipng, not pnmtopng) — netpbm
stays only if something else wants it; flag for the Phase 4 package sweep. matplotlib
`text.usetex` also works now as a side effect. `<leader>mi` binds MoltenInit (kernel
picker).

**The Phase 4 sweep flagged above, done 2026-08-27**: `netpbm` dropped from the packages
cell — grepped the whole repo, nothing else references it. `dvipng` needs no packages-cell
entry of its own: `pacman -Qi texlive-bin` shows it `Required By: dvisvgm texlive-basic
texlive-binextra texlive-latex` — already guaranteed transitively by the three packages
already listed here.

**The module itself was found not shipped at all, harvested as part of the `editor`
row's own harvest (2026-08-27).** `benchmarks/raw/4.15.pnglatex-replacement.py` (this
row's own module, unchanged since the day it was written) moved to
`assets/nvim/pnglatex.py` — `benchmarks/` is evidence, not something the live installer
should depend on. `install.d/75-nvim-notebook.sh` copies it into the provider venv's
site-packages. **Caught before shipping the wrong thing entirely**: the real PyPI
package named `pnglatex` still exists and installs cleanly (`uv pip install pnglatex`
resolves, no error) — it is the *abandoned, broken-on-3.13+* one this row's own text
already named and replaced, and a first pass at the install step used it by name
without noticing the file already deployed on `bunne-test` was this row's owned
replacement, not the pip package, until a cross-check against `nix-bunne`'s parallel
port (same module, byte-identical, same docstring) surfaced the mismatch.

**Three fixes from the author's first real test-drive of `molten_test.md`, 2026-08-27.**
Verbatim report: output latex/graphs sometimes clip into the stale `Out[..]` line on
cell re-run, no cell-navigation shortcut, and the Ctrl-D/Ctrl-U scroll animation
"slows me down" against priority 2a. All three landed in
`config/nvim/lua/plugins/molten.lua` and a new `config/nvim/lua/plugins/no-scroll-animation.lua`:

1. **Clipping** — traced molten's own clear-before-rerun path
   (`moltenbuffer.py:run_code` → `try_delete_overlapping_cells` → `outputbuffer.py:
   clear_virt_output`) and confirmed it correctly calls `canvas.remove_image()` +
   `canvas.present()`, and that `image.nvim`'s own `Image:clear()` correctly removes
   both the kitty graphics placement AND the extmark reserving its space — no leak at
   that level either. First attempt, `vim.g.molten_virt_lines_off_by_1 = true` (molten's
   own README names it for exactly this markdown-fence case), **made it worse when the
   author re-tested**: "the output box takes up no space, so the graphs just pop out
   behind the next cell's text." Root cause of the regression: molten's virt_lines and
   image.nvim's own image-space reservation are two independent, uncoordinated systems
   (`images.py`'s `add_image(..., with_virtual_padding=True)` reserves the image's lines
   itself, sized by image.nvim's own `virtual_padding.lua`, oblivious to molten's
   number) — shrinking molten's half by one does nothing to align the other.
   **Reverted.** What's left after reverting is the pre-existing occasional clip on
   rapid re-run, which by elimination looks like a genuine timing interaction between
   the two plugins' redraw paths rather than a missing-clear bug or a one-line config
   fix (`image.lua`'s `Image:render()` even has a documented cascade — "rerender any
   images that are below this one" — for exactly this kind of cross-image
   coordination). No further blind guesses; asked the author whether to file it upstream
   or accept it as an occasional, self-correcting glitch (author's report didn't say
   whether re-scrolling or re-entering the cell cleared it).
2. **Cell navigation** — real commands are `MoltenNext`/`MoltenPrev`; bound to `]m`/`[m`.
   **Author hit `"No cells to jump to"` on the first try** — traced to
   `_get_sorted_buf_cells` (`__init__.py:287`), which walks `kernel.outputs.keys()`:
   molten's notion of "cell" is *an already-executed output*, not a code fence in the
   document. `]m`/`[m` are correctly reporting zero cells when tried before any
   `<S-Enter>` — not a bug, but a real workflow gap: there is no upstream command for
   "jump to next code fence regardless of execution state." Left as-is (accurate
   behavior, no missing-fence-navigation feature added without being asked); the
   keybind's own `desc` doesn't yet warn about the run-once-first requirement.
3. **Scroll animation** — traced to LazyVim's own `lua/lazyvim/plugins/ui.lua` turning
   on `snacks.nvim`'s `scroll` module by default. New file overrides
   `opts = { scroll = { enabled = false } }`. **Verified headless**:
   `require("snacks").config.scroll.enabled == false` after full plugin load on
   `bunne-test`.
4. **MD025 (author's fourth report, same test-drive)**: every cell in `molten_test.md`
   is its own H1 section by design (one heading per cell, matching the notebook
   convention) — MD025 (single-H1-per-document) was firing on every one after the
   first. Pre-existing gap, not caused by 1-3: `.markdownlint.jsonc` only ever disabled
   MD012. Same review item, same fix shape — `"MD025": false` added alongside it.

Fixes 2-4 deployed to `bunne-test` and mechanically verified (commands/keymaps exist,
`off_by_1` confirmed unset, scroll config resolved false, config file updated). Fix 1 is
a revert to prior (imperfect but not actively broken) behavior — still needs the
author's own eyes to confirm the residual clipping is rare/tolerable.


### keybindings — cascading standard: Omarchy defaults <- author's `~/.config/hypr/bindings.conf` <- non-colliding <- installed-relevant

**picked** · 2026-08-24 · packages: —

**Measured:** `scripts/check-keybinds.sh`: 120 chords, no duplicates; `niri validate`
clean; deployed live

**Author's policy, verbatim intent:** keybinds are derived by cascade — Omarchy
defaults, overridden by his personal `bindings.conf`, filtered to non-colliding chords
and to apps BunnE actually installs; anything uncertain is asked, not guessed (two
question rounds, 2026-08-24). Ratified core: `Mod+Return` terminal, `Mod+W`
close-window, `Mod+Space` launcher, `Mod+Shift+N` nvim, `Mod+Shift+B`/`+Ctrl`
brave/private, `Mod+Shift+M/T/D/G/F` spotify/btop/lazydocker/signal/nautilus,
`Mod+Shift+Slash` bitwarden via `gtk-launch` (binary names differ across OSes: Arch
`bitwarden-desktop`, NixOS `bitwarden` — the .desktop name is the portable handle, and
it is the author's own desktop idiom), `Mod+I` hotkey overlay, `Mod+Comma`/`+Shift` mako
dismiss/all, `Mod+Ctrl+V` cliphist-fuzzel picker, `Alt+Tab` previous window,
`Ctrl+Mod+Shift+Left/Right` move-workspace-to-monitor (HJKL variants keep
move-column-to-monitor). Collisions resolved: tabbed-display `Mod+W`→`Mod+Shift+W`;
fullscreen `Mod+Shift+F`→`Shift+F11` (Omarchy's chord); niri's consume/expel stays on
brackets, freeing Comma/Period; bare `Mod+U`/`Mod+I` workspace-focus dropped (Page keys
remain; author's call). Declined/excluded by the author: Steam bind, webapp binds (no
infra), `input_delay`-style cwd terminal helper (plain kitty), Obsidian/Typora (not
installed), universal copy/paste `Mod+C/V/X` (Hyprland `sendshortcut` has no niri
equivalent), orca bind (niri-example inheritance, not in Omarchy defaults, package
absent — the earlier silent-keybind gap resolved by deletion, and playerctl by
installation). Config lives in ONE place: the `binds {}` block of
`config/niri/config.kdl`, mirrored byte-identical to nix-bunne
`reference/niri-config.kdl`. **Author standard added 2026-08-24: `;l` is Esc "everywhere
possible"** — in Neovim that is all five modes verbatim from his Omarchy config (i/c/v/n
map to `<Esc>`, terminal mode to `<C-\><C-n>`); ships in the Phase-4 editor config,
prototyped in `raw/4.15.markdown-prototype.lua`'s companion keymaps. **Terminal-chord
lesson from his test drive**: kitty owns the Ctrl+Shift chords (C-S-h is its scrollback
pager; C-S-s/o are also kitty defaults), so nvim bindings must avoid them — the molten
output bindings are `<leader>mo/mh/ms`.


### keybind-apps — apps bound by the ratified keybind set

**picked** · 2026-08-24 · packages: spotify-launcher btop lazydocker signal-desktop bitwarden playerctl nautilus

**Measured:** all installed on `arch-bunny` 2026-08-24 (pacman, snap-pac pairs 24-33)
and verified on PATH; `brave-bin`/`neovim` installed the same day under their existing
rows (fresh install had shipped without them — ledger-vs-machine divergence closed)

Author approved each explicitly in the keybind question round ("selected = row +
install"). None is resident: all launch-on-keypress (bitwarden and signal are Electron —
per-launch cost only; the resident-Electron trap is the Bitwarden autostart setting,
which is a NixOS-side finding and the author's own toggle to flip). Steam and webapp
helpers were offered and declined. `nautilus` was already on the box unclaimed by any
row; claimed here. Full install only for spotify/lazydocker/signal;
btop/playerctl/nautilus arguably lite — split when `install-profile` gets its column.


### kernel — linux (mainline)

**picked** · 2026-08-23 · packages: linux

**Measured:** —

No row existed; the dead install carried both `linux` and `linux-zen` and the
`bootloader` row's Measured column implies zen was what booted — usage, never a
decision. Author picked mainline 2026-08-23 (question round, install night) for the
bake-off install: one kernel is the fewest moving parts for an unattended first boot,
and it is apples-to-apples against NixOS's mainline kernel. **Correction, same night
(4.2):** the second half of that assumption was wrong in detail — NixOS 26.05's channel
pins kernel 6.18.44 (read off the box) vs Arch's rolling 7.1.9, so cross-OS boot
comparisons carry a kernel-version confound; recorded in
`benchmarks/4.2.arch-vs-nixos.md`. The pick itself stands. zen stays a live candidate
for a measured bake-off of its own — 1000 Hz + BORE is a plausible 2a win, but it is
unmeasured on this hardware, and the priority-2a rule wants the number, not the vibe.
**First probe, same night (`benchmarks/4.4.kernel-zen-probe.md`, informational, n=2
boots):** kitty spawn ~2-3% faster on zen (127-128.5 vs 130-132 ms median), fuzzel and
boot unchanged — at the edge of noise, does not displace this pick; a real re-argument
needs an input-latency metric, not spawn medians. **Input-rt measured later the same
night (`benchmarks/4.6.inputrt.md`): zen is null there too** (kitty/foot/delay-0 all
within run variance of mainline) — both queued metrics now have data and neither moves;
mainline stands on measurement. **zen removed 2026-08-24** (author decision after the
null probes): `pacman -Rns linux-zen linux-zen-headers`, limine entry dropped, nvidia
DKMS builds halved per update. One kernel ships; the canary-proven snapshot rollback is
the broken-kernel-update fallback (mkinitcpio 41 ships no fallback preset, noted).


### network-stack — NetworkManager

**picked** · 2026-08-23 · packages: networkmanager

**Measured:** —

No row existed. Phase 2's hand install used iwd + systemd-networkd (leaner: ~5 MB vs
NM's ~25 MB resident — a 2b figure with no 2a number attached, per the half-argued-row
rule); the 2026-08-23 handoff recipe assumed NM because the NixOS side runs it and the
wifi profile copies over as-is. Author picked NM that night for bake-off symmetry. The
2b trade is stated out loud: NM is the heavier resident by roughly 20 MB. Revisit for
shipped BunnE after the bake-off — iwd remains the lean candidate and the Phase-2 unit
files are preserved in `docs/phase2-install-log.md`.


### snapshot-system — snapper + snap-pac, pre/post only, qgroup byte-cap

**picked** · 2026-08-23 · packages: snapper snap-pac

**Measured:** canary-proven on `arch-bunny` at the production limit: 22 GiB of snapshots
→ cleanup deleted oldest-first down to 8 GiB and stopped with a snapshot still alive
(floor 0, so the stop was space-driven); +22 GiB real free-space recovered; DA gate
round 2 "survives with caveats" — see `benchmarks/4.1.snapshot-cap.md`

**The missing piece the plumbing always assumed.** `filesystem` created `@snapshots`,
`rollback-method` documented the swap, `snapshot-bloat` demanded retention limits — but
nothing ever *took* snapshots: no row picked snapper, and the Phase-2 log confirms it
was never installed. Author approved the design 2026-08-23: snap-pac pre/post pairs
around every pacman transaction (exactly `rollback-method`'s stated case),
`TIMELINE_CREATE=no` and the timeline timer never enabled (hourly timelines are the
Omarchy machine's bloat engine — gripe #2), and a byte cap: `snapper setup-quota`
(qgroup 1/0) + `SPACE_LIMIT=0.08` (~20 GiB of this 249 GiB fs) + `FREE_LIMIT=0.2`,
enforced by `snapper-cleanup.timer` (daily). **One deviation from what the author
approved, made under DA round 1 and needing ratification: `NUMBER_LIMIT="0-15"` /
`NUMBER_LIMIT_IMPORTANT="0-5"` (floor 0, not 2)** — a nonzero floor exempts the newest N
snapshots from the cap, so two huge snapshots would blow it forever; floor 0 is the
faithful reading of "must not blow up the drive." **Ratified 2026-08-24: the author
chose `NUMBER_LIMIT="2-15"` instead**, with the consequence stated and accepted in full:
the newest pre/post pair always survives (guaranteed rollback across the most recent
transaction — the update most likely to have broken something), and in exchange those
two newest snapshots are **exempt from the byte cap** and can exceed it without
recourse; the DA-proven hard-cap behaviour governs snapshots 3-15 only. The exemption
binds only the automatic cleanup: `snapper delete <N>` removes any snapshot regardless
of the floor (proven on the box 2026-08-24 — a fresh newest number snapshot deleted
manually without complaint), so a pathological exempt pair has a one-command manual
escape hatch. `NUMBER_LIMIT_IMPORTANT="0-5"` unchanged. The `baseline` snapshot stays
pinned (no cleanup algorithm) until the Phase 5 wipe — author, same day. Named edges,
all DA-recorded: snapshots *without* a cleanup algorithm are uncapped **by snapper's
design** (`prepareQuota()` source: only cleanup-class snapshots join 1/0 — so never
leave no-cleanup snapshots around; the install's `baseline` is one, kept deliberately
for the bake-off); enforcement is eventual, worst-case window ≈ `NUMBER_MIN_AGE` 1800 s
+ daily timer ≈ ~1 day; error direction is over-deletion only (dying snapshots' qgroups
linger `<under deletion>` in 1/0 and inflate the reading — one extra 7 GiB snapshot died
for this in the rerun); FREE_LIMIT's real-low-disk behaviour and create-vs-cleanup
concurrency remain untested. Full transcripts: `benchmarks/da-logs/4.1.snapshot-cap.md`.

**Live drift found and fixed 2026-08-26 by writing `install.d/40-snapshots.sh`.** This row
says `TIMELINE_CREATE=no` *"and the timeline timer never enabled"*. On `bunne-test` the
timer was **enabled** — waking hourly to run a service that reads `TIMELINE_CREATE`,
decides there is nothing to do, and exits. Harmless in output and completely pointless in
cost: 24 wakeups a day for a decision that had already been made against it. Now
`disabled` and `inactive`, verified. **The general point is worth more than the fix:** a
decision recorded in prose and applied by hand can drift without anything noticing, and
writing the installer step is what compared the two. Every step since has found one of
these.

**What the deviations actually are, read rather than described.** Diffing the live config
against `/usr/share/snapper/config-templates/default` gives exactly five of ours —
`SPACE_LIMIT`, `NUMBER_LIMIT`, `NUMBER_LIMIT_IMPORTANT`, `NUMBER_MIN_AGE`,
`TIMELINE_CREATE` — plus `QGROUP="1/0"`, which is not set by hand but written by `snapper
setup-quota`. Two things this row's prose implies but the diff refutes: `FREE_LIMIT="0.2"`
and `NUMBER_CLEANUP="yes"` are **already the template defaults**, so setting them would be
restating upstream. The installer sets the five and runs `setup-quota`, and nothing else.


### launcher — fuzzel

**picked** · 2026-08-21 · packages: fuzzel

**Measured:** spawn → on-screen **~25 ms** (3.8, via niri IPC); re-sampled on the fresh
install **21.9 ms median, n=19 warm** (load 0.0, 4.12 close); **0 MB resident** —
per-use process, and a pure cairo/pixman shm client: maps zero GPU/GL libraries (4.12)

**Recorded 2026-08-25 by the 4.17 audit — the decision itself was made and deployed long
ago and never got a row**: installed with the desktop set, bound to `Mod+D`,
acceptance-tested session 7 (2026-08-21), and listed in nix-bunne's winners table.
Recording, not re-deciding; author glance requested.


### wallpaper — swaybg, solid `-c #0f0f0f`

**picked** · 2026-08-21 · packages: swaybg

**Measured:** **8.2 MB resident** (session-7 measurement)

Same 4.17 audit class as `launcher`: spawned at startup by the shipped niri config,
measured, in the winners table, rowless here until 2026-08-25. The one resident process
bought purely for priority 3 (niri alone draws flat grey; the theme requires matte
black) — the 2b trade was accepted in session 7 with the cost stated. Author glance
requested.

**TODO — real wallpapers, several to choose from, different ones per monitor** (author,
2026-08-25). This supersedes the solid-colour premise of the row above; the row stays
`picked` for the *package*, but `-c #0f0f0f` becomes the fallback rather than the answer.
The ask, in the author's words: *"the ability to select from several types of wallpaper
easily"*, *"prep the pictures in `assets/wallpaper/`"* for **1920x1080, 4K, and
2880x1920**, and *"ideally we can have multiple different wallpapers if a computer has
multiple monitors."* All 22 current wallpapers have bunnies.

**`swaybg` already does the per-monitor half — no new package.** Verified on the desktop:
`-o, --output <name>` (or `*`), repeatable, so `swaybg -o eDP-1 -i a.jpg -o DP-1 -i b.jpg`
is the whole mechanism. Modes are `stretch, fit, fill, center, tile, solid_color`.
This matters because `gpu-topology` says the external DP/HDMI ports hang off the NVIDIA
card while the panel is on Intel — multi-monitor is the author's real configuration.

**Three targets are only two crops.** 1920x1080 and 3840x2160 are both **16:9**; 2880x1920
is **3:2**. So each wallpaper needs one 16:9 crop and one 3:2 crop, and the 1080p asset is
a downscale of the 4K one. That halves the cropping work, and it is the reason to think in
aspect ratios rather than in resolutions.

**Which sources can actually serve which target, without upscaling** (largest crop of the
target aspect that fits inside the source, measured 2026-08-25):

| sources | 1920x1080 | 3840x2160 | 2880x1920 |
|---|---|---|---|
| 15 of 22 — every `*-unsplash.jpg` at 4240x2832 or larger | yes | yes | yes |
| `lisa-siefert-kiSEykBcJXU` (2976x1984) | yes | **no** | yes |
| `jei-lee-p0TGhqO3rck` (2823x2117), the four `photo-*.avif` (2052x1642 … 2831x1593) | yes | **no** | **no** |
| `eevee-fell-into-a-prism-…webp` (**1080x607**) | **no** | **no** | **no** |

So the author's *"not every wallpaper is sure to be able to be used for every dimension"*
is exactly right, and it is 7 of 22. Note the eevee file is **1080x607 despite `1920-1080`
in its filename** — it cannot serve even 1080p and should be re-sourced or dropped.

**Open, and not to be settled unilaterally:**

- **Cropping to content cannot be fully automated.** The author already said *"some may
  have to be cropped to their content"* — a centre crop will decapitate a bunny. Options:
  hand-pick a crop box per image per aspect (accurate, 44 crops), or a saliency auto-crop
  (fast, wrong sometimes, and wrong is very visible on a wallpaper). Lean hand-picked given
  22 images is a one-time cost and priority 3 is a first-class feature.
- **Generate at install, or commit the derivatives?** **The package half of this
  question is void: `imagemagick` already ships**, as a picked package on the
  `jupyter-in-neovim` row (`image.nvim`'s `magick_cli` backend needs it) — confirmed by
  `scripts/check-packages.sh`. So generating costs **no new package**, only install-time
  latency: 52 crops took **17 s** on the author's desktop, and would be slower on the
  target. Committing the derivatives costs nothing at runtime and nothing at install.
  Disk is explicitly not a criterion here, so what is left is a small install-time-latency
  question against keeping ~40 MB of derived files in git.
- **The 52 MB of originals are now in git history.** If the derivatives are what ships,
  the originals arguably belong somewhere else.
- **What "select easily" means.** A `bunny` subcommand, a niri keybind cycling the set, or
  a picker entry — undecided, and it interacts with the `launcher` row.
- **Priority 2 cost, now measured** (2026-08-25, `bunne-test`, two 1920x1080 outputs):
  solid `-c #0f0f0f` **2.2 MB PSS**, one image on both outputs **9.1 MB**, a different
  image per output **18.0 MB**. So wallpapers cost **+6.9 MB PSS** over solid and
  per-monitor variety **+8.9 MB more again** — the decoded buffer is per output, not
  shared. This also most likely **explains BUDGET.md's 8.2 MB puzzle as an RSS reading**
  (solid measures 8.1 MB RSS) — *consistent with*, not proven (DA round 19), since that
  figure came off a different machine and the original command was never recovered. All
  three figures are **single samples taken 2–3 s after start**, not steady state. **4K is
  unmeasured and the buffers are 4x the pixels**, so these numbers must not be
  extrapolated to a 4K dual-head machine. A priority-3 spend against 2b, for the author to accept or refuse.

**A single default image shipped 2026-08-27, ahead of the full TODO above**:
`03-clover-dreamer-by-enq-1998.jpg` (1920x1080), `swaybg -i ... -m fill`, `#0f0f0f` kept as
the fallback fill for any output the image doesn't cover. This is a narrower step than the
TODO asks for — one image, every output, no selection mechanism, no per-monitor variety —
not a resolution of it. The "select easily" mechanism and per-monitor assignment are still
undecided.

**"Select easily" resolved, same day, author's word ("we should make an easy way to
change the background")**: `scripts/bunny-wallpaper.sh` — `fuzzel --dmenu` over the
`1920x1080/` basenames (same invocation style as the `Mod+Ctrl+V` cliphist picker), repoints
`$XDG_CONFIG_HOME/bunny/wallpaper` (a symlink, `config/README.md`) at the chosen image, then
`pkill swaybg` + respawn so the change is live immediately, not just on next login. niri's
own startup line now points `swaybg -i` at that symlink instead of a hardcoded path, so a
reboot just follows whatever it currently targets. `install.d/87-wallpaper.sh` seeds it once
(scaffold-never-own, same shape as `dir-aware-display`'s `dirmap.conf`) — **default changed
2026-08-27 to `15-neon-hare-by-omar-ramadan.jpg`** (author's word), off the `03-clover-dreamer`
placeholder above. Per-monitor variety and the multi-resolution question are still
undecided — this script only ever reads `1920x1080/`. **Verified on `bunne-test`**: `niri
validate` passes on the new startup line; the symlink-then-respawn sequence was run directly
(seed the link, `pkill -x swaybg`, respawn pointed at the link) and `pgrep -a swaybg` showed
it running against the symlink path afterward. The `fuzzel --dmenu` half needs a real
Wayland session and wasn't exercised interactively — only the mechanism it drives.

### screenshot — niri built-in actions + satty for annotate

**picked** · 2026-08-23 · packages: grim slurp satty

**Measured:** — (no resident cost; all per-use)

**Recorded 2026-08-25 by the 4.17 audit** — installed on install night (2026-08-23
22:52, pacman.log) per session 7's "install-and-bind" C4 item, never recorded.
As-deployed: `Print`/`Ctrl+Print`/`Alt+Print` are bound to **niri's built-in
`screenshot*` actions** (own picker, no grim needed on that path); grim+slurp remain the
scriptable path satty consumes. **Gap the audit exposed: satty is bound to nothing — the
annotate half of C4 is installed but unreachable by key.** Keybind decision needed
(author, with the Phase-4 keybind block). C4 acceptance (screenshot→annotate→clipboard
round-trip) still pending.

**Bound 2026-08-25 (author's 2026-08-25 queue, `docs/open-questions.md`).** `Mod+Print {
spawn-sh "grim -g \"$(slurp)\" - | satty -f -"; }` — drag a region, satty opens on the
grab for annotation. The pipeline itself was verified live on the box (grim writes a
valid PNG to stdout, satty reads `-f -`); only the region drag is interactive. Goes in
the Phase-4 keybind block, closing the C4 annotate gap the 4.17 audit found — satty was
installed and reachable by nothing.

**In the config 2026-08-25** (`benchmarks/4.24`, screenshot
`benchmarks/raw/4.24.satty-c4-proof.png`). The bind is in `config/niri/config.kdl` as
deviation 9; `scripts/check-keybinds.sh` reads 121 chords with no duplicates and `niri
validate` passes. Driven over IPC with a fixed geometry standing in for the interactive
`slurp` drag, satty opened as the only window (`app_id com.gabm.satty`) with a 640×400
image loaded.

**The "pipe proven" claim is downgraded (DA round, same day), and the criticism is
right: the test could not have failed visibly.** The captured region was empty desktop,
so the image satty holds is a **flat RGB(15,15,15) field** — the same colour as the
wallpaper around it. A wrong region, stride, pixel format, or a half-drawn frame would
all render identically. What is established is only that a 640×400 PNG of one uniform
colour reached satty, and that it was `0f0f0f` rather than `000000`, so not a zeroed
buffer. Capturing a region containing text would have been decisive and cost nothing.

**Two gaps this leaves, both wanting a decision rather than just a retest:**
`slurp` — the interactive half the bind is built around — was never exercised, since the
tested command used a hardcoded geometry. And **`slurp`'s cancel path is silent**: press
Escape and it exits non-zero with empty stdout, `grim -g ""` fails, and satty is handed
an empty stream, inside a `spawn-sh` with no terminal to complain to. That is the
*default* user gesture failing invisibly, which `CLAUDE.md`'s "fail loudly, do not
degrade silently" rule covers directly — it wants either a guard in the bind or an
explicitly accepted silence. C4's remaining acceptance is therefore one real
annotate-and-export by hand, plus that decision.



**Cancel guarded 2026-08-25 (open question 25, author: "guard the bind").** The bind is
now `sel=$(slurp) || exit 0; grim -g "$sel" - | satty -f -`. If the assignment's command
substitution fails — which is what Escape during the drag produces — the whole `spawn-sh`
exits 0 and nothing else runs, so cancelling is a clean no-op instead of a silent failure
propagating through `grim -g ""` into satty. `niri validate` clean, deployed to
`bunne-test`, and **both branches tested under `sh -c`** rather than assumed: the cancel
path prints nothing and exits 0, the success path passes the region string through. A
mako notification was rejected as the alternative — it would fire on every deliberate
Escape, which is noise, not a diagnosis.

**Still open on this row:** `slurp`'s interactive drag has never been exercised
end-to-end by hand, and the flat-colour proof image above still needs one capture
containing text to be decisive. Both want the author at the keyboard.

### brightness-keys — brightnessctl on XF86 keys

**picked** · 2026-08-23 · packages: brightnessctl

**Measured:** — (no resident cost; per-keypress binary)

**Recorded 2026-08-25 by the 4.17 audit** — installed install night, and the shipped
config already binds `XF86MonBrightnessUp/Down` with `allow-when-locked=true`
(deliberately usable at the lock screen — the same `do_action` gate the 4.15 lock
correction documents). Hardware acceptance (keys actually change the panel) worth one
press next hands-on sitting.


### kernel-boot-entries — limine-mkinitcpio-hook (same publisher as the snapshot tool)

**picked** · 2026-08-25 · packages: limine-mkinitcpio-hook

**Measured:** no runtime cost to measure — a pacman hook that runs at kernel
install/removal only; zero resident, zero boot, nothing in any interactive path. Version
on the author's desktop: `1.37.1-1`, from the same `[omarchy]` repo and the same signing
key as `limine-snapper-sync` (verified 2026-08-25).

**Picked 2026-08-25 (author's 2026-08-25 queue, `docs/open-questions.md`), as the direct
consequence of unblocking `snapshot-boot-entries`.** `limine-snapper-sync` manages
*snapshot* entries and explicitly does not generate entries for newly installed kernels
— upstream points at the `limine-entry-tool` family for that, which is the same Zesko
codebase, the same GraalVM build problem, and therefore the same binary-repo answer.
Without it `limine.conf` is hand-maintained, and a hand-maintained bootloader config
drifts silently the first time a kernel is added, removed or renamed: the machine keeps
booting off the old entry until the day the old kernel is gone, which is a priority-1
failure on the one file recovery depends on. The hook writes the entry when the kernel
is installed and removes it when the kernel is removed, in the same transaction, so the
config cannot disagree with `/boot`. Trust posture is inherited wholesale from
`snapshot-boot-entries` — same repository, same pinned fingerprint, same
last-in-`pacman.conf` shadowing — so it adds no new trust surface, only one more package
from a publisher already trusted. **Not yet installed on `bunne-test`:** it lands with
the snapshot-entry acceptance run, and it is what will rewrite today's hand-written
`limine.conf` into the `//Kernel` + `//Snapshots` shape that row describes.

**Installed 2026-08-25, and it did rewrite the config unprompted** (`benchmarks/4.24`).
On install it built the initramfs, deposited a content-hashed kernel + initramfs pair
under `/boot/<machine-id>/linux/`, registered a `Limine` UEFI entry, and emitted the
`//linux` child entry — all in the same pacman transaction, which is the drift-proofing
this row was picked for. `limine-list` renders the tree, so the state is inspectable
rather than inferred.

**Deviations go in `/etc/default/limine`, not in the shipped
`/etc/limine-entry-tool.conf`** — upstream's own file says so in its first line, and
the pacman-owned copy would be clobbered on upgrade anyway. One deviation so far:
`FIND_BOOTLOADERS=no`. With the default `yes` the tool scans the ESP and adds an "EFI
fallback" entry for `/boot/EFI/BOOT/BOOTX64.EFI` — which on a limine machine is
**byte-identical to `limine_x64.efi`**, i.e. a menu entry that chainloads the menu you
are already in. Confirmed with `cmp`, entry removed with `limine-remove-entry`. Harmless
but incoherent, and exactly the kind of unexamined line this repo does not ship.

**Trap this row now owns, because it cost a boot.** `limine-entry-tool` writes the
`default_entry` + `/+Name` scaffolding only for OS entries it **creates**. Adopting a
pre-existing hand-written entry — what happens on any machine that had a working
`limine.conf` before the hook arrived — it adds children and leaves the scaffolding
alone. The moment that entry becomes a directory, `default_entry` defaults to `1`, entry
1 is the folder, and limine forces the timeout off and waits at the menu forever
(mechanism read from `common/menu.c`, v12.5.2; see `snapshot-boot-entries`).

**What the installer must therefore do:** set `default_entry` explicitly, **in the path
form** (`default_entry: Arch Linux/linux`), which cannot resolve to a directory and
cannot be renumbered when the tool reorders entries. The numeric form additionally
requires `/+Name`, because a collapsed directory hides its children from the numbering —
two coupled edits where forgetting one is a *different* failure, which is precisely the
shape that caused this. `scripts/check-limine.sh` enforces it. Full account in
`benchmarks/4.24`.


### disk-alert — user timer, one `df`, threshold 80%

**picked, shipped** · 2026-08-26 · packages: —

**Measured:** rewrite: **8.7 ms ± 0.8 (n=964)** healthy-run cost, down from 3-6 s — see
below. Original three-meter version: healthy run **3-6 s wall**, silent, exit 0; fires a
critical mako notification on a forced breach (`DISK_THRESHOLD=0`, screenshot in
`benchmarks/raw/p4-disk-alert-draft/`). **Soak: three consecutive unattended firings**
(00:00:30, 04:01:16, 08:00:16 on 2026-08-25) across a reboot and an OS flip, zero false
alerts, zero misses, timer rescheduling itself correctly. Zero resident: a user timer
firing 6x/day, nothing in any interactive path.

**Shipped 2026-08-26.** Author, reviewing the three-meter draft: *"i dont like the
disk-alert. way too many lines of code. simplify the hell out of it."* Rewritten to **one
`df`** — 19 lines across 3 files, down from 183 across 5 — because every byte this repo
worries about (Docker images, volumes, snapshots, the package cache) lives in the same
btrfs pool as `/`, checked rather than assumed (`df -B1` reports identical used/size bytes
for `/`, `/home`, `/var/lib/docker`, `/var/lib/containerd` and `/.snapshots`). That also
removed the root-owned helper and its `NOPASSWD` sudoers entry entirely — they existed only
because reading qgroups needs root, and the rewrite doesn't read qgroups. Per-subvolume
attribution moved from the notification body to the three commands it now names
(`lazydocker`, `snapper list`, the package cache); the `UNMONITORED` breach states and the
`docker`-group/sudoers-templating installer items are gone because the mechanisms that
needed them are gone. Files at `config/systemd/user/`, symlinked like everything else in
`config/` by `70-dotfiles.sh`; the timer is enabled by `install.d/80-disk-alert.sh`. Tested
on `bunne-test` in all four shapes — healthy, forced breach, delivered through mako for
real (which also confirmed `notifications`' D-Bus-activation design), `shellcheck`/`shfmt`
clean. **The 80% threshold is unchanged and is still the author's number to move** — on
this box's 249 GiB filesystem that's ~50 GiB free at the fire point. Full history:
`benchmarks/raw/p4-disk-alert-draft/NOTES.md`.

**Ratified 2026-08-25 (author's 2026-08-25 queue, `docs/open-questions.md`)** — the
design, not just the soak. This is the alarm on the caps that `docker-storage-quota` and
`snapshot-system` set: those rows stop the disk filling, this row is what tells the
author it is happening. **Since 2026-08-26 that is no longer the division of labour** —
`docker-storage-quota`'s caps are gone (open question 26), so where Docker is concerned
this row is not the alarm on a wall, it *is* the protection. Port of the predecessor's `disk-usage-alert`, taught btrfs
qgroups, with the threshold moved 85 → **80**. Three meters instead of the predecessor's
one: (1) root filesystem via `df`; (2) the two Docker subvolumes' referenced bytes, read
through one root-owned read-only helper (`/usr/local/sbin/disk-qgroup-usage`) whitelisted
by a narrow sudoers entry — the predecessor's exact pattern; (3) snapper's own qgroup exclusive bytes against its
`SPACE_LIMIT x fs-size` budget, so the alert precedes cleanup pressure rather than
reporting it afterwards. **A missing helper is itself a breach** ("UNMONITORED"),
because monitoring that is silently off is indistinguishable from monitoring that is
broken. Installer items this raised, all recorded rather than fixed here: the user must
be in the `docker` group or the alert loses its most useful culprit line; the sudoers
file is templated on the username rather than hardcoding `bunne`; mako's default body
height truncates the diagnostics, which is a `notifications`-row cosmetic decision, not
this one's. Units live in `benchmarks/raw/p4-disk-alert-draft/` and move into `config/`
with the Phase-4 port.


**Meter 2 reworked 2026-08-26, and it had to be — the caps it read no longer exist.**
`docker-storage-quota` dropped the qgroup limits (open question 26), and this meter
selected its rows by *"has a numeric `max_referenced`"*. With no limits set, that filter
matches nothing: the meter would have gone quiet, reported healthy, and monitored Docker
not at all — with no cap behind it any more. Precisely the failure `CLAUDE.md` names, and
it would have arrived as a side effect of a decision made elsewhere.

The fix keeps the author's numbers and changes what they mean. The helper stays dumb —
every qgroup, path and referenced bytes, no filtering — and the alert carries the watch
list: `WATCH=([containerd]=100 GiB [dockervol]=50 GiB)`. **The figures that used to be
walls are now thresholds**, so the 80% line still fires at the same place it always would
have. And a watched subvolume *absent* from the helper's output is itself a breach
("UNMONITORED"), which covers the two ways this can silently stop working: the subvolume
gone, or `btrfs quota disable` run on the filesystem.

**All four states tested on `bunne-test`** (2026-08-26, `notify-send`/`paplay` stubbed on
`PATH` so nothing fired at the author):

| state | result |
|---|---|
| healthy | silent, exit 0, unit `success` through the real timer path |
| `DISK_THRESHOLD=0` | fires; containerd correctly reports 0% of 100 GiB |
| watch narrowed to 120 MiB | `📦 containerd at 85% of its watch — 104MB of 120MB` |
| watched rows absent from helper | `❓ containerd absent … UNMONITORED`, both subvolumes |

The 85% line is the replacement for the old *"87% of its cap"* proof, and it is a strictly
safer test: it narrows the **threshold** rather than narrowing an enforcing cap, so nothing
on disk changes and no write can be denied.

**Two bugs the run found that reasoning had not.** (a) The helper stripped a leading `@`
to prettify `@containerd`, which turns the root subvolume `@` into the **empty string** —
a hard error as a bash associative-array subscript, printed on every healthy run. It was
invisible before only because the old cap filter excluded `@`. (b) The parse now rejects an
empty path before the lookup rather than after. Both are the kind of defect that only
appears when the thing is actually executed.

### display-manager — getty-autologin; greetd driven and rejected

**picked** · 2026-08-25 · packages: —

**Measured:** `benchmarks/4.19`. greetd: **~6.8 MB PSS resident forever** across two
processes (`Restart=always`) — the earlier "~2 MB" estimate was 3x light. Boot: **no
detectable difference** (greetd 2.906/2.690 s vs autologin 3.244/2.708 s; within-config
spread exceeds the gap). greetd worked first try on both boots (niri up, spawn canary
PASS, polkit agent running). getty-autologin: **0 MB**.

**Deferred 2026-08-25 by the author (author's 2026-08-25 queue,
`docs/open-questions.md`): he wants to drive both himself before picking.** The
measurement is done and says the trade is 6.8 MB forever against a supervised session
plus a real greeter on logout; getty- autologin is an instant re-login loop with no
greeter and no resident cost. On priority 2b alone getty wins on a single-user autologin
box, but this is a feel-of-the-machine question and the numbers are close enough that
measurement cannot settle it. **State on `bunne-test`:** greetd is installed and
**disabled**, box reverted to getty-autologin and verified; flipping between them is
`systemctl enable/disable greetd` plus a reboot. **One thing to re-check before greetd
could ever ship:** it changes the session class to `greeter`, so the screen-share portal
acceptance (`portal` row) has to be re-run under it — a greeter-class session is not the
same object to xdg-desktop-portal.

**Test drive set up 2026-08-25, on the box, awaiting the author's verdict.**
Deliberately *not* the shape 4.19 measured: that run used `default_session` alone, which
autologins forever and therefore feels identical to getty-autologin — nothing to drive.
`/etc/greetd/config.toml` now carries the shape the decision is actually about —
`initial_session` = `niri-session` as `bunne` (first boot goes straight to the desktop,
LUKS remains the only prompt) and `default_session` = `agreety --cmd niri-session` as
`greeter` (a real text greeter on logout instead of an instant re-login). `greetd` is
enabled — it takes over tty1 by `Conflicts=getty@tty1.service`, so no getty change was
needed — and takes effect on the next reboot. The resident number transfers from 4.19
(the greeter binary only runs after a logout). Previous config saved as
`config.toml.getty-era.bak`; snapper snapshot 66 taken before the change. **Revert:**
`sudo systemctl disable greetd && sudo cp /etc/greetd/config.toml.getty-era.bak
/etc/greetd/config.toml`, reboot.

**Observed running, 2026-08-25 evening — the drive has started, and one worry looks
smaller than it did** (`benchmarks/4.24`; incidental to that session's work, not a
measurement run). The `initial_session` shape came up first-try and was still the live
configuration across the evening's reboots: `greetd` enabled and active,
`getty@tty1.service` **inactive** — its own `Conflicts=getty@tty1.service` handles the
tty hand-off, so the autologin drop-in can stay in place unused rather than needing to
be removed and restored to flip between them.

**The refinement worth having: `loginctl list-sessions` shows the initial session as
`bunne`, seat0, tty1, class `user`** — not `greeter`, even though its leader is
`greetd --session-worker`. So 4.19's "session class becomes `greeter`, re-run the portal
acceptance" applies to the **`default_session`/`agreety` path** (which does run as the
`greeter` user), and not to the desktop session a normal boot lands in. **Scope this
honestly: one observation, one machine, and the logout path was never exercised.** It
narrows what has to be re-tested before greetd could ship; it does not remove the
re-test, and it settles nothing about the actual question, which is whether the greeter
is worth 6.8 MB. That remains the author's to answer by using it.



**Decided 2026-08-25 (late) — getty-autologin. greetd is removed, not merely disabled.**
The author drove it across the evening's reboots and the verdict was about feel, exactly
as this row predicted measurement could not settle: *"greetd did nothing that seemed
worthy of keeping. I just saw a tty. not sure what you expected me to see but it doesn't
seem worth it. let's get rid of it."*

Worth recording *why* the drive nearly failed to happen: greetd was configured with
`initial_session`, so it goes **straight into niri at boot and the greeter only ever
appears on logout**. The author reasonably read a silent boot as "nothing to test" — the
comparison needed one deliberate logout, not more reboots. When he did see it, it was
`agreety`: a bare text login on a TTY. **6.8 MB PSS forever for that is an easy no.**

Applied and verified: `systemctl disable greetd`, `getty@tty1` re-enabled,
`pacman -Rns greetd` (took `greetd-agreety` with it, 650 KiB, nothing else depended on
it), `/etc/greetd` removed, and no `display-manager.service` symlink remains. **Two
reboots confirm it** — niri running, `getty@tty1` active, zero failed units, and the
autologin path was intact throughout
(`/etc/systemd/system/getty@tty1.service.d/autologin.conf` plus `exec niri-session` in
`.bash_profile`). The 6.8 MB is the whole difference and it is now zero.
**Boot is a wash — on the strength of `benchmarks/4.19`'s n=2-per-arm measurement above,
not on tonight's numbers.** Tonight produced single `systemd-analyze` samples of 17.658 s
(getty) and 17.344 s (greetd) from boots whose state differed in several ways; **DA round
19 rejected quoting that 0.314 s gap as evidence**, since 4.19's own within-config spread
exceeds it. Recorded here as non-evidence so nobody re-quotes it.

**The screen-share portal re-acceptance worry attached to this row is void** — it applied
to a greeter-class session, and there is no greeter any more.

**Known consequence, 2026-09-01: getty-autologin means gnome-keyring can never
auto-unlock, and every fresh install will hit this.** `gnome-keyring` (pulled in as a
hard dependency of `bitwarden`, see `keybind-apps`) autostarts locked via
`/etc/xdg/autostart/gnome-keyring-*.desktop`. The usual fix, `pam_gnome_keyring`, uses
the password typed at login to unlock the keyring — but `agetty --autologin` never runs
PAM authentication at all, so no password is ever available to feed it. This is not a
bug to patch; it is a structural consequence of picking autologin over a real login
prompt, so it gets one documented line rather than an install-time workaround (`CLAUDE.md`
on expected absences). The first time anything (typically Bitwarden or Brave) asks to
store a secret, gnome-keyring prompts to create a new keyring and set **its own**
password — unrelated to the Linux login password, which is why that password never
satisfies the prompt. **Fix on first prompt: set a blank password** (and confirm past
the "no password" warning) — consistent with a box that already boots to a desktop with
no password at all. If a keyring was already created with a forgotten password, delete
`~/.local/share/keyrings/{default,*.keyring}` and let it recreate on the next secret
request.

### palette — one palette file + `envsubst` templater

**picked** · 2026-08-25 · packages: —

**Measured:** `envsubst` templater **2.3 ms** to render every config from one palette
file, and it reproduces hand-picked colors **exactly**. `matugen` 13.1 ms and — the
disqualifying part, tested under both config syntaxes including `blend=false` — it
*tones* hand-picked colors rather than passing them through. `wallust` was not measured:
it has dropped to an AUR git package. Details in `docs/megaultrabunny-research.md`.

**Picked 2026-08-25 (author's 2026-08-25 queue, `docs/open-questions.md`), on
measurement.** The C10 requirement is that one palette change propagates everywhere,
which is priority 3's "colors come from one shared source". Three mechanisms were
compared and the cheapest one also turned out to be the only faithful one. `matugen` and
`wallust` are *material-you* generators: they derive a harmonized scheme from an image,
which is the wrong grain for a hand-designed matte-black-and-neon palette — asked for
exact hex values they returned toned approximations, and no config syntax turned that
off. The templater is about five lines: a `bunne.palette` file of `NAME=hex` shell
assignments, and `envsubst` rendering `*.in` templates for kitty, niri, fuzzel, mako and
the rest. **Zero packages** — `envsubst` comes from `gettext`, which is a `base`
dependency, so nothing is installed for this. Nothing resident, nothing at boot, and the
cost is paid only when the palette is edited. Wallpaper color extraction, if it is ever
wanted, becomes a generator that writes the palette file rather than a runtime
dependency of every config.

### docker — docker + compose, socket-activated

**picked** · 2026-08-25 · packages: docker docker-compose

**Measured:** **0 resident until first use** — `docker.socket` is enabled,
`docker.service` is not, so `dockerd` starts on the first `docker` call and not at boot.
No boot-time cost. Storage behaviour measured separately in `benchmarks/4.5` and capped
by `docker-storage-quota`.

**Written 2026-08-25 (author's 2026-08-25 queue, `docs/open-questions.md`).** Docker was
installed on `bunne-test`, governed by `docker-storage-quota`, and picked by no row at
all until this one — caught by the 4.21 audit's reverse sweep, and exactly the kind of
gap that makes a generated-from-the-ledger installer ship an incomplete machine. It is a
data-science staple and the workload this box exists for; the decision here is only
*how* it ships, and the answer is **socket-activated**: `systemctl enable
docker.socket`, never `docker.service`. That is what keeps a multi-hundred-megabyte
daemon off the idle RAM budget for the days it goes unused, and it costs one first-call
delay when it is actually wanted. **`docker-compose` (the plugin, not the old Python
`docker-compose` binary) ships with it** — it runs nothing, adds no daemon and no
autostart, and a data-science box is expected to have it; that is the low-bar case the
parsimony rule describes rather than the audit-surface case it warns about. **Installer
item, and it is not optional:** the user must be added to the `docker` group, or every
`docker` call needs `sudo` and the `disk-alert` row loses its most useful culprit line.
Caps, the storage driver and the subvolume layout are all `docker-storage-quota`'s
business, not this row's.


## Example: working `limine.conf` (ESP-mounted `/boot`)

Confirmed booting `Arch Linux (zen)`, fallback, and Windows chainload on real
hardware after the ext4-`/boot` fix above. UUIDs are this specific machine's —
substitute your own `cryptsetup luksUUID`.

```
timeout: 3

/Arch Linux (zen)
    protocol: linux
    kernel_path: boot():/vmlinuz-linux-zen
    module_path: boot():/intel-ucode.img
    module_path: boot():/initramfs-linux-zen.img
    cmdline: cryptdevice=UUID=a62ff676-2c64-419a-9b3a-c8297160881c:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw

/Arch Linux (fallback)
    protocol: linux
    kernel_path: boot():/vmlinuz-linux
    module_path: boot():/intel-ucode.img
    module_path: boot():/initramfs-linux.img
    cmdline: cryptdevice=UUID=a62ff676-2c64-419a-9b3a-c8297160881c:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw

/Windows
    protocol: efi_chainload
    image_path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
```


### status-bar — waybar — the clock is what buys the 28.4 MB

**picked** · 2026-08-26 · packages: `waybar`

**Measured 2026-08-26 on `bunne-test`, in the live niri session** (waybar 0.15.0-2, a
5-module bar: `niri/workspaces`, `clock`, `wireplumber`, `disk`, `battery`):

| | |
|---|---|
| resident | **28.4 MB PSS** (48.5 MB RSS, 22.5 MB private, 12 threads) |
| idle CPU | **2 ticks / 120 s = 0.017%** — negligible |
| spawn to bar drawn | **86 ms**, n=3, no spread (per-login bucket) |
| new packages | **14** (~5.7 MB), including `gpsd`, `libmpdclient`, `jsoncpp`, the gtkmm3 stack |

**The config barely matters, and that is the finding.** The author's own Omarchy bar —
same version, plus `custom/weather`, `custom/update` and `custom/voxtype`, each of which
polls and forks — measures **29.8 MB PSS** on the desktop. Five static modules cost 28.4
MB. **The GTK3 runtime is ~95% of the number**, so trimming the module list is not a lever:
`03-alternatives.md`'s "keep it to clock, workspaces, audio, disk" saves about 1.4 MB.

**The comparison the author should actually weigh is `display-manager`.** greetd was
rejected six days ago at **6.8 MB PSS**, and the reason given was that a bare text login
did nothing worth 6.8 MB. Waybar is **4.4× that number**, permanently, for a bar. Against
the resident-RAM budget it is 28.4 of 600 MB and takes the bucket from ~343 MB (57%) to
~371 MB (62%) — comfortably inside, and BUDGET.md rule 6 says that is not the test.

**What it buys** is the honest other half: a clock, workspace indicators, volume, battery
and a disk meter that are visible without a keystroke. On priority 2a it is *neutral to
positive* — every one of those is currently a command you type, and 0 ms to glance beats
`date`. This is exactly the 2a-versus-2b trade CLAUDE.md says must be stated out loud
rather than resolved silently, and the size of it is 28.4 MB.

**Three things not measured, named rather than left to the RAM figure:**

1. **Whether the author misses a bar at all.** He has run one continuously under Omarchy,
   so he has never been without one on this workflow. Driving niri barless for a week is
   the cheap experiment and it has not been run.
2. **The `disk` module against `disk-alert`.** That row already delivers the disk warning
   at 80% through a 6×/day timer at **0 resident**. A `disk` module is a second
   implementation of the same information at 28 MB — if the bar is wanted *for* the disk
   meter, `disk-alert` is the cheaper answer and already picked.
3. **niri's own alternatives.** niri draws workspace indicators in its overview, and
   `clock` is `Mod+T`-and-type away. Nothing here has compared "bar" against "the same
   information one keystroke deeper", which is the 2a question.

**Alternatives, and the shelf is thin.** Of the obvious lighter bars, only **`ironbar`**
(extra, 25.9 MiB installed) is in the official repos — `yambar`, `sfwbar`, `eww` and
`hyprpanel` are all AUR, which is a maintenance surface this repo has so far only accepted
for `yay-bin`, `brave-bin` and `satty`. ironbar is GTK4-based and unmeasured here; if the
28.4 MB is the blocker rather than the concept, it is the one candidate worth a bake-off.

**PICKED 2026-08-26, same day, by the author — and on the one thing this row did not
weigh.** *"i want waybar. i check the time quite often, so having info similar to what i
have on Omarchy: day, time ~ date ~ week ~ weather is definitely worth it to me."* The
analysis above put the 28.4 MB against workspaces, volume, battery and a disk meter, all of
which niri or `disk-alert` already answer more cheaply, and it recorded "whether he misses a
bar at all" as unmeasured. The answer is that **a clock is not a bar feature, it is the
bar's whole reason to exist here**, and it is the one thing on the list with no keyboard
equivalent worth having — checking the time by typing `date` is exactly the priority-2a
failure this project is about. 28.4 MB, knowingly, for that.

**The bar carries the five things he named and nothing else**: day, time, date, ISO week,
weather. Battery, network, volume, workspaces and a tray are each one config line and are
absent because nothing asked for them. The clock format is his Omarchy string verbatim,
`~` separators and all — `{:L%A %I:%M %p ~ %d %B %Y ~ W%V ~}`, with `format-alt` swapping
to 24-hour on click.

**Weather is one script and one request, against Omarchy's two of each.** `config/waybar/weather`
curls wttr.in's plain-text `?format=%t+%C` endpoint and prints `76°F Overcast`. Three things
that shape is deliberately not doing:

- **No `jq`, no JSON, no icon font.** Omarchy pulls `format=j1`, parses it with `jq` to
  extract a numeric weather code, and maps 40 codes to Nerd Font glyphs in a 30-line case
  statement. `jq` is not installed here, `font` picked Fragment Mono (no icon glyphs), and
  the glyph shows *less* than the temperature does. `curl` needs no row of its own: `pacman`
  depends on it, so it is present on every Arch machine by construction.
- **900 s, not 60.** Omarchy's module fires **1440 HTTPS requests a day** at a service whose
  data refreshes about hourly, each one a `curl` plus a shell plus three `date` forks. 15
  minutes is 96 a day — a **93% cut** in requests, forks, and in how often the machine tells
  a third party where it is — for a difference in a displayed temperature that cannot be
  perceived.
- **One request, not two.** Omarchy runs `omarchy-weather-icon` for the bar and
  `omarchy-weather-status` for the click-notification, each fetching wttr.in separately. The
  temperature goes in the bar and the second request stops existing.

**The location is not in this repo, and the privacy trade is stated rather than inherited.**
With no location wttr.in geolocates by IP, which tells it roughly which city you are in and
is the right default for a stranger who cloned this. The author's Omarchy script has his
lat/lon hardcoded in it; here that is one machine-local line in
`~/.config/bunny/weather-location` (beside the `dirmap.conf` already there), and what it
buys wttr.in is his street rather than his city. His trade, made knowingly, not copied
across silently.

**Failure is visible.** No network, no wttr.in, or a location the service cannot parse — all
three print `weather n/a` rather than going blank, and all three were exercised (unreachable
proxy, garbage location string, empty location file). **No cache, deliberately**: a stale
reading shown as current is a worse answer than no reading.

**A screenshot found a priority-1 bug that running the script by hand could not, and the
first fix for it was wrong.** niri spawns waybar ~9 s into boot; NetworkManager writes
`/etc/resolv.conf` at ~12 s. The first poll therefore cannot resolve anything — and because
`interval` is also the retry interval, **the bar read `weather n/a` for fifteen minutes
after every boot on a machine whose network was fine.** By hand, over ssh, the script always
worked. What exposed it was `grim`-ing the bar one second after a cold boot and looking at
the pixels.

`curl --retry 5 --retry-delay 3 --retry-all-errors` was the obvious fix, it went in, and
**it did not work** — proven by instrumenting the script across a real boot rather than by
assuming: six attempts over fifteen seconds, every one `curl: (6) Could not resolve host`,
including attempts thirteen seconds after the default route came up. **glibc reads
`/etc/resolv.conf` once per process.** A curl started before NetworkManager writes that file
has no nameserver for its entire life, and every `--retry` inside it re-asks a resolver that
was never configured. The timestamps are exact: resolv.conf written `14:15:59.725`, first
curl started `14:15:58.198`. No flag on that process could have recovered.

**The general rule, worth carrying beyond this row: a retry that runs inside one process
cannot fix state that process cached at startup.** `curl --retry`, a library's own backoff,
a connection pool's reconnect — all of them re-ask something already decided. When the thing
that changed is per-process (resolver config, environment, a cached mount table), the retry
has to be a *new process*. Here that is six `curl` invocations five seconds apart, which
covers the ~12 s the network takes with room to spare and costs ~25 s on a genuinely offline
machine, in a background process nothing waits on.

**Verified the only way that counts:** cold boot, screenshot at 76 s uptime —
`Wednesday 02:20 PM ~ 26 August 2026 ~ W35 ~ 76°F Overcast`, zero failed units.

**The lazy-load question was raised and closed the same day.** The author asked whether the
bar could be deferred, on the strength of a `BUDGET.md` row that wrongly put waybar's 86 ms
into the *per-session-login* bucket and reported that total doubling. It does not belong
there — niri forks waybar and carries on, so those 86 ms run concurrently while the
compositor is already taking input, and `hyperfine -N "bash -lc true"` measures **75.7 ms ±
0.6 (n=39)** with the bar present. The wait never changed. For the record, neither deferral
mechanism would have helped anyway: `"start_hidden": true` still runs the process, so the
28.4 MB is still paid (and waybar's own man page notes hide modes "may be not as useful
without Sway IPC" — niri is not Sway), and spawning it from a keybind defers the RAM at the
cost of not having a clock until you press a key, which is the thing the bar was bought for.
**Ratified as-is by the author:** *"i dont mind the 28.4 MB process so let's keep it
as-is."* `spawn-at-startup`, always visible.

**The author on the temperature, 2026-08-26:** *"i like that you print the exact temperature
instead of just a weather icon. that is an improvement over omarchy."* Worth recording
because the simplification and the improvement were the same decision — showing the number
is what made `jq`, the Nerd Font, and the 40-code icon map unnecessary, rather than
something bought at their expense.

**What is still stock and what the styling is not.** `config/waybar/style.css` is almost
empty on purpose — `palette` (C10) says every colour comes from one shared source and app
configs are generated from it, and that templater does not exist yet. The one colour in
there is `#0f0f0f`, already decided by `wallpaper`, so the bar disappears into the desktop
instead of drawing a second, different black across the top of the screen. Like
`niri/config.kdl` and `kitty.conf`, this file is the *input* to the palette generator rather
than the finished article.

**`niri/config.kdl` deviation 6 reversed.** Stock niri spawns waybar; this repo used to
comment that line out. It is now simply uncommented, so the deviation is gone rather than
inverted.

*(Superseded — the deferred state this row held for a few hours:)* waybar was installed and
not running on `bunne-test`, config untracked at `~/.config/waybar/`, nothing in
`install.sh` referencing it.


### git-config — deviations only, identity excluded

**picked** · 2026-08-26 · packages: —

**Measured:** —

`~/.gitconfig` was flagged `absent` in `docs/phase4-config-inventory.md` §6 — the predecessor
repo carries git config as a feature, but `bunne-test` has never had one to harvest (`ssh
bunne-test 'cat ~/.gitconfig'` — no such file). What shipped instead is the author's own live
desktop config (`git config --global --list` on `arch-bunny`'s own machine), which is taste, not
harvested state, and the row exists to say so rather than let `config/README.md`'s "pulled from a
working `bunne-test`" line quietly stop being true.

**Only behavior, never identity.** `config/git/config` (an XDG `$XDG_CONFIG_HOME/git/config` —
git reads it automatically, no `~/.gitconfig` needed) carries `pull.rebase`,
`push.autoSetupRemote`, `diff.algorithm=histogram` + `colorMoved`/`mnemonicPrefix`,
`commit.verbose`, `column.ui`, `branch`/`tag` sort order, `rerere`, and the `co`/`br`/`ci`/`st`
aliases — all reasonable defaults nothing about a specific person. `user.name`, `user.email` and
the `credential.https://github.com.helper` line are deliberately **not** included: personal, and
`CLAUDE.md` wants exactly that kind of detail isolated rather than spread through the repo.
`install.sh` never writes them; a friend runs `git config --global user.name "..."` themselves,
same as any fresh git install.

**This is a taste call the author has not explicitly ratified** — the settings are his own
current preferences, adopted here on the reasoning that they are uncontroversial and already
proven on his own machine, not because he was asked and said yes. Flagged so it reads as a
pointed question rather than a settled fact: keep as shipped, or trim/change any of it.


### media-viewers — imv + mpv; PDF in the browser

**picked** · 2026-08-28 · packages: imv mpv

**Measured:** — (0 daemons, 0 autostart, 0 resident RAM; both are launch-on-demand)

`02-functionality.md` C11 asks for an image viewer, a video player and a PDF viewer, and
until today the machine had none of the three — a requirement with no slot, which is how
requirements quietly stop being met. `imv` is a Wayland-native image viewer with vi-style
keys; `mpv` is the default answer for video and has been for a decade. Neither runs
anything until launched, so both clear the low bar `CLAUDE.md` sets for a package that
costs nothing at boot and nothing at idle.

**No PDF reader is installed, and that is the deviation from C11** (author's choice,
2026-08-28): Brave already renders PDFs, so `zathura` + `zathura-pdf-mupdf` would be
1.9 MB and a second keybind to read a format the browser opens on click. The cost being
accepted is a *keyboard-first* PDF path — `zathura` is the one that would give vi keys
and no chrome. Revisit if reading papers in the browser turns out to annoy; the row is
here so that is a reversal of a stated choice rather than the discovery of a gap.

Both are bound in `keybind-apps`' cascade only insofar as they are default `xdg-open`
handlers; neither gets a `SUPER+` binding, because neither is opened by name — they are
opened by opening a file.


### git-forge-cli — github-cli

**picked** · 2026-08-28 · packages: github-cli

**Measured:** 39.2 MiB installed, 0 daemons, 0 autostart, 0 resident RAM

`02-functionality.md` C7 names `gh` explicitly and the predecessor's own `git-config.sh`
calls it (`gh auth setup-git`, to make it the git credential helper), so the tool was
already load-bearing in the workflow that is being carried forward — it simply had no row.
It runs only when invoked. The 39 MiB is a Go binary, and per `CLAUDE.md` install size is
not a decision criterion here; the audit surface is what counts, and a single static
binary that starts nothing is close to none.

**`gh auth login` is manual, and stays manual.** Same category as `gcalcli init` and the
wifi credentials — an interactive OAuth consent that nothing in this repo should script
(`CHOICES.md` `secrets-bootstrap`). `install.sh` does not run it and does not configure a
credential helper; until the author authenticates once, `gh` is present and unconfigured,
which is the honest state rather than a half-configured one.

**`jq`, `yq` and a postgres client were considered and dropped** (author's choice,
2026-08-28), though C7 names all three. They install nothing that runs and would have
cleared the same bar — the reasoning for leaving them out is that none has a caller in
this repo today, and `CLAUDE.md`'s parsimony rule wants a reason to add rather than an
absence of a reason not to. Any of them is one `pacman -S` away when something actually
needs it.


### shell-helpers — harvest the predecessor's git + diagnosis functions, nothing else

**picked** · 2026-08-28 · packages: —

**Measured:** function definitions only — no fork, no subprocess, nothing on the prompt
path (`prompt-hooks`' rule is not engaged; none of these run unless called by name)

The `shell-startup` row decided against installing a *package* here, which left the
predecessor's `.bashrc` **functions** unaccounted for — and two of them are named as
requirements: C7 wants "the `gu`/`gur` helpers", C9 wants "the diagnosis helpers … port it
whole". Harvested into `config/bash/helpers.bash`, sourced by `install.d/90-shell-helpers.sh`
the same way `prompt.bash` and `dir-display.bash` are, so `.bashrc` stays otherwise
untracked.

What came across, and why each earns its line:

- `_git_default_branch` — resolves `main` vs `master` from `origin/HEAD`. One caller each
  in `gu` and `gur`, which is normally the signature of an abstraction not worth having;
  it survives because the fallback chain is three branches long and duplicating it is how
  the two helpers drift apart.
- `gu` — stash (including untracked), pull the default branch, come back, pop only if it
  actually stashed. The conditional pop is the whole point: an unconditional `git stash
  pop` on a clean tree pops someone else's stash.
- `gur` — `gu`, then rebase onto the default branch.
- `diagnose` / `diagnose_snapshots` / `_hr` — the C9 disk-forensics helpers. These are the
  ones that "saved the machine before".

**What was deliberately left behind**, so the omissions read as decisions:

- The conda block (`miniforge3/etc/profile.d/conda.sh`) — `python-env-manager` picked `uv`;
  the predecessor's conda is gone, and the block hardcoded `/home/char` besides.
- The Omarchy `default/bash/rc` source — that substrate does not exist here.
- `~/vpn/.vpnrc` — `CLAUDE.md`'s employer/client rule. The generic mechanism, if it is ever
  wanted, is its own row.
- `check` (sha256 verify), `empty-trash`, and the `vim`/`vi`/`chad` aliases — taste, not
  contract (author's choice, 2026-08-28: "git + diagnose only"). `check` in particular is
  `sha256sum -c` with an argument check around it, which is the shape `CLAUDE.md`'s
  parsimony rule points at.
- `emergency` (`rm /var/reserved-space.img`) — depends on a reserved-space file this repo
  never creates. `disk-alert` is the protection here, not a reserve.

Two things changed rather than being ported verbatim, both for reasons this repo already
decided. `diagnose`'s final `sudo ncdu -x /` is **dropped** — `ncdu` is not installed and
nothing else wants it, so the function would have ended in a command not found; the eight
sections before it are the diagnosis. And `diagnose_snapshots` no longer runs `btrfs quota
enable` / `quota rescan -w` first: `40-snapshots.sh` enables qgroup accounting at install
time, so the predecessor's enable-then-rescan was working around a machine this one is not.
The `qgroup show` is sorted by the **exclusive** column, since shared bytes free nothing when
a snapshot is deleted.

**`libnotify` added to this row, 2026-08-28.** `mako` is the *daemon*; `notify-send` is the
*client*, and it ships in `libnotify`, which nothing here was naming. It was present on
`bunne-test` only as a transitive dependency of `bitwarden`, `signal-desktop` and
`limine-snapper-sync` — so every notification this repo promises (`disk-alert`,
`calendar-poll`, `colorpick.sh`) was riding on three unrelated packages continuing to want a
library. That is the `man-db`/`less` failure mode exactly: a commonly-assumed tool that is not
named, breaking things far from the decision that omitted it. Naming it costs nothing new on
disk — it is already installed — and makes the dependency real.

**`scripts/colorpick.sh` shares this slot's toolchain, added 2026-08-28.** Bound to
`Mod+Shift+Print`: `slurp -p` for the pixel, `grim -g` for its colour, ImageMagick to read
it back as hex, `wl-copy` to the clipboard, `notify-send` to say what was picked. Every one
of those was already installed for the screenshot and annotate paths — it adds no package
and nothing resident, which is why it is a note here rather than a slot of its own. Written
by the author as a rough draft on `bunne-test` and cleaned up into the repo's script shape.
The one non-obvious line is `-depth 8`: without it ImageMagick's `%[hex:...]` reports its
internal 16-bit-per-channel value (`D3D37272F9F9`, not `D372F9`) — a valid hex colour string
that nothing else here understands, which would have failed silently into the clipboard.

**PATH, added to `agent-clis` 2026-08-28.** Claude Code's own installer puts the binary in
`~/.local/bin`, and **Arch does not put that directory on PATH** — `/etc/profile` calls
`append_path` for `/usr/local/bin` and stops (read on the box). So `install.d/95-claude-code.sh`
exports it from `.bash_profile` *before* installing, or the step would succeed and leave
`claude: command not found`. `[omarchy]` does carry a `claude-code` package and it was
considered — rejected because Claude Code ships its own updater, so a pacman-managed copy
and a self-updating binary would contend for the same file. What is trusted instead is
Anthropic over TLS, which the step says out loud; it downloads the script, checks it starts
with a shebang, and only then runs it, so a captive portal fails as a file rather than as
half a script that already executed.


### vpn — `openvpn`, aliases generated from a directory nothing in this repo names

**picked** · 2026-08-28 · packages: openvpn

**Measured:** 1.8 MiB installed · 0 daemons, 0 autostart, 0 resident RAM — `openvpn.service`
is not enabled and never runs unless an alias is typed. At shell startup the mechanism costs
one glob and at most a handful of `alias` builtins: **no fork**.

`02-functionality.md` C8 asks for "OpenVPN with the generated `v<letter>` per-profile
aliases", and it had no row — the last of the C-list gaps found on 2026-08-28. Installed on
the author's word the same day.

**The interesting part is what is *not* here.** `CLAUDE.md`'s hardest rule is that employer
and client work never appears in this repo — "no VPN config, no shell alias, no path
reference, nothing naming an employer or client anywhere a friend installing this repo would
see it", stronger than the personal-details rule, which at least allows an overridable
placeholder. A VPN slot is the exact place that rule gets broken by accident, so the
mechanism is built to make it impossible: `config/bash/helpers.bash` globs
`$XDG_CONFIG_HOME/bunny/vpn/*.ovpn` and aliases each profile's first letter
(`dev.ovpn` → `vd`). It reads whatever is there and **names nothing**. The directory is
untracked, `install.sh` does not create it, and no `.ovpn` can ever be committed.

**The predecessor's `scripts/vpn.sh` is deleted rather than ported.** It wrote a `.vpnrc`
file of `alias` lines which `.bashrc` then sourced — a generator, a generated artifact, and a
regeneration step you had to remember after adding a profile. A glob plus `alias` is bash
doing the same job with nothing on disk and nothing to re-run. This is the parsimony rule
paying out: the best version of that script is no script.

**Named limitation:** two profiles whose names start with the same letter collide, and the
last one silently wins. The predecessor had the identical bug. Left in place because both
fixes are worse — an alias the author's fingers don't know, or a warning printed on every
single shell startup for a condition that is almost never true. Rename a profile if it bites.

**Not enabled, and that is deliberate.** `openvpn.service`/`openvpn-client@.service` stay
disabled: a VPN that connects at boot is a VPN you cannot choose not to use, and every
connection here is a deliberate act. `sudo` is required per invocation for the same reason
the predecessor did it — `openvpn` needs `CAP_NET_ADMIN` to create the tun device, and
`setcap`-ing the binary would hand that capability to every process that can exec it.
