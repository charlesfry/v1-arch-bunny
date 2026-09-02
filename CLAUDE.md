# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **STALE — transplant in progress (started 2026-09-02).** This repo is being
> rebuilt as a variant of [viacoffee/dotfiles](https://github.com/viacoffee/dotfiles),
> whose boot, session and network configuration are taken as authoritative over
> anything decided here. Everything below describing `install.d/`, `CHOICES.md`
> as the package source of truth, the `archinstall-*.json` three-way check,
> `BUDGET.md`, or the benchmark ledger is **void** — those files now live in
> [`docs/archive/`](docs/archive/) as history, not as instructions. The new shape
> is `install/` (sourced numbered phases), `install/packages`, `install/default/`,
> and stow-managed `home/`, `config/`, `local/`. Rewrite this file once the
> transplant lands; until then, prefer the actual tree over any claim made here.

## What this repo is

`arch-bunny` is a personal Arch Linux configuration — dotfiles plus the provisioning to reproduce
them. The goal is to get a machine **from zero to BunnE in a minimal, maintainable number of quick
steps**. Target workload is data science.

The original goal was a *single file droppable onto a Ventoy USB*. **That constraint was
deliberately relaxed on 2026-08-19 to cut scope**, and the relaxation is the point rather than a
regret: the base install is now delegated to `archinstall` driven by a checked-in JSON config
pinned to a specific Arch ISO, and this repo does **post-install only** — `install.sh` turns a
vanilla Arch into BunnE. Hand-rolled partitioning worked on one test machine but was unproven
anywhere else, which is the priority-1 risk; anyone willing to try this repo can already install
vanilla Arch. `README.md` carries the setup steps and names the exact ISO. See `CHOICES.md`
`base-install-method`.

Two audiences: primarily the author's own workstation (opinionated tastes need no justification or
config toggles), secondarily friends who install it to see the rice — so keep personal details
(username, hostname, keys, monitor layout) isolated and overridable rather than spread everywhere.

**Employer and client work never appears in this repo, full stop** (author, 2026-08-27): no VPN
config, no shell alias, no path reference, nothing naming an employer or client anywhere a friend
installing this repo would see it — stronger than the personal-details rule above, which allows an
overridable placeholder; this one allows nothing. `secrets-bootstrap` in `CHOICES.md` is the row
this came from. Where the author's own workflow needs one of these (a work VPN, a per-project
`.envrc`), the repo carries at most a generic mechanism — never the specific name.

**Default Linux username: `bunne`.** This is what the installer creates and what friends installing
the repo will see — part of the bunny branding, not incidental. (The author's own in-progress test
box currently has a `char` account from before this was decided; that's a one-off, not the pattern
to follow.)

## Design priorities

In this order. When two conflict, the lower number wins.

1. **It just works.** A fresh install boots into a usable desktop with no manual repair. Prefer a
   boring option that survives an update over a clever one that breaks.
2. **Fast and light, like its namesake.** Two metrics, in this order:

   **2a. Fast — the time between pressing a key and the intended thing having happened.**
   This is the headline metric of the whole project. It means *perceived* latency along the paths
   actually used: keystroke to glyph, keybind to window on screen, `Enter` to prompt back, cold
   app launch, power button to a desktop that accepts input. Given a choice between fast and nice,
   choose fast ~99% of the time.

   **2b. Light — total RAM in use.** Idle RAM is the number to watch, because a resident process
   costs it forever for a service used a few times a day. No heavyweight DE services, no
   always-running daemon that could be a keybind, Wayland-native and compiled over Electron and
   interpreted.

   **2a beats 2b when they genuinely conflict** — a soft preference, not a rule, and one that has
   to be *said out loud*: when a pick trades RAM for responsiveness, state the trade and the size
   of it in the `CHOICES.md` note, and let the author decide. A silent trade is the failure mode
   here, not a wrong one. Most of the time they agree — a daemon that isn't running is both
   faster to nothing and lighter — which is why older rows saying "priority 2" without a letter
   are still correct.

   **Disk space is not a metric.** See the parsimony rule below.
3. **Bunny themed.** Matte black, ASCII, neon accents, futuristic / cyber-bunny. Theming is a
   first-class feature, not bolted on last — colors come from one shared source so a palette change
   propagates everywhere.

2 and 3 pull against each other; resolve toward 2. Achieve the rice with config, shaders, and ASCII,
not with resident processes.

