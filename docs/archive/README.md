# Archive

Everything here is **history, not instruction.** It records how `arch-bunny` was
designed before 2026-09-02, when the repo was rebuilt as a variant of
[viacoffee/dotfiles](https://github.com/viacoffee/dotfiles).

Where the archive and the live tree disagree, the live tree is right. Several
decisions here were deliberately reversed in the transplant — non-UKI boot,
getty autologin over greetd, NetworkManager, firmware pruning, `compress=zstd:1`,
`realtime-privileges`, hand-rolled `ln -sfn` deployment.

| Path | What it was |
|---|---|
| `CHOICES.md` | The decision ledger — 66 picked rows, and the package source of truth. |
| `BUDGET.md` | Running tally of every runtime cost, bucketed by how often it was paid. |
| `OPINIONS.md` | Standing preferences behind the picks. |
| `benchmarks/` | 40 measurement write-ups backing the ledger. |
| `01-…` – `05-choices.md` | The original phase documents. |
| `archinstall-*.json` | The pinned base-install configs, superseded by the README's archinstall steps. |
| `plymouth-debug.log` | Capture from the Plymouth investigation that prompted the rebuild. |

The measurements remain valid — they were taken on this hardware and are still
the best evidence about what things cost. The *conclusions* drawn from them are
not binding.
