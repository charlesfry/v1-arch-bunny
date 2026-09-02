# Phase 4 config inventory — what `install.sh` must actually produce

**Written 2026-08-26 from `bunne-test` as it stands**, because the installer cannot be
written without knowing what it has to end up with, and `config/` currently tracks **three
files** while the working machine carries considerably more.

Nothing here is a decision. It is a survey of the gap between "the box that works" and
"the repo that claims to reproduce it", with each item pointed at the `CHOICES.md` row that
already decided it.

## Method

- `pacman -Qkk` over every installed package, which lists **exactly** the package-owned
  config files that differ from what shipped. That is the deviation set, and the repo's
  own rule is that a config file should contain only deviations.
- A direct check of the paths that picked rows imply but that no package owns.
- `diff` of each tracked `config/` file against the box.

**Method corrected 2026-08-26, and it had missed things.** `pacman -Qkk` reports
package-owned files that *differ from what shipped* — so a file **no package owns at all**
is structurally invisible to it, and the hand check can only look at paths some row's prose
happens to spell out. Three live configuration files of `picked` rows were missed that way,
plus a second must-not-ship item.

The method that cannot miss them asks the opposite question — not *"are the files I know
about correct"* but *"what is here that I do not know about"* — as a set difference between
what pacman owns and what is on disk. It is now
[`scripts/check-unowned-etc.sh`](../scripts/check-unowned-etc.sh), and **it must be run as
root**: as a normal user, 12 directories under `/etc` are unreadable, and the user-level run
missed three more paths (including the `sudoers.d` pair). The script says so loudly rather
than dropping them silently.

It surveys `/etc` only. `$HOME` has no package ownership to difference against, so the two
shell files and the user units in §8 still need finding by hand.

## 1. Already tracked, and verified in sync