**Every runtime cost that survives a decision goes in [`BUDGET.md`](BUDGET.md)**, bucketed by how
often it is paid — per prompt, per terminal, per login, per boot, resident RAM. Buckets are never
summed with each other: 1 ms in the prompt bucket is worth ~200 ms/day, 1 ms in the login bucket is
worth 1 ms/day, and conflating the two wasted most of a session. The point is that features which
are individually imperceptible can aggregate into a slow machine, and the only defence is a running
tally that can be reviewed as a group instead of defended one row at a time.

**Measure both halves, and beware the asymmetry**: idle RAM is trivial to measure, latency is not,
so the ledger fills up with RAM numbers and decisions quietly get made on the metric that was easy
to collect. If a slot sits in the interactive path, a `Measured` column with no time in it is an
incomplete argument — say so rather than letting the RAM figure stand in for the answer.

## How to work in this repo

The author wants to **understand every line here** — no vibe coding. This outranks convenience.

**This is a quality gate for priority 2, not a matter of taste.** A line the author cannot explain
is a line nobody has checked against fast-and-light, and unexamined code is where the suboptimal
choice hides: the daemon that did not need to be resident, the fork on every prompt, the config
restating a default. Comprehension is how the priorities actually get enforced, so anything that
trades understanding for speed of delivery is trading away the thing that keeps the system fast.
If a line cannot be justified in the currency of priority 2 — this is what it costs at idle, this
is the latency it removes — it has not been justified.

- **Parsimony is the point**, for the same reason. The best code is code we don't have to write;
  the best change to a file is removing unneeded lines. A line that isn't there costs no RAM, adds
  no latency, and cannot be misunderstood. Prefer deleting to adding.
- **Parsimony is about runtime cost and complexity, not disk.** Priority 2's metrics are latency
  and RAM; neither one is megabytes on a 1.8 TB drive, and Arch is lean on disk without anyone
  working at it. **Disk usage is not a decision criterion here.** It appears in this repo in
  exactly one form — running *out* of space, which is a priority-1 "it just works" failure and the
  reason `C9` exists — and that is a story about Docker images and snapshot retention, not about
  whether a package is 3 MB or 30 MB. Do not reject a thing for its install size, and do not
  present a size figure as an argument.
  **Fewer packages is still a real preference — but as a means, never as the metric.** Every
  package is one more thing to audit against 2a and 2b, one more thing that updates and can break
  priority 1, and one more thing whose defaults nobody has read. That is a *complexity* argument
  and it is the parsimony rule doing its job; it is not a disk argument wearing a different hat.
  The test that separates them: if the objection survives the machine having infinite disk, it is
  the complexity argument and it counts. If it evaporates, it was the disk argument and it does
  not. A package that runs nothing, is understood, and is commonly assumed to exist fails that
  test — it adds essentially no audit surface, which is why the bar for it is low.
  So a package that is small, costs **nothing at boot and nothing at idle** (no daemon, no
  autostart, no timer), and is **commonly assumed to exist on an Arch machine** should face a
  *low* bar, not a high one — lean toward installing it. Anything that runs at startup, adds a
  resident process, or sits in the interactive path still faces the full priority-2 argument,
  unchanged.
  **`man-db` is the cautionary example** (see `CHOICES.md` `documentation`): rejected on a
  misread cost, which then broke kitty's default `scrollback_pager less` on every fresh install,
  because `less` arrives as a man-db dependency. That is the real hazard — omitting a
  commonly-assumed tool does not merely remove that tool, it **silently breaks unrelated things
  that assume it exists**, and those failures surface far from the decision that caused them.
  **Always consult the author before adding a package on this reasoning** — the point is to lower
  the bar, not to remove it.
- **Hacky solutions are brittle solutions — parsimony includes the future** (author, 2026-08-24).
  A hack is usually hacky *because it goes against the grain of developer intention*, and things
  that fight upstream intent break — either today, in the normal course of events, or later, when
  upstream updates over them. Large hacks are doubly disqualified: harder for the author to
  validate line-by-line, and more likely to cause problems down the road. **We are not just
  optimizing Fast & Light for today; we are keeping it Fast & Light in the future.** The shape of
  a good fix is "choose this package over that package" or "change this supported config option
  from A to B" — not "lobotomize assumed functionality" or "write 50 lines of code to shave 2 ms
  off boot." The repo's own record already enforces this: `NoExtract` was rejected for hiding a
  file from a package that still owns it (`shell-startup`), the nix-side raw-drop-in fight against
  docker's unit was abandoned as not worth winning, and the vapoursynth per-login fork was left in
  place rather than hacked out. When the only available fix is a hack, prefer living with the cost
  or reporting the bug upstream — and if a hack is ever genuinely warranted, its brittleness is a
  named cost the author signs off on, not a footnote.
