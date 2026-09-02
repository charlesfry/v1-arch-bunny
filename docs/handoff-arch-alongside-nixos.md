# Handoff — install Arch alongside NixOS on `bunne-test`

Written 2026-08-23 by the preceding session. **STATUS UPDATE, later that night: the install
described here is COMPLETE** — see `docs/resume.md` and `docs/morning-report-2026-08-24.md`.
Kept for the disk map (§3) and recovery paths (§8), which remain authoritative.

Original status line: Disk preparation is done and verified; the Arch
install itself has not started. Everything below was read off the machine, not recalled.

The author is running an **Arch vs NixOS bake-off** on the test laptop. NixOS 26.05 is installed and
must survive. Note that `CHOICES.md` `os-base` already records **Arch picked / NixOS rejected**, so
this exercise re-litigates a settled row — worth knowing before you treat it as an open question.

---

## 1. Access

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i ~/.ssh/id_ed25519_bunne_test -o IdentitiesOnly=yes bunne@192.168.1.5
```

- The pubkey is already in `~bunne/.ssh/authorized_keys` on the NixOS side.
- **`sudo` is passwordless** on NixOS. You do not need a password for anything there.
- `StrictHostKeyChecking=no` is passed per-command **on purpose**: the laptop's host key changed when
  it was reinstalled and will change again when Arch boots. The author asked that the desktop
  (`omarchy`) not be modified, so `~/.ssh/known_hosts` is deliberately left stale rather than fixed.
- `~/.ssh/config` still has `Host bunne-test` → `User char`. That user no longer exists. Use
  `bunne@192.168.1.5` explicitly.
- `ARCH_PASSWD` lives in `/home/char/github/arch-bunny/.env` on the desktop (gitignored). It is the
  NixOS login password and the intended Arch user password. **It is 5 characters.** Fine for a test
  box login; it is not meaningful full-disk encryption. Say so again rather than let it pass silently.

**Do not interpolate that password into a shell command.** The auto-mode classifier blocks it as
credential-shaped, correctly. It is not needed — key auth plus passwordless remote sudo covers
everything.

## 2. Hardware

| | |
|---|---|
| Model | ASUSTeK ROG Strix `G731GU_G731GU` |
| CPU | Intel i7-9750H, 12 threads — **`GenuineIntel`, so `intel-ucode`** |
| RAM | 15 GiB usable (16 GB fitted) |
| Disk | INTEL SSDPEKNW512G8, 476.9 GiB, `/dev/nvme0n1` |
| GPU | Hybrid Optimus — `i915` iGPU + NVIDIA dGPU, both loaded under NixOS |
| Wifi | `wlo1`, driver `iwlwifi` — **this is the remote-access lifeline** |
| Ethernet | `eno2`, driver `r8169` |

`lspci` is not installed on the NixOS side; the above came from `/sys` and `lsmod`.

## 3. Disk state — authoritative, verified post-reboot

GPT label-id `B43C6C68-1387-4115-8B67-E13B544A0B98`. Sectors are 512 B.

| part | start | sectors | size | type | role |
|---|---|---|---|---|---|
| p1 | 2048 | 4194304 | 2 GiB | EF00 | **NixOS ESP.** systemd-boot + 35 generations. `UUID=6ED1-66C1`. Do not touch. |
| p2 | 4196352 | 32768 | 16 MiB | 0C01 | MS reserved. Do not touch. |
| p3 | 4229120 | 200253440 | 95.5 GiB | 0700 | **Windows.** 34 G used. `PARTUUID=C7B1204C-…`. Do not touch. |
| p5 | 726605824 | 2097152 | 1024 MiB | **EF00** | **`arch-esp`** — FAT32, `LABEL=ARCH_ESP`, `UUID=3AE5-058A`. Arch's `/boot`. |
| p6 | 728702976 | 270004224 | 128.7 GiB | 8300 | **NixOS root.** LUKS → ext4 `nixos`. Do not touch. |
| p4 | 998707200 | 1505280 | 735 MiB | 2700 | Windows recovery. Do not touch. |
| **p7** | **204482560** | **522123264** | **249.0 GiB** | 8300 | **`arch-root`** — empty, awaiting LUKS+btrfs. `PARTUUID=32C5DC11-38C5-4605-99F2-CA17FB24D3A6` |

Free space remaining on the drive: **2.3 MiB**. Both `p7` boundaries are 1 MiB-aligned.

**Only `p5` and `p7` may be written to.** If any tool proposes formatting `p1`, `p2`, `p3`, `p4`, or
`p6`, stop.

## 4. Already done, with evidence

- **Windows repaired.** It had 256 doubly-referenced clusters; `ntfsresize` refused to touch it. The
  author ran `powercfg /h off` then `chkdsk C: /f` and rebooted twice. Re-checked: consistency pass
  is clean, `hiberfil.sys` gone, Fast Startup disabled so it will not re-corrupt.
- **Windows shrunk** from 344.5 → 95.5 GiB using Windows' own Disk Management (not `ntfsresize`).
  `PARTUUID` unchanged, so its BCD still resolves.
- **`p7` created** and **`p5` converted** from a 1 GiB ext4 labelled `unused` (empty, never mounted,
  absent from fstab — created 2026-08-22, purpose unknown, author authorised taking it) to an EF00
  FAT32 ESP. Kernel has re-read the table after a reboot; both are live.
- **4 dead NVRAM entries deleted** — `ubuntu`, `debian`, `Omarchy`, and a `Limine` pointing at the
  uninstalled Arch. Survivors: `0007` NixOS (default), `0002` Windows, `0005` UEFI OS fallback,
  `0006/0008/0009` firmware. `0008 UEFI:Removable Device` is the Ventoy path if you need it.
- **`EFI/BOOT/BOOTX64.EFI` attributed and kept** — `cmp` proves it byte-identical to
  `EFI/systemd/systemd-bootx64.efi`, i.e. NixOS's own fallback loader.
- **Backups, in `~bunne/preinstall-backup/` on the NixOS root (p6):** `esp-2026-08-23.tar.gz` (494 MB,
  full p1 contents pre-cleanup), `gpt-nvme0n1-2026-08-23.sfdisk`, `gpt-nvme0n1-post-winshrink.sfdisk`,
  `gpt-primary-first34.bin`, `nvram-before.txt`.

## 5. NOT done

1. **The Arch install.** Nothing has been written to `p7`.
2. **ESP cleanup on `p1`.** Still 515 MB with orphans of the dead Arch/Omarchy install:
   `vmlinuz-linux`, `vmlinuz-linux-zen`, both `initramfs-linux*.img`, `intel-ucode.img`,
   `limine.conf`, `limine.conf.old`, `EFI/limine/`, `EFI/Linux/omarchy_linux.efi` (**262 MB**), and
   `70118603501341d29127db75e789a850/` (machine-id of the dead install; this machine's is
   `16b6872f40614e36aa31da6749569dd5`). All provably orphaned and unreferenced by NixOS. Reclaims
   ~363 MB. Purely optional now that `Boot0004` is gone.
   The preceding session's attempt was **blocked by the auto-mode classifier** (`sudo rm -rf` on an
   ESP over SSH). Either have the author run it, or get a permission rule. Do not work around it.

## 6. Route — decided by the author

**Install by `pacstrap` from the running NixOS, driven over SSH.** Rejected alternative: boot the
Ventoy stick and drive `archinstall`'s TUI.

Why this is safe to iterate on: **NixOS is on its own ESP (`p1`) with its own NVRAM entry.** A botched
Arch bootloader cannot strand the author — they boot NixOS and you retry over SSH. That containment is
the main argument for the route.

### The keyring problem — read this before you `pacstrap`

`nix search` confirms nixpkgs has `pacman` 7.1.0-unstable-2026-01-25 and `arch-install-scripts` 31,
but **no `archlinux-keyring`**. So a plain `pacstrap` can only proceed with `SigLevel = Never`, which
installs an entire unverified base system. **Do not do that.** `CHOICES.md` `snapshot-boot-entries`
already refuses `SigLevel = Optional TrustAll` for a *single* package on trust grounds; doing it for
the whole root is strictly worse.

Use the signed **`archlinux-bootstrap-x86_64.tar.zst`** from an Arch mirror instead — verify its
`.sig` against Arch's release signing key, unpack it, and `arch-chroot` into it to run a `pacstrap`
that has a real, current keyring. This is the documented "install from an existing Linux" path.
Budget for it; it is the one genuine cost of not using the ISO.

## 7. Install recipe, derived from `CHOICES.md`

Cited so you can check each line against the row rather than trusting this summary.

**Filesystem** (`filesystem`): LUKS2 on `p7` → btrfs, subvolumes `@` `@home` `@log` `@pkg`
`@snapshots`, mounted `noatime,compress=zstd:1`. `@snapshots` **must** exist as a real subvolume
mounted at `/.snapshots` via fstab — `rollback-method` depends on it, and letting `snapper
create-config` make it later is explicitly rejected.

**Mapper name**: NixOS already has `/dev/mapper/cryptroot` open while you install. Open Arch's as
something else (e.g. `archcrypt`) during the install, but write the *boot* cmdline to name it
`cryptroot`, which is what `rollback-method`'s recovery procedure assumes. Use `genfstab -U` so fstab
records the btrfs filesystem UUID and is independent of the mapper name.

**ESP at `/boot`** (`bootloader`): mandatory, not stylistic. Limine has no ext4 driver by design; a
non-FAT `/boot` panics with "failed to open kernel" even with a correct UUID. `p5` is already FAT32.
Use `boot():/path` in `limine.conf`, not `uuid(...)`.

**Bootloader**: `limine` + `efibootmgr`, installed to `p5`. Do not reuse or overwrite anything under
`p1`. Optional: a `protocol: efi_chainload` entry for `boot():/EFI/Microsoft/Boot/bootmgfw.efi` —
but the author chose the **firmware boot menu** as the inter-OS selector, so Arch's menu does not need
to know NixOS exists.

**initramfs** (`initramfs`): mkinitcpio, `encrypt` hook **before** `filesystems`. Keep the `kms` hook
so `i915` gives a native-resolution LUKS prompt. Cmdline shape:
`cryptdevice=UUID=<p7-luks-uuid>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw`.

**The 130 MB NVIDIA trap** (`initramfs`, `firmware-set`) — this machine is exactly the affected shape
(NVIDIA dGPU present). Do **not** install the `linux-firmware` metapackage and **never**
`linux-firmware-nvidia`: the `kms` hook matches the NVIDIA card to `nouveau` and packs its entire
661-file firmware set (~104 MB) uncompressed into the early CPIO. Install **named splits** instead
(`firmware-set`): `linux-firmware-{intel,realtek,atheros,mediatek,broadcom,other,whence}`.
No `-amdgpu`/`-radeon` — this box is Intel+NVIDIA.

> **VERIFY, do not assume: which split ships `iwlwifi-*.ucode`.** `firmware-set` names
> `linux-firmware-intel`, but confirm with `pacman -Fl` / `pacman -Ss '^linux-firmware'` before
> rebooting. Getting this wrong means **no wifi on first boot**, which means no SSH, which means the
> author has to sit at the machine. That is the single highest-consequence detail in this document.

**Microcode** (`microcode`): `intel-ucode` — `vendor_id` is `GenuineIntel`, confirmed. The
`module_path` line in `limine.conf` must follow the same branch.

**Swap** (`swap-zram`): `zram-generator`, **no disk swap, no hibernation** (one-way door, already
decided). Write `zram-size = ram / 2` **explicitly** — the shipped default is
`min(ram / 2, 4096)` and that 4 GiB cap is not wanted; on 15 GiB this should give ~7.7 GiB. Also set
`vm.swappiness = 180` and `vm.page-cluster = 0`; the stock 60/3 are wrong for zram.

**LUKS header backup** (`luks-header-backup`): `cryptsetup luksHeaderBackup` at install time, stored
**off the machine**. A copy on the encrypted root is worthless for the case it exists to cover, and
`~bunne/preinstall-backup/` is on `p6` — that is *on* the machine. Hand it to the author (Ventoy
stick); do not put it on the desktop, which they asked to leave untouched.

**Remote access before first boot — do this inside the chroot, not after.** Install `openssh`, enable
`sshd.service`, and place `~bunne/.ssh/authorized_keys` with:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEnoX+b0KNQXpYBCScNvfbImljYd5wHSavBYOGGgFTT3 claude-diagnostics@omarchy
```

