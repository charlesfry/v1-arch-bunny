# Phase-4 disk-alert draft — DRAFT for author review

**Status: rewritten 2026-08-26 on the author's instruction — *"i dont like the disk-alert.
way too many lines of code. simplify the hell out of it."* Tested live on `bunne-test`;
NOT ratified, NOT in `config/`.**

## What it is now

**One `df`.** 19 lines of code across three files, down from 183 across five.

| | before | after |
|---|---|---|
| files | 5 | 3 |
| lines of code (excl. comments/blank) | 183 | **19** |
| root helper (`/usr/local/sbin/disk-qgroup-usage`) | yes | **gone** |
| `NOPASSWD` sudoers entry | yes | **gone** |
| healthy-run cost | 3-6 s | **8.7 ms ± 0.8** (n=964) |

### Why three meters collapsed to one

**Everything this repo worries about is in the same btrfs pool as `/`.** Docker images in
`@containerd`, volumes in `@dockervol`, snapshots in `@snapshots`, the package cache in
`@pkg` — separate *mounts*, one filesystem. Checked rather than assumed: `df -B1` reports
**identical used and size bytes** for `/`, `/home`, `/var/lib/docker`, `/var/lib/containerd`
and `/.snapshots`. So one number already sees all of them, and meters 2 and 3 were a second
way of learning something meter 1 had already been told.

They were not redundant when they were written — **they watched the qgroup *caps***
(containerd 100 GiB, dockervol 50 GiB) and snapper's `SPACE_LIMIT` budget, warning as each
was approached. **Open question 26 deleted the caps** (a qgroup limit denied an fs-verity
rollback and forced the whole filesystem read-only, `benchmarks/4.27`), and with them went
the thing two of the three meters measured against. What is left to run out of is the
filesystem, which is what `df` reports.

That is also why the root helper and its `NOPASSWD` sudoers entry could go: they existed
only because `btrfs qgroup show` needs root. **The simplification removed a custom root
binary from the machine, not just lines from a file.**

### What was dropped, named rather than quietly lost

- **Per-subvolume attribution.** The old alert said *which* subvolume was growing. The new
  one says the disk is filling and names where to look (`lazydocker`, `snapper list`, the
  package cache). Detection is unchanged; attribution moved from the notification to the
  three commands it points at.
- **The `UNMONITORED` breach states** — helper missing, watched subvolume absent, snapper
  qgroup silent. All three were failure modes *of the helper*, which no longer exists.
- **`paplay` alarm sound.** Decoration behind a `|| true`.
- **`docker system df` totals, `du` of the caches, biggest `$HOME` dirs.** ~40 lines of
  diagnostics, including a unit-parsing `awk`, gathered only on breach. If they are wanted
  back, the place for them is a script the notification tells you to run, not the alert.
- **Review items 2 and 4 evaporated**: `bunne` no longer needs `docker` group membership for
  the alert to be useful, and there is no sudoers file to template a username into.
- **Review item 3 (mako truncates the body) is much reduced** — the body is two short lines
  rather than five.

### Verified on `bunne-test`, 2026-08-26

- Healthy: silent, exit 0.
- `DISK_THRESHOLD=0`: fires. Exact payload, with `notify-send` stubbed —
  `-u critical -a disk-monitor -i drive-harddisk -t 0` / `⚠️  Disk at 5%` /
  `12G used, 237G free` + the suspects line.
- Delivered for real: `makoctl list` shows it queued, critical, correct title — and mako was
  **D-Bus activated by it**, which incidentally confirms the `notifications` row's
  activated-not-enabled design.
- `shellcheck` + `shfmt` clean.

**Not verified: how it looks rendered.** The test box's screen was DPMS-off and then
swaylock'd, and notifications correctly do not draw over a lock screen, so `grim` captured
black. `benchmarks/raw/p4-disk-alert-draft/alert-breach-test.png` shows the older, *longer*
notification rendering, so the shape is known to work; a two-line body is strictly easier.
Said plainly rather than implied.

### Open for the author

1. **Ship it?** It is not in `config/` and `install.sh` does not enable it.
2. **Where it lives.** Proposal: `config/systemd/user/` for all three files, symlinked by
   `70-dotfiles.sh` like everything else — the units are `$XDG_CONFIG_HOME` by spec, and the
   script sits beside them exactly as `config/waybar/weather` sits beside the waybar config.
   Enabling the timer is then one `systemctl --user enable --now` in a small step.
3. **Threshold 80%** on a 249 GiB filesystem means firing with ~50 GiB left. Unchanged from
   the original draft; still the author's number to move.

---

## History below — the three-meter version and how it got here

## Update 2026-08-26 — meter 2 proven against a real cap breach, and a limit found

**Still a draft, still not ratified.** Two things changed its standing overnight.

**1. Meter 2 is now proven, not just reasoned.** The soak timer was still enabled and had
survived the snapshot rollback (last run 20:01, next 00:01). `@containerd`'s cap was
temporarily narrowed to 332 KiB against 292 KiB in use — **no write was denied, nothing
was written, both Docker services were `inactive`** — and the alert was run with
`notify-send`/`paplay` stubbed on `PATH` so nothing fired audibly at midnight. It
correctly breached:

```
[notify-send] -u critical -a disk-monitor ... ⚠️ Disk capacity warning
📦 containerd at 87% of its cap — 292KB of 333KB
🗄 var/log 135M · pacman cache 2.3G · journal 133.6M
Context: CHOICES.md docker-storage-quota / snapshot-bloat
```

Cap restored to 100 GiB immediately after. So meter 2 detects an approaching qgroup cap
and names the right culprit.

**2. `benchmarks/4.27` both raises this draft's importance and exposes its limit.**

Importance: reaching a qgroup cap is now known to be able to force the *whole filesystem*
read-only, so an alert that fires *before* the cap is not a convenience — it is the thing
standing between the machine and a reboot-to-recover. Option 3 of open question 26 ("cap
below the danger zone and monitor") is built directly on this draft.

**The limit, and it is serious for that option:** this is a **timer polling 6×/day**, and
during tonight's real event `@containerd` went from 9.79 MiB to its cap **inside a single
`docker pull`**. The 20:01 run saw a healthy machine; the cap was hit around 22:15; the
next scheduled run was 00:01. **A four-hour poll cannot protect against a fast fill** —
it would have reported the breach roughly two hours after the filesystem had already gone
read-only.

That is not an argument against the alert, which is still worth having for slow growth —
the actual gripe #1 shape, a disk filling over weeks. It *is* an argument that the alert
**cannot be the safety mechanism for a hard cap**, and option 3 should not be chosen on
the assumption that it can. Anything that wants to catch a fast fill has to be
synchronous with the write, which a timer is not.

**Review items 1–5 above still stand**, and item 2 (the `docker` group) is unchanged.

## Update 2026-08-26 — meter 2 rebuilt, because the caps it read are gone

**Open question 26 was answered with option 4: drop the qgroup limits, keep the qgroups
for accounting** (`CHOICES.md` `docker-storage-quota`). That decision breaks this draft,
and in the worst way: meter 2 selected its rows by *"has a numeric `max_referenced`"*, so
with no limits set the filter matches nothing. The meter would have gone quiet and
reported a healthy machine while monitoring Docker not at all — and Docker now has no cap
behind it. Silent, and arriving as a side effect of a decision taken in another file.

**What changed.** The helper stays dumb: every qgroup, path and referenced bytes, no
filtering, no opinion about what matters. The watch list moved into the alert:

```bash
declare -A WATCH=([containerd]=$((100 * 1024 ** 3)) [dockervol]=$((50 * 1024 ** 3)))
```

The author's own numbers, doing a different job — **thresholds now, not walls**, so 80% of
100 GiB fires exactly where it always would have. And the absent case is a breach: a
watched subvolume missing from the helper's output means either the subvolume is gone or
someone ran `btrfs quota disable`, and both must be loud.

Review item: the watch list is two hardcoded figures in a script, deliberately. They are
the same two figures the author picked for the caps, they belong to this one machine's
layout, and a config file for two constants is machinery the setting does not earn. If a
third subvolume ever wants watching, that is the moment to reconsider.

### Tested on `bunne-test`, all four states

`notify-send` and `paplay` stubbed on `PATH` so nothing fired at the author.

| state | result |
|---|---|
| healthy | silent, exit 0; `success` / `ExecMainStatus=0` through the real user unit |
| `DISK_THRESHOLD=0` | fires; containerd correctly at 0% of 100 GiB |
| watch narrowed to 120 MiB | `📦 containerd at 85% of its watch — 104MB of 120MB` |
| watched rows filtered out of helper output | `❓ containerd absent … UNMONITORED` + same for `dockervol` |

The 85% line replaces the *"87% of its cap"* proof above and is a **strictly safer test**:
it narrows the threshold, not an enforcing cap, so nothing on disk changes and no write can
be denied. The bytes behind it are real — 104 MB left in `@containerd` by a genuine
`docker pull python:3.12-slim`, which was deliberately not cleaned up.

### Two bugs the run found that review had not

6. **The helper reported an empty path for the root subvolume.** `sub(/^@/, "", path)`
   exists to turn `@containerd` into `containerd`; applied to `@` it yields the empty
   string, which is a **hard error** as a bash associative-array subscript —
   `WATCH: bad array subscript`, printed on every healthy run, to stderr, into the journal.
   Invisible until now only because the old cap filter excluded `@`. Fixed by not stripping
   when the path *is* `@`.
7. **The parse now rejects an empty path before the lookup**, not after. One condition
   moved; the input comes from another program and a bash array subscript is not a place to
   find out.

Both are the kind of defect that shows up only when the thing is executed. Neither would
have been caught by reading it again.

### Still standing

Review items 1–5 remain, item 2 (the `docker` group) unchanged. The 6×/day polling limit
recorded above is unchanged too — but its *consequence* has: with no cap to race, there is
no longer a fast-fill window in which the alert arrives after the filesystem has gone
read-only. It is now a slow-growth instrument watching a slow-growth problem, which is what
it was always good at. **Still a draft, still not ratified, still not in `config/`.**