- Don't add abstraction, indirection, or a helper function for one caller. Don't add a config knob
  until something needs to vary.
- Don't generate a large file wholesale. Build in small reviewable pieces, and be able to justify
  each line — if a line's purpose can't be stated plainly, it doesn't go in.
- Upstream defaults that are already correct should be left alone rather than restated in a config
  file. A config file should contain only deviations.
- **Verify on the machine, never from memory.** Read the shipped source, config,
  and package files before asserting how something behaves — `/usr/lib/`,
  `/etc/`, a `PKGBUILD`. This has already caught wrong answers: mkinitcpio has no
  `MODULES=(!module)` exclusion syntax, only a trailing `?` for optional, which
  reading `/usr/lib/initcpio/functions` showed and recollection did not.
- **Fail loudly; do not degrade silently.** Graceful degradation is fine for cosmetics and wrong
  for anything `02-functionality.md` names as a requirement. If a stated capability cannot be
  provided, **say so at the point of failure, once, with the reason** — a feature that is off and
  silent is indistinguishable from a feature that is broken, and the user pays for the difference.
  **The cautionary example is the predecessor's inline-image gate** (`CHOICES.md`
  `jupyter-in-neovim`): `image_terminal()` correctly disabled `image.nvim` under alacritty, exactly
  as designed, and never announced it — which is the entire reason "Jupyter notebooks are a pain"
  persisted for so long undiagnosed. The config was not buggy; it was quiet.
  Distinguish the two cases when writing this: *expected* absence (a TTY, an SSH session, a
  terminal deliberately chosen without the capability) deserves one quiet line stating the reason;
  *unexpected* absence (the capability should be present and is not) is a real failure and should
  be impossible to miss. Prefer also exposing current state on demand — a `:checkhealth` entry or
  a status command — since a diagnosis nobody can run is not a diagnosis.
- **Never gracefully handle a condition that should never happen** (author,
  2026-08-28). A missing subvolume, a package we meant to install, a file we meant
  to create, a script this repo ships — every one of those is a hard, loud error, not
  a note and not a skipped step. The test is simple: *could this happen on a machine
  built the way `README.md` describes?* If no, it is a bug somewhere and must stop the
  run. If yes — no Windows on the disk, `gcalcli` not yet authenticated, a check that
  genuinely needs root the step deliberately does not take — then one quiet line
  stating the reason is right.
  The failure this prevents is specific and this repo has hit it: a step that says
  `? config unvalidated` and carries on has *rewritten the boot configuration and
  confirmed nothing*, and a `create-config` that falls through to snapper's own
  `.snapshots` produces a machine whose rollback appears to work until the day it is
  needed. **Anything we intended to create, verify; and when the verification cannot
  run, that is itself the failure.**

- **Prove it, do not infer it.** Treat any safety mechanism that has never been
  exercised as broken until demonstrated. `snapper rollback` looked correct and
  would have silently done nothing here, because the root subvolume is pinned by
  name in two places. What turned "should work" into "does work" was a canary
  file — a test designed to fail loudly if the mechanism did nothing at all.
  Prefer that shape of test whenever something is meant to protect you.

## Predecessor repo (feature source)

`~/github/dotfiles-omarchy` is the author's current machine setup and the **rough spec for which
features to carry forward** — keep the functionality, minimize the runtime cost. Read its
`README.md` and `CLAUDE.md` for the full map. Roughly: bash config, Hyprland config, alacritty,
a LazyVim data-science Neovim (IPython REPL, Jupyter/molten, conda venv selection, SQL, CSV,
Claude Code), Miniforge conda, OpenVPN alias generation, a disk-usage-alert systemd user timer,
docker-on-its-own-btrfs-subvolume, git config, de-bloat, and a hand-made `daemon` theme.