`sshd` enabled contradicts `CHOICES.md` `ssh` (installed, service **disabled**). That is a
pre-existing, documented deviation for this laptop — see `docs/resume.md` "Deliberate deviations on
`bunne-test`". Keep it test-box-only.

**Wifi before first boot.** NixOS uses NetworkManager and the `bunne` user is in the
`networkmanager` group, so the existing profile is readable at
`/etc/NetworkManager/system-connections/*.nmconnection`. Copy it into the new root and install
`networkmanager` so Arch comes up on the same wifi with no credential prompt. Verify the firmware
question above in the same breath. If ethernet can be plugged in for first boot, do that too — it is
a free second path back in.

Identity: hostname **`arch-bunny`** (distinct from the NixOS `bunne-test` on the same LAN), user
`bunne`, uid 1000, in `wheel`.

### Open questions — ask the author, do not decide these alone

- **Which kernel.** There is no `kernel` row in `CHOICES.md`. The dead install had both `linux` and
  `linux-zen`, and the `bootloader` row's Measured column says "boots zen/fallback/Windows from one
  menu", which implies `linux-zen` was in use. Not the same as a decision.
- **Network stack.** No row exists for NetworkManager vs `iwd` + `systemd-networkd`. The recipe above
  assumes NetworkManager only because that is what makes the wifi profile copy trivial.
