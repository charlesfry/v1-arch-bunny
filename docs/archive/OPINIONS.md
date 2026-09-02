# Opinions

`arch-bunny` is opinionated on purpose — see `CLAUDE.md`: this is primarily the author's own
workstation, and "opinionated tastes need no justification or config toggles." This document is
the other half of that stance: a high-level tour of what is actually distinctive here and why,
for anyone who wants the shape of the thing without reading `CHOICES.md`'s hundred-plus rows.
Every claim below has a row and usually a number behind it — follow the links for the receipts.

## The one rule everything else follows from

Priorities, in order, from `CLAUDE.md`: **it just works**, then **fast** (perceived latency)
over **light** (idle RAM) when the two genuinely conflict, then the bunny theming. Two things
follow from this that are easy to get backwards:

- **Disk space is explicitly not a metric.** A package that is small, costs nothing at boot,
  and is commonly assumed to exist on Arch faces a *low* bar. The only disk failure mode this
  repo defends against is running *out* — a priority-1 "it just works" problem, never a
  priority-2 argument against installing something.
- **A slow, correct answer beats a fast, silent one.** Every "fail loudly" decision below —
  the prompt's dirty marker, the disk-alert's redesign, the notification path — traces back to
  this: a feature that is quietly off is indistinguishable from a feature that is broken, and
  the second one costs someone a debugging session months later.

## The prompt: measured against starship, then hand-rolled

**65.7 ms → 1.5 ms per prompt** (12.5 ms with the uncommitted-changes marker on). The rule that
produced the win: no `$( )` anywhere on the prompt path — a bare subshell alone cost more than
starship's entire replacement, on a 226-variable environment. Branch detection reads
`.git/HEAD` directly instead of forking git; the one command substitution that survives is the
dirty-marker's `git status --porcelain`, which is ~80× the cost of the rest of the prompt
combined and was kept anyway ("8ms is worth it") because seeing uncommitted work at a glance
outweighs a few milliseconds of a twenty-millisecond budget. Decided, not shipped as a toggle —
this repo doesn't ship config knobs for questions it has already answered. `CHOICES.md` `prompt`,
code at `config/bash/prompt.bash`.

## Docker's disk gripe, solved by a filesystem boundary instead of a limit

The predecessor setup let Docker eat the whole disk with no cap, and separately let snapshots
balloon because Docker's images were snapshotted right along with everything else. Both gripes
are the same bug: Docker's bytes were living in the same btrfs subvolume as the data being
protected. The fix is one subvolume boundary — `@containerd` and `@dockervol` mounted at the top
level, outside `@` — which makes Docker **structurally invisible to every snapshot of `@`**, no
snapper filter, no exclusion list to keep in sync. `CHOICES.md` `docker-storage-quota`,
`snapshot-bloat`.

**The qgroup byte-*limit* that seemed like the obvious next step was tried and reverted.**
Enforcing a hard cap on those subvolumes worked exactly as advertised — until a write collided
with an fs-verity rollback under the limit and forced the **entire filesystem** read-only,
because a qgroup limit is scoped to a subvolume but "forced read-only" is scoped to the whole
disk. Priority 1 ("it just works") beat the appeal of a hard guarantee: the cap is gone,
accounting stays on (it turns out snapper's own retention math depends on it anyway), and a
disk-usage alert does the job a hard limit was trying to do, without the failure mode.

## The disk-alert that got simpler on request

Three meters, five files, 183 lines, a root-owned helper binary, and a `NOPASSWD` sudoers entry
— because it needed root to read btrfs qgroup caps. The author's verdict: *"way too many lines
of code. simplify the hell out of it."* Rewritten to one `df` call: everything this repo worries
about (Docker images, volumes, snapshots, the package cache) lives in the same btrfs pool as
`/`, checked rather than assumed — `df -B1` reports identical used/size bytes across all of
them. **19 lines, 3 files, no root helper, no sudoers entry, no package.** Healthy-run cost went
from 3–6 seconds to **8.7 ms**. `CHOICES.md` `disk-alert`.

## No display manager

`greetd` was installed, driven for an evening, and removed: 6.8 MB resident forever, for a bare
text login on a TTY nobody looks at twice. `getty`'s autologin plus one guarded line in
`.bash_profile` (`exec niri-session`) does the same job for **0 MB and zero extra units**,
because getty is running anyway regardless of what greets you on it. `CHOICES.md`
`display-manager`.

## The compositor bake-off, and what "2.4×" actually meant

niri over Hyprland — not a vibes call. Both ran the same two monitors at the same resolutions;
niri's idle session cost **87.7 MB**, Hyprland's cost **266.6 MB stock / 214.0 MB stripped down**
— **2.4× niri even like-for-like**, so the gap wasn't explained by Hyprland shipping more
desktop. `CHOICES.md` `compositor`.

## Agent CLIs: one binary, not five wrapper scripts

`codex`, `gemini`, `copilot`, and `opencode` were all npm-installed bash wrappers that shelled
out to a Node runtime via `mise`. `claude` is a native ELF binary. Dropping the other four
removed both the wrapper layer and, very nearly, the reason Node needed a version manager at
all — Node stayed (LazyVim's `pyright` is `#!/usr/bin/env node`), but the coupling that justified
`mise`'s per-project pinning went with the wrappers. `CHOICES.md` `agent-clis`, `node-runtime`.

## The editor: measured, not assumed

LazyVim beat NVChad and a hand-rolled minimal config in a real three-phase bake-off — startup
time to a real 1500-line file, `gr` (go-to-references) correctness against a real
`pyrightconfig.json`, and Jupyter/molten inline-render acceptance, which is the gripe the whole
editor slot exists to fix. `CHOICES.md` `editor`, `jupyter-in-neovim`.

## Theming: one file, and no resident process pays for it

The palette (`CHOICES.md` `palette`) is one file of `NAME=hex` shell assignments, rendered into
every app's config by `envsubst` — which ships as part of `gettext`, a `base` dependency, so
**zero packages** are installed for it. `matugen` and `wallust` were measured and rejected for
the opposite reason a *material-you* generator exists: asked to reproduce hand-picked hex
values exactly, both *toned* them instead, and no config flag turned that off. The cost is paid
once, when the palette is edited — never at boot, never resident.

## Zero vibe coding

The methodology, not a feature: `CLAUDE.md` requires reading the shipped source before asserting
how something behaves, exercising the real write path rather than trusting a dry run, and
subjecting every test conclusion to a standing adversarial review before it's recorded as fact.
The `bootloader` row's `find-limine-conf.sh` fix is a good example of the shape this takes in
practice — a first version was verified against a permissively-mounted desktop and written up as
correct, and running it for real on the actual target box (an `archinstall`-produced install
with a root-only ESP mount) found a genuine bug within minutes. The mistake in the write-up got
corrected in the same session, in place, rather than left to look better than it was.

## What never ships, on principle

Employer and client work — VPN configs, shell aliases, path references naming a specific job —
never appears in this repo, full stop, stronger than the general personal-details-isolation rule
(`CLAUDE.md`). Where the author's own workflow needs one of these, the repo carries at most a
generic mechanism, never the specific name. `CHOICES.md` `secrets-bootstrap`.
