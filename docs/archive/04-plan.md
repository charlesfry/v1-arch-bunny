# Project plan

Rough step-by-step, phase by phase. Each phase ends with something checked in,
so a later phase never has to re-derive an earlier one's conclusions.

One foundational decision stays **open on purpose** and is called out where it
lands: the shape of the Ventoy artifact. Nothing below silently settles it.
(The dotfile deployment mechanism was the other; the author settled it as
**symlink** in Phase 4 on 2026-08-19.)

---

## Phase 0 — Write down the spec (this doc set)

`01-assessment.md` (what the current machine shows) → `02-functionality.md`
(what must exist) → `03-alternatives.md` (what could fill each slot, in try
order) → `05-choices.md` (how a verdict gets recorded). **Done.**

Nothing is installed in this phase. The point is that Phase 3 has a list to work
through instead of a vibe.

---

## Phase 1 — Baseline the current machine

Measure the thing being replaced, so "faster" and "lighter" are provable rather
than asserted. Record into `benchmarks/omarchy-baseline.md`.

1. **Boot**: `systemd-analyze`, `systemd-analyze blame`, `critical-chain`.
   *(Already captured: 34.5s total, 5.07s to `graphical.target`.)*
2. **Idle RAM**: log in, launch nothing, wait 2 minutes, then record
   `free -m`, `systemd-analyze --user blame`, and per-process RSS.
   **This has to be a genuinely idle session** — the first attempt was polluted
   by 8 python processes holding ~12 GB.
3. **Resident process census**: `systemctl --user list-units --state=running`
   plus the system list. Every entry needs a reason to exist on the new box.
4. **Latency — the priority-2a baseline, and the one most likely to be skipped
   because it is the hardest to collect.** `hyperfine` on cold and warm terminal
   spawn, `nvim --startuptime`, launcher keybind → first accepted keystroke,
   keybind → window on screen. For keystroke-to-glyph there is no honest
   software-only number: the credible method is a phone slow-motion capture of
   the screen with the key in frame, and the cheaper proxies (kernel evdev
   timestamp from `evtest` vs. Wayland delivery from `wev`) measure the input
   stack only, not the presentation half. Pick a method, **prove the method
   itself first**, and record which one produced each number.
5. **Inventory**: `pacman -Qeq` and `pacman -Qm` dumped to the repo, plus the
   non-pacman installs (`~/.local/bin`, mise/node, flatpaks, conda envs).

Also archive the parts of the predecessor repo being ported verbatim so they are
not lost when that machine is rebuilt: `disk-monitor/`,
`config/nvim/`, `vpn/` generator, git config, the `.bashrc` helper functions,
and `themes/daemon/colors.toml`.

---

## Phase 2 — Vanilla Arch on the new PC

Goal: a booting, encrypted, dual-booting base system with **no desktop opinions
in it yet**. Everything here comes from the Foundations section of
`03-alternatives.md`, which was ranked to be decided once and left alone.

**Historical note.** This phase was done by hand, dual-booting, before the base
install was delegated to `archinstall` (`CHOICES.md` `base-install-method`).
Phase 4 no longer harvests scripts from it — none of this becomes repo code.
What it still provides is the *specification* the archinstall JSON has to meet:
LUKS2, the btrfs subvolume layout, limine, and the ESP mounted at `/boot`. Read
it as the proven target, not as a procedure to automate.

1. **Preserve Windows.** Confirm the ESP, back up `efibootmgr` output, turn off
   Windows fast startup, set Windows to keep the RTC in UTC. Partition by hand
   into free space — never let anything auto-partition.
2. Base install: `base`, `linux` + `linux-zen`, `linux-firmware`, `amd-ucode`,
   btrfs subvolumes on LUKS2, zram.
3. Bootloader: limine, installed to the existing ESP, Windows entry verified,
   timeout ~1s. **Reboot into Windows once to prove it before continuing.**
4. Snapshots: snapper with retention limits set now, pacman pre/post hook,
   `limine-snapper-sync`, and a deliberate test rollback.
5. GPU: `nvidia-open`(-dkms), modeset, initramfs modules. Confirm a Wayland
   session runs.
6. Network, time, firewall, `yay`.
7. **Checkpoint**: `systemd-analyze` here is the clean floor to compare against.
   Take a snapshot named `base` — Phase 3 rolls back to it when a trial goes bad.

---

