# Resume here

Session state as of **2026-08-28**, for picking this back up cold.
Newest block first; everything below it is history, kept but superseded.

## Start here — what to do next

### ⚡ CURRENT STATE — 2026-08-28 (read this; every section below is history)

**LATEST — the installer reached `exit 0` on a real machine, then the layout it was
built for turned out to be wrong.**

**`install.sh` completed all 25 steps and the machine rebooted clean**: 0 failed units,
autologin into niri, all 7 btrfs mounts carrying `noatime,compress=zstd:1`, zram at
7.7 GiB (the uncapped `ram/2`), every service enabled, both user timers scheduled, the
`linux-firmware` metapackage gone with all named splits intact. **One credential prompt**,
proven from the journal — `LOGIN ON tty1 BY bunny` with no authentication step. That is the
first time this repo has produced a working machine end to end.

**Five defects were found in the process, each only findable on a genuinely fresh box**,
because `bunne-test` had been hand-configured months earlier and happened to look right:
1. `25-services.sh` demanded `is-active` for `nftables`, which is `Type=oneshot` with no
   `RemainAfterExit` — it goes `inactive (dead)` on success. **Would have failed every
   install.** Now checks `nft list ruleset` instead.
2. `40-snapshots.sh` refused to create the snapper config when `@snapshots` was already
   mounted, calling the fix a hack. It is the Arch wiki's documented sequence, and the
   ordering it called "unsettled" is now permanent. Implemented, guarded to an empty
   `/.snapshots`, with a trap that restores the mount.
3. Every read of `/etc/snapper/configs/root` needed `sudo` (0640 root:root).
4. `50-limine.sh` hardcoded `default_entry: Arch Linux/linux`, the *nested* path form.
   archinstall writes a flat `/Arch Linux (linux)`. Now derived from the file by
   `check-limine.sh --default-path`, one parser for both uses.
5. `51-windows-chainload.sh` found nothing — which exposed the real error below.

**THE LAYOUT WAS WRONG: never create a second ESP.** The Arch wiki, on the author's
prompting: *"An additional EFI system partition should not be created, as it may prevent
Windows from booting"* and *"there can only be one ESP per drive"* — *"Simply mount the
existing partition."* The rehearsal had built its own 1 GiB ESP beside Windows'. Sharing
Windows' ESP also makes the chainload work with no code change. **The condition is not
optional**: Windows Fast Startup and hibernation must be off (`powercfg /H off`), since a
hibernated Windows can corrupt a shared ESP.

**SIX SUBVOLUMES NOW**, `@ @home @snapshots @log @cache @tmp`. `@pkg` →
`/var/cache/pacman/pkg` became `@cache` → `/var/cache`, and `@tmp` is new — the Arch wiki's
Snapper page recommends both. The reason `@pkg` was narrow (matching archinstall's default
names) **expired** when `disk_config` left the JSONs and *Suggest* left the instructions.

**NEW STANDING RULE, `CLAUDE.md`:** never gracefully handle a condition that should never
happen. The test: could this occur on a machine built the way `README.md` describes? If no,
hard error. Three shrugs became failures — two steps that would rewrite the **boot config**
and then print `? config unvalidated` if the checker was missing, and `47-vconsole.sh`
exiting 0 while leaving the boot race it exists to fix in place. `00-preflight.sh` now
checks all six subvolumes, so a mistyped one stops the run before anything is written.

---

