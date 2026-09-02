# The choice ledger

The system for recording what got tried and what got picked, so that the
installer can be generated from decisions rather than from memory.

## The format

**One file, `CHOICES.md` at the repo root: an index table, then one section per
row.** It renders on GitHub, it is editable by hand in ten seconds, and the table
half is parseable by `awk` — so the eventual installer reads the same file a human
reads. No second source of truth, no generator, no database.

```
| Slot | Candidate | Packages | Status | Date |
|---|---|---|---|---|
| launcher | [fuzzel](#launcher--fuzzel) | fuzzel | picked | 2026-09-02 |
| launcher | [walker](#launcher--walker) | walker elephant | rejected | 2026-09-02 |
```

```
### launcher — fuzzel

**picked** · 2026-09-02 · packages: fuzzel

**Measured:** 0 daemons, 8 ms open

replaced walker; dmenu mode covers the emoji picker
```

**The seven fields are unchanged** — `Measured` and `Note` simply live in the
section instead of in a table cell. **Split 2026-08-25** (author: *"terribly
formatted grid… very hard to read"*): the Note column is the most valuable one and
had grown to paragraph length, which made every row a horizontally-scrolling cell
nobody could read. The index table keeps the five short, scannable fields; the
prose gets normal page width. Column *positions* were chosen so the installer's
`awk` line below is byte-for-byte the same as before the split — `$4` is still
`Packages`, `$5` still `Status`. Only the Candidate cell is a link, because `$3`
is the one field nothing parses.

**Columns**

- `Slot` — the capability from `02-functionality.md`. Stable name; it is the join key.
- `Candidate` — human name of the thing tried.
- `Packages` — exactly what `pacman -S` / `yay -S` needs, space-separated.
  `—` when the choice is not a package (e.g. "no bar", "TTY autologin").
- `Status` — one of the five words below.
- `Date` — `YYYY-MM-DD` the status was set.
- `Measured` — the numbers that justified it: launch/interaction ms, idle RSS,
  resident daemons added, boot delta. `—` if the choice was not made on
  measurement. **Time first, and for any slot in the interactive path a row with
  no time in it is incomplete** — write what is missing rather than letting the
  RAM figure stand in for it. Idle RSS is easy to collect and latency is not,
  which is precisely how a project that cares about speed ends up with a ledger
  full of megabytes. **Audited 2026-08-21: of the 50 rows then in `CHOICES.md`,
  exactly one — `font` — carried a timing comparison at all, and even that one
  measures throughput (`time cat` a 14 MB file) rather than the latency a hand
  feels. Not a single row records a keystroke-to-glyph, launch, or
  window-mapped time.** **Never a size-on-disk figure as a justification** — disk is not a
  criterion (`CLAUDE.md`); record it as context if it is interesting, not as an
  argument.
- `Note` — the one-line reason. **This is the most valuable column.** It is what
  stops a rejected candidate from being re-litigated in six months.

**Status vocabulary** — exactly five words, no others:

| Status | Meaning |
|---|---|
| `untried` | Seeded from `03-alternatives.md`, not yet installed. |
| `trying` | Installed right now, being lived with. **At most one per slot.** |
| `picked` | Won the slot. The installer installs this. |
| `rejected` | Tried and dropped. Never installed again; the `Note` says why. |
| `deferred` | Deliberately not decided yet (e.g. `docker-storage-quota`, pending Phase 3). |

**Rules**

- Rejections are rows, not deletions. A ledger that only records winners loses
  the expensive half of the information.
- One `trying` per slot at a time — two variables, no conclusion.
- `picked` requires either a `Measured` value or a `Note` explaining why
  measurement was not the deciding factor.
- **A pick that trades RAM for responsiveness, or the reverse, says so in the
  `Note` with the size of the trade**, and goes to the author rather than being
  settled in the row. Speed wins by default — a soft preference, not a rule.
- Optional-profile packages get a slot prefix (`gaming/`, `emulation/`,
  `creative/`) so the installer can filter them out of the core.

## How the installer consumes it

The whole integration, for reference — the core package list is one line:

```sh
awk -F' *[|] *' '$5=="picked" && $4!="—" && $2 !~ "/" {print $4}' CHOICES.md
```

...and a profile is the same line with `$2 ~ "^gaming/"`. That is the entire
reason for choosing a pipe-delimited markdown table over prose: **the doc is the
data**. If it ever needs more than one `awk` line to read, the format has drifted
and should be pulled back.

### What the one line does *not* solve — run it before trusting it

Ran end-to-end over the whole ledger on 2026-08-25 for the first time. It works
— 76 names, every one a real package — but running it surfaced things that
reading the cells did not, so it is worth running as a check in its own right,
not only as an installer step.

- **It caught a live bug.** `firmware-set` carried
  `linux-firmware-{intel,realtek,…}`. That reads as shorthand and is broken as
  data: **brace expansion happens before command substitution**, so
  `pacman -S $(awk … CHOICES.md)` passes pacman the literal string and the
  install dies on "target not found" — on the one row whose failure mode is *no
  wifi during the install itself*. Fixed by naming all seven. **The general
  rule: a Packages cell may contain only literal package names separated by
  single spaces.** No braces, no globs, no prose, no `or`.
- **The list is not installable in one command, and the format cannot fix
  that.** Of the 76, two are AUR (`brave-bin`, `yay-bin`) and two come from the
  pinned `[omarchy]` repo (`limine-snapper-sync`, `limine-mkinitcpio-hook`).
  `pacman -S` handles neither group, and `yay-bin` is the AUR helper itself, so
  it cannot come from the helper. **The installer therefore needs an ordering,
  not just a list**: official repos → add `[omarchy]` and its pinned key →
  bootstrap `yay-bin` from source → AUR. Which bucket a package falls in is
  derivable at install time (`pacman -Si`), so this stays one column and one awk
  line; it is a sequencing fact about `install.sh`, not format drift.
- **Nothing checks the names but this.** Every row is a *claim* that a package
  exists; `4.17` already found one that did not (`ttf-fragment-mono`, which was
  never a package at all). Piping the awk output through `pacman -Si` is the
  cheap standing check. **It lands 2026-08-26 as `scripts/check-packages.sh`** —
  its own file rather than the mooted `check-configs.sh`, matching the
  `check-limine.sh` / `check-keybinds.sh` convention already in `scripts/`.
  It uses the awk line above verbatim, so it checks the same parse the installer
  will use, and it **prints the packages grouped by repo**, which is the install
  ordering derived from the ledger instead of hardcoded beside it. First run on
  `bunne-test`, 2026-08-26: **all 74 resolve** — 70 from `core`/`extra`,
  `limine-mkinitcpio-hook` + `limine-snapper-sync` from `[omarchy]`, and
  `brave-bin` + `yay-bin` from the AUR, exactly the four the note above predicts.

## Workflow during the bake-off

```
snapshot  →  install candidate  →  set Status=trying  →  live with it
          →  measure  →  set picked/rejected + Measured + Note  →  pacman -Rns the loser
```

Fill in the `Measured` column at the moment of decision, not later — the number
is the whole argument, and it is unrecoverable once the package is gone.

## Seeding it

Create `CHOICES.md` at the start of Phase 3 with **one row per slot**, using the
#1-ranked candidate from `03-alternatives.md` and `Status=untried`. Add a row per
additional candidate only when it is actually tried. Slots to seed, in the order
Phase 3 works through them:

**Foundations** — `bootloader`, `kernel`, `gpu-driver`, `filesystem`,
`snapshots`, `initramfs`

**Session** — `display-manager`, `compositor`, `bar`, `launcher`,
`notifications`, `lock`, `idle`, `screenshot`, `annotate`, `clipboard`,
`volume-osd`, `wallpaper`, `polkit-agent`, `portal`

**Terminal & editor** — `terminal`, `shell`, `prompt`, `editor`, `multiplexer`

**Development** — `python-env`, `containers`, `aur-helper`, `git-tui`,
`agent-clis`, `node`

**Network & ops** — `network`, `wifi`, `dns`, `vpn`, `firewall`, `bluetooth`,
`sysmon`, `disk-monitor`, `backup`

**GUI** — `browser`, `passwords`, `file-manager`, `images`, `video`, `pdf`,
`music`, `calculator`, `chat`

**Theming** — `palette`, `fonts`, `icons`, `gtk-theme`, `cursor`

**Deferred** — `install-artifact` (see `04-plan.md` Phase 5; the last
foundational decision still open. `dotfile-deployment` was the other and was
settled as symlink on 2026-08-19.)

**Optional profiles** — `gaming/*`, `emulation/*`, `creative/*`, `notes/*`,
`comms/*`, `printing/*`, `office/*`

## What the ledger is not

Not a changelog and not a wishlist. It *has* become a place for prose — the `Note`
sections run to paragraphs, which is why the table was split in 2026-08-25 — but the
rule behind the original one-line limit still holds: a Note earns its length only by
recording why a decision was made and what would reverse it. Exploration, options
weighed and dropped, and anything a future reader would skim past belong in
`03-alternatives.md` or `benchmarks/`, with the row pointing at it.

**Nor is it the budget.** `CHOICES.md` answers *what did we pick and why*, one
row per decision. [`BUDGET.md`](../BUDGET.md) answers *what does the whole
machine now cost*, bucketed by how often each cost is paid. A decision is
defensible on its own row and still unaffordable in aggregate — that is exactly
the failure the budget exists to catch, so **a `picked` row with a runtime cost
should gain a budget row in the same sitting.**