## Phase 3 — The bake-off

The core loop. Work through `03-alternatives.md` **in the order the slots appear
there**, because later slots depend on earlier ones (compositor before bar,
terminal before editor, launcher before the keybinds that call it).

For each slot:

1. Install candidate #1 (`03-alternatives.md` already ranks them).
2. Use it for real work — a day minimum for anything in the daily path.
3. Measure **both halves of priority 2, latency first**: launch/interaction
   latency for anything in the interactive path, then idle RAM delta, added
   resident processes, and boot-time delta if it starts at login. A row that
   records only RAM for a slot the hands touch every day has measured the
   convenient thing, not the deciding thing. **If the two point opposite ways,
   say so explicitly in the `Note` and take it to the author** — 2a wins by
   default, but only as a soft preference, and never silently.
4. Record the verdict in `choices.tsv` — **including rejections**, so a
   candidate is never silently re-litigated (`05-choices.md`).
5. `pacman -Rns` the loser. If it left files behind, note that too; it matters
   for the installer.

Guardrails, because this phase deliberately breaks things on a machine that is
also the daily driver:

- **Snapshot before each trial.** This is what btrfs+snapper is for.
- **Never trial two slots at once.** Two variables, no conclusion.
- **Keep a known-good fallback reachable**: a second TTY, the plain `linux`
  kernel entry, and a compositor that is known to start.
- Compositor-level trials are the riskiest — consider a second user account, so
  a broken config cannot lock the main one out.

Suggested sequencing within the phase — get to a usable machine fast, then
optimize:

1. **Make it usable** (blocks everything else): compositor, terminal, launcher,
   notifications, keybinds, monitor layout.