**The crucial difference:** that repo is a *layer on top of [Omarchy](https://omarchy.org)*, which
supplies the Hyprland defaults, the Quickshell desktop shell, and the theming system it overrides.
`arch-bunny` installs onto a bare machine, so that substrate does not exist. Some of the decisions
the author made were driven by compatibility with Omarchy, not necessarily because they were
optimal for his workflow. He is very unhappy with the current (broken) Jupyter notebook workflow
on his current Omarchy machine. Be skeptical of the necessity including many of these Omarchy
settings into the new Arch configuration. If you are confident that better configurations or
packages or alternatives (such as kitty instead of alacritty) are better suited for his
workflow, recommend changes. Remember that some of the author's customizations may have been made as a fight
against Omarchy, not because this is how he would have wanted an OS to be set up from scratch.

**Do not overindex to that repo.** In `dotfiles-omarchy` most design decisions were made *for* the
author and he is putting dressing on top; in `arch-bunny` he is building the whole thing himself.
Structural choices, the copy-in-place deployment, and the commitment to alacritty are all
Omarchy-driven artifacts, not considered preferences — the copy convention in particular exists only
because he was not yet comfortable with symlinks when that repo was built. Treat anything inherited
from there as evidence of a *want*, never as a settled design. **When unsure, or when something in
that repo looks suboptimal, ask the author rather than porting it** — he wants to understand every
line here, so a question is cheaper than an inherited mistake.

**His three biggest gripes with the current Omarchy setup** — fixing these is what the project is
for, so weigh them heavily whenever a decision touches them:

1. Docker images have no space cap and have filled the disk (`CHOICES.md` `docker-storage-quota`).
2. Snapshots contain far too much, Docker images included (`CHOICES.md` `snapshot-bloat`).
3. Jupyter notebooks are a pain to work with, forcing a PyCharm fallback he does not want
   (`CHOICES.md` — see the terminal/graphics-protocol and editor notes in `docs/resume.md`).

**Assume no Omarchy package is kept.** Every optional Arch package that repo pulls in gets
reassessed on its own merits against the priorities above, and a lot of its customization is
expected to be thrown out — much of it exists only to override Omarchy defaults that won't be
present here. Omarchy's choices are not automatically the lean ones (its Quickshell desktop shell is
exactly the kind of resident process priority 2 argues against). Treat the predecessor as a list of
*wants*, not of implementations or of dependencies.

Its conventions worth keeping: scripts are `#!/usr/bin/env bash` + `set -Eeuo pipefail`, idempotent
(check-then-install) so re-running is safe, and each provisioning step is a standalone script that a
master installer merely sequences.

## Conventions — write what a seasoned coder would expect

Unsurprising beats clever. Where a standard already exists, follow it rather than inventing a local
one; the reader should never have to learn this repo's private habits to follow along.

- **Respect the XDG Base Directory spec**, and read the variables rather than hardcoding their
  defaults: `${XDG_CONFIG_HOME:-$HOME/.config}`, `${XDG_DATA_HOME:-$HOME/.local/share}`,
  `${XDG_CACHE_HOME:-$HOME/.cache}`, `${XDG_STATE_HOME:-$HOME/.local/state}`. The repo itself lives
  at `${XDG_DATA_HOME:-$HOME/.local/share}/arch-bunny`.
- **`shellcheck`-clean and `shfmt`-formatted** (both in `extra`). If a warning has to be suppressed,
  suppress that one line with a comment saying why — never disable a check globally.
  **Both are development dependencies, not part of the BunnE package list** — they run where scripts
  are *written*, never on an installed machine, so they get no `CHOICES.md` row and the installer
  never mentions them. **`hyperfine` is the same category** (author, 2026-08-21): it is the
  instrument the priority-2a numbers are taken with, not something the finished machine needs, so it
  is installed on whatever box is being measured and **excluded from the final package list**. The
  general rule these three share: *a tool used to build or measure BunnE is not part of BunnE.* If
  one is ever wanted as a daily-driver tool in its own right, that is a separate decision needing
  its own row — not an inheritance from having installed it during development. Stated because this line previously did not say, and could reasonably be read
  as shipping them. They earn their place on a dev box the same way any linter does: shell fails
  silently and destructively — a `cd` that fails followed by an `rm`, or a `local x=$(cmd)` that
  swallows the failure `set -e` was supposed to catch — and this repo's installer runs as root on a
  fresh machine. shellcheck is the mechanical half of "understand every line": it catches the case
  where a line's stated purpose and its actual behaviour differ.
- **Never require `sudo ./install.sh`.** Run as the user and escalate per command, so it is obvious
  from reading which steps need root. A script that demands root for all of itself cannot be audited
  by someone deciding whether to trust it.