**LATER THE SAME DAY: the JSONs stopped touching disks at all, and the install
finally ran.** Author's call, in two steps: `disk_config` out of the coexist file
(*"it's more work on the end user to audit a repo that messes with his partitions, so the
lower-code option for us is also the easier implementation for them"*), then out of
`-wholedisk` too. **Neither archinstall JSON now contains `disk_config`,
`disk_encryption` or a device path** — `grep disk` proves it. `plan-disk.sh` was written
to compute offsets and **deleted the same hour**, unused: *"i dont want it. too scary."*
Correct, and it should never have existed — archinstall's manual partitioning menu already
does the arithmetic and the 1 MiB alignment, so it was reimplementing upstream.

**What that cost, and what it bought back.** Cost: LUKS **cannot** come from the files —
`lib/args.py:269-287` reads `disk_encryption` *and* `encryption_password` only inside
`if disk_config:`, and `DiskEncryption.parse_arg` resolves partition `obj_id`s, so
encryption inherently names a partition the files no longer define. `encryption_password`
is therefore gone from the creds file (it was being silently ignored — same defect class as
`swap.algorithm` and the plymouth theme) and the passphrase is typed once in the menu.
Bought back: two new steps for things archinstall cannot express —
**`05-mount-options.sh`** (`noatime,compress=zstd:1`; the menu can only write plain
`compress=zstd`, which is level 3, and `noatime` appears nowhere in archinstall's source)
and **`27-firmware.sh`** (removes the `linux-firmware` metapackage archinstall hardcodes at
`installer.py:69`, which drags in `-nvidia` against the `initramfs` row's measured
130 MB → 25 MB). **25 steps.** `15-docker-subvols.sh` also reverted to creating
`@containerd`/`@dockervol` itself, which is what keeps the manual subvolume list at five.

**ARCHINSTALL FAILS SILENTLY ON EVERY INPUT THAT MATTERS. Five caught in one evening**,
all by reading the saved config rather than trusting the menu:
1. `/dev/CHANGEME` → whole disk section dropped (`if not device: continue`), surfacing as
   *"Luks or LvmOnLuks encryption require partitions to be defined"*.
2. A `create` aimed at occupied space → a **1 MiB stub**, dying much later as
   *"cryptsetup: Requested offset is beyond real size of device"*. Left junk partitions
   7-10 on the disk.
3. No creds file → encryption block discarded, **unencrypted root**, no warning.
4. *Suggest partition layout* → silently sets `wipe: true` and spans the whole disk. It was
   in the README as a shortcut; it very nearly ate Windows and is now removed.
5. `1 GB` where `1024 MiB` was meant → `GB` is 1000³, so the next partition starts off a
   1 MiB boundary. archinstall's own loader rejects that on reload
   (`device.py:214`) but never on the path you actually took.
**`README.md` step 4b is the countermeasure**: save the config, read it back, check six
things. It is the only checkpoint that exists.

**Windows survived all of it, proven not assumed** — sha256 of all four regions before and
after, byte-identical.

---

**The day the installer stopped being mostly bespoke bash.** 17 commits. The through-line
is one instruction from the author: *"anything that can be in the configs almost certainly
should be... we need overwhelming evidence in order to keep something out."* And the
reframing that made it more than golf: *"this isn't just code golf. this is using standard
procedures to generate our desired arch configuration, which makes the entire repo more
auditable and cleaner."*

**81 of the ledger's 86 packages now install via `pacstrap`**, from
`archinstall-2026.08.01-wholedisk.json` / `-coexist.json`. Five cannot, both mechanisms
read from archinstall 4.4's own source rather than assumed: `yay-bin`, `brave-bin`,
`gcalcli` are AUR (no AUR path exists anywhere in archinstall), and
`limine-snapper-sync`, `limine-mkinitcpio-hook` need `[omarchy]`, whose
`SigLevel = Required DatabaseOptional` cannot be expressed — `SignOption` is
`TrustedOnly`/`TrustAll` only, omarchy's database is genuinely unsigned
(`omarchy.db.sig` → 404), and `TrustAll` would disable signature verification on a
third-party repo. Also moved: `network_config`, `app_config.bluetooth_config`, `services`,
`locale_config`, `pacman_config`, `hostname`, `bootloader_config.plymouth`,
`disk_config`'s `@containerd`/`@dockervol`.

**`install.d/20-packages.sh` checks the duplication three ways** and that is what makes it
safe rather than merely admitted: nothing in a JSON the ledger does not claim, nothing
eligible the JSON left out, and no stale entry in `NOT_IN_JSON` — the third matters because
without it that array becomes the one place a package can hide from both other checks.

**THE BIG FINDING WAS NOT LINE SAVINGS. Four services and one group were enabled by
nothing at all.** `NetworkManager.service`, `bluetooth.service`, `nftables.service`,
`docker.socket` — every one required by a `picked` row, none enabled anywhere in the repo.
They worked on `bunne-test` because they had been switched on by hand during research.
A fresh install had **no firewall, no Bluetooth, no Docker and no network manager**, which
is why the first rehearsal box came up unable to reach the network. Same shape: the user
was never added to the `docker` group, and `gcalcli` was named by the `notifications`
detail section but absent from the table row the parser reads, so it has **never** been
installed by this repo. `install.d/25-services.sh` and `27-firmware.sh` are new.

**`archinstall` reinstalls the `linux-firmware` metapackage no matter what** —
`__packages__` is hardcoded at `lib/installer.py:69` with no JSON key to prevent it — so
every archinstall box has silently carried `linux-firmware-nvidia` since the
`base-install-method` decision, against the `initramfs` row's measured 130 MB → 25 MB.
`27-firmware.sh` removes it with `pacman -R`, never `-Rs`.

**Three rehearsal traps, all found by running it rather than reading:**
1. **`/dev/CHANGEME` fails as a LUKS error.** `parse_arg` does `if not device: continue`,
   so an unresolvable device silently drops the entire disk config and the only symptom is
   *"Luks or LvmOnLuks encryption require partitions to be defined"*. Cost two failed runs.
   **The `sed` must be re-applied after every `scp`.**
2. **The JSON cannot carry the LUKS passphrase.** `DiskEncryption.parse_arg` ends
   `if not password: return None`, and the passphrase comes from a top-level
   `encryption_password` — so without a creds file the whole encryption block is discarded
   **silently** and an unencrypted root installs. `archinstall-2026.08.01-creds.json` now
   ships placeholders (`bunny` / `bunny` / `bunny`), committed on the author's word.
3. **`user_credentials.json` is archinstall's live output**, rewritten from the menu every
   save, so it stays gitignored; the tracked template deliberately uses a different name.

**Renamed and recorded.** `archinstall-2026.08.01.json` → `-wholedisk.json` (its
`wipe: true` is the opposite of the coexist twin and the bare name gave no hint which would
eat Windows — I briefly told the author to use the wrong one). **The Framework is the AMD
variant** (author's word), so `linux-firmware-amdgpu` is in the ledger; `-radeon` was
deliberately left out and is the one open question there.

**Everything on a machine is now `bunny`, not `bunne`** — paths, env vars, functions,
`.bunny.bak`, the Jupyter kernel, `:checkhealth bunny`, the plymouth theme. `bunne-test`
(dev-box hostname) and `arch-bunny` (checkout dir, tied to the remote) deliberately stay.

**All 24 steps open with a plain-English block** naming what changes, what you gain, what
it costs, and why upstream's default is wrong here — no idempotency or dry-run talk. Also
landed: the niri edits recovered from an nvim undo file after a sync overwrote them, the
stock lock screen with `--indicator-idle-visible`, `KEYMAP=@kernel`, OpenVPN's directory
mechanism, and `scripts/colorpick.sh`.

**WHAT IS NOT DONE: `install.sh` has never run on a machine built from these JSONs.**
Everything above is read from source and reasoned. The last rehearsal is what caught the
`sshd`/`openssh` and nested-`limine.conf` bugs that reading did not. **The next session's
first job is to finish that install and run all 24 steps on it.**

---

### ⚡ CURRENT STATE — 2026-08-27, evening (read this; every section below is history)

**Meeting alerts are un-deferred and cost nothing — the answer was the browser after all.**
The author asked for calendar alerts in mako again, and the Omarchy hypothesis from the
afternoon's deferral turned out to be checkable rather than merely plausible: that desktop's
own Brave profile has `calendar.google.com` at `setting: 1` under
`content_settings.exceptions.notifications`, and a live `calendar.google.com` tab in
`Default/Sessions/Session_*`. `bunne-test`'s profile has `{}`, no session restore, no pinned
tabs — which is the entire difference. So bunne gets meeting alerts from **three manual Brave
clicks** (Allow the prompt, pin the tab, *On startup → Continue where you left off*), no Google
Cloud OAuth client, no new code, no new package. Nothing scripts them — Chromium validates its
own prefs and a permission grant is a consent action, so automating it is the against-the-grain
hack `no-hacky-solutions` rejects; manual by policy, same as `gcalcli init` and wifi creds.
The named cost: Brave not running or the tab closed means no alert and no warning. The
`gcalcli` poller stays enabled and dormant as the fix for that, unchanged. `CHOICES.md`
`notifications` carries it. **What's left is the author clicking the three steps on bunne** —
and that closes the notifications acceptance test's calendar half.

### 2026-08-27, later

**Nine deferred `CHOICES.md` rows answered in one sitting, asked as multiple-choice.** With the
Limine fix and the harvest done (below), the author asked to knock out everything still marked
`deferred`/TBD. Went through all 11, found 3 that didn't need a question (`desktop-portals` was
a stale duplicate of the already-picked `portal` row; `xwayland` is designed to wait for a real
app failure; `prompt-hooks` is an implementation rule that follows automatically once
`prompt`/`dir-aware-display` ship), then asked the other 9 as three rounds of multiple-choice.
Answers: **prompt** ships as designed (plus a new `OPINIONS.md`); **node-runtime** ships as
designed (pyright already made it non-optional); **install-profile** rejected — one profile
only, no lite/full split; **notifications** mechanism confirmed, meeting alerts via a calendar
poller, not the browser; **dir-aware-display** ships both halves; **snapshot-bloat** part 3
(nested subvolumes for regenerable caches) approved; **secrets-bootstrap** is manual copy, plus
a much harder rule — employer/client work never ships in this repo, now in `CLAUDE.md`;
**backup** is no longer a Phase 6 gate (no external disk, won't have one for a while — the
blocking language in `04-plan.md`/`02-functionality.md` is removed); **ascii-bunnies** dropped
(low-quality frames, not the mechanism — revisit if fixed).

**Of those, `prompt` got actually built, not just decided.** `config/bash/prompt.bash` (the
`benchmarks/3.5` prototype, `BUNNE_PROMPT_GIT_STATUS` removed since the dirty marker was decided
on rather than left as a toggle) plus `install.d/85-shell-prompt.sh`, which appends one `source`
line to `~/.bashrc` — same shape as `60-autologin.sh`'s `.bash_profile` block, `.bashrc` stays
otherwise untracked. Twelve steps now. Verified on `bunne-test` for real: synced, ran the full
`./install.sh` (12/12 steps clean, `mako`/`nodejs`/`npm`/`direnv` newly installed, 0 failed
units), then hit a test-methodology trap worth remembering — `bash -c "..."` looked like it
proved the prompt broken (empty `PS1`) because Arch's stock `.bashrc` guards everything behind
`[[ $- != *i* ]] && return` and `-c` mode isn't interactive, so `PROMPT_COMMAND` never fires. A
real pty (`script` + `bash -i`) showed the actual cyan `~ ❯` rendering correctly. **The lesson
generalizes**: a shell-config verification has to reproduce the actual invocation shape
(interactive login) or it tests nothing.

`README.md`'s stack table: 72 slots, 66 picked (was 60), 3 still TBD (`backup`, `xwayland`,
`prompt-hooks`), 3 resolved to nothing. `check-packages.sh`: 79 packages resolve (was 75).
`OPINIONS.md` is new — a high-level tour of this repo's most distinctive choices, requested
alongside the prompt decision.

**`snapshot-bloat` part 3 turned out to need nothing** — checked on `bunne-test` rather than
built: `@home` is already a separate top-level subvolume from `@` (the `filesystem` layout,
which postdates the row), so `~/.cache` was already outside every snapshot the same way
Docker is. `snapper list-configs` shows one config (`SUBVOLUME="/"`), a live snapshot's
`/home` is empty, and snapshot sizes (196 KiB after a package install) confirm no gigabytes
are leaking in. All three parts of that row are now closed.

**Still not built, decided but scoped as follow-up**: the `dir-aware-display` `.bashrc` wiring
and mapping-file format (note: the 4.20 prototype's example map uses `tradeswell` as a path —
genericize it before shipping, per the new `secrets-bootstrap` rule); the `notifications`
calendar-poller mechanism (API/auth path, poll interval, systemd timer — same shape as
`disk-alert`).

---

### ⚡ CURRENT STATE — 2026-08-27, morning (history)

**Eleven steps, all reboot-verified. `install.d/80-disk-alert.sh` and `config/git/config` landed,
and a real bug in `50-limine.sh` was found and fixed by running the whole pipeline on `bunne-test`
rather than trusting a synthetic test.**

**`scripts/find-limine-conf.sh` replaces the hardcoded `/boot/limine.conf`.** `CHOICES.md`
`bootloader` had flagged, 2026-08-26, that `archinstall` nests the config
(`/boot/EFI/arch-limine/limine.conf` with our `removable: false`) while every box actually
provisioned so far has it flat — two real layouts, one hardcoded guess. The finder reads limine's
own documented search order (`CONFIG.md` on the box): first the directory next to the booted EFI
app (`efibootmgr -v`), then limine's own four boot-drive candidates.

**The first version was verified against the wrong box, and it showed within minutes.** Tested
against synthetic fake-ESP directories on a manually-installed desktop with a permissive ESP mount
(`fmask=0022`), generalized to "no root needed," and written up as verified before `bunne-test` had
actually been touched — a documentation mistake caught and corrected in the same session
(`CHOICES.md` now tells it in the right order). Running it for real on `bunne-test` — an
`archinstall`-produced box — failed immediately: `archinstall`'s own fstab mounts `/boot`
`fmask=0077,dmask=0077`, root-only, so a non-root reader cannot even list it. The finder now exits
2 (distinct from exit 1's real not-found) when the ESP itself needs root; `00-preflight.sh` reports
that as "cannot check" rather than a false failure; `50-limine.sh` runs the finder under `sudo`,
which is not a new privilege since everything else in that step already escalates.

**Then verified for real.** Synced this repo onto `bunne-test` (it holds a working copy at
`~/.local/share/arch-bunny`, not a git clone — a plain `tar` pipe over ssh is how it gets updated),
booted Arch (`sudo efibootmgr --bootnext 0001` + `sudo reboot` from the NixOS side, ~2 min to
login), and ran the full `./install.sh`. Clean exit, "BunnE is installed.": all eleven steps `=` or
`+`, 0 failed units, `disk-usage-alert.timer` genuinely scheduled (not just "enabled" —
`systemctl --user list-timers` shows a real next-fire time), all 75 packages resolve, and
`check-unowned-etc.sh`'s ten unowned `/etc` paths are all still accounted for by a step or a named
exclusion. `70-dotfiles.sh` also proved its own backup path live: pre-existing
`disk-usage-alert.service`/`.timer` files from an earlier manual soak got replaced and the old ones
kept as `.bunne.bak`, exactly as designed.

**`disk-alert` and `git-config` are both harvested and shipped**, landed the session before this
one and confirmed working here: `install.d/80-disk-alert.sh` enables the one-`df` timer at
`config/systemd/user/`; `config/git/config` (deviations only, no identity) lands at
`$XDG_CONFIG_HOME/git/config` via the same generic `70-dotfiles.sh` walk, no special-casing needed.

**The Ventoy-artifact deferred decision and open question 28 are both settled** (carried in from
the prior session, written up properly this one): stock pinned Arch ISO + this repo, no custom
artifact; keep btrfs qgroup accounting because snapper's `SPACE_LIMIT`/`FREE_LIMIT` retention runs
on it, not on a notification line. `docs/phase4-config-inventory.md` §8 (pending ratification) is
now empty.

**What's actually left is the author's, not a task list**: `scripts/gen-stack-table.sh` reports 72
slots, 60 picked, 11 still `deferred`, 1 resolved to nothing. Reading the eleven, most cluster
behind one thing —
`prompt`, `prompt-hooks`, `notifications`, `node-runtime`, `dir-aware-display` are all named in
`CLAUDE.md`/`docs/phase4-config-inventory.md` as waiting on the **shell-config review** the author
has flagged as his own open item since at least 2026-08-25. `install-profile`, `snapshot-bloat`,
`backup`, `desktop-portals`, `secrets-bootstrap`, `ascii-bunnies`, `xwayland` are unrelated
one-offs, each `deferred` for its own stated reason, not a gap in the harvest. None of these are
mine to settle unilaterally (`CLAUDE.md`'s own rule) — surfacing them is the whole point of this
paragraph.

**Six commits landed this session**, each independently reviewable: the finder itself, the pinned
`archinstall-2026.08.01-wholedisk.json`, the disk-alert step, the git-config harvest, a one-line shellcheck
fix in `15-docker-subvols.sh`, and a docs-sync commit — plus the permission fix and its own docs
correction on top once `bunne-test` found the real bug. Not yet pushed to `origin/main`.

---

### ⚡ CURRENT STATE — 2026-08-26 afternoon (history)

**Eight steps now. Three landed this session: `15-docker-subvols`, `60-autologin`,
`70-dotfiles`.** All three reboot-verified on `bunne-test` — back up with **0 failed
units**, root on `/@`, both Docker subvolumes remounted from fstab with their modes intact,
docker still listing its image, the symlinks live, and **autologin landed in niri on
tty1**, which is the half that only a real boot can prove. A full `./install.sh` afterwards
is clean at exit 0.

**`15-docker-subvols.sh` runs BEFORE `20-packages.sh`, and the number is the argument.** A
mount placed over a directory that already has bytes in it hides them, so the subvolumes
have to exist before pacman installs docker. It creates `@containerd` and `@dockervol` at
the btrfs top level (mounting `subvolid=5` on a throwaway `/run` mountpoint, since `/` is
`subvol=/@` and a top-level subvolume cannot be created from inside it), appends two fstab
lines, mounts them, enables quota **accounting**, and **clears any qgroup limit it finds** —
`4.27`'s forced-readonly is a decided-against state, not merely an unset one. It is not a
migration tool: data already at either path is a loud refusal pointing at
`benchmarks/instruments/4.24-docker-subvol-promote.sh`.

**Exercising the write path found four defects, and not one was visible by reading:**

1. **The qgroup column was read one field left.** `btrfs qgroup show -re --raw -f` is
   `qgroupid, referenced, exclusive, max_referenced, max_exclusive`; the first version read
   `$3` and so reported "cleared the qgroup limit" on two subvolumes whose limits were
   already `none`. A log line that lies about what it did.
2. **The mode was applied to the mountpoint, which the mount then hides.** btrfs makes a new
   subvolume's root `0755`, so `/var/lib/docker` came up **world-traversable** — every
   container filesystem readable by any local user — and docker's own daemon did not correct
   it on start. The mode now goes on the *mounted* root.
3. **The refusal fired half way through a write.** A leftover file under `/var/lib/docker`
   aborted the run with `/var/lib/containerd` already mounted and fstab already edited. All
   refusals now run before the first mount.
4. **`grep -qxF 'exec niri-session'`** missed the live `~/.bash_profile`, whose copy is
   indented — so a second `exec` block would have been appended on every run.

**The autologin drop-in got smaller, and that is the deviations-only rule biting.** The
harvested file was the Arch wiki's `-/sbin/agetty -o "-p -f -- \u" --noclear --autologin
bunne %I $TERM`. Arch's own `getty@.service` ships
`ExecStart=-/usr/bin/agetty --noreset --noclear - ${TERM}`, so against it the wiki form
*drops* `--noreset`, hardcodes a path, and re-specifies by hand the `-f username` that
`--autologin` already passes to `login(1)` (agetty(8), read on the box). The step writes one
added flag. **The username is `$USER`, never `bunne`.** `~/.bash_profile` is **appended to,
not owned** — `shell` is still `deferred`, and writing that file wholesale would settle it
by accident.

**`70-dotfiles.sh` narrows the `dotfile-deployment` row on purpose, and says so.** The row
prefers whole-*directory* links; this links per file, because nothing tracked here rewrites
its own config (niri, kitty and portals are hand-edited text read at startup) and because
the directories are shared — other software has dropped `~/.config/kitty/dank-theme.conf`
and `~/.config/niri/dms/` beside ours, and a directory link either swallows those into the
repo or has to relocate them. **Revisit the day a config with a GUI settings dialog lands.**
It re-links a link replaced by a regular file (which the row asks for by name): identical
content is replaced quietly, differing content is kept as `.bunne.bak`, and a second
collision is a refusal. It warns when the repo is not at
`${XDG_DATA_HOME:-$HOME/.local/share}/arch-bunny` rather than relocating itself — **an
installer moving itself mid-run is its own decision and has not been made.**

**waybar is PICKED and shipped — `CHOICES.md` `status-bar`, `config/waybar/`, spawned by
niri.** The author decided the same day the measurement landed, and on the one thing the
analysis had not weighed: *"i check the time quite often."* A clock is the one thing on a
bar with no keyboard equivalent worth having, and 28.4 MB is what that is worth to him. The
bar carries the five things he named — day, time, date, ISO week, weather — and nothing
else; his Omarchy clock format is used verbatim, `~` separators included. `BUDGET.md` now
reads 371 MB of 600 in the resident bucket.

**A budget error the author caught, and it is the one this repo is most prone to.** waybar
was first written into the *per-session-login* bucket at 86 ms, taking that total from 81 to
167 ms — *"doubling the per-login wait time is rough."* **It does not cost that bucket
anything.** That bucket sums things that run one after another inside the login shell;
`/etc/profile.d` scripts block `exec niri-session`, whereas niri *forks* waybar and carries
on, so its 86 ms of GTK startup happens in another process while the compositor is already
rendering. Adding a concurrent cost to a serial total is the same mistake as summing two
buckets. Re-measured: `hyperfine -N "bash -lc true"` gives **75.7 ms ± 0.6 (n=39)** and
`waybar` appears in none of `~/.bash_profile`, `~/.bashrc`, `/etc/profile`,
`/etc/profile.d`. **The per-login wait did not change.** The row now reads 0 ms with the 86
ms stated as concurrent, because a missing row is indistinguishable from an unmeasured one.

**Weather is one script, one request, and no `jq`.** wttr.in's plain-text `?format=%t+%C`
endpoint gives `76°F Overcast` directly, which removed Omarchy's whole `jq` + Nerd Font +
40-code icon map — and the author's verdict was that showing the number is *better*, not a
compromise: *"i like that you print the exact temperature instead of just a weather icon."*
The interval is **900 s against Omarchy's 60** (1440 requests/day → 96) and there is one
request where Omarchy makes two. Location lives in `~/.config/bunne/weather-location`, never
in the repo; without it wttr.in geolocates by IP, which is the right default for a stranger.

**The bug of the session, and it took a screenshot to find.** niri spawns waybar ~9 s into
boot; NetworkManager writes `/etc/resolv.conf` at ~12 s. The first poll cannot resolve, and
since `interval` is also the retry interval **the bar read `weather n/a` for fifteen minutes
after every boot** — on a machine whose network was fine, with a script that worked
perfectly when run by hand over ssh. `grim`-ing the bar one second after a cold boot is what
exposed it.

**Then the obvious fix was wrong, which is the part worth carrying.** `curl --retry 5
--retry-all-errors` went in and did nothing: instrumented across a real boot, six attempts
over fifteen seconds, every one `Could not resolve host`, including attempts thirteen
seconds after the route came up. **glibc reads `/etc/resolv.conf` once per process** —
resolv.conf written `14:15:59.725`, first curl started `14:15:58.198`. **A retry inside one
process cannot fix state that process cached at startup.** The retry had to become six
separate `curl` invocations. Verified by cold boot and screenshot at 76 s:
`Wednesday 02:20 PM ~ 26 August 2026 ~ W35 ~ 76°F Overcast`, zero failed units.

*(Superseded, kept for the numbers:)* **waybar measured, briefly `deferred`.** On
`bunne-test` in the live niri session, a 5-module bar costs **28.4 MB PSS**, 0.017% idle
CPU, 86 ms to draw, and **14 new packages** (`gpsd` among them). The author's own Omarchy
bar, with three polling custom modules on top, measures **29.8 MB** — so **the GTK3 runtime
is ~95% of the cost and trimming modules is not a lever** (about 1.4 MB). The comparison to
put in front of him is `display-manager`: greetd was rejected six days ago at **6.8 MB**,
and this is **4.4×** that, forever, for a bar. It is inside the budget (343 → 371 MB of
600) and BUDGET.md rule 6 says that is not the test. **Waybar is installed but not running
on `bunne-test`**, config at `~/.config/waybar/` marked unratified; `waybar &` drives it,
`pacman -Rns waybar` removes it. Three things named as unmeasured, chief among them
*whether he misses a bar at all* — he has never driven this workflow without one.

**Focus-follows-mouse is on — deviation 11 in `config/niri/config.kdl`.** The author asked
where Omarchy's version lives; in niri it is `input { focus-follows-mouse }`, and it was
sitting commented out in our own config at line 135 all along. Enabled *with*
`max-scroll-amount="0%"`, deliberately: without the attribute, hovering a partly-offscreen
column makes niri scroll the view to bring it in, so passive mouse motion moves the viewport
under you. Hyprland's `follow_mouse = 1` has no scrolling viewport to move, so 0% is what
actually reproduces the liked behaviour. **The trade, and it is his to reverse:** a column
only partly on screen can no longer be focused by hovering it. `niri validate` passes and
the live compositor reloaded it with no error; **the hover behaviour itself is unexercised**
— that needs a hand on the mouse.

**`35-oom-protection.sh` landed, and with it §2 of the config inventory is CLOSED.** The
two `10-oomd.conf` drop-ins (`ManagedOOMSwap=kill` on `-.slice`; that plus
`ManagedOOMMemoryPressure=kill` on `user@.service`) plus `systemd-oomd.service` enabled. No
package — oomd ships inside systemd, which is why 2b could accept it. Ordered after
`30-zram` as a dependency, not a preference: oomd's swap-kill path is inert without swap and
zram *is* the swap here. Re-running the unowned-`/etc` sweep afterwards returns the same ten
paths, and every one is now written by a step or deliberately excluded.

**Two things the write path taught, both now in the step:**

1. **`daemon-reload` alone propagates drop-in changes to a running oomd** — tested by
   deleting the drop-ins with oomd live (`oomctl` emptied), then re-running the step without
   a restart (`oomctl` refilled). So the `try-restart` the first version had was bouncing a
   working daemon on every install run for nothing, and it is gone.
2. **The verification was too loose to fail.** It grepped the whole `oomctl` output for each
   cgroup path — but the user session appears under *Swap* Monitored, so the check passed
   whether or not memory-pressure monitoring existed at all, and pressure is the half that
   catches a slow leak. Now section-aware. **Proven able to fail** by dropping a
   `99-override.conf` with `ManagedOOMMemoryPressure=auto` next to ours: our file is still
   correct, the protection is not in effect, and the step exits 1 saying so.

**A false alarm worth recording, because the instrument was the bug.** A post-boot check
appeared to show `Memory Pressure Monitored CGroups` empty. It was not — the reading used
`sed -n '/Swap Monitored/,/^Memory Pressure/p'`, and a `sed` range *ends on* the line it
matches, so that command prints the pressure header and stops. Reading it that way always
shows an empty list. A boot-time probe (60 samples over 3 minutes, `benchmarks`-style)
settled it: both sections populate by **14 s of uptime** and stay populated. The step now
uses `awk` ranges and says the 14 s figure in its own failure message, so nobody re-diagnoses
this as a startup race.

**`10-wheel` got a check DELETED rather than added.** The inventory said the installer should
verify it. It should not: `install.sh` already proves `sudo -n true` before any step runs,
which tests the capability `10-wheel` grants rather than the file granting it — strictly
stronger, and it was already there.

**`load-protection` has nothing to install.** The row is picked, but `BUDGET.md` has it right
— it is an *invocation shape* (`systemd-run --user -p CPUWeight=… -p AllowedCPUs=…`), zero
packages and zero files. It becomes real when the shell config lands and can carry a wrapper;
until then there is no step to write.

**`/etc/mkinitcpio.conf` turned out to want a CHECK, not a step — two lines in
`00-preflight.sh` instead of a new file.** `archinstall` produces it and gets it right on a
LUKS install, so there is nothing to write. What was missing is that **nothing on the machine
would notice it being wrong**: the running system booted from an initramfs that already
works, so a broken `HOOKS=` changes nothing today. It governs the *next* build — unattended,
from a pacman hook, at the next kernel update — and the failure lands at a boot nobody is
watching, on a `/boot` that is FAT and outside every snapshot, so there is no rollback.

Two read-only checks:

1. **`encrypt` present and ordered** `block` → `encrypt` → `filesystems`, and only when `/`
   is on a `crypt` device (`encrypt` on an unencrypted root is a hook with nothing to unlock,
   not a missing feature). All three present in the wrong order still builds an initramfs
   that cannot open the root.
2. **Every `FILES=` entry exists.** A dangling entry does not warn, it *fails the build* —
   `add_file()` errors `file not found`, the `RETURN` trap counts it into `_builderrors`, and
   `mkinitcpio` exits non-zero (read in `/usr/lib/initcpio/functions`). The way to get there
   is a **half-done `benchmark-unlock` teardown**: keyfile deleted, `FILES=` line left. It
   then breaks the next kernel update rather than the boot after it.

**Repair is left to a human on purpose** — fixing `HOOKS=` means rebuilding the initramfs,
and doing that unattended on the boot path of a machine the installer just met is not this
repo's call. All four failure paths exercised on `bunne-test` by editing the config only,
file restored byte for byte, `mkinitcpio` never run.

**The whole write path now runs end to end — `benchmarks/4.30`.** Every step had been broken
and re-run *individually*; what had never been tested is all of them at once, which is the
only shape that surfaces an ordering problem. `benchmarks/instruments/p4-installer-writepath.sh`
breaks every state the installer creates — both Docker mounts and their fstab lines, zram's
size and sysctls, both oomd drop-ins plus the unit, all five snapper values plus the timeline
timer *enabled*, the autologin drop-in and the `.bash_profile` block, and three different
dotfile shapes. **One `install.sh` run put it all back, exit 0, and a cold boot came up with
zero failed units**, `710`/`700` on the Docker subvolumes, oomd pressure-monitoring live,
timeline disabled, 6/6 symlinks, waybar and niri up, the image still in `@containerd`.

It found nothing in the installer and **one bug in the instrument, which is the more useful
find**: the first version chmod'd `/var/lib/docker` *after* unmounting it, so it changed the
mountpoint rather than the mounted subvolume root, the next mount hid that, and the step's
mode check was never exercised. That is the same mechanism as the real defect the check
exists for, reappearing in the test instead of the code. **A test that cannot fail is
indistinguishable from a test that passes** — the only thing separating them was checking
that the break actually took.

**Both halves of the drift sweep are now clean.** `check-unowned-etc.sh` returns ten paths,
every one written by a step or deliberately excluded; `pacman -Qkk` returns sixteen
package-owned files, every one already named in inventory §3 or §4. **No file exists that no
row explains.** Worth re-running after any step lands, since a step quietly modifying a
package-owned file it should not touch would show up there and nowhere else.

**The `disk-alert` soak is still healthy** and has been through both of today's upheavals —
the qgroup-limit removal that forced its meters to be rebuilt, and the write-path break and
repair. `Result=success`, `ExecMainStatus=0`, no restarts, firing on its 4-hour timer.

**Repo's own validators all pass**: `check-packages` (75 resolve), `check-limine`,
`check-keybinds`; `shellcheck` and `shfmt` clean across `install.sh`, `install.d/`,
`scripts/`, `config/waybar/weather` and the new instrument.

**Still to write:** the disk-alert units, once that draft is ratified — the only item left,
and blocked on the author rather than on work.

---

### ⚡ 2026-08-26 morning (history)

**Open question 26 is ANSWERED and applied: option 4 — the Docker qgroup caps are
dropped, the qgroups stay for accounting.** Author's call this morning. `btrfs qgroup
limit none` on `@containerd` (was 100 GiB) and `@dockervol` (was 50 GiB); subvolumes,
top-level placement and fstab mounts all untouched, so `snapshot-bloat` is unaffected —
Docker stays out of every snapshot of `@` because of the subvolume boundary, never the
limit.

The reasoning worth carrying: gripe #1's real shape is **slow** growth, and against slow
growth a 6×/day alert is a good instrument. What the limit added on top was not protection
against the gripe, it was a **new priority-1 failure mode the gripe never had** — an
unbounded disk gives ENOSPC to the process filling it, a qgroup limit can give the whole
filesystem forced-readonly until a reboot.

**The load-bearing claim was tested, not assumed.** Option 4 rests on *"the limit is the
trigger, not the accounting"* — if accounting alone could deny the Merkle write, dropping
the limits would fix nothing. `4.27-verity-quota-repro.sh` grew an `--accounting` arm:
quota on, no limit → verity **ENABLED**, fs **rw**, 3/3, against the tight-limit control's
forced-readonly 1/1 on the same box in the same session. Accounting is also exact
(209731584 bytes read back for a 200 MiB file), which is what makes the alert possible.
Then live through Docker: `docker pull python:3.12-slim` exits 0, `@containerd` 292 KiB →
103.05 MiB, `/` still `rw`, zero failed units. **That image was left in place on purpose** —
every prior test of this layout ran against an empty `@containerd`, the one state where the
migration's nested-per-layer-subvolume hazard cannot surface.

**One trap, and it is now an installer rule: a qgroup read needs a `sync` first.** The first
accounting read reported **16 KiB** for a subvolume holding 200 MiB — qgroup figures count
*committed* extents. Wrong by four orders of magnitude, silently. The 6×/day alert does not
care (btrfs commits every 30 s); anything verifying bytes it just wrote does.

**`disk-alert`'s meter 2 had to be rebuilt, or answering 26 would have silently switched
off Docker monitoring.** It selected qgroups by *"has a numeric `max_referenced`"*; with no
limits that filter matches nothing, so it would have reported a healthy machine while
watching nothing — with no cap behind it any more. The helper is now dumb (every qgroup,
path + referenced bytes) and the alert carries `WATCH=([containerd]=100 GiB
[dockervol]=50 GiB)`: **the author's figures as thresholds instead of walls**, so 80% fires
where it always would have. A watched subvolume *absent* from the helper's output is itself
a breach. Four states tested on the box — healthy (silent, `success` through the real user
unit), `DISK_THRESHOLD=0`, watch narrowed to 120 MiB (`containerd at 85% of its watch —
104MB of 120MB`, the safe replacement for the old "87% of its cap" proof), and both watched
rows filtered out (`UNMONITORED` for each). **Running it found two bugs reading it had
not**: the helper's `sub(/^@/,"",path)` turned the root subvolume `@` into the empty string
— a hard `bad array subscript` error on every healthy run, invisible before only because
the old cap filter excluded `@` — and the parse now rejects an empty path before the lookup.

**Question 27 is ANSWERED too: non-XDG settings are installer lines, not tracked files.**
Author: *"i like your suggestion."* All six §2 files in `phase4-config-inventory.md` become
`install.sh` lines — 28 bytes, or one line, or five `snapper set-config` calls, or (the
`getty` drop-in) they contain the username and must be generated anyway; and
`.bashrc`/`.bash_profile` are separately `deferred` pending the shell review so they are not
harvestable today at all. **`config/` keeps its `$XDG_CONFIG_HOME`-only layout**, and the
layout question re-opens the day a file genuinely wants tracking — the named trigger is the
shell config. Same shape as `install-artifact`: dissolved by the work, not settled. **The
harvest is unblocked.**

**Question 28 was raised and then measured the same morning — `benchmarks/4.29`.** Only
ratification is left. Keeping the qgroups costs **0.355 s per `subvolume delete` against
0.008 s** (46×, n=9/arm, no overlap), +0.022 s per snapshot create, +0.035 s per `rm -rf` of
6457 files, and **nothing measurable on writing** them. New `BUDGET.md` bucket, *per snapshot
deletion*, since none of the existing ones fits: nothing waits at the keyboard, but btrfs
commits are filesystem-wide so a cleanup retiring several snapshots stalls every writer to
`/` for ~1.8 s. **Then the premise collapsed** — `man 5 snapper-configs` says `QGROUP` is the
qgroup used for *space aware cleanup algorithms*, and our config sets `SPACE_LIMIT="0.08"`
and `FREE_LIMIT="0.2"`. The quotas are not paid for a notification; they are what snapper's
space-based retention runs on. **Recommended: keep, cost stated instead of silent.**

Two side-findings, both applied. **Meter 3 had the same silent-blindness bug meter 2 had** —
with quotas off, `excl` is empty and it just `continue`d, so snapper's retention would have
stopped working *and* the alert would have said the machine was healthy. Now a loud breach,
tested. And **the first deletion measurement was measuring its own instrument**: `btrfs
subvolume delete` + `btrfs subvolume sync` reported 28-30 s in *both* arms; the delete returns
in 0.02 s and `subvolume sync` blocks a flat ~29 s regardless. `delete -C` is the honest
instrument. *A figure identical across both arms of a controlled test is evidence the
instrument is broken, not that the effect is absent.*

**Then the harvest turned up that the inventory was wrong.** Before writing installer
pieces for the six §2 files, a sweep for *everything in `/etc` that no package owns* —
now `scripts/check-unowned-etc.sh` — found **three more live configuration files of
`picked` rows**: `/etc/sysctl.d/99-zram.conf` (`swap-zram`, whose row names both sysctls
in its own text) and the two `oom-protection` drop-ins. The old method could not have found
them: `pacman -Qkk` reports package-owned files that *differ from what shipped*, so a file
no package owns is invisible to it, and the hand check only looks at paths a row's prose
spells out.

Three things fell out of that, all recorded in `phase4-config-inventory.md`:

1. **The two oomd drop-ins are named `10-oomd-test.conf` and are not a test** — they are
   the exact config `oom-protection` was ratified with. Shipping that name invites someone
   to delete the row's whole mechanism as debris. Rename to `10-oomd.conf`.
2. **A second must-not-ship item, next to the crypto keyfile:**
   `/etc/sudoers.d/20-bunne-testbox-nopasswd` — `bunne ALL=(ALL:ALL) NOPASSWD: ALL`, the
   thing most of today's ssh-driven work actually ran on. **It is invisible to a non-root
   survey** (`/etc/sudoers.d` is `0750`), which is why it went unnoticed until the sweep ran
   under `sudo`. Teardown canary: after removal, `sudo -n true` must *fail*.
3. **Run that check as root.** As `bunne`, 12 directories under `/etc` are unreadable and
   three real paths were missed. The script now names the unreadable paths loudly instead of
   dropping them, because silently dropping files is the failure it exists to catch.

**Live on the author's desk: only 28, and only to ratify.**

#### `install.sh` exists (author's ask, 2026-08-26)

**A sequencer plus two steps, and that is the point** — the installer is being written from
the ledger in reviewable pieces. `install.d/` holds the steps, numbered so `ls` is the plan
and there is no manifest to drift out of step with the directory. Steps are **executed, not
sourced**, so one cannot clobber the sequencer's variables or change its `set -e`. They are
idempotent, which is the whole resume story: a failure names the step, you fix the cause and
re-run everything. No `--from`/`--only` until re-running proves too slow.

Reviewed `viacoffee/dotfiles`'s `install.sh` for safeguards as asked. **Taken:** the EXIT
trap that reports where a run stopped (its best idea), the phase-must-exist guard, root
resolved from `BASH_SOURCE`, a log file, and the ASCII banner. **Deliberately not taken:**
`source`ing phases; and its `COFFEE_INSTALL_LOG_FILE="~/.local/state/…"`, where the quoted
`~` never expands — that `mkdir -p` creates a directory literally named `~`. **Added, because
it has none of these:** `--help`, `--dry-run`, idempotency, preconditions checked up front,
and a refusal to run as root.

**Every guard was tripped on purpose on `bunne-test`, not assumed** — and doing that found
three bugs in my own code:

1. **`sudo -v` prompts even under `NOPASSWD`**, so the first version refused to install on a
   machine where sudo works perfectly. Now `sudo -n true` first, a prompt only if that fails
   and there is a tty, and an accurate message if there is no tty.
2. **`$dry_run && say …` exits under `set -e`** when `dry_run` is false — an AND-list that
   evaluates false is a failed command. It was on the *normal* path. The same shape in the
   EXIT trap would have skipped the failure message entirely, which is the one thing the
   trap exists to print.
3. **The preflight's must-not-ship check silently missed its own target.** `[[ -e ]]` on a
   file inside `/etc/sudoers.d` (mode 0750) is false, not an error, for a non-root reader —
   so it reported clean for `20-bunne-testbox-nopasswd` sitting right there. It now reports
   the blind spot instead.

Also fixed: the log directory was created before the root check, so refusing still left a
root-owned `/root/.local/state/bunne`. The two "wrong machine / wrong user" checks now run
before anything is written at all.

Proven on `bunne-test`: dry run, a full idempotent real run (`=` for every file, `✓ zram
active: /dev/zram0 7.7G`, both sysctls verified), root refusal leaving no trace, unknown
option, a step that exits 3 (`FAILED in 99-fail.sh (exit 3)`), and a non-executable step.

#### Five steps now, all reboot-verified

`00-preflight`, `10-omarchy-repo`, `20-packages`, `30-zram`, `40-snapshots`, `50-limine`.
`bunne-test` was rebooted through Limine after the boot config was edited: back up, **0
failed units**, root on `/@`, zram 7.7 G, niri up, `vm.swappiness=180`/`page-cluster=0`
persisted across the boot (so `/etc/sysctl.d/99-zram.conf` works, not just a live
`sysctl --system`), timeline timer still disabled, `check-limine.sh` ok, and a full
`install.sh` re-run afterwards is clean at exit 0.

**The method that is actually producing results: exercise the write path.** On an
already-provisioned box every check reports `=` and the code that changes things never
runs — unproven by this repo's own rule. Deliberately breaking the state and re-running
found, in order: `sudo -v` prompting under `NOPASSWD` (refused to install on a machine
where sudo works); `$dry_run && say` exiting under `set -e` on the *normal* path; the
preflight leak check silently missing its own target through an unreadable directory;
`pacman -S --needed` against a `-Sy`'d db performing a **partial upgrade** that redeployed
the bootloader as a side effect of installing one package; a dry run that *wrote* to
`/var/lib/pacman/sync`; a `wc -l` counting pacman's progress lines as packages; and
nondeterministic `limine.conf` directive ordering. **Every step so far has found a defect
this way, and not one was visible by reading.**

**Two live drifts found by comparing decided state to actual**, which is the other thing
writing a step does: `snapper-timeline.timer` was **enabled** against a row that says it
never should be (24 wakeups/day to do nothing — now disabled), and `ParallelDownloads = 5`
was recorded in the inventory as our deviation when it is the pristine value in the pacman
package itself. General rule now written down: `pacman -Qkk` says a file differs, never
which lines differ — diff against the package's own copy.

**Also this session, at the author's ask:** `README.md` has a generated Stack table
(`scripts/gen-stack-table.sh --write`, 70 slots — 58 picked, 11 TBD, 1 resolved to
nothing), rebuilt from `CHOICES.md` rather than maintained by hand.

**Next steps to write**, each one feature and one row: the `getty@tty1` autologin drop-in
(username templated, never `bunne` hardcoded) plus `~/.bash_profile`'s `exec niri-session`,
the Docker subvolumes and their fstab lines, the `config/` symlinks, `/etc/mkinitcpio.conf`
(with §5's must-not-ship guard), and the disk-alert units once that draft is ratified.

**`default_entry` is now the path form — author's call, and reboot-proven.**
`default_entry: Arch Linux/linux`, set by `50-limine.sh` rather than merely warned about.
Verified in the order the boot path deserves: limine's own `CONFIG.md` read on the box for
the escaping rules, then `check-limine.sh --self-test` to establish the validator is sound
*before* trusting it, then the validator on the live file, then a reboot (back up on
`subvol=/@`, which proves it picked the live kernel and not a snapshot), then the write
path by reverting to `2` and letting the step fix it. **Scoped honestly:** the menu
regenerations seen afterwards added snapshots inside the *collapsed* `Snapshots` directory,
which does not shift the visible index — so nothing here shows the numeric form breaking.
What is shown is that the path form boots, resolves to the live kernel, and survives two
menu rewrites.

---

### 2026-08-26 overnight (history)

#### 🔓 `bunne-test` REBOOTS UNATTENDED — you do not need the author for this

**There is no LUKS passphrase prompt on `bunne-test`.** `CHOICES.md` `benchmark-unlock`
put a random keyfile in a second LUKS keyslot, baked into the initramfs, precisely so the
box can be rebooted without a human. Verified 2026-08-25: `crypto_keyfile.bin` is in
`/boot/<machine-id>/linux/initramfs`, `cryptsetup luksOpen --test-passphrase --key-file`
succeeds against `/dev/nvme0n1p7`, `luksDump` shows **two** keyslots, and a full boot is
`5.3 s` of kernel phase — no typing anywhere in it.

**So: `ssh bunne-test sudo reboot` is a thing you can just do.** Set
`sudo efibootmgr --bootnext 0001` first or it lands NixOS. What still needs a human is
only the **Limine menu keypress** — selecting a snapshot — because that is a keyboard act
before any OS is running.

**This was got wrong for an entire session (2026-08-25 evening/overnight), and it cost
real work.** Believing the box needed the author to unlock meant a reboot was treated as
an expensive, human-gated event: boot-path edits were left "not reboot-verified" when a
reboot was free, the author was handed the keyboard repeatedly for things that could have
been driven over ssh, and `4.27`'s reasoning for not reproducing on the real box named a
constraint that did not exist. **Do not re-derive this from the presence of `cryptdevice=`
on the kernel cmdline — the cmdline looks exactly like a passphrase setup, because the
keyfile is what makes the difference and it lives in the initramfs.**

Note the flip side, since it is the same fact: `benchmark-unlock` is **`bunne-test` only
and must be removed before shipping**, and `docs/04-plan.md` carries the teardown checklist
— one keyslot, empty `FILES=`, no `/crypto_keyfile.bin`, and *the next boot must actually
ask for the passphrase*, which is the canary.

**The box is healthy and everything is committed and pushed.** `bunne-test` is on `/@`
(the restored root), niri up, no failed units, both Docker caps back at 100/50 GiB,
Docker back to socket-activation with nothing resident, and two bunnies on the two
monitors. One thing needs your keyboard and one needs your judgement — both below.

#### The gate is closed: the snapshot rollback acceptance test PASSED

`benchmarks/4.25.rollback-acceptance.md`. Proven by subvolume identity, not just the
canary: `@` moved from ID **256 → 353** with `Parent UUID` equal to snapshot 97's UUID, so
`RESTORE_METHOD=replace` genuinely swaps the root — which is exactly what `snapper
rollback` failed to do here. `alpine:3.21` and both capped subvolumes survived. **DA round 19 scoped that back**: the
Docker subvolumes are top-level and fstab-mounted, so a snapshot of `@` structurally
cannot contain them — the test confirms the wiring rather than discovering isolation. And
the restored snapshot was minutes old, so the realistic case is untested: **a pre-18:00
snapshot has an `/etc/fstab` with no Docker lines, and restoring it would put Docker back
inside `@`, uncapped** — gripe #1 reintroduced by the recovery mechanism. Cheap to test
and worth doing.

**Two legs stay unproven, and want you:** the way back (snapshot 98 `pre-rollback` is in
the menu, never booted) and the **GUI restore gesture**, which failed silently and has
never been seen to work. Four priority-1 defects in the recovery path are recorded there —
the silent GUI failure, a restore lock that is a bare `[[ -e file ]]` test with no
staleness detection, that same lock failing `snapper-cleanup.service`, and the fact that
restore **cannot be scripted** (two interactive prompts, no `--yes`, unknown flags
silently ignored).

#### Your four answers are applied

`timeout: 3`, `hash_mismatch_panic: no`, and the screenshot bind guarded with
`sel=$(slurp) || exit 0` (both branches tested under `sh -c`).

**#12 is now ANSWERED — greetd is out.** The author drove it and the verdict was
*"greetd did nothing that seemed worthy of keeping. I just saw a tty… let's get rid of
it."* `greetd` is `disable`d, `getty@tty1` re-enabled, `/etc/greetd/config.toml` restored
from the getty-era backup, **and the login path was reboot-verified**: greetd `inactive`,
`getty@tty1` `active`, niri running, no failed units. The autologin path was intact the
whole time (`/etc/systemd/system/getty@tty1.service.d/autologin.conf` plus `exec
niri-session` in `.bash_profile`). `greetd` and `greetd-agreety` are now **removed** (`pacman -Rns`, 650 KiB, nothing
depended on them), `/etc/greetd` is gone, and a second reboot verified the box with the
package absent: niri up, `getty@tty1` active, zero failed units. The 6.8 MB PSS is now
zero. **Boot is a wash on `benchmarks/4.19`'s n=2-per-arm measurement, not on tonight's** —
DA round 19 rejected quoting tonight's single 17.658 s vs 17.344 s samples, since 4.19's
own within-config spread exceeds that 0.314 s gap.
`display-manager` is **`picked`**. That reboot was driven entirely over ssh, which is the
correction above in practice.

**C4 is CLOSED.** The author ran the bind by hand: Escape cancelled silently (the new
guard), then a real drag over terminal text opened satty, an arrow was drawn, and the
export landed at `~/screenshot` — **851x118 PNG with legible text**, which is exactly what
the old flat-colour proof image could not demonstrate. Both gaps on the `screenshot` row —
`slurp`'s interactive drag, and a capture whose success is distinguishable from failure —
are now closed. Proof kept at `benchmarks/raw/4.25.c4-satty-proof.png`.

**Both limine directives parse and the box boots through them** — three Arch boots,
header read back from the live file, `check-limine.sh` passes, old file kept at
`/boot/limine.conf.pre-2026-08-25-decisions.bak`. **DA round 19 cut the stronger
"reboot-verified" wording**: neither directive was shown to *do* anything. `timeout: 3`
was never timed, and **`hash_mismatch_panic: no` is wholly unexercised** — it acts only on
a hash mismatch and there has never been one here, which by this repo's own rule makes it
an unproven safety mechanism. Testable: corrupt one byte of a `boot():` file on the ESP
and watch for warn-instead-of-panic.

#### Wallpapers: prepped, renamed, and per-monitor proven on real hardware

`scripts/prep-wallpapers.sh` carries each bunny's centre as a fraction, read off all 22
images by eye, and crops the largest rectangle of the target aspect around it. **Three
target resolutions are only two crops** — 1920x1080 and 3840x2160 are both 16:9, 2880x1920
is 3:2. 52 derivatives written, **14 skipped rather than upscaled**. Six images needed the
crop nudged up after looking at the first pass; `17-carrot-heist` still loses ear tips and
cannot be fixed — they are cut in the source. Renamed with author kept, numbered, and a
name that says what the picture is.

Measured while proving it: swaybg is **2.2 MB PSS solid / 9.1 MB one image / 18.0 MB a
different image per monitor**, and **BUDGET.md's mystery 8.2 MB was RSS of the solid case**
(8.1 MB measured). 4K is unmeasured and the buffers are 4x the pixels — do not
extrapolate. The niri config is deliberately untouched: hardcoding `eDP-1`/`HDMI-A-1` into
a repo strangers clone is the machine-specific detail to keep isolated, and how you select
a wallpaper is still open in the `wallpaper` row's TODO.

#### ⚠️ The one thing that needs your judgement: open question 26

**Exercising the 100 GiB `@containerd` cap — the one gripe #1 is actually about — found
that it can take the entire machine read-only.** `benchmarks/4.27.containerd-cap.md`.

Every earlier proof on `docker-storage-quota` tested `@dockervol`, which holds no images:
this Docker uses the containerd image store. The first overflow is exemplary — `disk quota
exceeded`, exit 1, daemons healthy, cap exact to the byte. A later one made btrfs fail an
fs-verity rollback for want of quota'd metadata space, which is unrecoverable, so it
**forced the whole filesystem read-only** — `/` and `/home` too, because **a qgroup limit
is scoped to a subvolume while forced-readonly is scoped to the filesystem**, and they are
one btrfs on `cryptroot`. Only a reboot cleared it.

**Reproduced 4/4** on a loopback image with the identical kernel signature
(`benchmarks/instruments/4.27-verity-quota-repro.sh`), so 4.26's reproduce-before-recording
rule is satisfied. (The loopback was the right call regardless, but note the stated reason
— "reproducing it risks an outage on a box only the author can unlock" — **was wrong**;
see the correction below.) **The ENOSPC arm is not a control and DA round 19 threw out the argument built on it** —
verity *succeeded* there, so the write was never refused and it says nothing about how
btrfs handles ENOSPC. All that survives is that a qgroup limit makes the denial trivially
reachable while ENOSPC did not. **It does not settle "just accept it."** Also
unestablished: whether ordinary Docker use against the shipped 100 GiB cap ever gets
there — the real event was at a 200 MiB synthetic cap. Four options are laid out;
**nothing was changed.**

#### Later in the night: a DA round, and four things it changed

**DA round 19 (`benchmarks/da-logs/4.25-4.27.md`) put tonight's eight conclusions through
the standing gate. Three survive as stated; four were weakened and one rejected.** The
pattern was uniform and worth naming: *a real result written up one notch stronger than
its evidence*, and three of the four landed in the documents you read to decide rather
than in the raw write-up. Concessions are applied in place.

- **Rejected** — the "control" in 4.27. The ENOSPC arm never actually refused a write, so
  the argument that the cap *introduces* the failure mode is withdrawn. See question 26.
- **Rejected as stated** — the greetd boot comparison, quoted from n=1 vs n=1. "Boot is a
  wash" stands on `benchmarks/4.19`'s n=2-per-arm data instead.
- **Weakened** — "reboot-verified" for the limine directives, the swaybg 8.2 MB
  "resolution", and the Docker rollback-isolation claim.

**Then three of those were chased down rather than left as caveats:**

1. **`timeout: 3` is now timed** (`benchmarks/4.28`): 16 s median at `timeout: 1` vs 18 s
   at `timeout: 3`, n=3 per arm, Δ exactly 2 s. Real, and 2 s on every boot. **Bonus trap
   recorded in `BUDGET.md`: `systemd-analyze` cannot see the menu wait at all** — its
   `loader` figure moved 4 ms across that 2 s change.
2. **The fstab hazard is real but bounded.** Two of 24 snapshots (1 and 75) have no Docker
   fstab lines, so restoring them reintroduces gripes #1 and #2 — but neither is in the
   Limine menu, and a fresh install never has the problem.
3. **The disk-alert draft's meter 2 is proven** against a real (narrowed) cap breach —
   *"containerd at 87% of its cap"*. **But it also killed option 3 of question 26**: it is
   a 6×/day poll, and tonight `@containerd` went from 9.79 MiB to its cap inside one
   `docker pull`. A four-hour poll would have announced the breach ~2 h after the
   filesystem went read-only. Good for slow growth; useless as a hard-cap safety net.

**`hash_mismatch_panic: no` is still wholly unexercised** and is the one thing here that
genuinely needs you present: proving it means corrupting a `boot():` file on the ESP, and
a wrong outcome hangs the machine pre-kernel with no remote power control.

#### What I would do next

1. **Answer open question 26.** It is the only thing blocking `docker-storage-quota`, and
   it touches gripes #1 and #2 directly.
2. **The `hash_mismatch_panic` test** — corrupt one byte of a `boot():` file on the ESP,
   reboot, and confirm it warns instead of panicking. Needs you in the room.
3. **The two unproven rollback legs** — boot snapshot 98 to prove the way back, and make
   the GUI restore gesture work once.
4. **Decide where non-XDG config lives in the repo** (`phase4-config-inventory.md` §8),
   then harvest. The survey found the next six files are all small and all decided — and
   that **none of them can go into `config/` as it stands**, because that directory
   mirrors `$XDG_CONFIG_HOME` and these are `/etc` and `$HOME`. Two of them
   (`.bashrc`/`.bash_profile`) are also explicitly deferred in `config/README.md`. Three
   options are laid out, including *don't track them at all* — several are 28-byte,
   one-line settings where a line in `install.sh` beats a file plus a symlink. **Blocked on
   a structural choice, not on effort.**
5. **One deliberate logout** if you still want the greetd comparison.
6. **Phase 4 proper.** The installer, in small reviewable pieces.

#### Two process notes worth carrying

- **I caused a read-only outage.** A destructive quota test was pointed at a subvolume
  sharing a filesystem with `/` and `/home`, on a box only you can unlock. The blast radius
  was foreseeable from qgroups and forced-readonly having different scopes, and a loopback
  image — which is what finally reproduced it safely — was available the whole time.
  **Establish the blast radius before running the destructive test, not after.**
- **A tool's own error path can be the thing that is broken.** The GUI restore
  authenticated, ran as root, and vanished, because the error scrolled past inside a
  terminal that closed with it. Recovery paths need the same "fail loudly" scrutiny as
  features — arguably more.

#### Booting the other OS, unchanged

Plain reboot lands NixOS (`Boot0007` systemd-boot is first in `BootOrder`).
**`Boot0001` is Limine** → `\EFI\limine\limine_x64.efi`; `Boot0000` is the fallback
`\EFI\BOOT\BOOTX64.EFI` on the same ESP. `--bootnext` is **one-shot and consumed by the
reboot**, so a two-reboot task needs it set twice. From NixOS: `nix-shell -p efibootmgr
--run "sudo efibootmgr --bootnext 0001"`. efivars stay writable even when the btrfs root
is forced read-only, which is how the box was steered back to Arch during the outage.

### ⚡ Session of 2026-08-25 evening (HISTORICAL — superseded by the block above)


**Everything is committed and pushed in both repos. The box is healthy.** The one thing
that went wrong this session is fixed and reboot-verified; nothing is left in a broken or
half-applied state, and there is no cleanup waiting for you.

#### `bunne-test`, as you will find it

Booted **Arch**, greetd's `initial_session` straight into niri, zero failed units.
`nvidia-open` (prebuilt) 610.57.04. `@containerd` and `@dockervol` are top-level
subvolumes mounted from `/etc/fstab`, capped 100/50 GiB, accounting consistent. Snapper's
`1/0` qgroup intact. `/boot` at 14 %. `limine.conf` carries `default_entry: 2` +
`/+Arch Linux`. My scratch files and test packages are gone.

**Booting the other OS is unchanged:** plain reboot lands NixOS; `sudo efibootmgr
--bootnext 0001` (or `0000`) first lands Arch. From the NixOS side `efibootmgr` is not in
the system profile — use `nix-shell -p efibootmgr --run "sudo efibootmgr --bootnext 0001"`.
`bootctl` cannot do it, because limine is not a BLS entry.

#### What landed (all of it in [`../benchmarks/4.24.hands-on-queue.md`](../benchmarks/4.24.hands-on-queue.md))

Five of the seven hands-on queue items, applied and survived a reboot: **MUB sweep**
(−54 packages), **`nvidia-open`** swap, **Docker subvolumes promoted** to the btrfs top
level, **fonts vendored** (byte-identical to the Google Fonts release), **satty bound**.
greetd was left alone as your test drive. Snapshot boot entries are installed and
configured; **their acceptance test is the one real gate left.**

#### Read the outcomes as scoped, not as ticks

A DA round (**#18**, `da-logs/4.24.hands-on-queue.md`) rejected or narrowed **six of
seven** conclusions and the corrections are applied in place. In particular:

- The nvidia **power and boot-time numbers are withdrawn** — both control-void.
- The docker **cap is re-proven for `@dockervol` only**, at a synthetic cap, via `dd`
  rather than through docker. **The rollback isolation the move exists for is
  unexercised**, so gripes #1/#2 are *not* closed by the promotion — they are closed by
  the acceptance test passing.
- The **satty pipe claim is downgraded**: the proof image was a flat colour field, so
  pass and fail looked identical.
- The MUB sweep's "no collateral damage" is retracted: `pacman -Rs` ignores optdepends.

#### The incident, and what it produced

The `limine.conf` restructure left the box at the boot menu for 56 minutes until you got
it past. `journalctl --list-boots` then proved the diagnosis outright — **a 56-minute hole
with no kernel start** (17:31:49 → 18:27:30), so the machine was pre-kernel throughout,
which rules out both a LUKS prompt and a hash-mismatch panic. Repaired, and the
before/after is one variable:

| config | shutdown → next kernel start | ended by |
|---|---|---|
| broken | 17:31:49 → 18:27:30 — **56 min** | you, at the keyboard |
| repaired | 18:29:38 → 18:29:54 — **16 s** | nothing; unattended |

Out of it: **`scripts/check-limine.sh`** (limine ships no validator; the mechanism is read
from `common/menu.c`, not from `CONFIG.md`, which does not describe it), and a rule the
installer now owns — *set `default_entry` explicitly, in the path form.*

**Three claims got proven live that had only been asserted:** the menu-wait mechanism;
`limine-snapper-sync`'s no-resident-watcher sync path actually firing (menu went 1 → 18
entries unattended); and the ESP dedup arithmetic (18 snapshot entries = 4 files / 41 MB).

#### Next, in the order I would do it

1. **The snapshot rollback acceptance test.** The last real gate.
   `benchmarks/instruments/4.25-rollback-acceptance.sh arm`, restore that snapshot from
   the Limine menu, reboot, then `… verify`. Closes `snapshot-boot-entries` **and** the
   docker-promotion question above in one sitting.
2. **The four decisions in [`open-questions.md`](open-questions.md)** — limine
   `timeout: 1` (a one-second window to reach the recovery menu), `hash_mismatch_panic`,
   the screenshot bind's silent `slurp`-cancel path, and greetd vs getty.
3. **One satty annotate-and-export** by hand, which is all that C4 still needs.
4. **Phase 4 proper.** 65 rows `picked`; `CLAUDE.md`'s current-state block is refreshed
   and says how to build it — small reviewable pieces, each traceable to a row.
   `docs/05-choices.md` now records what the package-generating `awk` does *not* solve:
   the list is not installable in one command (AUR + the `[omarchy]` repo need ordering).

#### Two process notes worth carrying, not just filing

- **A boot-path edit whose only verification is a reboot has no verification** — the
  reboot is the experiment, not the check. Both things that would have caught this were
  on the desktop the whole time: your own working `limine.conf`, and limine's source.
- **Before writing down an alarming result, try to reproduce it on purpose.** Late in the
  session I nearly recorded "the qgroup caps stop enforcing" — the mechanism behind gripes
  #1/#2 — on one uncontrolled sample. It did not replicate (`benchmarks/4.26`). Ten
  minutes of trying to make it happen again was the whole cost.

### ⚡ Session of 2026-08-25 overnight (HISTORICAL — superseded by the block above)

**Read [`morning-report-2026-08-25.md`](morning-report-2026-08-25.md) first** —
the night's results live there. **Every question waiting on the author now lives
in one file, [`open-questions.md`](open-questions.md)** (created 2026-08-25 because
the numbered questions were raised in one doc and worked up in another, so "#5"
was findable in neither). State:

**HANDS-ON QUEUE for `bunne-test`** — everything the 2026-08-25 answers created.

> **SUPERSEDED 2026-08-25 evening.** Most of this turned out to be doable over ssh
> after all, and was: **items 1, 3, 4, 5 and 7 are DONE and reboot-verified**, item 6
> is running, and item 2 is installed-and-configured but its acceptance test is still
> the gate — and its `limine.conf` step is what left the box at the boot menu. The
> per-item state is folded in below; the account is
> [`../benchmarks/4.24.hands-on-queue.md`](../benchmarks/4.24.hands-on-queue.md).
> **What genuinely needs the keyboard is now short:** the recovery keypress and the
> two-line `limine.conf` repair (banner at the top of this file), then the snapshot
> rollback acceptance test, then one satty annotate-and-export.

Original list, annotated:

1. ✅ **DONE** — **Sweep the MUB packages** (author's word): `sudo pacman -Rns cava fastfetch
   gpupaper matugen dms-shell`, then `sudo pacman -Rns $(pacman -Qtdq)` to drop
   the orphaned `hypr*` stack `dms-shell-hyprland` dragged back in. Confirm with
   `pacman -Qq | grep ^hypr` returning nothing.
2. ⚠️ **INSTALLED, ACCEPTANCE STILL THE GATE** — and the `limine.conf` step is
   what stopped the box. **Snapshot + kernel boot entries.** Add `[omarchy]` **last** in
   `/etc/pacman.conf` with `SigLevel = Required DatabaseOptional`; `sudo pacman-key
   --recv-keys 40DFB630FF42BCFFB047046CF0134EE680CAC571 --keyserver
   keys.openpgp.org` then `--lsign-key` the same fingerprint; `pacman -S
   limine-snapper-sync limine-mkinitcpio-hook`; restructure `limine.conf` into one
   OS block with `//Kernel` children + `//Snapshots`. **Then the acceptance test,
   which is the point:** snapshot → drop a canary file → restore from the Limine
   menu → reboot → canary gone, Docker images still there, "backup" entry puts it
   back. Until that runs, the row is decided but unproven.
3. ✅ **DONE, reboot-verified, cap re-proven** — **Docker subvolumes to the top level** — `@containerd` → `/var/lib/containerd`,
   `@dockervol` → `/var/lib/docker`, mounted from `/etc/fstab` like `@home`; move
   the data, re-apply the 100/50 GiB qgroup caps, re-run `btrfs quota rescan -w`.
   Without this a rollback silently un-caps Docker and puts it back inside every
   snapshot.
4. ✅ **DONE, reboot-verified** — **`nvidia-open-dkms` → `nvidia-open`** (prebuilt), reboot, confirm the driver
   loads and `linux-headers` is no longer required.
5. ✅ **DONE** (byte-identical to the Google Fonts release; the installer symlink
   step is Phase 4) — **Vendor the fonts** — confirm Fragment Mono's license string, copy both TTFs to
   `assets/fonts/` with `OFL.txt`, symlink + `fc-cache -f`.
6. ▶️ **RUNNING — it is the live configuration; go use it** — **Test-drive greetd vs getty-autologin** — **already armed, just reboot.**
   `/etc/greetd/config.toml` is in the `initial_session` + `agreety`-on-logout shape
   and `greetd` is enabled (2026-08-25, snapshot 66 taken first). Revert is `sudo
   systemctl disable greetd && sudo cp /etc/greetd/config.toml.getty-era.bak
   /etc/greetd/config.toml` + reboot.
7. ✅ **BOUND, pipe proven; the annotate-and-export half needs you** — **satty keybind**
   into the niri config, then the C4 round-trip acceptance.

- **Laptop**: Arch, getty-autologin, disk-alert soak verified through the
  night (details in the report). NixOS untouched since its evening work;
  plain reboot lands NixOS, `sudo efibootmgr --bootnext 0000` first → Arch.
- **Closed tonight** (all DA-gated, committed): the niri "IPC spawn wedge"
  — root mechanism is niri's locked-session action gate dropping actions
  **pre-fork**, proven on both OSes + v26.04 source (4.15 correction, nix
  round 15; diagnostic: `pgrep -x swaylock` — **corrected 2026-08-25 from
  `-f`, which matches swayidle's own arguments and so always says
  "locked"**); fuzzel +1 ms → attributed
  compositor-side, accepted (4.12 addendum); **4.17 package audit** — four
  lying rows fixed on the box, rejected terminals removed, four
  deployed-but-rowless decisions recorded (launcher/wallpaper/screenshot/
  brightness-keys), `ttf-fragment-mono` package is DEAD (font = unowned
  user-local files; delivery decision pending); **4.18** — systemd-oomd
  swap-kill canary PASSES and load-protection decomposed (CPUWeight +
  AllowedCPUs = baseline latency under a saturating hog); uv-standalone
  CUDA confirmed end-to-end on Arch (`python-env-manager` row measured);
  CHOICES format debt paid; `README.md` added.
- **nix-bunne tonight**: pytorch/CUDA replicated + the Arch comparison leg
  (rounds 14/17 — round-8 DA #4 closed); `nixos-rebuild switch` measured
  (~11.3 s no-op floor, round 16); mate-polkit spawn path re-fixed after
  its second silent clobber; `mate.mate-polkit` rename fixed live+repo.
- **Why this section exists — the stale-premise pattern**: five tasks
  tonight launched off outdated lines below (pytorch "never run",
  vapoursynth "awaiting go-ahead" — the author had DECLINED filing, 4.12
  "write-up pending" — it existed, editor "phase 2 next" — all phases done
  and the row `picked`, spawn-wedge "open" — 4.15 had closed it). **When
  resuming: trust CHOICES.md rows, the DA tallies, and the newest
  benchmarks/ files over any "next/open" list in this file**, and read the
  tally before claiming a task from one ledger row.
- **Author's open items** (his, unchanged): notifications acceptance (real
  Slack + calendar), bar confirm ("none"), 3.5 shell-config review, ESP p1
  cleanup, Bitwarden in-app autostart toggle, nvim-p4 draft line-by-line
  review, NixOS hands-on acceptance, dotfile-deployment one-word confirm —
  plus the numbered decision list in the morning report.

### ⚡ Session of 2026-08-24 (day) — decisions ratified, gripes #1/#2-docker CLOSED, glvnd tax found

**Standing rule, saved to Claude's persistent memory (author's instruction):
every test conclusion clears the Devil's Advocate gate, all sessions, both
repos.** Also saved: no FOSS-on-principle (fast/light/private/functional are
the criteria), and **Claude never installs OR removes packages on the Omarchy
desktop — all package changes there are the author's alone.**

**Author ratified the entire decision queue** (full pros/cons round in
session; rows updated, applied live on the box, boot-verified):

- `NUMBER_LIMIT="2-15"` — newest pre/post pair guaranteed, consciously
  accepting its byte-cap exemption; manual `snapper delete` proven to
  override the floor. `baseline` stays pinned until Phase 5.
- **zen removed** (package, headers, initramfs, limine entry; reboot
  verified). One kernel ships.
- **kitty `input_delay 0` declined** (4.6's 7× win stays on the table,
  recorded); **mesa-ICD pin declined everywhere**.
- **Docker: gripes #1 and #2's docker half are CLOSED.**
  `/var/lib/containerd` capped **100 GiB** (images), `/var/lib/docker` now
  its own subvolume capped **50 GiB** (volumes; ENOSPC-on-DB trade explained
  and accepted; 50 is Claude's stated default, vetoable). Applied with the
  mandatory `quota rescan -w` (installer must carry that line), canary write
  refused at the cap, docker restarted clean (`raw/4.11`). Phase 4 task:
  port the predecessor's disk-alert timer, teach it qgroups, alert at 80%.

**nvidia-open on BOTH OSes** (author decision; iGPU-only still supported in
the final product). Installed on Arch (610.57.04, both kernels — then zen
removed), nouveau gone, idle P8 9.25 W. His "does kitty need the GPU?"
hypothesis: **refuted, sign reversed** — the driver made kitty *slower*, and
chasing that found the **glvnd EGL-vendor enumeration tax**: kitty maps the
whole nvidia EGL stack per launch on hybrid boxes — 7-10 ms (Arch/610),
10-12 ms (NixOS/595), removable by ICD pinning (declined). 4.2's ~23 ms
kitty gap decomposed: ≈ NixOS's ICD tax stacked on a **roughly 10-12 ms
as-shipped OS gap** (kernel confound named). Desktop 4090: kitty **~67 ms**
warm, ICD enumeration free there (4.10, informational). All DA-gated —
tally rows 8-10, transcripts in `da-logs/`; the rounds caught real errors
(zen-contaminated baseline, stale-window probes, a false PSS retraction).

**Open questions created/closed today:** kitty PSS absolutes are
**unquotable** until a steady-state method exists (72-263 MB observed for
one window depending on session age — 4.8b); fuzzel is +~1 ms in 5/5
post-nvidia boots (suspect: niri's own 73 nvidia maps) — open; niri PSS
post-nvidia re-measured (`raw/4.12`) — largely explains 4.2's cross-OS niri
oddity (write-up pending). **vapoursynth investigation CLOSED**
(`BUDGET.md`): the profile.d file forks Python per login (66-83 ms) to set
a variable nothing reads — ffmpeg's .vpy demuxer provably works without
it; package must stay (dlopen'd by soname), file is an upstream bug report
awaiting the author's go-ahead.

**Arch keybind sweep** (same test that caught 3 gaps on NixOS): `playerctl`
and `orca` are MISSING on active keybinds. Author decision pending —
recommend installing playerctl and *dropping* the orca bind (inherited from
niri's example config, not a choice).

**Logistics now solved:** `ssh bunne-test` works whichever OS is booted
(user `bunne`, host-key checking off for that host — dual-OS fingerprints);
**passwordless sudo confirmed on NixOS too**, so Claude flips OSes freely
(`efibootmgr --bootnext 0000` = Arch; plain reboot = NixOS). Bitwarden's
455 MB resident mystery: **its own "start on login" setting** writes
`~/.config/autostart/bitwarden.desktop` — author flips it in the app.

**Still physical/author-only:** ESP p1 orphan cleanup, and flipping
Bitwarden's own start-on-login toggle next time the app is open (the
autostart file it wrote was deleted; the app may recreate it).

### ⚡ EVENING CLOSEOUT (2026-08-24 ~20:00) — both queued tests DONE; handoff below is now historical

**4.16 kitty anon drift: CLOSED (DA row 14).** 40 samples over 3 h: anon
plateaus at **54.33 MB, bit-identical from age 600 s to 10,800 s** — the
4.14 "drift" was a one-time +3.5 MB settling step. BUDGET's right-censored
hedge is retired; spawn floor replicated (n=7). Raw: `raw/4.16.drift.log`.

**swaylock "ran twice": SOLVED, benign.** Two mechanisms, both live-tested:
(1) **every single `swaylock -f` is a two-process pair** (both reparented to
init, both persist the whole lock — verified with ps) — a process list
during any lock shows "swaylock twice"; this is upstream `-f` behavior and
almost certainly the original observation. (2) swayidle's unguarded
timeout/before-sleep re-spawn into a locked session **fails instantly and
cleanly** — niri logs "refusing lock as already locked with an active
client", swaylock exits 2, nothing lingers. No config change needed; the
observation moves off the open list. Bonus finding for the shipped design:
**if the locker dies, niri keeps the session locked** (correct,
ext-session-lock) and **a fresh swaylock can take over the orphaned lock**
— so the recovery from a locker crash is "run swaylock from a TTY, then
unlock normally", never a forced reboot. Box was rebooted back to Arch
(fresh unlocked autologin session) at ~19:57.

### ⚡ COLD-RESUME HANDOFF (2026-08-24 ~19:00) — desktop may be shut down mid-run (HISTORICAL — completed above)

The author may power off the desktop (where Claude runs) before the evening's
last steps finish. Everything durable is committed+pushed; the laptop stays
on, booted **Arch**, and carries the only live state. Finish list, in order:

1. **Harvest the 4.16 drift run.** A detached sampler on the laptop
   (`~/t-4.16-drift.sh`, log `~/t-4.16-drift.log`) finishes ~19:50 with a
   `DONE` line, then kills its kitty window itself. Partial data through age
   7800 s is committed at `benchmarks/raw/4.16.drift-partial.log`
   (instrument at `benchmarks/instruments/4.16-drift.sh`): **anon has sat at
   exactly 54.332 MB from age 600 s through 7800 s** — the pre-registered
   "plateau" outcome (margins in `benchmarks/4.16.kitty-anon-drift.md`,
   committed before the data) is already met unless the last 50 min surprise.
   To finish: scp the full log over the partial, fill the Results section of
   4.16 (plateau value, spawn floor 50.788 MB replicating 4.14), run a DA
   round (obvious attack: the box was NOT idle 16:50-17:10 and ~18:50 —
   p4-draft testing and the alert test ran; anon never moved through any of
   it, which *strengthens* plateau), then add the BUDGET.md idle-window anon
   figure: **~54.3 MB steady-state** (was right-censored ">=54").
2. **Swaylock double-instance test — do LAST, it may wedge the session.**
   Mechanism already established: swayidle fires `swaylock -f` on `timeout`
   and `before-sleep` with no already-locked guard, so any manual lock held
   past the timeout gets a second instance (15 min in the shipped config!).
   Protocol: over ssh with `NIRI_SOCKET` set, spawn swaylock #1 via
   `niri msg action spawn -- swaylock -f -c 0f0f0f`; then run the exact
   swayidle command as #2 **in the foreground over ssh** to capture its
   stderr/exit code; record `pgrep -ax swaylock` and the journal. The
   question is what #2 does: exits cleanly (benign, cosmetic log noise) vs
   lingers (process leak — real bug worth an upstream look / a guard).
   Recovery: `pkill -x swaylock`; if niri keeps the session locked after the
   locker dies (ext-session-lock allows this), reboot — plain reboot lands
   NixOS, `sudo /tmp/efi/bin/efibootmgr --bootnext 0000 && sudo reboot`
   (NixOS side) or `sudo efibootmgr --bootnext 0000` (Arch side) returns to
   Arch. Then update the resume open-observations list with the verdict.
3. **Write the drift + swaylock results into this file** and push.

Laptop state right now (all recorded): Arch booted; disk-alert timer
**enabled as a live soak** (fires every 4 h, first 20:00 — a critical mako
notification at some point means a real breach, not the test); `nvim-p4`
draft config + `~/.venvs/neovim` + `bunne` kernel installed; fzf+lazygit
installed (pacman, for the p4 draft); one kitty window belongs to the drift
sampler until ~19:50. The author's open items are unchanged in the list
below; **the `dotfile-deployment` relitigation now has its fair examination
written into the row and closes on the author's one-word confirm
(recommendation: keep symlinks).**

### ⚡ Session of 2026-08-24 (evening) — handoff item 1 DONE autonomously

**The NixOS notebook-stack port is wired, rebuilt, and fresh-boot first-try
PASSED** (Claude, unattended; box flipped Arch → NixOS and left on NixOS).
All five render paths proven with the real bindings on a fresh boot: text
output, matplotlib plot, pnglatex typeset equation, PIL inline image,
decorated markdown + inline markdown image. DA round 13 in nix-bunne
(`da-logs/notebook-stack-port-2026-08-24.md`) — **the gate caught a real
bug**: the prototype's `<Space>` bindings depended on LazyVim's
`mapleader=space`, which bare nvim doesn't set; fixed in nix `nvim-init.lua`.
**The same landmine awaits the Phase-4 arch editor port if the base ever
isn't LazyVim — set `mapleader` explicitly.**

Deployed imperatively on the NixOS box (not yet in nix config): kitty.conf,
`~/molten_example.md` (+ python-logo.png, kernel name sed'd to `bunne`),
jupyter runtime dir, `ipykernel install --name bunne`. sympy NOT installed —
the example's sympy fence will fail loudly; author's call to add `ps.sympy`.
Watch item found: `:e`-reloading a molten buffer + re-init orphans rendered
outputs (image.nvim `identify` errors on deleted temp files) — mechanism not
pinned, does not reproduce in a normal open-once session.

**Author hands-on acceptance on NixOS still pending** (item for his next
sitting, plus his open items in the list below).

### ⚡ HANDOFF for the next session (written end-of-day 2026-08-24)

**State**: laptop on Arch (fresh boot, niri up; swayidle killed this
session — the 8 h idle-timeout deviation is applied in the box's config
for future boots). All repos committed. Box flips: plain reboot → NixOS;
`sudo efibootmgr --bootnext 0000` first → Arch.

**The day's headline: gripe #3 is author-accepted.** The markdown-notebook
stack (LazyVim + upstream molten + image.nvim + render-markdown + OUR
40-line themed pnglatex replacement) renders plots, inline images,
decorated markdown, and transparent-bg typeset equations — fresh-boot
first-try verified, author quote in the `jupyter-in-neovim` row: "can
completely replace my current pycharm workflow." Prototype configs are
deposited in `benchmarks/raw/4.15.*` and mirrored to nix-bunne
`reference/notebook-stack/` with `PORTING.md`.

**Next session, in order:**
1. **NixOS boot day**: wire the notebook stack per
   nix-bunne `reference/notebook-stack/PORTING.md` (render-markdown plugin,
   image.nvim markdown integration, our pnglatex.py into the provider
   python, texlive-with-dvipng equivalent, example doc), deploy
   `reference/kitty.conf`, rebuild, and re-run the fresh-boot acceptance
   there. The keybind-apps rebuild is already live on NixOS.
2. **Phase-4 editor port begins**: LazyVim shipped config in `config/`,
   from the deposited prototypes — plus the venv bootstrap (pynvim,
   jupyter_client, ipykernel, matplotlib; register kernel; CREATE
   `~/.local/share/jupyter/runtime`), the `;l` keymaps block, and the
   venv-selector requirement. `latex-rendering` row carries the texlive
   package set; netpbm is flagged unneeded (Phase-4 sweep).
3. **Author items still open**: notifications acceptance (real Slack +
   calendar), bar slot confirm ("none"), 3.5 shell-config review, ESP p1
   cleanup, Bitwarden in-app autostart toggle, whether to PR our pnglatex
   fix upstream.
4. ~~**Open observations**: swaylock ran TWICE after a long lock (a second
   instance — one look someday); kitty anon drift past age 300 s
   right-censored; fuzzel +1 ms post-nvidia unattributed.~~ **All three
   closed**: swaylock-twice = benign `-f` two-process pair (evening
   closeout); kitty anon drift = 54.33 MB plateau (4.16, DA row 14);
   fuzzel +1 ms = compositor-side by elimination, accepted (4.12
   addendum, 2026-08-25).

### Afternoon addendum, same day (all committed; details in benchmarks/)

- **External display: the hybrid hard case PASSES on both OSes** (4.13 +
  nix ledger) — AOC on the NVIDIA-wired HDMI, real windows moved onto it
  via IPC, dGPU stays P8 during scanout on Arch. The nix GPU row's
  "needs reverseSync" prediction was X11-era thinking; niri's native
  multi-GPU handles it under offload.
- **Bluetooth acceptance passed** (author paired a keyboard, typed to
  terminals). **vapoursynth upstream report declined** — investigation
  closed in BUDGET.md. **sshd boot question DISSOLVED** (nix r12: docker
  gates every chain, sshd on none; startWhenNeeded trialed, DA-rejected
  as kept, reverted same hour).
- **Keybind standardization ratified and live on both OSes** (CHOICES
  `keybindings`/`keybind-apps`): the author's cascade (Omarchy defaults ←
  his bindings.conf ← non-colliding ← installed), two question rounds,
  seven app rows installed, gtk-launch as the cross-OS bitwarden shim.
  **nix repo drift found**: hosts/configuration.nix was stale vs the live
  /etc/nixos — live is source of truth; synced from box.
- **Author doctrine codified in both CLAUDE.mds**: hacky solutions are
  brittle; Fast & Light includes the future; fixes are package choices or
  supported options, never lobotomies or 50-line micro-hacks.
- **kitty PSS saga closed to its floor** (4.14/b/c, three DA rounds):
  anon floor ~50.8 MB at spawn (n=5 boots, 40 kB agreement), drifting to
  ~54 MB within minutes (open); ALL other variance is page-cache file
  accounting, **causally proven** by the drop_caches counterfactual
  (warm 204 MB → 60 MB at matched uptime). No total is BUDGET-quotable;
  the anon floor is.
- **Editor bake-off started** (4.15, editor row in CHOICES): phase 1
  startup — NVChad 16.3 ms / minimal 24.1 / LazyVim 126.8 / floor 9.6
  (old ordering replicates). **Phase 3: GRIPE #3 RENDERED ON ARCH** —
  molten inline matplotlib inside NVChad inside kitty, screenshot
  deposited (`raw/4.15.molten-render.png`); one warm render, provisional.
  Found on the way: **NVChad's second silent molten-killer** (`"rplugin"`
  in disabled_plugins — remote plugins can never register), the jupyter
  runtime-dir bug reproducing on fresh installs, and lazy-by-default
  silently emptying rplugin manifests. Phase 2 (gr correctness) is next.
- **Open watch item**: niri's IPC spawn silently wedged mid-session on
  one boot (no windows, no journal errors; reboot cleared). Recurs ⇒
  priority-1 bug — keybinds route through it.
- Standing rules from today's eight DA rounds codified in nix-bunne
  `METHODOLOGY.md` (wall-clock deposits, pre-reg margins, fail-loudly
  probes, no-delta power, dissolved ≠ answered, etc.).

### ⚡ Session of 2026-08-23 (night) — ARCH IS INSTALLED; bake-off in progress

**The install in the handoff below is DONE.** `arch-bunny` boots from p5/p7
(LUKS2+btrfs, limine, linux mainline, NetworkManager, zram 7.7 G, niri desktop
from `config/`, sshd up, NixOS untouched and still the firmware default).
Handoff doc kept for the disk map and recovery paths; its "NOT started" status
is stale. Overnight work + results: **`docs/morning-report-2026-08-24.md`**.

Three decisions the author made that night (now `CHOICES.md` rows): `kernel` =
linux mainline, `network-stack` = NetworkManager, `snapshot-system` = snapper +
snap-pac + qgroup byte-cap (~20 GiB) — canary-proven, DA-gated
(`benchmarks/4.1.snapshot-cap.md`, `benchmarks/da-logs/`,
`benchmarks/DA-TALLY.md`). **Needs ratification: `NUMBER_LIMIT="0-15"`** (floor
0, not the approved 2 — see the row).

Test-box deviations added that night (undo before Phase 5, same table as the
others below): **passwordless sudo for `bunne`**
(`/etc/sudoers.d/20-bunne-testbox-nopasswd`) for unattended overnight work;
LUKS keyfile auto-unlock in the initramfs (`benchmark-unlock` pattern);
`BootNext`-only reboots so any power cycle lands in NixOS.

One repo-relevant lesson: an unconditional `exec niri-session` in
`.bash_profile` fork-loops — niri-session re-execs through a **login** shell,
which sources `.bash_profile` again. The guard must test interactivity:
`[[ $- == *i* && -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]]`. Carry that
into the Phase-4 shell config.

### ⚡ Session of 2026-08-23 — Arch/NixOS bake-off install, READ THIS FIRST

The author uninstalled Arch from `bunne-test` and installed **NixOS 26.05** to run an Arch vs NixOS
bake-off. Arch is being put back **alongside** it. Disk prep is done and verified; the Arch install
has not started.

**→ [`docs/handoff-arch-alongside-nixos.md`](handoff-arch-alongside-nixos.md)** carries the full
state: access details (the `char` user is gone, it is `bunne@192.168.1.5` now), the exact partition
map, what was already changed, and the install recipe traced back to `CHOICES.md` rows.

Three things from it that change how you work on this repo:

- **`bunne-test` is NixOS right now**, not Arch. Anything in this file that assumes an Arch test
  laptop is stale until Arch is reinstalled. Absolute-number benchmarks taken there are not
  comparable to the pre-2026-08-23 ones.
- Arch gets its **own ESP** (`p5`) and `p7` (249 GiB). NixOS keeps `p1`/`p6`. `p3` is Windows,
  shrunk to 95.5 GiB. **Only `p5` and `p7` may be written to.**
- `os-base` in `CHOICES.md` already records **Arch picked / NixOS rejected** — this bake-off
  re-opens a settled row, so treat it as a validation exercise, not an open question.


### ⚡ Session of 2026-08-21 (evening) — read this first

Two things happened: the Docker cap test came back empty, and **the `gr` gripe
was reproduced and fixed.**

#### `gr` — 7.5 s → 0.47 s. See [`benchmarks/3.12`](../benchmarks/3.12.gr-after-the-exclude.md) and [`3.13`](../benchmarks/3.13.picker-bakeoff.md).

**The author's `cdk.out` diagnosis was right.** Time to a correct
find-references on `get_adstock_saturated_media_jax`, measured on the real
repository:

| config | time to correct answer |
|---|---|
| author's `pyrightconfig.json` | **469 ms** |
| no config (the pre-16:00 state) | **7,540 ms** |
| author's config + `mmm` venv | 1,393 ms |

**16x, and that reproduces the gripe** — with a venv configured the slow case
lands near 8–9 s, which is the reported "10+ seconds for a symbol with only a few
references". Warm repeats are 46–178 ms.

**The picker is not the bottleneck.** Content-arrival medians: quickfix
3–7 ms, **telescope 8.6 ms and snacks.picker 8.7 ms — indistinguishable** —
fzf-lua 27–28 ms (flat at every size; it spawns the `fzf` process on each open,
which argues against the laptop's `nvim-bunne` pick for this binding).
**Recommendation: keep snacks.picker** — already installed, ties the best plugin
option, and switching would add `plenary.nvim` for nothing.

**One config change is worth making:** gate `gr` on the server's first
`publishDiagnostics` for the buffer. Pyright answers from a partial index and
returns **1 reference** if asked immediately — in every configuration, including
the fast one. The gate costs **~50–130 ms** and needs a `BUDGET.md` row. It fixes
correctness only; the exclude is what fixes speed, and both are wanted.

Two things carry forward:

- **These files were rewritten after the first pass got the headline backwards.**
  It reported "wrong, not slow" and "the picker gap is 4x", both artifacts of
  measuring too impatiently and of reporting only one of two signals. The
  corrections are recorded in place in `3.12` and `3.13`. **Treat any single-run,
  single-signal number in this repo with suspicion.**
- **Headless nvim could not be used as a harness and all its numbers were
  thrown out.** pyright answers a raw stdio client in 0.69 s but went silent
  against a minimally-configured `vim.lsp` client — even `hover` on a two-file
  project timed out at 20 s. Pull diagnostics were tested and cleared as the
  cause; it remains unexplained. Worth understanding, since the real editor uses
  that client. Working harnesses: [`scripts/lspref.py`](../scripts/lspref.py),
  [`scripts/lspref-coldstart.py`](../scripts/lspref-coldstart.py),
  [`scripts/pickerbench.py`](../scripts/pickerbench.py).

**Still unmeasured: the author's actual LazyVim.** Everything above is the bare
server and the bare picker. Measure once inside the real editor before closing
the gripe.

#### Docker

The author ran `~/t-docker-quota.sh` on `bunne-test` at 16:01. **It reported
`cap_enforced=0` and that result is worthless** — see the new
[`benchmarks/3.11.docker-quota.md`](../benchmarks/3.11.docker-quota.md), written
from the journal because the script's stdout was never captured.

Two findings, the second bigger than the first:

1. **The harness could not reach the cap.** It filled with `docker run --rm`, so
   each 256 MiB blob died with its container before the next was written — peak
   usage 256 MiB against a 2 GiB limit. 39 containers, zero refusals.
2. **The cap was on the wrong directory.** Docker is 29.7.2 with
   `containerd-snapshotter=true` as the stock default (no `/etc/docker/daemon.json`
   exists), and containerd logs `containerdRootDir: /var/lib/containerd`. So
   `/var/lib/docker` holds only the per-container merged overlay mount; the image
   layers sit on `@`, uncapped and inside every snapshot. This also undercuts the
   other candidate — `overlay2.size=` has nothing to size when the `overlay2`
   driver is not in use.

`CHOICES.md` `docker-storage-quota` and `snapshot-bloat` are updated with both,
and both stay **deferred**.

**Next action:** `sudo ~/t-docker-quota2.sh 2>&1 | tee ~/log-t-docker-quota2.log`
on `bunne-test` — written this session, `shellcheck`/`shfmt`-clean, **needs root
and has not been run.** It measures which directory actually grows before
choosing what to cap, then fills with *retained* image layers of incompressible
random data. `--teardown` undoes it. **Root is still not available to Claude**
(`sudo` wants a password), so the author has to launch it.

### ⚡ Session of 2026-08-21 (late)

Three new benchmark files: [`3.8`](../benchmarks/3.8.input-to-onscreen.md)
(spawn→on-screen latency), [`3.9`](../benchmarks/3.9.nvim-startup.md) (Neovim
startup), [`3.10`](../benchmarks/3.10.nvim-references.md) (why `gr` is slow).
**`CHOICES.md` and `config/` were deliberately not touched.**

**THE FIRST THING TO DO NEXT SESSION IS NOT A BAKE-OFF.**

The `gr`-is-slow gripe looks like it is **not an editor problem at all**.
`~/tradeswell/ds-ml-platform` contains **`mlapi/cdk.out` with 124,748 generated
`.py` files** (AWS CDK synth output). Real source is ~2,500 files. The repo has
**no `pyrightconfig.json` and no `pyproject.toml`**, and `cdk.out` is neither
dot-prefixed nor `node_modules`, so **pyright's default excludes do not catch
it** — it is indexing roughly 50x the actual codebase. That fits the reported
symptom exactly: *10+ seconds even for a symbol with only a few references*,
because the cost is the workspace scan, not the result set.

**Action, in this order:**

1. ~~Add a `pyrightconfig.json`, then re-time `gr`~~ — **both done.** The config
   landed 2026-08-21 16:00 (gitignored, local-only); the re-timing is
   [`benchmarks/3.12`](../benchmarks/3.12.gr-after-the-exclude.md) and the
   verdict is **46–164 ms warm and correct**. The exclude fixed a *wrong answer*,
   not a slow one. *Count correction:* the real tree is **7,668 `.py` files**,
   not the ~2,500 estimated below — `cdk.out`'s 124,748 outnumber it **16x**.
2. **It did fix it, so most of the planned bake-off is moot** — the editor
   decision goes back to being about startup and features, not references.
   The server-comparison half of the grid below can be dropped.
3. **What is left is the picker half**, plus the cold-call correctness problem,
   which is a config question (do not let `gr` run before indexing settles)
   rather than a bake-off.

### The bake-off, if still needed

The author runs **pyright + snacks.picker under LazyVim** (confirmed by reading
`~/.config/nvim/lua/plugins/lsp.lua` and `lazyvim.json`). **Everything measured
in `3.10` used basedpyright + fzf-lua — neither of his components**, so those
numbers do not describe his path. Two independent variables:

- **Servers** (references on a large repo, cold + warm, **and the reference
  count**, since `3.10` proved speed can hide a wrong answer): `pyright`,
  `basedpyright`, `jedi-language-server`, `python-lsp-server`. Confirm whether
  `ruff` supports references at all — believed not, which disqualifies it here.
- **Pickers** (rendering ~1000 results): `snacks.picker`, `fzf-lua`, `telescope`.

### Everything else still open from this session

1. **Wire molten into NVChad.** Override point is
   `~/.config/nvim-chad/lua/options.lua`, which is `require`d *after* NVChad's
   `nvchad/options.lua` sets `loaded_python3_provider = 0`. Set it back to `nil`
   plus `python3_host_prog`, then add `molten-nvim`. `python-pynvim` and
   `luarocks` are now installed, so `image.nvim`'s ImageMagick binding should
   build — previously the blocker.
2. **`python-pynvim` + pinned `g:python3_host_prog` is approved by the author**
   ("if we need it for jupyter, include it in the list") and **still needs a
   `CHOICES.md` row**. Worth **52.4 → 12.0 ms** on every `.py` open, with a
   provider that actually works. See `3.9`.
3. **Do not bind bare `gr`** — it collides with Neovim's built-in `gr*` prefix
   and costs a free `timeoutlen` (1000 ms). Additive, not the main cause.
4. **MegaUltraBunny — not started.** New request, 2026-08-21: an *optional*
   full-rice theme for beefy machines (64 GB / 4090). Hard constraint from the
   author: **zero boot cost and zero idle RAM unless explicitly switched to** —
   disk only. Every package installed for it must be itemised so its cost is
   accountable. Nothing installed yet.
5. **Test the loaded-machine hypothesis** — `3.4` documented the desktop at load
   32.5 inflating primitives 2.5-2.9x. Cheap, and it may explain the rest.

### State of `bunne-test` right now

- **Root was never granted this session.** The sudoers one-liner in the chat log
  was never run; `sudo` still needs a password. Everything below was worked
  around, and **no package decision should rest on the workarounds.**
- Installed by the author on request: `python-pynvim`, `luarocks`, `nodejs`,
  `npm`, `ripgrep`, `fd`, `fzf`, and Docker (`inactive`/`disabled`, so no idle
  cost).
- **Installed by Claude, user-local, NOT packages**: `~/.local/bin/{rg,fd,fzf}`
  downloaded from GitHub releases (now redundant — the real packages exist);
  `~/t-venv-nvim` holding `pynvim`, `basedpyright`, `jedi-language-server`,
  `python-lsp-server`, `ipykernel`, `pandas`.
- **Throwaway Neovim configs** kept deliberately: `nvim-lazy`, `nvim-chad`, and
  `nvim-bunne` — the last is a hand-rolled 3-plugin contender (fzf-lua +
  grug-far + basedpyright) at **34.3 ms** against LazyVim's 215 ms, built so
  LazyVim cannot win by default. `grug-far` is the answer to the missing
  project-wide find/replace (10.8 ms to open).
- Scratch: `~/t-*.sh`, `~/t-lspref.lua`, `~/t-probe.lua`, `~/t-proj/{rich,pandas,venvtest}`,
  `~/t-docker-quota.sh` (**run 2026-08-21 16:01; null result, superseded**) and
  `~/t-docker-quota2.sh` (**the replacement — linted, not yet run, needs root**).
- A live nvim may still be listening on `~/t-nvim.sock`; `pkill -x nvim` if so.


Phase 3 is well advanced. **`CHOICES.md` now holds 44 `picked`, 15 `deferred`,
7 `rejected`, 1 `blocked`.** The desktop on `bunne-test` is usable: niri, kitty,
fuzzel, swaybg, mako, cliphist, mate-polkit, swaylock+swayidle, brave — all
installed, configured from `config/`, and acceptance-tested.

### Read this first — the priorities were corrected on 2026-08-21

The author flagged that "fast and lean" had been read as mostly *lean*. It is now
**2a fast — the time between pressing a key and the intended thing having
happened — then 2b light — total RAM.** Speed wins by a soft preference when they
conflict, *and the conflict must be stated out loud rather than settled quietly*.
**Disk space is not a criterion at all** — not install size, not package count.
Fewer packages survives only as a means to those two, never as a metric.

**New file: [`BUDGET.md`](../BUDGET.md)** — a running tally of what every feature
costs, bucketed by how often the cost is paid (per prompt / terminal / login /
boot / resident RAM). **Buckets are never summed with each other**: 1 ms per
prompt is ~200 ms/day, 1 ms per login is 1 ms/day. Rule 6 is the author's and
matters: *headroom is not an allowance.*

### Next, in the order I would do them

1. **Screenshot, annotate, brightness — the last hole in C4.**
   `grim`, `slurp`, `satty`, `brightnessctl` are **all missing**, and
   `02-functionality.md` C4 lists screenshot/region-select/annotate as core.
   `04-plan.md` says "make it usable" blocks everything else. Rankings are clean
   (the Hyprland audit cleared them), so this is install-and-bind, not a bake-off.
2. **Land the shell config.** `prompt`, `node-runtime` and `prompt-hooks` are
   `deferred` only because they are product code awaiting the author's review —
   prototyped, measured, `shellcheck`-clean, code in
   [`benchmarks/3.5`](../benchmarks/3.5.prompt-and-shell.md). Per prompt
   **65.7 → 8.4 ms**, per terminal **317 → 19 ms**, node **143 → 0 ms**.
   Note the immediate gain on the laptop is ~zero (its `.bashrc` is stock Arch at
   3.4 ms); the value is **not porting Omarchy's 317 ms config to the desktop in
   Phase 6**.
3. **Neovim — the last headline gripe.**
   *Started 2026-08-21, see [`benchmarks/3.9.nvim-startup.md`](../benchmarks/3.9.nvim-startup.md).*
   **LazyVim 208.8 ms vs NVChad 20.5 ms** to open a 1500-line `.py` (not
   like-for-like — LazyVim loads 13 plugins to NVChad's 4). Two things found that
   outrank the bake-off: **~34 ms of every `.py` open is a failing python3
   provider probe**, fixable with `pynvim` + a pinned `g:python3_host_prog`; and
   **NVChad disables `loaded_python3_provider` outright**, which would silently
   break molten/Jupyter — the gripe itself. Neither distro is picked; the
   find-references diagnosis is still blocked (no `ripgrep`, needs root).

   `jupyter-in-neovim` is proven at the
   terminal layer but the config was never ported. Bring over the predecessor's
   `jupyter.lua`; **make its image gate announce itself** rather than silently
   disabling (that silence is why the gripe went undiagnosed for years); bake off
   LazyVim vs NVChad; and **diagnose the slow find-references before assuming the
   editor is at fault** — isolate Telescope vs ripgrep vs the LSP.
4. **Notifications acceptance test.** `mako` is installed and running but
   `notifications` is still `deferred`, because the test is **a real Slack
   message and a real calendar alert**, not `notify-send hello`.
5. **Bar — close it by confirming "none".** `03-alternatives.md` ranks no-bar
   first and nothing has missed it.
6. **The two remaining gripes**, both needing hardware time:
   `docker-storage-quota` and `snapshot-bloat`. *Started 2026-08-21 — see
   [`benchmarks/3.11`](../benchmarks/3.11.docker-quota.md) and the block at the
   top of this file. Blocked on someone with root running `t-docker-quota2.sh`.*

### Small things still on the author's desk

- **`CHOICES.md` format bug**: four rows put prose in the `Packages` column
  (`— (no package)`, `— (no manager)`, `— (cryptsetup already present)`,
  `— (no packages)`), so the installer's documented `awk` line emits four
  non-packages. Fix by normalising those cells to a bare `—` and moving the
  explanation to `Note`, **or** widening the filter to `$4 !~ /^—/`. The first is
  better: the column's whole justification is that it is data.
- **Nothing else pending** — `compositor-cleanup` was closed when Hyprland was
  actually removed (23 packages, 76.47 MiB).

## The two machines

- **Omarchy desktop** — `192.168.1.4`, where Claude runs and where this repo
  lives (`~/github/arch-bunny`). **This is the eventual daily driver**: the
  long-term plan is that BunnE replaces Omarchy here in Phase 6, leaving
  Windows + BunnE. It is *not* an install target during Phases 2–5, and it holds
  work (Unreal Engine game dev on the Windows side, DS work on the Linux side)
  whose loss has a real cost — so never run destructive commands here without
  checking which machine the shell is on. AMD CPU (`AuthenticAMD`), RTX 4090,
  64 GB, 1.8 TB NVMe that is **100% allocated** (1 MiB free).
- **`bunne-test` laptop** — `192.168.1.5` (DHCP, on wifi `wlan0`), the Phase 2/3
  install target. Intel Coffee Lake-H + GTX 1660 Ti Mobile, 16 GB, dual-boot
  with Windows, LUKS2 + btrfs. **Entirely disposable**: its partitions and data
  can be destroyed freely, Windows included — the only real limit is not
  bricking the firmware.
  **Its security is explicitly a non-concern during development** (author,
  2026-08-21, stated so it stops being re-raised): the machine sits inside his
  house, holds no valuable data, and a thief would wipe it regardless. **Security
  matters here in exactly two ways — as something to *test*, and as a property of
  the *final product*.** So do not spend design effort, or interrupt him, over
  the laptop's own exposure; `benchmark-unlock` leaving the disk effectively
  unencrypted is fine and needs no further justification. What still matters is
  unchanged: the removal gate before Phase 6 step 1 (that is the *final product*
  and the machine holding real credentials), and never letting a
  development-only shortcut reach the installer. Phase 5 wipes it to rehearse the installer on bare
  metal, and that install becomes the emergency work machine Phase 6 step 1
  validates.

**Do not overindex to the laptop.** It differs from the real target in ways that
silently hide requirements: Intel vs. AMD (microcode), hybrid graphics vs. a
single 4090, 16 GB vs. 64 GB, one legacy `HDA Intel PCH` codec vs. six audio
devices, and legacy HDA vs. the SOF audio that a future ThinkPad or Framework
will use. The hybrid-graphics compositor testing is the exception — it is the
*hard* case, so those results transfer upward safely. Little else does.

Future hardware in scope: this desktop, plus a ThinkPad or an AMD Framework.

## Deliberate deviations on `bunne-test`

The test laptop is **intentionally not identical to what BunnE ships**. Each
entry below is a testing convenience, not a design decision, and each one must
be undone or is undone by the Phase 5 wipe. **Do not copy any of these back into
`config/` or `CHOICES.md`.**

| Deviation | Why | Repo ships instead |
|---|---|---|
| `swayidle` timeouts **28800s / 28860s** (8 h) | idle-lock interrupting benchmarking (author, 2026-08-21). `Mod+Escape` still locks on demand, so the mechanism stays exercised. | **900s / 960s** (15 min), `config/niri/config.kdl` |
| `sshd.service` **enabled** | Claude needs read-only diagnostics over SSH | `openssh` installed, **`sshd` disabled** (`CHOICES.md` `ssh`) |
| `benchmark-unlock` keyfile in LUKS | makes total boot time measurable at all | manual passphrase only (`CHOICES.md` `disk-unlock`) |
| `shellcheck`, `shfmt`, `hyperfine` installed | linting and measurement | development dependencies, **not in the package list** (`CLAUDE.md`) |

The niri config on the laptop carries a loud `!!! LOCAL DEVIATION !!!` banner at
the timeout lines for the same reason. **A machine that silently differs from
its repo is how a testing shortcut becomes a shipped default** — that is exactly
how `sshd` ended up on the boot critical path and briefly looked like a
regression (`benchmarks/3.3`).

**SSH is set up.** `ssh bunne-test` works from the desktop using a dedicated key
(`~/.ssh/id_ed25519_bunne_test`, `Host bunne-test` in `~/.ssh/config`). The
laptop's `authorized_keys` entry is restricted with `from="192.168.1.4"` — if the
desktop's DHCP lease changes, drop that clause. Claude needs the permission rule
`Bash(ssh bunne-test:*)`.

**Working split — widened by the author 2026-08-21. Read this before asking
permission for anything.**

> *"Your time is cheap, my time is expensive. If you can run a test on your own
> that would improve your ability to advise me, take the initiative to do so."*

- **Claude runs tests on `bunne-test` unprompted**, including writing scratch
  `~/t-*` scripts and running them, whenever the result would sharpen a
  recommendation. **Do not ask first, and do not stop at one sample** — the
  laptop is disposable, testing is ephemeral, and the only hard limits are *no
  `sudo`*, *nothing that reaches the final product*, and *do not brick the
  firmware*. Under-testing is the failure mode here, not over-testing.
- **The author's explicit approval is still required for anything that lands in
  the final product** — installer code, package picks, configs BunnE ships. He
  wants to personally verify what he will run and maintain forever; he does not
  want to hand-run diagnostics that get thrown away.
- `sudo` on the laptop needs a password, so root actions remain his by
  construction, not merely by agreement. When a diagnosis needs root, write the
  one command and hand it over rather than working around it.
- **The distinction is *destination*, not risk**: a script that measures is his
  to ignore; a script that installs is his to approve. Two hours of measurement
  to avoid one wrong line in `install.sh` is the trade he is asking for.

## Phase 2 is COMPLETE

All of `04-plan.md`'s Phase 2 list is done and proven on hardware, except one
item deliberately dropped. Checkpoint recorded in
[`benchmarks/2.1.base.md`](../benchmarks/2.1.base.md).

Done this session, on top of the earlier base install / limine / snapper work:

1. **GPU** — `nvidia-open-dkms` + headers for both kernels, `nvidia-prime`,
   `mesa`/`vulkan-intel`/`intel-media-driver`. Works on both `linux-zen` and
   `linux`. **Zero config written**: `nvidia_drm.modeset` is already `Y` by
   upstream default, and upstream's `60-depmod` → `70-dkms-install` →
   `90-mkinitcpio-install` hook chain already handles kernel bumps.
2. **Hybrid-graphics topology discovered** — `card0` is NVIDIA and owns DP-1 and
   HDMI-A-1; `card1` is Intel and owns `eDP-1`. The panel runs on `i915`, but
   **every external monitor is driven by the NVIDIA card**. This is a hard
   constraint on Phase 3, see below.
3. **The 130 MB initramfs bug, fixed** — was 117.6 MB of nouveau firmware for
   every NVIDIA chip ever made, pulled in by the `kms` hook even though nouveau
   is blacklisted. Removed `linux-firmware` + `linux-firmware-nvidia`. Images are
   now 25 MB. Full mechanism in `CHOICES.md`, `initramfs` row.
4. **Limine menu timeout** set to `1` (it was briefly `60`).
5. **`yay-bin`** installed. Note `base-devel` is a *meta-package* now, not a
   group — `pacman -Qg base-devel` returns nothing even when installed.
6. **Rollback proven on hardware** with a canary file. Critically:
   **`snapper rollback` does NOT work on this layout** — see `CHOICES.md`,
   `rollback-method` row. The working method is a manual btrfs subvolume swap.
7. **Firewall** — `nftables` enabled. Arch's shipped `/etc/nftables.conf` was
   already exactly right, so **no config file is carried by this repo**. It is a
   `oneshot`, so `is-active` reporting `inactive` is correct and expected.
8. **`sshd` decided** — `openssh` always installed (needed for *outgoing* ssh),
   but `sshd.service` **disabled by default**. The test laptop deviates.

### The one thing dropped

**`limine-snapper-sync` cannot be built.** Arch's `gradle` 9.7.0 package is
missing `gradle-public-api-legacy`, so `nativeCompile` fails. This affects
Zesko's whole family (`limine-entry-tool`, `limine-mkinitcpio-hook`,
`limine-snapper-cli` are all GraalVM + system gradle), so there is no sibling to
switch to. Recorded as `blocked` in `CHOICES.md`. Shipping without it: snapshot
rollback works, you just do not get a menu of bootable snapshots. Revisit in
Phase 4 — Arch may have fixed gradle by then, or evaluate `limine-tool` (Rust,
`makedepends=cargo`, but v1.0.0 / 0 votes / unproven).

## Numbers to beat

From `benchmarks/2.1.base.md`:

- **`graphical.target` at 2.095s** (Omarchy baseline: 5.07s)
- **Idle RAM 599 MB**, 11 system services, **0 user services**
- 267 packages, 30 explicit, 1 AUR — **context, not a metric.** Package count is
  a proxy for disk, and disk is not a criterion here (`CLAUDE.md`).

**The largest gap in this list is latency, and it is not an oversight of
convenience — it is the headline metric of the project.** Corrected in the docs
on 2026-08-21: priority 2 is *fast* (2a) then *light* (2b), the author's soft
preference is speed when the two conflict, and **disk space is not a criterion at
all**. Across every session since 2026-08-17, what has actually been measured is
RAM — because `free -m` takes a second and input latency does not. An audit of `CHOICES.md`
that day: of 50 rows, one carries a timing number, and it measures throughput
rather than the delay a hand feels.

So there is **no latency baseline for anything** — not the Omarchy machine we are
replacing, not `bunne-test`, not niri.

> **Partly closed 2026-08-21**, see
> [`benchmarks/3.8.input-to-onscreen.md`](../benchmarks/3.8.input-to-onscreen.md):
> spawn → on-screen is now measured through niri's IPC — **fuzzel ~25 ms,
> kitty ~146 ms, brave ~642 ms cold**, plus a `bash -lic` login shell at
> 74.1 ms and an 11 ms bare-`nvim` floor. **This is not keystroke-to-photon**
> and does not retire step 4 below; it makes the paths comparable, nothing
> more. Note `3.7` had already measured terminal cold start — the claim that
> *nothing* had a latency number was too strong even when written. The compositor slot was closed on idle RAM
alone (`+87.7 MB` vs `+266.6 MB`), which is a legitimate 2b result and is *not*
the 2a comparison; niri is also the more responsive of the two by reputation, but
reputation is not the standard this repo holds anything else to. Nothing here
argues for reopening that slot — it argues for the number existing before the
next slot closes the same way.

**Before the next slot is decided, establish the 2a baseline** (`04-plan.md`
Phase 1 step 4 now specifies it): `hyperfine` on terminal spawn cold and warm,
`nvim --startuptime`, launcher keybind → first accepted keystroke, keybind →
window on screen. For keystroke-to-glyph, pick a method and prove the method
first — a phone slow-motion capture is the honest one; `evtest` vs `wev`
timestamps measure the input half only and would overstate the result.

Later checkpoints go in `benchmarks/` as **`<phase>.<test>.name.md`**. Most
recent: [`benchmarks/3.1.audio-bluetooth.md`](../benchmarks/3.1.audio-bluetooth.md)
— idle RAM **595 MB** with audio and Bluetooth installed, i.e. unchanged from
the floor, because audio is socket-activated and costs nothing until used.
`graphical.target` 2.305s (+0.21s). Both measured with no desktop running, so
they compare cleanly with the base checkpoint.

**Boot timing — resolved 2026-08-21, six boots, full data in
[`benchmarks/3.3.boot-unattended.md`](../benchmarks/3.3.boot-unattended.md).**

- **The `kernel` phase was human typing speed**: 3min 22.176s left sitting vs
  5.200s typed promptly. The keyfile makes total boot time a usable metric for
  the first time.
- **`graphical.target` is ~2.21s whichever way the disk is unlocked** — 2.194 /
  2.210s on passphrase boots, 2.221 / 2.209s on settled keyfile boots. **The
  original standing rule was right**: `userspace`/`graphical.target` *are*
  comparable across boot types, and **the Phase 2 baseline of 2.095s stands.**
- **New measurement rule: discard the first boot after anything that regenerates
  the initramfs.** Both first-boots-after-`add` were the outliers (4.432s,
  3.222s) and settled to ~2.21s within one or two reboots. After `mkinitcpio -P`,
  reboot twice before recording.
- **Two hypotheses were raised and killed here** — that the passphrase wait
  pre-warmed hardware, and that the keyfile cost 2.2s of userspace. Both were
  single-sample conclusions dressed as mechanisms; three reboots settled them.
  There was never a `graphical.target` regression, and `sshd` never caused one.
- **Still open**: the keyfile's `kernel` phase runs ~1.2s longer than a fast-typed
  passphrase boot (6.33–6.48s, n=4, against 5.200s). Suspected wasted Argon2 run
  against the wrong keyslot; `cryptsetup benchmark` shows argon2id tuned to ~2s
  here, which fits the order of magnitude. **`cryptsetup luksDump` settles it and
  needs root** — the author's to run. Harmless either way: it vanishes with the
  keyfile and never reaches the product.

## Phase 3 — the bake-off, in progress

Work `03-alternatives.md` **in the order the slots appear there**; later slots
depend on earlier ones. Started with the compositor.

**Non-negotiable for this machine:** test every compositor candidate **with an
external display attached**. The panel is on Intel and the external ports are on
NVIDIA, so a docked session is a genuine multi-GPU Wayland session — the hard
case. Testing on the laptop panel alone exercises the easy path and proves
nothing.

Guardrails from `04-plan.md`: snapshot before each trial, never trial two slots
at once, keep a second TTY and the `linux` kernel entry reachable.

Rollback target: the snapshot described `phase2-base`, created with no cleanup
algorithm so retention will never delete it.

### Session 3: Hyprland, `trying`

`hyprland kitty xdg-desktop-portal-hyprland` installed and running. Full detail
and gotchas in `CHOICES.md`'s `compositor` and `font` rows; summary:

- **Launch with `start-hyprland`, never the bare `Hyprland` binary.** The bare
  binary runs, config loads, both monitors come up, `hyprctl binds` shows
  keybinds registered — but every keypress leaks through to the raw VT as
  literal text instead of reaching the compositor. `start-hyprland` (the
  package-provided entrypoint) fixes it outright.
- **Hyprland 0.56 configs are Lua now**, not the old `.conf` syntax —
  `~/.config/hypr/hyprland.lua`, seeded from the stock
  `/usr/share/hypr/hyprland.lua` example for this trial.
- **External-monitor test passed**: `eDP-1` (Intel panel) and `HDMI-A-1`
  (NVIDIA port) both render correctly as an extended desktop simultaneously —
  the hard multi-GPU case this machine exists to prove out.
- 03-alternatives.md's Hyprland/hyprlock-hypridle rows were **wrong** and have
  been corrected: the predecessor repo does not carry the Hyprland
  keybinds/window-rules/lock/idle config — that lives in Omarchy's own default
  layer, which does not exist on this machine. All of it gets written fresh in
  Phase 4.
- **Font picked**: Fragment Mono (`ttf-fragment-mono`), size 18, ligatures off
  (`disable_ligatures always`) — measured, not assumed, that this fully
  eliminates ligature shaping cost (37ms/16% worst-case over a 200k-line flood,
  landing within noise of a font with no ligature table at all). Local-only so
  far: `~/.config/kitty/kitty.conf` on the test box, not committed to the repo.
  Now that dotfile deployment is settled as **symlink**, this is one of the files
  that should start flowing back.

**Not yet done**: niri and sway haven't been tried. No measurement yet against
either — Hyprland is `trying`, not `picked`. **Nothing has ever measured a
*running* desktop** — every checkpoint so far is TTY-idle, so the cost of a live
compositor session is the largest unmeasured number in the project.

### Session 4 (2026-08-19): scope cut, audio/bluetooth, Jupyter closed

The largest change was **scope**, not a package: the base install is delegated
to `archinstall` and this repo is now **post-install only** (`CHOICES.md`
`base-install-method`). That deleted all partitioning code, the disk-mode split,
and most of the Phase 5 VM matrix. `04-plan.md` gained Phase 6 for the desktop
migration. Both foundational open decisions are now closed.

**One of the three headline gripes is fully closed.** Jupyter-in-Neovim works:
the test was staged deliberately — terminal protocol, then python→PNG, then
molten — so each layer was proven before the next was built. Plots render
inline and arbitrary expressions evaluate. `~/t-jupyter` and `~/t-molten` on the
laptop reproduce it.

Also settled: audio (`pipewire-audio` + `realtime-privileges`, not `rtkit`),
bluetooth promoted to core, terminal → kitty, `terminal-navigation`,
`dotfile-deployment` → symlink, `documentation` → man-db reversed to `picked`,
plus swap/zram, firmware, microcode, firewall, clipboard, shell, and
`luks-header-backup`. Benchmarks renamed to `<phase>.<test>.name`.

**Three working rules were added to `CLAUDE.md` this session, all earned by
real bugs — read them before writing Phase 4 code:**

1. **Parsimony is about runtime cost, not disk.** Rejecting `man-db` on size
   broke kitty's default pager on every fresh install, because `less` arrives
   as its dependency.
2. **Fail loudly; do not degrade silently.** The predecessor's inline-image gate
   worked exactly as designed and never said so — which is the entire reason the
   Jupyter gripe went undiagnosed for years.
3. **Verify by exercising, not by reading.** Three bugs this session (`less`
   missing, the Jupyter runtime dir missing, images silently off) were invisible
   to config review and appeared the moment someone pressed the key. Assumptions
   about what already exists are this project's characteristic defect — worth a
   deliberate Phase 4 pass asking what our configs invoke that we never install.

*(Session 5 — niri, the portal, `polkit`, `cursor-theme`, earlier on
2026-08-20 — has no section of its own; its results are in the "Closed on
2026-08-20" paragraph at the top and in `benchmarks/3.2.compositor-idle.md`.)*

### Session 6 (2026-08-20, late): browser closed, and a measurement technique worth reusing

The `browser` slot went from "no row at all" to closed in one sitting, because
the author already knew what he wanted: **`brave-bin` is a hard requirement**
(his favourite) and **`chromium` is the deliberate small fallback** for the
occasions Brave cannot load a site. Firefox is out. Both are installed on
`bunne-test`. What actually took the time was the *test*, and it produced three
findings that outlive the browser question.

1. **The Omarchy "GPU hack" was never a GPU hack.** Reading the predecessor's
   `scripts/brave-with-gpu.sh`, all it did was wrap Brave in
   `--ozone-platform=wayland` — no GPU flag anywhere. And it is now unnecessary:
   run with **no `brave-flags.conf` at all**, Brave passes
   `--ozone-platform=wayland` to its own children and picks
   `--render-node-override=/dev/dri/renderD128` by itself. **So this repo ships
   no flags file** — an upstream default that is already correct gets left alone.
   The `/usr/local/bin/brave-wayland` wrapper is dead code and is not ported:
   `/usr/bin/brave` already sources `~/.config/brave-flags.conf` itself.
2. **`/proc/<pid>/fdinfo` is the right way to prove GPU use, and `chrome://gpu`
   is not.** The kernel counts GPU engine time per DRM client, so
   `drm-engine-render` / `drm-engine-video` are ground truth: Brave showed
   `drm-driver: i915`, real render time, and **204 ms of video-engine time** on
   a played video. **The trap that cost this session an hour: one process opens
   the render node several times and gets several `drm-client-id`s** — a render
   client *and* a separate decoder client. Reading a single fd showed
   `video: 0` forever while decode was in fact running on another client of the
   same pid. `~/t-video-decode` now sums across deduplicated client ids; reuse
   that shape for any future GPU claim. Related gotcha: the "is swiftshader
   mapped?" check in `~/t-brave` is **weak evidence on modern mesa**, because
   llvmpipe now lives inside `libgallium.so` rather than its own `.so`.
3. **A ledger row claimed packages that were never installed.** `gpu-driver`
   had listed `vulkan-intel` and `intel-media-driver` as picked since
   2026-08-18, but `/var/log/pacman.log` shows **neither ever hit the disk** —
   an intention recorded as a fact, invisible for two days because nothing
   exercised the video path. Corrected: `intel-media-driver` stays
   (Intel-conditional, and *measured* — `iHD_drv_video.so` is loaded by Brave's
   GPU process, 1.8 MB PSS); `vulkan-intel`, `libva-utils` and
   `libva-nvidia-driver` were installed, measured, found to be mapped by **no
   process at all**, and removed. `libva-nvidia-driver` stays a live question
   for the **NVIDIA-only desktop**, where it would be the only VA-API path —
   decide it there with `nvidia-smi --query-gpu=utilization.decoder`, do not
   inherit this laptop's answer. **Worth a Phase 4 sweep**: other rows may
   list packages nobody ever installed either.

**Numbers.** Brave with one window and two tabs: **540 MB PSS across 9
processes, plus 74 MB of i915 GEM buffers** that never show up in PSS. The GPU
process is 130 MB of that, and **32.9 MB of it is `libnvidia-gpucomp` +
`libnvidia-eglcore` for a GPU Brave never touches** — glvnd dlopens every vendor
in `/usr/share/glvnd/egl_vendor.d/` during EGL init. That is a hybrid-laptop
artifact only (on the NVIDIA-only daily driver those libraries do the work), so
it is recorded, not fixed. Note also that **render-node numbering is the reverse
of card numbering here**: `card0` is NVIDIA but `renderD128` is Intel.

**Format debt, found 2026-08-21 while adding the `disk-unlock` rows — the
installer's documented package line is currently broken.** `05-choices.md` says
the core package list is `awk -F' *[|] *' '$5=="picked" && $4!="—" ...'`, and
**four settled rows put prose in the `Packages` column**: `rollback-method`
(`— (no package)`), `dotfile-deployment` (`— (no manager)`), `luks-header-backup`
(`— (cryptsetup already present)`) and `terminal-navigation` (`— (no packages)`).
None equals a bare `—`, so all four survive the filter and the generated list
contains four entries that are not packages — `pacman -S "— (no package)"`.
The new `disk-unlock` rows use a bare `—` and put the explanation in the `Note`,
which is the convention that works. **Two valid fixes and it is the author's
call**: normalise those four cells to `—`, or widen the filter to `$4 !~ /^—/`.
Prefer the first — the point of the column is that it is data. Related: the
`browser` row's `Note` contains a literal `|`, which splits it into 15 fields
instead of 7; any future parser reading `$7` gets a truncated note.

**Format debt this created.** `gpu-driver`'s Packages column now reads
`mesa; **on Intel iGPUs additionally** intel-media-driver`, i.e. English inside
a column whose entire justification is that one `awk` line reads it. The
`microcode` row already does the same (`amd-ucode **or** intel-ucode`).
Vendor-conditional packages need a real convention in Phase 4 — a column or a
slot-name prefix — not prose.

### Session 7 (2026-08-21): priorities corrected, and the desktop became usable

The longest session so far. It started as a documentation fix and turned into
seven closed slots, because the corrected priority finally made latency
measurable and measuring it kept overturning things.

**What closed.** `disk-unlock` (manual LUKS passphrase; **TPM2 rejected**),
`benchmark-unlock` (a keyfile so boot time is measurable at all), `terminal`
(**kitty**, with ghostty, foot and alacritty all `rejected` on measurement),
`agent-clis` (**claude only** — codex, gemini, copilot, opencode dropped),
`polkit-agent` (**mate-polkit**), `lock-idle` (**swaylock + swayidle**),
`config-validation`, `remote-desktop`. Plus `fuzzel`, `swaybg`, `mako`,
`cliphist` installed and acceptance-tested.

**The Hyprland contamination audit.** Three slots in a row turned out to be
ranked *because a candidate integrated with Hyprland*, which is `rejected`. Swept
all of `03-alternatives.md`: only two #1 rankings were actually wrong
(`polkit-agent`, `lock-idle`), both now fixed; `hyprshot`/`hyprpaper` sit at #2
behind non-Hyprland winners and are harmless. **The opposite direction was also
checked and is clean** — most winners are wlroots-era tools and niri is Smithay,
but niri advertises all seven protocols they need.

**Measurement lessons, all learned the hard way and worth not relearning:**

1. **Single samples lied three times.** `walls` at 98.7 ms was a cold-cache first
   run (really 20.8 ms); niri's 4.430 s `graphical.target` was first-boot-after-
   `mkinitcpio` noise; a 460 ms cost was chased as per-terminal when it was
   per-login. **New rule already in `benchmarks/3.3`: discard the first boot after
   any initramfs regeneration.**
2. **Summing RSS overcounts by 36%** (610 MB vs 389 MB PSS on the live session).
   Use PSS. `BUDGET.md`'s per-process rows are labelled upper bounds until
   re-measured.
3. **The desktop is not a quiet machine** — load average 32.5 on 24 cores during
   the shell benchmarks, inflating everything ~2.5x. Record `uptime` with any
   desktop timing; prefer `bunne-test` for absolute numbers.
4. **A stale install corrupts the next comparison.** Hyprland was still installed
   despite being `rejected`, which made `hyprlock` look like it cost 2 packages
   instead of 7. Phase 3's "`pacman -Rns` the loser" is not housekeeping.
5. **`niri validate` is necessary but not sufficient** — it compares keybinds as
   literal strings, so `Super+Ctrl+L` and `Mod+Ctrl+L` look distinct while being
   one chord. Hence `scripts/check-keybinds.sh`.

**niri's memory was investigated and cleared.** 305 MB looked alarming; its own
heap is **30 MB**, and 241 MB is shared libraries paging in lazily. **90 MB of
that is NVIDIA libraries doing no work** (`fdinfo`: `driver=i915`, NVIDIA engines
at 0 ns) — a hybrid-laptop artifact, so **`bunne-test` overstates compositor
memory for the real target**. Re-measure on the desktop in Phase 6.

**Configs are now in the repo** (`config/`), closing a standing risk: the entire
working niri setup existed only on a machine Phase 5 wipes.

## Still open, on purpose — do not settle as a side effect

*(Both foundational decisions are now closed. Dotfile deployment settled as
symlink; the Ventoy artifact dissolved into "pinned stock Arch ISO" once the
base install was delegated — see the note below.)*
- **Encryption as an installer variable** — Phase 5's VM runs want unencrypted
  installs for fast iteration, real machines want LUKS. Decide in Phase 4; do
  not invent the flag before then.
- **Lite vs. full install** — newly raised 2026-08-19. Lite: any Arch-compatible
  PC, the user's workflow, no data-science tooling required. Full: lite plus
  Docker, Spotify, Jupyter-in-Neovim, etc. Not much harder than full-only if
  package lists are tagged critical-vs-extra as they're written; `choices.tsv`
  needs a column for this before Phase 4 scripts exist. See `CHOICES.md`
  `install-profile` row.
- **Docker storage cap** — newly raised. User has hit full-disk crashes from
  Docker image bloat before and wants a hard ceiling so a container/image pull
  fails instead of the whole disk filling. Candidates: `overlay2.size=` in
  `daemon.json` (needs xfs-backed overlay2, check against btrfs), or a
  size-capped btrfs subvolume + qgroup for `/var/lib/docker` (matches the
  predecessor repo's docker-on-its-own-subvolume item). Only relevant to the
  full install. See `CHOICES.md` `docker-storage-quota` row.
- **Memory headroom / OOM protection** — newly raised, same incident as above:
  ran fully out of disk+memory and everything crashed simultaneously.
  `systemd-oomd` (in systemd already, no new daemon) kills the worst offender
  under memory pressure before the kernel OOM-killer thrashes. Pair with
  zram/swap sizing. See `CHOICES.md` `oom-protection` row.
- **Jupyter rendering in Neovim — half solved 2026-08-19.** The *terminal* layer
  is proven: `kitten icat` and an inline matplotlib plot both rendered under
  Hyprland (`~/t-jupyter`, `CHOICES.md` `terminal`). So the predecessor's broken
  notebooks were **alacritty's** fault — no graphics protocol at all — and kitty
  already fixes it. **What remains is entirely inside Neovim**: molten and
  image.nvim. Next step is stage 3 of that test — a real notebook in Neovim —
  which is now worth building because the layers beneath it are known good.
  **No JetBrains products (PyCharm, DataGrip) in this repo's install.**
- **Editor bake-off scope** — add NVChad as a second candidate alongside
  LazyVim (currently the user's only experience). Also diagnose why
  find-references is slow in LazyVim before assuming a different editor
  fixes it — likely layers are Telescope UI, ripgrep, or the LSP server
  itself; isolate which one before concluding it's an editor problem.
- **`direnv` + per-directory terminal display** — newly raised. `direnv`
  (`extra/direnv`, single static binary, no daemon) is not Omarchy-specific,
  install it directly. Design as two layers: real per-project env vars stay in
  `.envrc` as today; a separate small user-editable mapping file
  (path-prefix → display profile) drives visual changes (kitty tab color/title,
  prompt color) via a `$PROMPT_COMMAND` hook that fires only on directory
  change, e.g. `~/tradeswell` (work) vs. personal dirs. Optional/adjustable
  config, not hardcoded, per the user's request. See `CHOICES.md`
  `dir-aware-display` row.

- **ASCII bunnies** — newly raised 2026-08-19. Flip-book rabbit animations as
  ricing. Deferred deliberately: the design rule (no animation may own a process
  that outlives it) and the four viable placements are in `CHOICES.md`
  `ascii-bunnies`, but it is Phase 4 step 5 and should not be built until a
  *running* desktop has been measured — it is the reward for hitting the idle-RAM
  number, not a withdrawal against it.

- **`vapoursynth` — reopen it** (author, 2026-08-21). It is **79% of the
  per-login budget** (64 ms fresh, 460 ms on the mature desktop) and buys nothing
  anyone chose. He is not convinced it is both unnecessary and unremovable, and
  the record supports the doubt: what was proven is that `pacman -Rp` fails and
  that `NoExtract` works but hides a file from a package that still owns it. What
  was **never tested**: whether anything breaks with `VSSCRIPT_PATH` simply
  unset; whether a fresh BunnE install pulls `vapoursynth` in at all (on
  `bunne-test` `ffmpeg` arrived via the portal chain, not via `mpv`); whether any
  Arch `ffmpeg` variant ships without `--enable-vapoursynth`. **Nothing links
  `libvapoursynth`** — not ffmpeg, not libavformat, not mpv — so the declared
  dependency looks simply wrong, which makes this an upstream bug report rather
  than a local workaround. `CHOICES.md` `shell-startup` is `rejected` for the
  *NoExtract approach*, not for the problem. Full brief in
  [`BUDGET.md`](../BUDGET.md) under "Open re-investigation".
- **Backup — now a blocking prerequisite, not a wishlist item.** There was no
  backup story anywhere in the docs; snapshots share the LUKS volume with the
  data, so one dead NVMe takes both. Phase 6 cannot start without a *restored
  and booted* backup. See `CHOICES.md` `backup`.
- **Desktop portals** — screen sharing is core (C4) but no row ranked the
  portals, so the choice would default to whatever arrives as a dependency.
  See `CHOICES.md` `desktop-portals`.
- **Secrets bootstrap** — how API keys and `~/tradeswell`'s `.env` values reach a
  new machine without being committed to a repo other people install. Ties into
  dotfile deployment. See `CHOICES.md` `secrets-bootstrap`.
- **Load protection** — the other half of the OOM story: keeping the desktop
  responsive *during* a training run or Docker build, via systemd cgroup weights
  rather than a package. See `CHOICES.md` `load-protection`.

## Decided 2026-08-21

- **Priorities corrected** — priority 2 is **2a fast, then 2b light**, speed
  winning by a soft preference and the conflict always stated out loud; **disk
  space is not a criterion**; fewer packages remains a preference in service of
  both, never a metric of its own. `CLAUDE.md`, `02-functionality.md`,
  `03-alternatives.md`, `04-plan.md`, `05-choices.md`.
- **C2 tightened to *exactly* one credential prompt** — not zero, not two.
  The author's reasoning: zero prompts is not a fast login, it is no
  authentication.
- **`disk-unlock` settled — manual LUKS2 passphrase, autologin after it, and
  TPM2 auto-unlock `rejected`.** Both rows are in `CHOICES.md`. The author's
  reasoning: he will not take a permanent security hole to save 15 seconds of
  dev time on the OS, and unattended reboot — TPM2's only real benefit — is
  worth nothing when the test laptop is sitting next to him. **This is the row
  that lets `display-manager` take a zero-prompt login**; the two move together.
  **Expect the boot numbers to keep arguing for TPM2** and do not re-derive it
  from them: the passphrase wait is why the `kernel` phase measured 30.026s and
  5.988s on consecutive boots, which is a measurement inconvenience, not an
  argument. Use `userspace`/`graphical.target`.
- **`display-manager` re-ranked, not yet closed** — greetd's `initial_session`
  gives a zero-prompt boot *and* keeps a greeter for when the session exits, so
  the speed-vs-safety trade this slot was ranked on mostly does not exist. Two
  facts in the old row were wrong: greetd is in **`extra`**, not the AUR, and it
  does **not** exit after login — it is a daemon (`Restart=always`), so the
  unsourced "~2 MB" is a resident cost that still needs measuring. That
  measurement is what closes the slot.

## Decided 2026-08-19

Written into `CHOICES.md` this session. Most needed no hardware evidence; several
were reconciliations of decisions that already existed in `03-alternatives.md`
but had been re-opened by mistake.

- **`audio`** — this was missing from every doc. The test laptop **cannot play a
  sound**: it has `pipewire` only because `xdg-desktop-portal-hyprland` depends
  on it, and no session manager. Picked `pipewire-audio` + `pipewire-pulse` +
  `wireplumber`; take the metapackage, because it carries the Bluetooth codecs.
- **`bluetooth`** — promoted to a core requirement at the user's request; it was
  ranked in `03-alternatives.md` but required by nothing. 6.8 MB, one daemon.
- **`swap-zram`** — and a **Phase 2 gap found**: the laptop has *zero* swap and
  no zram, though `04-plan.md` Phase 2 step 2 lists it. This also disarms half of
  `systemd-oomd`, which needs swap for its pressure path.
- **`firmware-set`** and **`microcode`** — both now vendor-conditional and both
  consequences of earlier decisions that were never written down.
- **`python-env-manager` → uv**, **`firewall` → nftables** (closing a stale
  `03-alternatives.md` row that still ranked `ufw` first), **`clipboard`**
  (measured: the "daemon" is a 2.1 MB `wl-paste --watch`), **`shell` → bash**,
  and **`luks-header-backup`**.
- **`desktop-migration`** — confirmed by the user: when the time comes, Omarchy
  is **removed**, not run alongside. Reformat `p2` (591 GiB) in place and install
  BunnE into it. No partition-table operations, NTFS never touched, and the only
  bootloader question is Windows vs. BunnE — so there is no ESP namespacing or
  anti-clobber machinery to build. **Do not shrink a partition on the desktop.**
  Two rejected alternatives and the disk layout are in `CHOICES.md`.
- **Phase 6 gate, the user's own condition:** `p2` is not touched until the
  laptop has been *proven* adequate as an emergency DS machine — a full day of
  real work on it with the desktop powered off. See `04-plan.md` Phase 6 step 1.
- **`install-disk-mode`** — author's correction 2026-08-19, and a drift worth
  watching for: the docs had started treating "dual-boot with Windows on a full
  disk" as the model, when it describes **one machine**. Windows is optional and
  usually absent — a new ThinkPad/Framework and anyone installing this for the
  rice get a bare disk. **Superseded the same day by `base-install-method`**:
  the base install is delegated to `archinstall`, so disk modes are choices in
  its config, not code here. This repo is **post-install only** and performs no
  destructive disk operation at all.
- **`base-install-method`** — the largest scope reduction in the project.
  `archinstall` (verified to support limine and the ESP-at-`/boot` layout) does
  partitioning, LUKS2, subvolumes, `pacstrap` and the bootloader from a
  checked-in JSON config pinned to a specific Arch ISO named in `README.md`.
  `install.sh` then turns vanilla Arch into BunnE. Deleted: all partitioning
  code, the disk-mode split, the never-format-the-ESP rule, the destructive
  dry-run, and most of the Phase 5 VM matrix. Added: the JSON config, and
  **prerequisite checks in `install.sh`** — the base is no longer ours to
  guarantee.
- **Dropped:** laptop power management. The user does not care about battery.
- **Dropped:** the whole BunnE-vs-Omarchy coexistence problem, along with the
  bootloader namespacing it would have required. It only ever existed to serve a
  side-by-side test drive that is no longer part of the plan.

## How Claude should work here

- User drives installs by hand for editorial control and understanding; Claude
  advises step by step. **Diagnosis and measurement are Claude's to run
  unprompted** on `bunne-test` — see "Working split" above, widened 2026-08-21.
  The first real 2a finding of the project (`shell-startup`) came out of exactly
  that: a measurement nobody asked for.
- **Record `uptime` with every timing taken on the desktop, and prefer
  `bunne-test` for absolute numbers** (author, 2026-08-21). The desktop is his
  *working* machine and runs CPU-heavy ML training alongside this project — it
  measured **load average 32.5 on 24 cores** during the shell benchmarks. Same
  primitives on the idle laptop came in **2.3–2.9x faster**, so every desktop
  figure in `benchmarks/3.4` and `3.5` is inflated by roughly 2.5x. Relative
  comparisons survive because the inflation is near-uniform; absolute numbers do
  not. Note the bias *flatters* fork-free recommendations, since forking suffers
  more under contention — a reason to read those results sceptically rather than
  credulously.
- **Verify against primary sources on the box, not memory.** This session that
  meant reading `/usr/lib/initcpio/functions` and `install/kms` rather than
  guessing — and it caught a wrong suggestion (`MODULES=(!nouveau)`; mkinitcpio
  has no exclusion syntax, only a trailing `?` for optional). **`man-db` is now
  `picked`** (reversed 2026-08-19 — it is 2.5 MiB, and 120 MB of man pages are
  already on disk with no reader), so `man` is a primary source again. It is not
  yet installed on `bunne-test`; until it is, read package sources and shipped
  configs directly.
- **Write decisions into `CHOICES.md` immediately**, including rejections and
  blocks, so nothing is re-derived under pressure. **Then check the row is
  true** — the `gpu-driver` row listed two packages that were never installed
  (session 6). A Packages column is a claim about the machine, not a wish.
- **To prove a package is doing something, find what maps or opens it**, not
  what an app's own status page says. The tools that worked: `/proc/<pid>/maps`
  (is the library even loaded, and what is its PSS?), `/proc/<pid>/fd` (which
  device nodes are open), and `/proc/<pid>/fdinfo` (per-DRM-client GPU engine
  time). Three of the four VA-API/Vulkan packages installed in session 6 turned
  out to be mapped by **no process on the machine**, which no amount of reading
  documentation would have revealed.
- Do not write installer scripts before the decisions exist (Phase 4) — this
  does not apply to throwaway test/trial scripts (see next point), only to the
  real installer.
- **For anything the user has to run by hand on the laptop, write it to a
  small script in `~` on `bunne-test` (e.g. `t1`, `t2`) instead of a copy-paste
  chat block**, when there's more than one command or it's likely to be reused
  or edited across a few tries (a benchmark run, a multi-step trial). The user
  can inspect/edit it before running and it's re-runnable without re-pasting.
  A single one-off command is still fine as a plain command. These are scratch
  files, not part of the repo.
- **Every such script must tee its output to a log file**, so Claude can read
  the result over SSH instead of the user copy-pasting it back. First line after
  `set -Eeuo pipefail`:
  `LOG="$HOME/log-${0##*/}.log"; exec > >(tee "$LOG") 2>&1`
  Logs are named **`log-<script>.log`, never `<script>.log`** — the user's
  request, 2026-08-19: with the scripts named `t-*`, a log called `t-*.log`
  lands in the same tab-completion as the script itself. Deriving the name from
  `$0` keeps the two in sync automatically. Read them with
  `ssh bunne-test cat '~/log-t-<name>.log'`.
