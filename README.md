# arch-bunny

BunnE: a personal Arch Linux configuration — dotfiles plus the provisioning
to reproduce them, tuned for data-science work. Matte black, keyboard-first,
bunny-themed. The goal: **zero to BunnE in a minimal, maintainable number of
quick steps.**

Design priorities, in order (lower number wins when they conflict):

1. **It just works.** A fresh install boots into a usable desktop with no
   manual repair. Boring-and-durable beats clever-and-brittle.
2. **Fast and light.** 2a: perceived latency on the paths a hand actually
   feels (keystroke to glyph, keybind to window, cold app launch). 2b: idle
   RAM. Speed wins conflicts by a stated — never silent — preference. Disk
   space is not a metric.
3. **Bunny themed.** ASCII, one neon accent on matte black, cyber-bunny.
   Achieved with config and shaders, never with a resident process.

## Status: the installer works end to end (Phase 4)

**`install.sh` exists, runs clean, and has twenty-six steps.** It is written
*from* the decision ledger in small reviewable pieces rather than generated
from a plan, and every step is proven on real hardware before it lands — a
laptop that boots this repo's output and gets rebooted to check.

Run it with `--dry-run` and it will tell you exactly what it would change and
change nothing. What exists today:

| path | what it is |
|---|---|
| [`CHOICES.md`](CHOICES.md) | the decision ledger — one row per slot, with status, measurements, and reasoning. The installer's package list is generated from it. |
| [`BUDGET.md`](BUDGET.md) | running tally of every runtime cost, bucketed by how often it is paid (per prompt / terminal / login / boot / resident RAM) |
| [`docs/`](docs/) | assessment, functionality contract, alternatives ranking, phase plan, session logs |
| [`benchmarks/`](benchmarks/) | the evidence: numbered write-ups, raw logs, instruments, and Devil's-Advocate review transcripts for every conclusion |
| [`config/`](config/) | the dotfiles a finished machine runs (niri, kitty, …) |
| [`install.sh`](install.sh) | the sequencer: preconditions, logging, `--dry-run`, and one numbered step after another |
| [`install.d/`](install.d/) | the steps themselves, standalone and idempotent. `ls` is the plan; there is no manifest to drift. |
| [`scripts/`](scripts/) | measurement harnesses and repo checks (**not** the installer) |

## Stack

Every slot BunnE decides, and what it resolved to. **TBD** means the decision is
still open; **N/A** means it was decided and installs nothing. Each Choice links
to its row in the ledger, where the reasoning and the measurements live.

This table is **generated** — `scripts/gen-stack-table.sh --write` rebuilds it
from `CHOICES.md`. It is not maintained by hand, because a second copy of the
ledger would be wrong within a week.