- **Informational output to stderr, data to stdout**, so a step can be piped without its own chatter
  corrupting the stream. Support `--help` and `--dry-run` on anything destructive.
- **Fail loudly and early.** Check preconditions up front rather than discovering them half way
  through a disk write — this is the same instinct as asking every installer question before the
  first destructive operation.
- Standard repo furniture is expected of anything strangers clone: `README.md`, `LICENSE`,
  `.gitignore`. **All three now exist** (2026-08-25: MIT, `Copyright (c) 2026 Charles Fry`).
  `README.md` states the pre-installer status honestly rather than describing a product that
  is not there yet; keep it that way as the installer lands.

## Current state

**Phases 0-3 are done; Phase 4 (harvest the picks into the repo) is where the work now is.**
Read [`docs/resume.md`](docs/resume.md) first — it carries current state, the two machines
involved, and what to do next. Decisions live in [`CHOICES.md`](CHOICES.md); measurements live in
`benchmarks/`.

As of 2026-08-26 the ledger holds **66 `picked` rows, 12 `deferred` and 7 `rejected`**,
against **40** benchmark write-ups and 22 instruments. The bake-offs that Phase 3 existed to
run — compositor, terminal, editor, picker, Arch-vs-NixOS — have all reported, and the
`snapshot-boot-entries` acceptance test **passed** on 2026-08-25 (`benchmarks/4.25`), which
was the last gate Phase 3 left open.

**`docs/open-questions.md` has nothing blocking left.** Two were answered 2026-08-26:
**26**, the Docker qgroup caps are dropped and the qgroups kept for accounting only (so for
Docker the `disk-alert` row is no longer the alarm on a wall, it *is* the protection), and
**27**, non-XDG settings are written by `install.sh` rather than tracked, so `config/` keeps
its `$XDG_CONFIG_HOME`-only layout and **the harvest is unblocked**. **28** is open but
measured (`benchmarks/4.29`) and wants only ratification: keeping btrfs quotas costs 0.355 s
per `subvolume delete` against 0.008 s, and they turn out to be what snapper's `SPACE_LIMIT`
retention runs on, not what the notification reads. Everything else is answered or parked.

**`bunne-test` reboots unattended** — `CHOICES.md` `benchmark-unlock` keeps a keyfile in the
initramfs precisely so it can, and `ssh bunne-test sudo reboot` (after `sudo efibootmgr
--bootnext 0001`, or it lands NixOS) is a free action. Only the **Limine menu keypress**
needs a human. An entire session was spent believing otherwise, which left boot-path edits
unverified when verification was one command away.

**`install.sh` exists and has twenty-six steps** — `ls install.d/` is the plan and no
manifest can drift. Steps are **executed, not sourced**, so a step cannot clobber the
sequencer; they are idempotent, which is the entire resume story (no `--from`/`--only`).
It refuses to run as root and refuses *before writing anything*, has `--dry-run` and
`--help`, logs each step's own output to `$XDG_STATE_HOME/bunny/install.log`, and names
the failing step on exit.

**The base install now carries most of the machine, and that is deliberate** (author,
2026-08-28): *"anything that can be in the configs almost certainly should be... we need
overwhelming evidence in order to keep something out."* And the reason it is not golf:
*"this is using standard procedures to generate our desired arch configuration, which
makes the entire repo more auditable and cleaner."* So **81 of the ledger's 86 packages
install via `pacstrap`** from the checked-in `archinstall-*.json`, along with
`network_config`, `app_config`, `services`, `locale_config`, `pacman_config`, `hostname`,
`bootloader_config.plymouth` and the btrfs subvolumes. Only five packages cannot move —
three AUR, two `[omarchy]` — and `20-packages.sh` enforces the agreement **three ways**:
nothing in a JSON the ledger does not claim, nothing eligible the JSON left out, and no
stale entry in the exclusion list.

**When weighing whether something belongs in the JSON, "it duplicates `CHOICES.md`" is
not an argument.** The JSON necessarily restates decisions that must happen before this
repo exists on the machine. What was ever wrong was *silent* divergence, and the
three-way check removes it. The only real grounds to keep something out are: a genuine
security hole (e.g. `TrustAll` on a third-party repo), genuinely per-machine data, a
mechanism archinstall lacks, or an option contradicting a decided row.
**`custom_commands` stays empty** — bash inside a JSON string is bash `shellcheck` never
sees, with no dry-run, no idempotence and no re-run.