- **How far past `base` to go.** `install-profile` (lite/full) is **deferred**, and `install.sh` does
  not exist, so there is no "BunnE" to install yet. Decide with the author whether the bake-off needs
  a bare Arch or a hand-configured approximation, and what that means for a fair comparison.

## 8. Recovery

- Arch fails to boot → firmware menu → `0007 Linux Boot Manager` → NixOS. Retry over SSH. Nothing
  about Arch's install can touch `p1` or `p6` if you follow §3.
- Partition table damaged → `sfdisk /dev/nvme0n1 < ~bunne/preinstall-backup/gpt-nvme0n1-post-winshrink.sfdisk`.
- NixOS ESP damaged → the pre-cleanup tarball restores it wholesale.
- Windows unbootable → its `PARTUUID` is unchanged and `Boot0002` is intact; suspect `chkdsk` before
  suspecting this work.

## 9. Repo debts this surfaced

Flagging, not fixing — these are the author's calls.

- **No `README.md`, no `install.sh`, no archinstall JSON, and no pinned ISO anywhere in the repo.**
  `grep` for `archlinux-YYYY.MM.DD` finds nothing. `CLAUDE.md` states the README "carries the setup
  steps and names the exact ISO" and `CHOICES.md` `base-install-method` says the checked-in JSON is
  what this repo must build — both describe artifacts that do not exist.
- Choosing Route B means this install produces **no archinstall JSON**, so that debt stays open. If
  the author wants it, the cheapest source is still archinstall's own "Save configuration" button on
  a future run, plus its `--version` for the pin.
- `CHOICES.md` `install-disk-mode` says the installer "must never expect an existing Linux partition"
  and treats a pre-existing limine as a one-off. This machine is now precisely that shape — Windows,
  another Linux, and limine leftovers. **Do not let this install shape installer design.**