| file | row | state |
|---|---|---|
| `config/kitty/kitty.conf` | `terminal` | **identical** to the box |
| `config/niri/config.kdl` | `compositor` | **identical** (includes tonight's screenshot guard) |
| `config/xdg-desktop-portal/portals.conf` | `desktop-portals` | **identical** |

No drift. Checked 2026-08-26.

## 2. Files BunnE creates that no package owns — installer must write these

| file | bytes | what it carries | row |
|---|---|---|---|
| `/etc/snapper/configs/root` | 1238 | `SPACE_LIMIT=0.08`, `NUMBER_LIMIT=2-15`, `NUMBER_LIMIT_IMPORTANT=0-5`, `NUMBER_MIN_AGE=1800`, `TIMELINE_CREATE=no` — **plus `QGROUP="1/0"`**, which `snapper setup-quota` writes rather than a human. Confirmed by diff against the snapper template, 2026-08-26; `FREE_LIMIT` and `NUMBER_CLEANUP` are template defaults and **not** ours | `snapshot-bloat`, `4.1` |
| `/etc/systemd/zram-generator.conf` | 28 | `[zram0]` / `zram-size = ram / 2` | `swap-zram` |
| `/etc/default/limine` | 316 | `FIND_BOOTLOADERS=no` + the comment explaining why | `snapshot-boot-entries` |
| `/etc/systemd/system/getty@tty1.service.d/autologin.conf` | 100 | `agetty --autologin bunne` | `display-manager` |
| `~/.bash_profile` | 154 | `exec niri-session` — the other half of autologin | `display-manager`, `shell` |
| `~/.bashrc` | 172 | | `shell`, `shell-startup` |

**The autologin drop-in shrank when `60-autologin.sh` was written, 2026-08-26.** The 100
bytes above are the Arch wiki's widely-copied form:
`-/sbin/agetty -o "-p -f -- \u" --noclear --autologin bunne %I $TERM`. Arch's own
`getty@.service` ships `ExecStart=-/usr/bin/agetty --noreset --noclear - ${TERM}`, so
against it the wiki version *drops* `--noreset`, hardcodes a path, and re-specifies by hand
the `-f username` that `--autologin` already passes to `login(1)` (agetty(8), read on the
box). The deviation is one flag, and the step now writes one flag. Reboot-verified
2026-08-26: autologin into niri on tty1, zero failed units.

**Three more, found 2026-08-26 by `scripts/check-unowned-etc.sh` after this table was
written**, all of them live configuration of `picked` rows:

| file | bytes | what it carries | row |
|---|---|---|---|
| `/etc/sysctl.d/99-zram.conf` | 40 | `vm.swappiness = 180`, `vm.page-cluster = 0` | `swap-zram` |
| `/etc/systemd/system/-.slice.d/10-oomd.conf` | 28 | `ManagedOOMSwap=kill` | `oom-protection` |
| `/etc/systemd/system/user@.service.d/10-oomd.conf` | 60 | `ManagedOOMMemoryPressure=kill`, `ManagedOOMSwap=kill` | `oom-protection` |

The `swap-zram` row names both sysctls explicitly in its own text — *"`vm.swappiness = 180`
and `vm.page-cluster = 0`: zram is random-access RAM, so the kernel's conservative defaults
are actively wrong for it"* — so this was decided, applied and then dropped out of the
survey. The gap was the method, not the decision.

**The two oomd drop-ins carry a filename that says `test`, and they are not a test.** They
are exactly the config `oom-protection` was ratified with on 2026-08-25 (*"two drop-ins —
`ManagedOOMSwap=kill` on `-.slice`, and `ManagedOOMSwap=kill` with
`ManagedOOMMemoryPressure=kill` on `user@.service`"*), still in place as the live soak that
row describes. **The installer must not inherit that name** — a shipped machine with
`10-oomd-test.conf` in `/etc` reads as leftover debris and invites someone to delete the
`oom-protection` row's entire mechanism. `10-oomd.conf` is the obvious fix.

**Renamed on `bunne-test` 2026-08-26, and verified rather than assumed.** Both drop-ins are
now `10-oomd.conf`. Before and after `systemctl daemon-reload`, `systemctl show` reports the
same effective values — `ManagedOOMSwap=kill` on `-.slice`, `ManagedOOMSwap=kill` plus
`ManagedOOMMemoryPressure=kill` on `user@1000.service` — and `oomctl` lists both `/` and
`/user.slice/user-1000.slice/user@1000.service` as monitored, which is the stronger check:
it shows oomd itself loaded them, not merely that the files parse. `systemd-oomd` active,
zero failed units. The table above now names the files by their current paths.

One path was checked and is **not** ours: `/etc/mkinitcpio.d/linux.preset` is unowned
because mkinitcpio's own pacman hook generates it from
`/usr/share/mkinitcpio/hook.preset`. Filtered as package-hook output.

**All six are small and none is tracked — but none of them can simply be dropped into
`config/` either, and that is the finding.** `config/README.md` states the layout plainly:
*"Layout mirrors `$XDG_CONFIG_HOME`"*. Four of these six live in `/etc` and two live
directly in `$HOME`, so **not one of them has a place in the current structure.**

Worse, two are explicitly spoken for: `config/README.md`'s *"Not here yet, deliberately"*
section says the shell config is **`deferred` pending the author's review**, and that
`bunne-test`'s `~/.bashrc` "is stock Arch and carries nothing of ours". Harvesting
`.bashrc`/`.bash_profile` would settle a deferred decision by accident.

**So the blocker here was structural, not effort** — see §7. **Lifted 2026-08-26**: the
author's answer is that none of the six is tracked, so `install.sh` writes them and no
layout is invented. The two `deferred` shell files are still not harvestable.

**CLOSED 2026-08-26 — every file in this section now has an installer step.** The last two
were the oomd drop-ins, which `install.d/35-oom-protection.sh` writes; the sweep run
afterwards returns the same ten unowned paths and every one of them is now either written by
a step or deliberately excluded:

| unowned path | who owns it now |
|---|---|
| `/etc/systemd/zram-generator.conf`, `/etc/sysctl.d/99-zram.conf` | `30-zram.sh` |
| `/etc/systemd/system/-.slice.d/10-oomd.conf`, `/etc/systemd/system/user@.service.d/10-oomd.conf` | `35-oom-protection.sh` |
| `/etc/snapper/configs/root` | `40-snapshots.sh` (five `set-config` calls + `setup-quota`) |
| `/etc/default/limine` | `50-limine.sh` |
| `/etc/systemd/system/getty@tty1.service.d/autologin.conf` | `60-autologin.sh` |
| `/etc/NetworkManager/system-connections/*` | **deliberately not tracked** — §4, the author's wifi credentials |
| `/etc/sudoers.d/20-bunne-testbox-nopasswd` | **must not ship** — §5, and `00-preflight.sh` reports it every run |
| `/etc/sudoers.d/10-wheel` | see below |

**`10-wheel` needs no check, and that is a deletion rather than an omission.** This document
previously said *"the installer should verify it rather than write it."* It should not:
`install.sh` already proves `sudo -n true` (or a successful `sudo -v`) before any step runs,
and that tests the **capability** `10-wheel` exists to grant rather than the file that
happens to grant it. A file check would be strictly weaker — it passes on a `10-wheel` that
is present and malformed, and fails on a machine that grants wheel some other way — while
also being unreadable to a non-root preflight (`/etc/sudoers.d` is 0750). The stronger check
was already there.

`~/.bashrc` and `~/.bash_profile` remain the exception, and remain **`deferred`**:
`60-autologin.sh` appends the one `exec niri-session` block it needs and owns nothing else in
either file. **2026-08-27: `85-shell-prompt.sh` does the same for `prompt` (picked, shipped)** —
one `source` line into `~/.bashrc`, nothing else in the file touched. `shell` itself is still
`deferred`; each piece that ships ahead of the full review gets its own narrow append, same
shape, rather than waiting on one another.

## 3. Package-owned files BunnE deliberately modifies

From `pacman -Qkk`, minus the machine-identity and side-effect entries in §4:

| file | the deviation | row |
|---|---|---|
| `/etc/mkinitcpio.conf` | `HOOKS=(… block encrypt filesystems fsck)` — `encrypt` for LUKS. **Also `FILES=(/crypto_keyfile.bin)`, see §5.** **Verified by `00-preflight.sh`, never written** — see below | `filesystem`, `benchmark-unlock` |
| `/etc/fstab` | the btrfs subvolume layout, plus the `@containerd` / `@dockervol` top-level mounts | `docker-storage-quota` |
| `/etc/pacman.conf` | the `[omarchy]` repo at `SigLevel = Required DatabaseOptional` (**not** `TrustAll`), appended last. **`ParallelDownloads = 5` was listed here and is not ours** — see below | `snapshot-boot-entries` |
| `/etc/conf.d/snapper` | `SNAPPER_CONFIGS="root"` | `snapshot-bloat` |
| `/etc/locale.gen` | locale selection | base install (`archinstall`) |
| `/etc/pacman.d/mirrorlist` | mirror selection | base install (`archinstall`) |

**Re-verified 2026-08-26, after the installer's write path was exercised end to end
(`benchmarks/4.30`): zero drift.** `pacman -Qkk` reports exactly sixteen package-owned files
differing from what shipped, and every one is already named above or in §4 — the six in this
table, plus `passwd`/`group`/`shadow`/`gshadow`/`hosts`/`resolv.conf`/`subuid`/`subgid`
(machine identity) and `shells`/`fmtutil.cnf` (package side effects). **No file has appeared
that no row explains.** Worth re-running after any step lands, since a step that quietly
modifies a package-owned file it was not supposed to touch would show up here and nowhere
else.

One refinement to the `/etc/fstab` row: **two of its lines now have an owner.** The
`@containerd` and `@dockervol` mounts are written by `install.d/15-docker-subvols.sh`, which
*appends* them and never rewrites a line that already mounts the right subvolume — whatever
options that line carries. The rest of the file is `archinstall`'s and stays that way.

**`ParallelDownloads = 5` is not a deviation, corrected 2026-08-26.** It is the pristine
value: line 37 of the `pacman.conf` inside the `pacman` package itself, identical to the
live file. `pacman -Qkk` flags `/etc/pacman.conf` as modified because of the `[omarchy]`
block, and this line was attributed to us on the strength of that flag alone. It is exactly
the mistake `CLAUDE.md` warns about — *"upstream defaults that are already correct should be
left alone rather than restated"* — and an installer that wrote it would have been adding a
line that does nothing. **The general trap: `pacman -Qkk` tells you a file differs, never
which lines differ.** Diff against the package's own copy
(`tar -xOf /var/cache/pacman/pkg/<pkg> etc/<path>`) before calling any single line a
deviation. Also worth noting for the `[omarchy]`-goes-last rule: this machine has no
`[multilib]`, so "after core/extra/multilib" is in practice "at end of file".

**`/etc/mkinitcpio.conf` is checked and deliberately not written (2026-08-26).** It is not
in §2 because `archinstall` produces it, and it does not need a step because on a LUKS
install `archinstall` already gets it right. What it needed was a *check*, because **nothing
else on the machine would notice it being wrong**: the running system booted from an
initramfs that already works, so a broken `HOOKS=` changes nothing today. It governs the
*next* build — which happens unattended, from a pacman hook, on the next kernel update — and
the failure then surfaces at a boot nobody is watching, on a `/boot` that is FAT and outside
every snapshot, so there is no rollback for it. `00-preflight.sh` now checks two things,
both read-only:

1. **`encrypt` present and correctly ordered**, `block` → `encrypt` → `filesystems`, and only
   when `/` is actually on a `crypt` device (`encrypt` on an unencrypted root is a hook with
   nothing to unlock, not a missing feature). Position matters as much as presence: all three
   hooks present in the wrong order build an initramfs that cannot open the root device.
2. **Every `FILES=` entry exists.** A dangling entry does not warn, it *fails the build* —
   `add_file()` errors `file not found`, the `RETURN` trap counts it into `_builderrors`, and
   `mkinitcpio` exits non-zero (read in `/usr/lib/initcpio/functions` on the box). The way to
   reach that state is a **half-done `benchmark-unlock` teardown**: keyfile deleted,
   `FILES=` line left behind. It then breaks the next kernel update rather than the boot
   after it, which is a much harder thing to trace back.

**Fixing it is left to a human on purpose.** The repair for a wrong `HOOKS=` is an initramfs
rebuild, and doing that unattended on the boot path of a machine the installer has just met
is not a decision this repo should make for someone. All four failure paths were exercised
on `bunne-test` by editing the config only — `encrypt` absent, `encrypt` before `block`,
`encrypt` after `filesystems`, and a dangling `FILES=` entry — with the file restored byte
for byte afterwards and `mkinitcpio` never run.

Plus one that no package owns because it lives on the ESP:

| `/boot/limine.conf` | `timeout: 3`, `hash_mismatch_panic: no`, `default_entry: Arch Linux/linux` — the **path** form since 2026-08-26, not the index, and set explicitly because its default of `1` is the folder. Written by `install.d/50-limine.sh` | `snapshot-boot-entries` |

## 4. Modified, but deliberately NOT tracked

Listed so a future reader does not mistake the omission for an oversight.

- **Machine identity**: `/etc/passwd`, `/etc/group`, `/etc/shadow`, `/etc/gshadow`,
  `/etc/hosts`, `/etc/resolv.conf`, `/etc/subuid`, `/etc/subgid`. Created by the install,
  different on every machine, and `CLAUDE.md` says keep personal details isolated.
- **Personal, not just per-machine**: `/etc/NetworkManager/system-connections/*.nmconnection`
  — the author's wifi credentials. Found by the 2026-08-26 sweep; listed here so nobody
  mistakes it for something the installer should reproduce.
- **Side effects of installing packages**: `/etc/shells` (shell packages append),
  `/etc/texmf/web2c/fmtutil.cnf` (texlive). Nobody chose these; pacman will produce them
  again on any machine that installs the same packages.

## 5. One flag that must not ship

`/etc/mkinitcpio.conf` currently carries **`FILES=(/crypto_keyfile.bin)`** — that is
`CHOICES.md` `benchmark-unlock`, the second LUKS keyslot that lets `bunne-test` reboot
unattended. `docs/04-plan.md` already holds the teardown checklist: one keyslot, empty
`FILES=`, no `/crypto_keyfile.bin`, **and the next boot must actually ask for the
passphrase** — that last one being the canary, because a silent boot means the keyfile is
still live whatever the config says.

Confirmed present 2026-08-26. **Anything harvesting `/etc/mkinitcpio.conf` into `config/`
must not carry this line with it.**

**And a second one, found 2026-08-26:** `/etc/sudoers.d/20-bunne-testbox-nopasswd`, holding
`bunne ALL=(ALL:ALL) NOPASSWD: ALL`. Same category as the keyfile and the same reason — it
exists so this box can be driven over ssh without a human at the keyboard, and it is the
mechanism most of today's work ran on. **Passwordless root for the desktop user must never
ship.** It is invisible to a non-root survey (`/etc/sudoers.d` is `0750`), which is why it
sat here undetected until the sweep was run under `sudo`. Add it to `docs/04-plan.md`'s
teardown checklist next to the keyfile, with the same shape of canary: after teardown,
`sudo -n true` must **fail**.

Its neighbour `/etc/sudoers.d/10-wheel` (`%wheel ALL=(ALL:ALL) ALL`) is the opposite case —
that one is load-bearing, since without it the `bunne` user cannot escalate at all and
`CLAUDE.md`'s "never require `sudo ./install.sh`" convention has nothing to escalate
*with*. Created by the base install; belongs with the `archinstall` entries in §3 rather
than here, and the installer should **verify** it rather than write it.

## 6. Not yet configured at all

Picked rows whose config file does not exist on the box, so there is nothing to harvest
and the installer has nothing to copy:

- `~/.config/mako/config` — **absent**. `notifications` is picked and mako runs on
  defaults. The disk-alert draft's item 3 notes the default body height truncates its
  diagnostics, so there is at least one known reason to want a config here.
- `~/.gitconfig` — **absent**. The predecessor repo carries git config as a feature to
  bring forward.

## 7. The structural question this survey ran into

**`config/` can currently only express `$XDG_CONFIG_HOME` files.** Everything in §2 and §3
is either `/etc` or `$HOME`, and the repo has no convention for either. `dotfile-deployment`
picked *symlink via `ln -sfn`* — which works for `/etc` too, as root — but where the
source files **live in the repo** is undecided.

Obvious candidates, none chosen here:

1. **Mirror from the root**: `config/etc/...` and `config/home/...` alongside the existing
   XDG tree, with `config/` becoming "things that get placed" rather than "$XDG_CONFIG_HOME".
2. **A sibling directory** — `etc/` at the repo root, leaving `config/` exactly as
   documented.
3. **Generate rather than copy.** Several of these are two or three settings
   (`zram-generator.conf` is 28 bytes; `conf.d/snapper` is one line). A line in `install.sh`
   that writes them may beat a tracked file plus a symlink, and the parsimony rule leans
   that way — the best change to a file is not having the file.

Option 3 deserves real weight: of the six §2 files, four are short enough that tracking a
file *and* a symlink *and* a README entry is more machinery than the setting is worth.
`/etc/snapper/configs/root` (1238 bytes, and mostly upstream defaults) is the one that
plainly wants to be a file — or, more likely, a handful of `snapper set-config` calls,
since only five of its values are ours.

**Do not settle this as a side effect of harvesting one file.** It is the same trap
`config/README.md` already flags for the niri verbatim-vs-minimal question.

### ANSWERED 2026-08-26 — option 3, and the layout question stays open

**Author, 2026-08-26:** *"i like your suggestion."* The suggestion was that **none of the
six is tracked as a file** — `install.sh` writes each setting — and therefore **no new
repo layout is invented today.** Looking at what the six actually are, that is not a
compromise, it is the whole answer:

| file | why it is a line, not a file |
|---|---|
| `/etc/systemd/zram-generator.conf` | 28 bytes, one setting |
| `/etc/conf.d/snapper` | one line (`SNAPPER_CONFIGS="root"`) |
| `/etc/default/limine` | one setting plus the comment explaining it |
| `getty@tty1` autologin drop-in | contains the **username**, so it must be generated anyway |
| `/etc/snapper/configs/root` | 1238 bytes of upstream defaults with **five** values of ours → five `snapper set-config` calls |
| `~/.bashrc`, `~/.bash_profile` | separately **`deferred`** pending the shell-config review; not harvestable today at all |

So the structural question **dissolves for now** rather than being decided — the same shape
as `install-artifact`, where `base-install-method` removed the thing the question was
about. `config/` keeps its README exactly as written: `$XDG_CONFIG_HOME` and nothing else.

**It re-opens the day a file genuinely wants tracking**, and the likely trigger is named:
the shell config, when the author reviews it. `~/.bashrc` with a hand-rolled prompt in it
is a real file with real content, and it lives in `$HOME`. **When that lands, this question
is live again** — and the three options above are still the three options.

## 8. Pending ratification, not counted above

Nothing left here as of 2026-08-26. `disk-alert` shipped the same day: the author asked for
the three-meter draft to be simplified, it was rewritten to one `df` (19 lines, no root
helper, no sudoers entry), and it now lives at `config/systemd/user/` with its timer
enabled by `install.d/80-disk-alert.sh`. See `CHOICES.md` `disk-alert` and
`benchmarks/raw/p4-disk-alert-draft/NOTES.md` for the full history.