2. **Make it the daily driver**: shell config (`direnv` + dir-aware display,
   see `CHOICES.md` `dir-aware-display`), Neovim (bake off LazyVim vs. NVChad;
   diagnose slow find-references before assuming an editor problem — see
   `CHOICES.md` `dir-aware-display` row's sibling notes in `resume.md`), git
   tooling, Python environments, containers (with a storage cap — see
   `CHOICES.md` `docker-storage-quota`), VPN, browser.
3. **Make it safe**: disk monitor, snapshot tuning, firewall, backups,
   `systemd-oomd` (see `CHOICES.md` `oom-protection`).
4. **Make it fast**: boot cleanup, re-measure everything from Phase 1 and diff.
   Note that "kill resident daemons" used to be this step's definition of fast
   and is really step 4b — it serves 2b, and only helps 2a where a daemon is
   actually contending for CPU or delaying login. The 2a work is separate and
   more interesting: compositor frame pacing and present latency under load,
   scheduler and `linux-zen` verification against plain `linux`, terminal
   keystroke-to-glyph, cold-start times for the daily apps, and anything that
   turns out to fork per prompt.
5. **Make it pretty**: palette file + generator, wallpaper, ASCII.
6. **Optional profiles**: comms only. no printing, emulation, or gaming.

---

## Phase 4 — Harvest the picks into the repo

Only once `choices.tsv` is mostly filled in. Turning decisions into scripts
before the decisions exist is how a repo ends up full of code nobody can justify.

- One idempotent script per provisioning step (`#!/usr/bin/env bash`,
  `set -Eeuo pipefail`), and a master installer that only sequences them.
  Follow the conventions in `CLAUDE.md` — XDG paths read from their variables,
  `shellcheck`-clean, no blanket `sudo`, `--help`/`--dry-run`.
- **Add the repo furniture** a stranger expects before cloning: `README.md`,
  `LICENSE`, `.gitignore`. None exist yet; the repo has been notes until now.
- **Config validation runs before anything ships, and must catch what the
  upstream validator cannot.** `scripts/check-keybinds.sh` exists already
  (written 2026-08-21, `shellcheck`-clean, canary-tested) because
  `niri validate` **passed a config that silently shadowed a working binding**:
  it compares keybinds as literal strings, but `Mod` *is* `Super` on a TTY, so
  `Super+Ctrl+L` and `Mod+Ctrl+L` are one chord and two tokens. The check
  normalises `Super`→`Mod`, sorts modifiers so ordering cannot hide a duplicate,
  and fails with the line number of every colliding binding. It also warns when
  a config mixes both spellings at all, because that is what makes a collision
  invisible to a human reader even when nothing currently clashes.
  **The general rule this is an instance of: for every config we ship, ask what
  the upstream validator does *not* check, and write that check ourselves.**
  Known gaps to cover as the configs land:
  - **niri** — done: chord collisions across `Mod`/`Super`.
  - **any config referencing a binary** — that the binary is actually installed.
    `mate-polkit` lives at `/usr/lib/mate-polkit/`, not on `PATH`; a typo there
    fails silently at login, which is exactly the `scrollback_pager less`
    failure the `terminal-navigation` row already recorded.
  - **`spawn-at-startup` entries** — that each one runs. Stock niri ships
    `spawn-at-startup "waybar"`, which we ship no bar for; that was caught by
    reading, not by tooling.
  - **colours** — once the palette generator exists, that no config file
    contains a hardcoded hex value (`02-functionality.md` C10 allows exactly one
    source).
  - **limine** — done 2026-08-25: `scripts/check-limine.sh`. Limine has no
    validator at all, and the failure that prompted this one was a config that
    parsed perfectly and still left the machine sitting at the menu — the OS
    entry had become a directory and `default_entry` still defaulted to `1`.
    Checks: the default entry boots (not a directory), every booted file exists
    on the ESP, and the directory holding the default is expanded. Carries a
    `--self-test` that rebuilds the failing config and asserts rejection.
    See `benchmarks/4.24` and `CHOICES.md` `config-validation`.
  Wire these into one `scripts/check-configs.sh` that the installer's own test
  run and any future CI both call. **A check nobody runs is not a check**, so it
  gets an exit code and a canary test, as this one has.
- The package lists come *from* `choices.tsv` — one source, not two.
- Configs contain deviations from upstream defaults only.
- All colors come from one palette file.
- Optional profiles are separate scripts, not flags in the core.
- **This repo is post-install only** (`CHOICES.md` `base-install-method`). The
  base install — partitioning, LUKS2, subvolumes, `pacstrap`, bootloader — is
  delegated to `archinstall`, which supports limine and the ESP-at-`/boot`
  layout (verified). `install.sh` turns the resulting vanilla Arch into BunnE.
  **Nothing in this repo performs a destructive disk operation**, which deletes
  the disk-mode split, the never-format-the-ESP rule, and the dry-run
  requirement along with it.
- **Ship an `archinstall` JSON config, pinned to a specific Arch ISO**, and name
  that exact ISO release in `README.md` with a link. The config's filename
  records the tested ISO date, since JSON carries no comment. This is the
  replacement for all the deleted partitioning code: declarative and reviewable.
- **`install.sh` must refuse to provision a machine carrying a benchmark
  keyfile** (`CHOICES.md` `benchmark-unlock`): more than one enabled LUKS
  keyslot, a keyfile in `FILES=`, or a `cryptkey=` on the kernel command line.
  This is the check that makes the removal reliable rather than remembered — a
  note can be skimmed, a refusal cannot. It also protects a stranger who copies
  the technique out of the docs. Failing loudly here is cheap; shipping a machine
  whose disk decrypts itself is not.
- **Check prerequisites at the top of `install.sh` and fail loudly.** Post-install
  only means the base is no longer ours to guarantee — a friend may run this on
  an Arch set up differently. Verify btrfs, the subvolume layout, LUKS, limine,
  and the ESP mountpoint before touching anything, rather than half-configuring
  a machine and stopping in the middle.
- **The installer asks a short, bounded set of questions, all up front**
  (`CHOICES.md` `installer-prompts`). Questions about *you and your machine* are
  legitimate — username and password, hostname, timezone, keyboard/locale, disk
  mode and target, encryption and its passphrase, lite vs. full, wifi
  credentials if there is no ethernet. Questions about *this repo's internals*
  are not: which compositor, which bar, which init hook. Those are decided in
  `CHOICES.md` and are not toggles, per `CLAUDE.md`'s "opinionated tastes need no
  justification or config toggles."
- Ask **everything before anything destructive happens**, then run unattended.
  A prompt appearing forty minutes in, after the disk is already written, is the
  thing that makes an installer feel like babysitting. Every question gets a
  sensible default so the common path is confirming, not composing.
- Whichever mode, a **dry run** prints every destructive operation and exits
  without performing any, and microcode and firmware come from detected
  hardware rather than being hardcoded (`CHOICES.md` `microcode`,
  `firmware-set`).
- BunnE always owns `/boot` and `limine.conf` at ESP root, exactly as on the
  laptop. It never has to share the ESP with another *Linux* — see
  `CHOICES.md` `desktop-migration` for the one machine where one is present,
  and why it is removed rather than coexisted with.
- **Settled — dotfile deployment: symlink, hand-rolled.** The question was copy
  (the predecessor's choice; edits to `~/.config` never flow back) vs. symlink
  vs. a manager. The answer is **symlink via `ln -sfn` in `install.sh`, with no
  manager** — `stow` would be a dependency for what the installer already does.
  Symlink whole directories where the app allows it, and make the deploy step
  re-runnable so it repairs a link an application has replaced. The repo lives
  at a fixed location the installer owns. Full reasoning, and a correction to
  the "a package update clobbers the link" rationale, in `CHOICES.md`
  `dotfile-deployment`.
- **Open decision — lite vs. full install profile.** Tag each step
  critical-vs-extra as it is written (see `CHOICES.md` `install-profile`), then
  decide the selection mechanism (flag vs. two package-list files consumed by
  the same scripts) once there is a real script to hang it on.

---

## Phase 5 — Rehearse the installer, in a VM and then on real hardware

The proof that any of this worked. VMs first because a mistake costs nothing,
then the laptop, because a VM does not exercise real UEFI, NVMe, or GPU
firmware — and those are where installers actually break.

By this point the bake-off is over and its findings are in `CHOICES.md` and the
Phase 4 scripts, so **the laptop is finally free to destroy**. It is entirely
disposable: partitions and data can go, Windows included, and the only real
limit is not bricking the firmware.

Much smaller than it used to be: with the base install delegated to
`archinstall` (`CHOICES.md` `base-install-method`), the Windows-ESP,
allocated-disk and existing-Linux-partition scenarios are no longer this repo's
code to test. What is left to prove is the part we actually wrote.

*In a VM:*

1. **The documented path, end to end**: boot the pinned Arch ISO, run
   `archinstall` with the checked-in JSON, reboot, clone, `./install.sh`. This
   is what `README.md` tells a stranger to do, so it is the thing to rehearse.
2. **The prerequisite checks**, deliberately: run `install.sh` against an Arch
   installed *differently* — ext4, no encryption, a different bootloader — and
   confirm it refuses loudly and early instead of half-configuring the machine.
   A check that has never been seen to fire is not known to work.
3. **Idempotency**: run `install.sh` twice. The second run must be a no-op.
4. Fix whatever the VM runs reveal; repeat until boring.

*Then on the test laptop:*

5. **Run the whole documented path on bare metal**, wiping the laptop's Windows
   and its Phase 2/3 install — which is also what clears the benchmark keyfile
   (`CHOICES.md` `benchmark-unlock`), since the reinstall comes from the
   archinstall JSON and that JSON must never contain one. **If it gets re-added
   afterwards to keep benchmarking, Phase 6 step 0 applies again**: pinned ISO → `archinstall` with the JSON →
   `install.sh`. A VM exercises no real UEFI, NVMe or GPU firmware, and this is
   the last chance to find a hardware-only bug before Phase 6 touches the
   desktop. It also proves the JSON on hardware that is not the one it was
   written against.
6. Fix, repeat. **The gate for Phase 6** is that both the VM runs and the
   bare-metal run are uneventful several times over, not once.
7. Re-measure boot and idle RAM on the reproduced system and compare against the
   Phase 1 baseline. That diff is the headline result of the project.

Step 5 leaves the laptop running BunnE from the real installer, which is exactly
what Phase 6 step 1 needs to validate as an emergency work machine. The two
dovetail; do not do this twice.
8. **Settled — Ventoy artifact shape**: the pinned stock Arch ISO, with this
   repo alongside it or cloned after first boot. Delegating the base install
   dissolved this decision rather than answering it — there is no longer
   anything to build a custom artifact out of. `CHOICES.md` `install-artifact`.

---

## Phase 6 — Replace Omarchy with BunnE on the daily driver

The desktop is the eventual daily driver, and it holds work whose loss has a
real cost. This phase is deliberately separate from Phase 5 and separately
gated. Approach and rejected alternatives: `CHOICES.md` `desktop-migration`.

Reformatting `p2` is the point of no return: Omarchy is gone the moment it
happens, and there is no booting back into it to compare. Everything before it
exists to make that acceptable.

Ordered so that every irreversible step is preceded by the thing that makes it
recoverable:

0. **Remove the benchmark keyfile and prove the disk is really encrypted again**
   (`CHOICES.md` `benchmark-unlock`). This is step 0 rather than a line inside
   step 1 because **step 1 is the moment `bunne-test` stops being disposable**:
   it puts day-job repo access, VPN, credentials and SSH keys on a laptop that
   has spent the whole build effectively unencrypted at rest. The keyfile was
   accepted for a throwaway box and that is no longer what this is.
   Do not take its absence on trust — the removal is exactly the kind of
   never-exercised safety step this repo's rules exist for:
   `cryptsetup luksDump <device>` must show **exactly one enabled keyslot**,
   `FILES=` in `/etc/mkinitcpio.conf` must be empty, `/crypto_keyfile.bin` must
   be gone, and **the next boot must actually ask for the passphrase**. That last
   one is the canary: a boot that stays silent means the keyfile is still live no
   matter what the config says.
1. **Prove the laptop is a working emergency DS machine.** The whole plan rests
   on "if the desktop is down, work from the laptop," and that is currently an
   assumption. It should be running BunnE from Phase 5 step 5 by now — this is
   the step that proves that install is good enough to work on. Per this repo's
   own rule it does not count until exercised:
   **power the desktop off and do a full day of real work on the laptop.**
   Day-job repo access and VPN, credentials and SSH keys, editor with the Python
   env and Jupyter/molten rendering, containers if the work needs them, password
   access, and an external monitor. Its GTX 1660 Ti is Turing, so CUDA works —
   slower than the 4090, not absent. If the day cannot be completed on it, this
   gate is not met and `p2` is not touched.
2. ~~Backup, restored and verified~~ — **removed as a gate, author's word 2026-08-27: no
   external disk, won't have one for a while.** `CHOICES.md` `backup` carries the design for
   whenever this reopens; nothing else in this phase is blocked on it.
3. **Audit the Unreal work specifically.** "It is all git-repo'd" is necessary,
   not sufficient: the standard Unreal `.gitignore` excludes `Saved/`, where
   autosaves and crash-recovery files live; committed Git LFS *pointers* are not
   pushed LFS *objects*; and a source-built engine is in no project repo. Check
   for a clean tree, nothing unpushed, LFS objects present on the remote, and
   record the engine version per project.
4. **Image the ESP** (`dd`, 2 GiB, seconds) and save `efibootmgr` output. Because
   nothing here touches the partition table or NTFS, the ESP is the *only* path
   by which the Windows install can be harmed — which makes this the cheapest
   and most valuable insurance in the phase.
5. **Migrate data off `p2`** — `/home`, and anything on the Omarchy root that is
   not reproducible from this repo.
6. **Reformat `p2` and install BunnE into it.** No partition-table operations at
   all. `luksFormat` produces a new header and a new UUID, so the
   `cryptdevice=UUID=` in `limine.conf` changes. The ESP is reused, never
   reformatted, and the Windows entry is preserved.
7. **Verify Windows still boots before declaring success**, exactly as Phase 2
   step 3 did on the laptop.

Fallbacks, in order of preference: work from the laptop (proven in step 1), or
reinstall Omarchy into `p2`. Both are cheap, which is what makes committing to
this phase reasonable.

If `p2`'s 591 GiB later proves too small, that is when to shrink NTFS — on a
working system, with nothing at stake — and `btrfs device add` the freed space.
btrfs is multi-device and does not require contiguity, so it grows with no data
movement. Do not shrink anything during this phase.

---

## What "done" looks like

- A stranger follows `README.md`: install Arch from the pinned ISO using the
  checked-in `archinstall` config, then clone and run `./install.sh`. They get a
  usable BunnE desktop with **no manual repair afterwards**.
- `install.sh` is idempotent, re-runnable on a working machine, and refuses
  loudly on an Arch that does not meet its prerequisites.
- **Latency measurably beats the Phase 1 baseline** on the paths that get used —
  terminal spawn, `nvim` to an editable buffer, launcher, keybind to window,
  power-on to a desktop that takes input. This is the headline result; it is
  listed first because it is the one that can be quietly dropped for being
  awkward to measure.
- Boot and idle RAM also measurably beat the Phase 1 baseline.
- Every package on the box traces to a row in `choices.tsv` with a reason.
- Optional profiles are opt-in and add nothing at login.