**The most valuable audits found absences, not excesses.** Four services
(`NetworkManager`, `bluetooth`, `nftables`, `docker.socket`), the `docker` group, and
`gcalcli` were all required by `picked` rows and enabled or installed by **nothing** —
invisible because they had been done by hand on `bunne-test` months earlier. When
checking a row, ask *does anything actually do this* before asking whether it is done
well.

**Keep adding steps the same way — one feature, one row, small enough to read. And
exercise the write path, not just the no-op path**: on an already-provisioned `bunne-test`
every check reports `=` and the code that actually changes things never runs, which by this
repo's own rule leaves it broken until demonstrated. Deliberately breaking the state and
re-running is what found the `sudo -v`-under-NOPASSWD bug, the `set -e` AND-list bug, the
nondeterministic `limine.conf` ordering, the partial-upgrade hazard, and the preflight
check that silently missed its own target. **Every step so far has found a defect that way,
and none were visible by reading.**

**The three things a step must do:** implement only the ledger's *deviations* (diff against
the package's own copy before believing any single line is one — see the
`ParallelDownloads` correction), be idempotent, and **verify rather than assume** at the
end. Two live drifts were found purely by writing a step and comparing decided state to
actual: `snapper-timeline.timer` was enabled against a row that says it never should be,
and `ParallelDownloads = 5` was recorded as ours when it is upstream's default.

**Phase 4 output beyond the installer is** `config/` (dotfiles pulled from the working box), `scripts/` (the
config checks, the measuring instruments, and `prep-wallpapers.sh`), `assets/wallpaper/`
(22 bunny sources plus 52 derivatives at the three target resolutions), and two drafts
parked outside the shipped tree (`benchmarks/raw/p4-nvim-draft/`,
`benchmarks/raw/p4-disk-alert-draft/`). Keep building the installer the
same way: small reviewable pieces, each traceable to a `CHOICES.md` row, none of it generated in
one pass. There is no build or test command; `shellcheck` and `shfmt` are the lint gate for
anything under `scripts/` and `install.d/`, and they are development tools, never shipped
(see the conventions section).

**This block goes stale faster than anything else in this file, and stale state here has already
cost real work** — the 2026-08-25 morning report names five tasks that launched off superseded
"next" lines. When it disagrees with `CHOICES.md` rows, the DA tallies, or the newest files in
`benchmarks/`, **those win and this is the thing to fix.**

## Deferred decisions — do not settle these unilaterally

Nothing is open here right now — see history below for the shape of the rule. Both prior
foundational choices are settled; if a new one comes up, the pattern is: don't pick it silently as
a side effect of some other task, lay out the options, and let the author choose.

*Settled 2026-08-26:* shape of the Ventoy artifact — candidate B, said out loud. **Stock pinned
Arch ISO + this repo, no custom artifact.** Author: *"let's have them boot a stock arch iso and run
archinstall with a JSON config we give them."* The checked-in config is
[`archinstall-2026.08.01-wholedisk.json`](archinstall-2026.08.01-wholedisk.json), written against `archinstall`'s own
schema for the version shipped on that exact ISO (extracted and read from the ISO's own airootfs,
not guessed from docs — see `CHOICES.md` `base-install-method`) and rehearsed end-to-end in a local
qemu VM the same night, third attempt clean (`RUN3_EXIT:0`, "Installation completed without any
errors"): disk wipe, LUKS2 format, all five btrfs subvolumes, `pacstrap`, user creation all landed
exactly as configured. Two real things the rehearsal caught that reading would not have: `services:
["sshd"]` fails outright if `openssh` isn't also in `packages` (fixed, see `README.md`), and
`archinstall` 4.4 installs Limine to `/boot/EFI/arch-limine/limine.conf`, not the flat
`/boot/limine.conf` this repo's own `install.d/00-preflight.sh`/`50-limine.sh`/
`scripts/check-limine.sh` used to hardcode — **fixed 2026-08-27** with
`scripts/find-limine-conf.sh`, see `CHOICES.md` `bootloader`.
See `CHOICES.md` `install-artifact`.

*Settled 2026-08-19:* dotfile deployment was the other. It is now **symlink, via hand-rolled
`ln -sfn` in the installer** — no Stow, no chezmoi, no manager. See `CHOICES.md`
`dotfile-deployment`.