<!-- STACK:BEGIN -->
| Slot | Choice | Packages |
|---|---|---|
| `filesystem` | [btrfs + LUKS2](CHOICES.md#filesystem--btrfs--luks2) | `btrfs-progs` |
| `initramfs` | [mkinitcpio + `encrypt` hook, no `linux-firmware-nvidia`](CHOICES.md#initramfs--mkinitcpio--encrypt-hook-no-linux-firmware-nvidia) | N/A |
| `bootloader` | [limine](CHOICES.md#bootloader--limine) | `limine` `efibootmgr` |
| `windows-coexist` | [separate archinstall JSON, `parted` pre-delete, `limine-entry-tool` for the boot entry](CHOICES.md#windows-coexist--separate-archinstall-json-parted-pre-delete-limine-entry-tool-for-the-boot-entry) | N/A |
| `gpu-driver` | [nvidia-open (prebuilt)](CHOICES.md#gpu-driver--nvidia-open-prebuilt) | `nvidia-open` `nvidia-prime` `mesa` |
| `gpu-topology` | [hybrid (Optimus), panel on iGPU](CHOICES.md#gpu-topology--hybrid-optimus-panel-on-igpu) | N/A |
| `aur-helper` | [yay-bin](CHOICES.md#aur-helper--yay-bin) | `yay-bin` `base-devel` `git` |
| `makepkg-options` | [`!debug` in `/etc/makepkg.conf` `OPTIONS=`](CHOICES.md#makepkg-options--debug-in-etcmakepkgconf-options) | N/A |
| `ssh` | [`openssh` installed, `sshd.service` **disabled by default**](CHOICES.md#ssh--openssh-installed-sshdservice-disabled-by-default) | `openssh` |
| `documentation` | [man-db (reader). `man-pages` separately, probably skip](CHOICES.md#documentation--man-db-reader-man-pages-separately-probably-skip) | `man-db` `less` |
| `rollback-method` | [manual btrfs subvolume swap](CHOICES.md#rollback-method--manual-btrfs-subvolume-swap) | N/A |
| `snapshot-boot-entries` | [limine-snapper-sync, from the omarchy binary repo](CHOICES.md#snapshot-boot-entries--limine-snapper-sync-from-the-omarchy-binary-repo) | `limine-snapper-sync` |
| `docker-storage-quota` | [top-level btrfs subvolumes + qgroup **accounting only**, no limits; the `disk-alert` row is the protection](CHOICES.md#docker-storage-quota--top-level-btrfs-subvolumes--qgroup-accounting-only-no-limits-the-disk-alert-row-is-the-protection) | N/A |
| `snapshot-bloat` | [—](CHOICES.md#snapshot-bloat--) | N/A |
| `python-env-manager` | [uv, with pixi as the conda-only escape hatch](CHOICES.md#python-env-manager--uv-with-pixi-as-the-conda-only-escape-hatch) | `uv` |
| `oom-protection` | [systemd-oomd](CHOICES.md#oom-protection--systemd-oomd) | N/A |
| `dir-aware-display` | [direnv + prompt hook](CHOICES.md#dir-aware-display--direnv--prompt-hook) | `direnv` |
| `compositor` | [niri](CHOICES.md#compositor--niri) | `niri` |
| `font` | [Fragment Mono, `disable_ligatures always`](CHOICES.md#font--fragment-mono-disable_ligatures-always) | N/A |
| `audio` | [`pipewire-audio` + `pipewire-pulse` + `wireplumber` + `realtime-privileges`](CHOICES.md#audio--pipewire-audio--pipewire-pulse--wireplumber--realtime-privileges) | `pipewire-audio` `pipewire-pulse` `wireplumber` `realtime-privileges` |
| `bluetooth` | [bluez + bluez-utils + bluetui](CHOICES.md#bluetooth--bluez--bluez-utils--bluetui) | `bluez` `bluez-utils` `bluetui` |
| `swap-zram` | [zram only, no disk swap, no hibernation](CHOICES.md#swap-zram--zram-only-no-disk-swap-no-hibernation) | `zram-generator` |
| `firmware-set` | [named `linux-firmware-*` splits, never the metapackage, never `-nvidia`](CHOICES.md#firmware-set--named-linux-firmware--splits-never-the-metapackage-never--nvidia) | `linux-firmware-intel` `linux-firmware-realtek` `linux-firmware-atheros` `linux-firmware-mediatek` `linux-firmware-broadcom` `linux-firmware-other` `linux-firmware-whence` |
| `microcode` | [vendor-conditional, chosen at install time](CHOICES.md#microcode--vendor-conditional-chosen-at-install-time) | N/A |
| `firewall` | [nftables, Arch's shipped `/etc/nftables.conf` unmodified](CHOICES.md#firewall--nftables-archs-shipped-etcnftablesconf-unmodified) | `nftables` |
| `clipboard` | [wl-clipboard + cliphist](CHOICES.md#clipboard--wl-clipboard--cliphist) | `wl-clipboard` `cliphist` |
| `shell` | [bash](CHOICES.md#shell--bash) | `bash` |
| `luks-header-backup` | [`cryptsetup luksHeaderBackup` at install + recovery key recorded off-machine](CHOICES.md#luks-header-backup--cryptsetup-luksheaderbackup-at-install--recovery-key-recorded-off-machine) | N/A |
| `backup` | **TBD** | **TBD** |
| `desktop-portals` | N/A — decided against installing anything here | N/A |
| `secrets-bootstrap` | [—](CHOICES.md#secrets-bootstrap--) | N/A |
| `load-protection` | [systemd slice weighting + core reservation](CHOICES.md#load-protection--systemd-slice-weighting--core-reservation) | N/A |
| `jupyter-in-neovim` | [molten-nvim + image.nvim (`magick_cli`) + jupytext](CHOICES.md#jupyter-in-neovim--molten-nvim--imagenvim-magick_cli--jupytext) | `neovim` `imagemagick` |
| `terminal` | [kitty](CHOICES.md#terminal--kitty) | `kitty` |
| `terminal-navigation` | [kitty built-ins; deviate only on `scrollback_pager` + `scrollback_lines`](CHOICES.md#terminal-navigation--kitty-built-ins-deviate-only-on-scrollback_pager--scrollback_lines) | N/A |
| `ascii-bunnies` | N/A — decided against installing anything here | N/A |
| `os-base` | [Arch Linux](CHOICES.md#os-base--arch-linux) | N/A |
| `polkit` | [polkit](CHOICES.md#polkit--polkit) | `polkit` |
| `cursor-theme` | [adwaita-cursors](CHOICES.md#cursor-theme--adwaita-cursors) | `adwaita-cursors` |
| `notifications` | [mako (leaning), D-Bus activated not enabled](CHOICES.md#notifications--mako-leaning-d-bus-activated-not-enabled) | `mako` `libnotify` |
| `portal` | [xdg-desktop-portal-gnome + `portals.conf`](CHOICES.md#portal--xdg-desktop-portal-gnome--portalsconf) | `xdg-desktop-portal-gnome` `pipewire-jack` |
| `browser` | [brave-bin](CHOICES.md#browser--brave-bin) | `brave-bin` |
| `browser-fallback` | [chromium](CHOICES.md#browser-fallback--chromium) | `chromium` |
| `disk-unlock` | [manual LUKS2 passphrase at boot, autologin after it](CHOICES.md#disk-unlock--manual-luks2-passphrase-at-boot-autologin-after-it) | N/A |
| `boot-splash` | [Plymouth, script module, the flower-thief bunny background](CHOICES.md#boot-splash--plymouth-script-module-the-flower-thief-bunny-background) | `plymouth` |
| `silent-boot` | [`quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3`](CHOICES.md#silent-boot--quiet-loglevel3-systemdshow_statusauto-rdudevlog_level3) | N/A |
| `shell-startup` | N/A — decided against installing anything here | N/A |
| `prompt` | [hand-rolled bash `PS1`, no command substitution on the prompt path](CHOICES.md#prompt--hand-rolled-bash-ps1-no-command-substitution-on-the-prompt-path) | N/A |
| `node-runtime` | [Arch's **`nodejs`** package; **no `mise`, no shims, no version manager**](CHOICES.md#node-runtime--archs-nodejs-package-no-mise-no-shims-no-version-manager) | `nodejs` `npm` |
| `agent-clis` | [**`claude` only** — drop `codex`, `gemini`, `copilot`, `opencode`](CHOICES.md#agent-clis--claude-only--drop-codex-gemini-copilot-opencode) | N/A |
| `polkit-agent` | [**`mate-polkit`**](CHOICES.md#polkit-agent--mate-polkit) | `mate-polkit` |
| `lock-idle` | [**`swaylock` + `swayidle`**](CHOICES.md#lock-idle--swaylock--swayidle) | `swaylock` `swayidle` |
| `xwayland` | **TBD** | **TBD** |
| `remote-desktop` | [not available; **niri limitation, not a packaging choice**](CHOICES.md#remote-desktop--not-available-niri-limitation-not-a-packaging-choice) | N/A |
| `compositor-cleanup` | [remove Hyprland and its library stack from `bunne-test`](CHOICES.md#compositor-cleanup--remove-hyprland-and-its-library-stack-from-bunne-test) | N/A |
| `prompt-hooks` | **TBD** | **TBD** |
| `python-pynvim` | [pinned python3 provider for Neovim](CHOICES.md#python-pynvim--pinned-python3-provider-for-neovim) | `python-pynvim` |
| `editor` | [**LazyVim** (NVChad and hand-rolled minimal rejected)](CHOICES.md#editor--lazyvim-nvchad-and-hand-rolled-minimal-rejected) | `neovim` `python-pynvim` `lazygit` `ripgrep` `fd` |
| `latex-rendering` | [TeX for notebook LaTeX output (molten `text/latex` -> pnglatex -> pdflatex/pdfcrop/pdftoppm/pnmtopng)](CHOICES.md#latex-rendering--tex-for-notebook-latex-output-molten-textlatex---pnglatex---pdflatexpdfcroppdftoppmpnmtopng) | `texlive-basic` `texlive-latex` `texlive-binextra` |
| `keybindings` | [cascading standard: Omarchy defaults <- author's `~/.config/hypr/bindings.conf` <- non-colliding <- installed-relevant](CHOICES.md#keybindings--cascading-standard-omarchy-defaults---authors-confighyprbindingsconf---non-colliding---installed-relevant) | N/A |
| `keybind-apps` | [apps bound by the ratified keybind set](CHOICES.md#keybind-apps--apps-bound-by-the-ratified-keybind-set) | `spotify-launcher` `btop` `lazydocker` `signal-desktop` `bitwarden` `playerctl` `nautilus` |
| `kernel` | [linux (mainline)](CHOICES.md#kernel--linux-mainline) | `linux` |
| `network-stack` | [NetworkManager](CHOICES.md#network-stack--networkmanager) | `networkmanager` |
| `snapshot-system` | [snapper + snap-pac, pre/post only, qgroup byte-cap](CHOICES.md#snapshot-system--snapper--snap-pac-prepost-only-qgroup-byte-cap) | `snapper` `snap-pac` |
| `launcher` | [fuzzel](CHOICES.md#launcher--fuzzel) | `fuzzel` |
| `wallpaper` | [swaybg, solid `-c #0f0f0f`](CHOICES.md#wallpaper--swaybg-solid--c-0f0f0f) | `swaybg` |
| `screenshot` | [niri built-in actions + satty for annotate](CHOICES.md#screenshot--niri-built-in-actions--satty-for-annotate) | `grim` `slurp` `satty` |
| `brightness-keys` | [brightnessctl on XF86 keys](CHOICES.md#brightness-keys--brightnessctl-on-xf86-keys) | `brightnessctl` |
| `kernel-boot-entries` | [limine-mkinitcpio-hook (same publisher as the snapshot tool)](CHOICES.md#kernel-boot-entries--limine-mkinitcpio-hook-same-publisher-as-the-snapshot-tool) | `limine-mkinitcpio-hook` |
| `disk-alert` | [user timer, one `df`, threshold 80%](CHOICES.md#disk-alert--user-timer-one-df-threshold-80) | N/A |
| `display-manager` | [getty-autologin; greetd driven and rejected](CHOICES.md#display-manager--getty-autologin-greetd-driven-and-rejected) | N/A |
| `palette` | [one palette file + `envsubst` templater](CHOICES.md#palette--one-palette-file--envsubst-templater) | N/A |
| `docker` | [docker + compose, socket-activated](CHOICES.md#docker--docker--compose-socket-activated) | `docker` `docker-compose` |
| `status-bar` | [waybar — the clock is what buys the 28.4 MB](CHOICES.md#status-bar--waybar--the-clock-is-what-buys-the-284-mb) | `waybar` |
| `git-config` | [deviations only, identity excluded](CHOICES.md#git-config--deviations-only-identity-excluded) | N/A |
| `media-viewers` | [imv + mpv; PDF in the browser](CHOICES.md#media-viewers--imv--mpv-pdf-in-the-browser) | `imv` `mpv` |
| `git-forge-cli` | [github-cli](CHOICES.md#git-forge-cli--github-cli) | `github-cli` |
| `shell-helpers` | [harvest the predecessor's git + diagnosis functions, nothing else](CHOICES.md#shell-helpers--harvest-the-predecessors-git--diagnosis-functions-nothing-else) | N/A |
| `vpn` | [`openvpn`, aliases generated from a directory nothing in this repo names](CHOICES.md#vpn--openvpn-aliases-generated-from-a-directory-nothing-in-this-repo-names) | `openvpn` |

79 slots — 73 picked, 3 still TBD, 3 resolved to nothing. Generated from `CHOICES.md` by `scripts/gen-stack-table.sh`.
<!-- STACK:END -->

## Install shape

**1. Base install — `archinstall`, from a pinned ISO.** Boot
[`archlinux-2026.08.01-x86_64.iso`](https://archlinux.org/download/)
(sha256 `4e82dced1c4fd3e498b22a853f8db2a4d262d32b97e7e07d97390d9e425ffe5e`) and run:

```
archinstall --config archinstall-2026.08.01-wholedisk.json \
             --creds  archinstall-2026.08.01-creds.json
```

Use **`-wholedisk`** to take the entire disk, or **`-coexist`** to install
alongside an existing OS. The names are the difference: `-wholedisk` sets
`wipe: true`.

### The disk section is a template. Everything else is a decision.

`disk_config` is the one part of these files that **cannot** be portable.
`archinstall` has no percentage unit — `start` and `size` are absolute sector
offsets — so the numbers that shipped were computed against one specific disk.
Everything else in the file (packages, services, network, bluetooth, encryption
type, subvolumes, bootloader, hostname, locale) is a real decision and applies
to any machine unchanged.

So: **load the file, then fix the disk section in the menu.** Step by step.

**Before you start, if anything else is on the disk.** Delete the old OS's
partitions yourself, with `parted`, from the ISO shell — never let `archinstall`
mix `delete` and `create` entries (it crashes in its own cleanup). Then confirm
what you freed:

```
parted -s /dev/nvme0n1 unit s print free
```

**`archinstall` does not check that the region you asked for is actually free**,
and it does not fail when it isn't. Ask for a partition where one already exists
and it silently creates a **1 MiB stub** instead, which installs fine and then
dies much later with `cryptsetup: Requested offset is beyond real size of
device`. That error names neither the cause nor the partition. If you see it,
your free space did not match the file. This cost two runs on 2026-08-28.

**1. Start it.**

```
archinstall --config archinstall-2026.08.01-coexist.json --creds archinstall-2026.08.01-creds.json
```

**2. Disks — the only part you do by hand.** The files carry no `disk_config`
at all: a layout is absolute sector offsets computed on one specific disk, so a
shipped one is wrong for everyone else and dangerous next to an OS you want to
keep. **These config files cannot touch your disk** — `grep disk` them and see.

Open **Disks → Partitioning → Manual partitioning**, and pick your disk.

- ⚠️ **Never pick *Suggest partition layout*** on a disk shared with another OS.
  It sets `wipe: true` and lays root across the whole disk, destroying what is
  there. After picking your disk, confirm the summary reads **`Wipe: False`**.
- You now see a table of partitions **and free-space rows**. Selecting a
  *free-space* row is how you create a partition in it.

**The boot partition — reuse Windows', do not make a new one.**

- Select the **existing** EFI system partition (`fat32`, flagged `boot`/`esp`,
  usually the first partition on the disk)
- *Assign mountpoint* → `/boot`
- **Do not** *Mark to be formatted* — formatting it destroys Windows' bootloader
- Its status must stay **`existing`**, never `create`

The Arch wiki is explicit about this: *"An additional EFI system partition
should not be created, as it may prevent Windows from booting"*, and *"there can
only be one ESP per drive"*. Sharing also makes Windows appear in the Limine
menu for free, since `bootmgfw.efi` is then on the partition
`51-windows-chainload.sh` looks at.

Windows Setup usually makes this partition only 100 MiB, which is tight once
you hold several kernels plus snapshot entries. Check its size first; if it is
small, see the wiki's *"The EFI system partition created by Windows Setup is too
small"*.

⚠️ **Sharing an ESP requires Fast Startup and hibernation off in Windows.** A
hibernated Windows assumes nothing else touches the disk, and can corrupt a
shared ESP. In an admin Command Prompt on Windows: `powercfg /H off`. Keeping
Windows hibernation would require the Linux ESP on a *different drive*, which a
single-disk machine cannot do.

**On a disk with no other OS**, there is no existing ESP to reuse, so make one:
select a **free space** row, size **`1024 MiB`** (not `1 GB` — archinstall reads
`GB` as 1000³ and `GiB` as 1024³, and a size that is not a whole number of MiB
leaves the next partition off a 1 MiB boundary), filesystem `fat32`, mountpoint
`/boot`.

**Make the root partition:**

- Select the **free space** row that is left
- Size: press Enter to accept the default, which is all of it
- Filesystem: `btrfs`
- It does not ask for a mountpoint. That is correct — `/` comes from the `@`
  subvolume

**Add the subvolumes:**

- Select the **btrfs** partition → **Set subvolumes** → add these six:

  | name | mountpoint |
  |---|---|
  | `@` | `/` |
  | `@home` | `/home` |
  | `@snapshots` | `/.snapshots` |
  | `@log` | `/var/log` |
  | `@cache` | `/var/cache` |
  | `@tmp` | `/var/tmp` |

- `@containerd` and `@dockervol` are **not** here on purpose —
  `install.d/15-docker-subvols.sh` makes them later
- Get one wrong and `install.d/00-preflight.sh` stops the run before anything
  is written, naming the one that is missing. Nothing here degrades quietly

**Turn on encryption** (this cannot come from the files — see step 3):

- Back out to **Disk encryption**
- Encryption type: **LUKS**
- Partitions: select the **btrfs** one
- Set your passphrase — this is the one credential the machine ever asks for

**Two menu items to decline, and how to decline them:**

- **Btrfs snapshots** → **do not open it.** If you do open it, press **Esc** to
  come back out without choosing. If you already picked Snapper or Timeshift,
  open it again and press **Ctrl+C**, which resets it to unset. Correct is
  `"snapshot_config": null` in the saved config.
  *Why:* `install.d/40-snapshots.sh` sets up snapper the way this repo decided.
  archinstall's version enables `snapper-timeline.timer` and creates a `home`
  config — both explicitly rejected — and does not install `snap-pac`, which is
  the part that actually hooks snapshots to pacman.

- **Mark/Unmark as compressed** → **do not run it.** It is a toggle on the
  btrfs partition and starts off; running it once turns it on, running it again
  turns it back off. Correct is `"mount_options": []` in the saved config.
  *Why:* it can only write plain `compress=zstd`, which is zstd level 3.
  `install.d/05-mount-options.sh` sets `noatime,compress=zstd:1` instead —
  level 1, because level 3 spends two to three times the CPU per write to buy
  disk space, and disk space is not a metric here. Turning it on is not harmful;
  the step overwrites it either way.

**Throughout this menu: Esc backs out without changing anything, Ctrl+C resets
the item you are on to unset.**

**3. What the two files do and do not cover.** Between them the config and
creds files set packages, services, network, Bluetooth, bootloader, kernel,
hostname (`arch-bunny`), locale, and the user account — **`bunny`**, with
sudo and password **`bunny`**. Change that password once you are in.

They do **not** set the disk layout or the encryption, and cannot: both are
properties of partitions the files deliberately do not define. That is why
step 2 is the one part you do by hand.

**4. Nothing — the files cover the rest.** Hostname, timezone (`US/Eastern`),
username, the user password, keyboard and locale all come from the config and
creds files. Change the timezone in the menu if you are not on US Eastern; it
is a default, not a requirement.

**4b. Check the config before you commit to it.** *Save configuration*, then
read the disk section back. Four things, in this order:

- `"wipe": false` — if it says `true` on a shared disk, stop.
- both partitions' `start`/`size` fall inside the free region you saw in
  `parted print free`
- `disk_encryption` exists and names the btrfs partition
- the `btrfs` list has **five** entries, `@snapshots` among them
- every `create` partition's `start` divides by 2048 — 1 MiB alignment. Divide
  the byte value by 512 to get sectors; if that is not a whole multiple of
  2048, you typed `GB` where you meant `MiB`

archinstall warns you about none of these. It installs whatever you confirmed.

**5. Install**, at the bottom of the menu, past `Save configuration`. Saving the
config does not install anything.

The JSON's filename carries the ISO date because JSON has no comment syntax to
record it in. It was written against `archinstall`'s own schema for the version
that ships on that exact ISO (verified by reading the package straight out of the
ISO, not from web docs — see `base-install-method`), not guessed. If you're on a
newer ISO, either use the pinned one or expect to re-verify the schema against
yours.

*Setting up an already-remote-managed box (e.g. re-provisioning `bunne-test`)?*
`ssh` is picked but `sshd.service` ships disabled by default (`CHOICES.md`, `ssh`)
— that's the right default for a stranger's fresh install, but it means a
`--silent` or unattended run would leave you locked out until you're physically
at the keyboard. `sshd` needs `openssh`, and archinstall's base install doesn't
carry it — enabling the service without adding the package fails outright
(`Unit sshd.service does not exist`, caught by rehearsing this exact config in a
VM). Add **both** `"openssh"` to `packages` and `"sshd"` to `services` for that
run only; don't commit either — it's a box-specific deviation, the same shape as
`benchmark-unlock`.

*Windows already on the machine?* Use `archinstall-2026.08.01-coexist.json`
instead of the base file, and do one extra manual step first. Rehearsed
end-to-end in a VM under real UEFI firmware, 2026-08-27: Windows preservation
proven by SHA256 checksums on all four Windows regions (ESP/MSR/data/recovery)
matching before and after, and the resulting install reaches a real login
prompt.

**`archinstall` itself has a bug that this file's shape works around.** A
JSON mixing `delete` entries (for the old OS's partitions) with `create`
entries (for the new ones) makes archinstall crash in its own post-commit
cleanup — it calls `wipefs --all` on a `delete` entry's device path, which no
longer exists once the delete has already succeeded. The partition table
change itself lands correctly despite the crash, but don't rely on that: the
proven-clean sequence is to delete the old OS's partitions **yourself**, with
`parted`, from the live ISO shell, *before* running `archinstall` — then the
JSON only ever contains `create` entries, and archinstall completes without
crashing (proven twice, in separate rehearsal runs).

**The partition offsets in the checked-in file are the rehearsal VM's, not
your machine's.** They were sized against a disk shaped like the VM's
simulated Windows layout, not the real desktop's. Read the real disk's actual
free space (`parted /dev/sdX print free` after deleting the old OS's
partitions) and recompute `start`/`size` for both new partitions before
running this file for real — using the shipped numbers as-is on real hardware
risks overlapping a partition Windows still owns.

**Windows won't appear in the boot menu on its own.** `archinstall` doesn't
detect other OSes, and neither does anything in `install.d/`'s base steps —
that's what `install.d/51-windows-chainload.sh` is for (adds a Limine
chainload entry via `limine-entry-tool`, already on the machine, no new
package; silent no-op if there's no Windows to find).

**2. Post-install — `install.sh`.** Clone this repo onto the resulting vanilla
Arch and run `./install.sh`. Twenty-six steps, each idempotent and independently
runnable, `ls install.d/` is the plan:

| step | what it does |
|---|---|
| `00-preflight` | verifies the machine matches what post-install-only assumes (btrfs, LUKS, limine, ESP at `/boot`, mkinitcpio config) before touching anything |
| `05-mount-options` | `noatime,compress=zstd:1` on every btrfs mount — archinstall can express neither |
| `10-omarchy-repo` | adds the `[omarchy]` pacman repo, pinned by key fingerprint |
| `15-docker-subvols` | `@containerd`/`@dockervol` as top-level btrfs subvolumes, before Docker can put bytes anywhere else |
| `20-packages` | installs every `picked` row's package, derived from `CHOICES.md` — one source of truth |
| `25-services` | adds you to the `docker` group, and proves the JSON's `nftables.service` and `docker.socket` actually came up — enabled is not running |
| `26-docker-nftables` | patches two `accept` rules for `docker0` into nftables' `chain forward` — the shipped ruleset's `policy drop` there silently blocks every container's traffic past its own gateway |
| `27-firmware` | removes the `linux-firmware` metapackage archinstall installs unconditionally, and `linux-firmware-nvidia` with it — 130 MB of initramfs down to 25 MB |
| `30-zram` | zram swap, sized and tuned |
| `35-oom-protection` | `systemd-oomd` drop-ins |
| `40-snapshots` | snapper + snap-pac, retention limits, qgroup accounting |
| `45-plymouth` | boot splash — the flower-thief bunny behind the LUKS prompt |
| `46-silent-boot` | quiets kernel/systemd console spam between LUKS unlock and the desktop |
| `50-limine` | boot menu directives (`timeout`, `hash_mismatch_panic`, `default_entry`), config path found not assumed |
| `51-windows-chainload` | adds Windows to the boot menu if it's on the machine; silent no-op otherwise |
| `60-autologin` | `getty@tty1` autologin drop-in |
| `70-dotfiles` | symlinks `config/` into `$XDG_CONFIG_HOME` |
| `75-nvim-notebook` | the Jupyter/molten provider venv, kernel, and runtime dir LazyVim's config points at |
| `80-disk-alert` | enables the disk-usage-alert user timer |
| `85-shell-prompt` | sources the hand-rolled prompt from `~/.bashrc` |
| `86-shell-dir-aware` | sources the directory-aware title + gated `direnv` hook, scaffolds the (untracked) mapping file |
| `87-wallpaper` | seeds the (untracked) desktop-wallpaper symlink `scripts/bunny-wallpaper.sh` repoints |
| `88-calendar-poll` | enables the calendar-poll user timer (meeting alerts via `gcalcli`) |
| `90-shell-helpers` | sources the `gu`/`gur` git helpers and the disk-forensics `diagnose` pair from `~/.bashrc` |
| `95-claude-code` | puts `~/.local/bin` on `PATH` and installs Claude Code from its own installer |

Two properties worth knowing before you run it:

- **It refuses to run as root**, and refuses before writing anything. Steps
  escalate per command, so reading the file tells you exactly which parts need
  root and why. A script that demands root for all of itself cannot be audited
  by someone deciding whether to trust it.
- **Steps are idempotent, and that is the whole resume story.** If one fails,
  the run stops, says which step and where the log is, and you fix the cause and
  run the whole thing again. There is no `--from`/`--only` flag.

**3. What `install.sh` deliberately leaves to you.** Everything below is a
credential, a consent, or a thing that has to leave the machine — none of it
should be scripted, and a repo that scripted it would be one you should not
trust. The installer says so at the point it applies; this is the same list in
one place, roughly in the order you will want them.

| do this | why it is not automated |
|---|---|
| `cryptsetup luksHeaderBackup /dev/<part> --header-backup-file luks-header.img`, then **move the file off the machine** | a corrupted LUKS2 header loses the whole volume, passphrase or not. A copy on the encrypted root is worthless for the case it exists for, so only you can finish this one (`CHOICES.md` `luks-header-backup`) |
| `nmcli device wifi connect <ssid> --ask` | a wifi password is a credential |
| `git config --global user.name "…"` and `user.email "…"` | `config/git/config` ships behaviour, never identity (`CHOICES.md` `git-config`) |
| `gh auth login` | interactive OAuth consent |
| `claude` — run it once | interactive login |
| `gcalcli init` | Google OAuth consent; until then `calendar-poll.timer` runs and stays quiet |
| In Brave: allow notifications on `calendar.google.com`, pin the tab, set *On startup → Continue where you left off* | a permission grant is a consent action, and Chromium validates its own preferences file — writing it from a script is the against-the-grain hack this repo rejects (`CHOICES.md` `notifications`) |
| Edit `~/.config/bunny/dirmap.conf` | your directories, not ours; the installer scaffolds an empty one |
| **Dual-booting?** In Windows, run `powercfg /H off` as admin | Fast Startup is a hibernation, and a hibernated Windows can corrupt the EFI system partition Linux shares with it. The Arch wiki calls disabling it the safest option; the alternative needs a second drive |
| Drop your `.ovpn` profiles in `~/.config/bunny/vpn/` | one `v<first-letter>` alias appears per profile at the next shell. No profile, path or name is in this repo and none ever will be (`CLAUDE.md`) |

Two of these are load-bearing rather than nice-to-have: without the header
backup a single bad write ends the machine, and without the Brave clicks you
get no meeting alerts and **no warning that you are not getting them** — the
`gcalcli` poller is the backstop, and it needs its own `init` above.

`--dry-run` and `--help` are both supported. `CHOICES.md` is still the whole
point of the repo — read it for the reasoning behind every step.
