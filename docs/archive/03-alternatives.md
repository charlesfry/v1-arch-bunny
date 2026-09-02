# Alternatives by slot, in the order to try them

One section per capability from [02-functionality.md](02-functionality.md).
**Try order is left-to-right / top-to-bottom: most likely to stick, first.**
Ranking rule — priority 1 (it just works) filters the list, then **speed orders
what survives, then weight**, then taste breaks ties. Speed before weight is the
correction of 2026-08-21: several rows below still read as though "leanest" were
the argument, because idle RAM is the easy number to get and latency is not.
Where a row's only stated reason is that a candidate is lean, that row has not
actually been decided yet — it has been guessed.

`AUR` marks packages not in the official repos. Everything else was verified
present in `core`/`extra` on 2026-08-17.

## Hyprland contamination audit — 2026-08-21

Three slots in a row turned out to be ranked *because a candidate integrated
with Hyprland*, which is `rejected`. The author asked for a sweep rather than
another one-off fix. Result:

| Slot | `hypr*` candidate | Verdict |
|---|---|---|
| polkit agent | `hyprpolkitagent` was #1 | **was void** — fixed, `mate-polkit` |
| lock and idle | `hyprlock + hypridle` was #1 | **was void** — fixed, `swaylock + swayidle` |
| screenshot | `hyprshot` at #2 | harmless — `grim`+`slurp` already ranks #1 on its own merits |
| wallpaper | `hyprpaper` at #2 | harmless — `swaybg` already #1, and now installed and proven |
| bar | `hyprpanel` named only to be rejected | fine as written |

**Only the two #1 rankings were actually wrong, and both are now corrected.**
The `hypr*` entries at #2 are fallbacks behind a non-Hyprland winner, so they
cost nothing unless promoted — but do not promote one without re-checking.

**The opposite contamination was also checked and is clean.** Most of the winners
here (`grim`, `slurp`, `swaybg`, `swaylock`, `swayidle`, `wl-clipboard`) are
wlroots-era tools, and **niri is Smithay-based, not wlroots** — so they could in
principle have failed. Verified against the running compositor: niri advertises
`ext_session_lock_manager_v1`, `ext_idle_notifier_v1`,
`zwlr_screencopy_manager_v1`, `zwlr_layer_shell_v1`, `zwlr_output_manager_v1`,
`zwp_idle_inhibit_manager_v1` and `zwlr_data_control_manager_v1`. **All the
wlroots-era picks are safe on niri**, and `swaybg` + `wl-paste` are already
proven running.

---

## Foundations — decide early, expensive to change later

### Bootloader
| Order | Candidate | Why |
|---|---|---|
| 1 | **limine** | Already proven on this exact machine: chainloads Windows, and `limine-snapper-sync` puts bootable snapshots in the menu. Set `timeout: 0`/`1` — the current 3.5s loader phase is pure configured delay. |
| 2 | systemd-boot (`bootctl`, ships with systemd) | Leanest and fastest; auto-discovers the Windows entry. Loses automatic snapshot boot entries — would need a generator or manual entries. |
| 3 | rEFInd / GRUB | Only if a dual-boot or Secure Boot problem forces it. GRUB is slow and its config is the least pleasant of the three. |

Dual-boot rule for all three, **when Windows is present** — usually it is not,
see `CHOICES.md` `install-disk-mode`: install to the **existing** ESP, never
reformat it, never let an installer auto-partition. On a bare disk the installer
creates the ESP and partitions freely; that is the default case.

**Limine gotcha, confirmed on real hardware**: Limine reads FAT\*/ISO9660 only —
no ext4 driver, by design. A separate ext4 `/boot` panics with "failed to open
kernel" on a correct path; no `mkfs.ext4 -O ^feature` combination fixes it. Put
`/boot` on the ESP itself. Full writeup: `CHOICES.md`, bootloader row.

### Kernel
| Order | Candidate | Why |
|---|---|---|
| 1 | **linux-zen** | The standard answer for desktop snappiness (BORE scheduler, desktop-tuned defaults). Costs an extra DKMS build per update. |
| 2 | linux | The safety net. Install it alongside zen regardless, as a second boot entry — a kernel that will not boot on a dual-boot workstation is a priority-1 failure. |
| 3 | linux-lts | Only if NVIDIA breaks on a kernel bump. |

Measure: `hyperfine` a cold app launch and check compositor frame pacing under
load. If zen is not measurably better, keep plain `linux` and one less DKMS build.

### GPU driver

Hardware scope: **NVIDIA discrete, over Intel or AMD integrated**. This test
laptop is likely the only Intel machine that will ever be in scope — a future
Framework is expected to be AMD — but Intel support costs one package line, so
it stays. The same split reaches past the GPU: an AMD box needs `amd-ucode`
rather than the `intel-ucode` installed here.

Open vs. proprietary is **not** a philosophy question: both ship the same
proprietary userspace (`nvidia-utils`), and the open module offloads its work to
the proprietary GSP firmware on the card. The axis is GPU generation.

| Order | Candidate | Why |
|---|---|---|
| 1 | **nvidia-open-dkms** | Turing (GTX 16xx / RTX 20xx) and newer. Upstream's default and the only actively developed module since driver 560. DKMS because `linux-zen` is the primary kernel — prebuilt `nvidia-open` targets plain `linux` alone, which would leave the *fallback* kernel as the only one with a working GPU. |
| 2 | nvidia-open | The same module, prebuilt. Correct only if zen is dropped after the Phase 3 measurement. Switch then, not before. |
| 3 | nvidia (proprietary) | Only for pre-Turing cards, where the open module does not work at all. No advantage on supported hardware. |
| — | mesa + vulkan-intel + intel-media-driver | Intel-only machines, and the iGPU half of any hybrid box. |
| — | mesa + vulkan-radeon + libva-mesa-driver | AMD integrated (`amdgpu`). The expected Framework case. |

Hybrid (Optimus) laptops are the common case in scope and differ from a desktop:
the internal panel is usually wired to the iGPU, so `i915` drives the compositor
and NVIDIA is used for offload via `nvidia-prime`'s `prime-run`.

Settled on hardware 2026-08-18 — **write no GPU config**. `modeset` already
reads `Y` with nothing in `modprobe.d`, so it is the module's compiled-in
default, and the "non-negotiable `nvidia_drm.modeset=1`" advice above this line
is stale. Upstream's `60-depmod` → `70-dkms-install` → `90-mkinitcpio-install`
hook chain already covers kernel bumps, so no `MODULES=` edit and no custom hook
are needed either. Details in `CHOICES.md`, `gpu-driver` row.

### Filesystem and snapshots
| Order | Candidate | Why |
|---|---|---|
| 1 | **btrfs + LUKS2 + snapper + `pacman` pre/post snapshot hook** | Already in use, already integrated with limine. Mount `noatime,compress=zstd:1` (level 1, not the default 3 — decompression is nearly free but level 3 costs write latency). |
| 2 | btrfs without LUKS | Faster, but drops full-disk encryption. Only if measurement shows LUKS is actually hurting NVMe throughput enough to matter. |
| 3 | ext4 | Fastest and simplest, but no snapshots — and snapshot rollback is what makes the "try and uninstall packages" workflow in this project safe. Effectively ruled out by the plan itself. |

Tune snapper retention **at install time**, not after the disk fills.

### Boot-time cleanup (not a slot, a checklist)
Drop `plymouth`, drop the TPM2 setup units, set the bootloader timeout to ~1s,
and move `docker`/`containerd` off boot to socket activation. That is ~7s of the
measured 34.5s, before touching anything harder.

---

## Session entry

### Display manager

**Re-ranked 2026-08-21.** The old table ranked greetd first as "the lean
standard" and put autologin second as the fast-but-less-safe option, framing this
as a 2a-vs-2b trade. Reading greetd's own package and man pages showed the row
had **two facts wrong**, and that the trade largely does not exist.

| Order | Candidate | Why |
|---|---|---|
| 1 | **greetd + `greetd-tuigreet`, with `initial_session` set** | Boots straight into the session with **no prompt** — the same fast path as bare TTY autologin — while keeping a greeter for every case where the session ends. This is not a workaround; it is what upstream built `initial_session` for. |
| 2 | No DM — TTY autologin, `exec` the compositor from `~/.bash_profile` | The same zero-prompt boot with one less package and no resident supervisor. Loses what candidate 1's fallback buys: when the compositor dies, this lands on a logged-in shell rather than a login prompt. |
| 3 | SDDM | Current. Drags in Qt6 and stays resident. Only worth it if the greeter is doing something needed. |

**Two corrections to the old row.** (1) `greetd` and `greetd-tuigreet` are both in
**`extra`**, not the AUR — verified 2026-08-21 (`greetd 0.10.3-2`,
`greetd-tuigreet 0.9.1-2`). (2) **greetd does not "exit after login."** Its man
page calls it "a login manager *daemon*", its unit is `Type=simple`
`Restart=always`, and it has to stay alive because the default session is
"started again whenever no session is running, such as when the user logs out."
What exits after login is *tuigreet*, the greeter UI. So greetd is a resident
process — small (660 KB binary), but **its idle RSS is unmeasured and the old
"~2 MB" figure has no provenance**. Measure it before the row is closed.

**What `initial_session` actually does**, quoted from `greetd(5)` because the
reasoning is upstream's, not ours: it "will only be executed during the first run
of greetd since boot **in order to ensure signing out works properly and to
prevent security issues whenever greetd or the greeter exit**", tracked via a
runfile cleared at reboot. So the first boot logs straight in; anything that ends
the session afterwards falls through to the greeter.

**This is why the trade mostly dissolves.** Ranked honestly, a DM protects
against far less than it appears to:

- *Powered off and stolen* — LUKS is the whole defence. A DM adds nothing.
- *Running, unlocked, walked away from* — the DM is long gone. The **screen
  locker** (C4) is what protects this, and it is a different slot.
- *Running, screen locked* — the locker holds. niri implements
  `ext_session_lock_v1`, whose entire design point is that a crashing lock client
  leaves the screen locked rather than exposed.
- *Compositor itself dies while locked* — **the one case where the answer
  differs.** Autologin drops to a logged-in shell on tty1; greetd shows a login
  prompt. Narrow, but it is a real difference and it is free under
  `initial_session`.

So candidate 1 costs one small resident daemon and buys a fallback; candidate 2
costs nothing and does not. **Neither costs a password on the fast path**, which
is the thing that was actually being weighed. Decide it on greetd's measured idle
RSS, not on the boot-time difference — power-on → desktop-accepts-input should be
within noise between them, and that is worth confirming rather than assuming.

**Hard constraint, not a judgement call — `02-functionality.md` C2 requires
*exactly* one credential prompt.** A zero-prompt *login* is fine; a zero-prompt
*boot* is not. Candidates 1 and 2 both spend the machine's single prompt on the
**LUKS passphrase**, and are only acceptable on that basis. **This forecloses
combining either of them with TPM2 auto-unlock**: TPM2 removes the LUKS prompt,
autologin removes the login prompt, and together they produce a machine that boots
from cold into an unlocked desktop with no authentication anywhere.

**Settled 2026-08-21 — `CHOICES.md` `disk-unlock`.** The prompt lives at the LUKS
passphrase and **TPM2 auto-unlock is `rejected`**, so a zero-prompt *login* is
permitted here permanently: the disk is still gated by a human. The comparison
that produced that answer is kept below, because it is what any future "should we
take TPM2 to make boot benchmarkable?" has to argue against — **these two slots
are one decision, and reopening either reopens both**:

| | Disk decrypts | Password guards | Unattended reboot |
|---|---|---|---|
| **Manual LUKS + autologin** | only with a human present | the data itself | **no** — stops at the prompt |
| TPM2 + greeter password | on any power-on | the session, not the data | yes |

Same single prompt and roughly the same wall clock either way, since one password
gets typed in both. So the second row buys **only** unattended reboot, and pays
for it by exposing a decrypted volume to anyone who can press the power button —
which also puts evil-maid and cold-boot attacks back in scope. **Row one is the
picked answer** — the author's call 2026-08-21, on the grounds that a permanent
security hole is not worth 15 seconds of one-off dev time, and that unattended
reboot is worth nothing while the machine is within arm's reach. If remote reboot
ever becomes a stated requirement, it argues against this table.

**Multi-user, for the record.** `initial_session` logs in one user by name.
Logging out falls through to the greeter, where any account can log in, so
multiple users still work — they are simply not the optimised path, per C2's
single-user assumption. Bare TTY autologin (candidate 2) handles this less
gracefully: other users get a plain `getty` on another VT.

---

## Compositor and shell

### Compositor
| Order | Candidate | Why |
|---|---|---|
| 1 | **Hyprland** | Highest chance of "just works" — most mature of the three, best docs, best NVIDIA track record. **Correction, 2026-08-18**: this row previously claimed the keybinds/window rules/monitor config "already exist" for it. Checked on the machine and that's wrong — `dotfiles-omarchy/config/hypr/hyprland.lua` does `require("default.hypr.omarchy")`, and that default layer lives in Omarchy's own `/usr/share/omarchy` (readable on the Omarchy desktop at `~/.local/share/omarchy/default/hypr/`), not in the predecessor repo. The repo only carries thin personal overrides (`monitors.lua`, `input.lua`, `bindings.lua`, `looknfeel.lua`, `autostart.lua`) layered on top of that missing substrate. `arch-bunny` has no Omarchy, so **none of that default layer exists here** — the bindings/window-rules/lock/idle config all have to be written from scratch in Phase 4, using the Omarchy defaults as a reference to read, not a file to copy. Costs: heavier than sway, faster-moving config format. |
| 2 | niri | Scrolling layout, very responsive, actively good on NVIDIA now. The predecessor's `looknfeel.lua` literally carries a commented-out note about wanting a niri-like layout — the curiosity is already documented. Rewriting bindings is the cost. |
| 3 | sway | Leanest and most stable of the three, i3 keybind model. NVIDIA needs `--unsupported-gpu`. The conservative fallback if Hyprland regressions get annoying. |
| 4 | river | Only if the other three disappoint. |

### Bar / status
| Order | Candidate | Why |
|---|---|---|
| 1 | **None** | Clock, battery, and network status are all available on demand from a keybind. A bar is a permanently resident process rendering information looked at a few times a day — it costs 2b continuously and buys **no** 2a, since nothing in the interactive path waits on it. That makes this a clean win rather than a trade. Start here and see if it is actually missed. |
| 2 | waybar, ~4 modules | If a bar is missed. Keep it to clock, workspaces, audio, disk. |
| 3 | eww (AUR) | Only if the rice ambition demands something waybar cannot draw. Costs a resident process *and* a config language. |

Do not consider Quickshell, hyprpanel, or ags — exactly the class of resident
desktop shell priority 2 exists to reject.

### Audio and Bluetooth — no bake-off, deliberately

Both settled 2026-08-19 without a ranked list, because neither has real
competition: `pipewire-media-session` is dead upstream, so `wireplumber` is the
only session manager, and PipeWire without one routes nothing. Take the
`pipewire-audio` metapackage rather than a hand-picked "lean" subset — it is what
carries the Bluetooth codecs. Full reasoning, the measured cost, and the
`sof-firmware` trap for future laptops: `CHOICES.md` `audio` and `bluetooth`.

### Launcher
| Order | Candidate | Why |
|---|---|---|
| 1 | **fuzzel** | Wayland-native C, no daemon, launches in single-digit ms, does app-launch + dmenu mode. Straight replacement for walker with a daemon deleted. |
| 2 | tofi (AUR) | Even faster (sub-ms is its headline claim), even more minimal. Try if fuzzel's startup is somehow noticeable. |
| 3 | walker + elephant | Current. Feature-rich, but the `elephant` daemon runs forever to make it feel fast. **This is the archetypal 2a-vs-2b trade** — RAM spent permanently to buy latency — and it loses here not on principle but on arithmetic: fuzzel opens in single-digit ms *without* the daemon, so the resident cost buys nothing that is left to buy. **That number is inherited, not measured here** — it is exactly the sort of claim this slot should now confirm, since it is the whole reason the daemon loses. Had the daemonless option been slow, this row would have gone the other way and said so. |

Note what walker also provided (emoji picker, calc, clipboard, window switcher).
Anything genuinely used needs its own answer — most map to a fuzzel dmenu script.

### Notifications
| Order | Candidate | Why |
|---|---|---|
| 1 | **mako** | Tiny C daemon, already in use, config is trivially generated from the palette. |
| 2 | dunst | Equivalent weight, more mature, more configurable. |
| — | swaync | Rejected: a notification *center* is a heavier daemon for a feature not in evidence. |

### Lock and idle

**Settled 2026-08-21 — `swaylock` + `swayidle`** (`CHOICES.md` `lock-idle`). The
ranking below was **void, not stale**: it put `hyprlock + hypridle` first for
"integrates with Hyprland", and Hyprland is rejected. Measured instead:
sway pair **123 KiB and zero new dependencies**; hypr pair **1119 KiB plus five
new hypr-ecosystem packages** on a machine that never ran Hyprland. Both work —
niri advertises `ext_session_lock_manager_v1` and `ext_idle_notifier_v1` — so
cost decides. Original ranking follows.

| Order | Candidate | Why |
|---|---|---|
| 1 | ~~hyprlock + hypridle~~ | Tiny, integrates with Hyprland. Same correction as the compositor row above: no config for either exists in the predecessor repo — checked, there is no `hyprlock.conf`/`hypridle.conf` under `customs/` or `config/`. Both configs come from Omarchy's default layer and need to be written new in Phase 4. |
| 2 | swaylock + swayidle | Compositor-agnostic; the answer if the compositor changes. |
| 3 | gtklock | Only if a GTK lock screen is wanted for theming. |

### Screenshot / annotate / clipboard / OSD
| Slot | Order |
|---|---|
| Screenshot | **`grim` + `slurp`** (no daemon, scriptable) → `hyprshot` → `grimblast` |
| Annotate | **`satty`** (already in use, Rust, launches on demand) → `swappy` |
| Clipboard | **`wl-clipboard`** alone → add `cliphist` only if history is genuinely missed (it is a daemon) |
| Volume/brightness | **keybind → `wpctl` / `brightnessctl` + a `notify-send` bar** → `swayosd` (current; a resident server for on-screen bars) |
| Wallpaper | **`swaybg`** (sets and sleeps) → `hyprpaper` → static color, no process at all |
| Polkit agent | ~~`hyprpolkitagent`~~ → **`mate-polkit`**, settled 2026-08-21 (`CHOICES.md` `polkit-agent`). The old ranking was **void, not stale** — it put `hyprpolkitagent` first *because it integrates with Hyprland*, which is rejected. On measured cost `mate-polkit` adds **1** package against `hyprpolkitagent`'s 4 (incl. `qt6-declarative`) and `lxqt-policykit`'s 6. **`polkit-gnome` is not the fallback**: upstream is archived at 0.105 (2012). |

---

## Terminal, shell, editor

### Terminal — the gap is now closed; re-ranked 2026-08-19

**Tested on hardware, so this row is no longer speculative** (`CHOICES.md`
`terminal`): `kitten icat` and an inline matplotlib plot both rendered under
Hyprland. The graphics-protocol gap was **alacritty's**, and kitty already fixes
it. That re-ranks everything below.

| Order | Candidate | Why |
|---|---|---|
| 1 | **kitty** | The reference implementation of the graphics protocol, already installed, and **proven working on this machine**. Was #2 on the assumption ghostty would be needed to close the plot gap; it wasn't. |
| 2 | ghostty | Still worth measuring, but its headline justification is spent — it was ranked #1 *because* it implements the kitty protocol, which kitty obviously also does. **It must now win on latency, and only then on weight** — in that order. |
| — | foot | **The only remaining speed lever, and it is a genuine question again as of 2026-08-21.** kitty is `picked` at **177 ms** cold with nothing left to tune, `--single-instance` is rejected, and ghostty measured *slower* (280 ms). foot is the fastest Wayland terminal by a clear margin and would beat both — **but it does Sixel only, no kitty graphics protocol.** The author's own framing is what makes this live: he wants the terminal "extremely responsive" and needs "jupyter notebooks **on occasion**". That points at a two-terminal split — foot for daily use, kitty on a separate keybind for notebook work — which trades a priority-1 cost (two terminals to configure, and "which one am I in?") for a 2a gain on the most-used application. **Not proposed, not tested, and not to be settled while doing something else.** Original note follows. **Effectively eliminated.** Leanest and lowest-latency by a clear margin, and would win on both halves of priority 2, but Sixel only — no kitty graphics. `02-functionality.md` C5 makes the protocol a hard requirement, so choosing foot means giving up inline plots. **Worth naming what this costs**: the terminal is the single most latency-sensitive surface on the machine, and the fastest candidate was ruled out by a functionality requirement, i.e. by priority 1. That is the right outcome and an expensive one — which is a reason to hold kitty to a measured keystroke-to-glyph number rather than assuming it is fine. |
| — | alacritty | **Rejected.** No graphics protocol at all; this is the cause of the predecessor's broken notebook workflow. |

Remaining Jupyter risk is entirely *above* the terminal now — molten and
image.nvim inside Neovim. Decide kitty-vs-ghostty on a benchmark, since the real
notebook session no longer distinguishes them.

### Shell and prompt
| Order | Candidate | Why |
|---|---|---|
| 1 | **bash** | Login shell today, all helper functions are bash, and it starts faster than the alternatives. No reason to move. |
| 2 | fish / zsh | Only if something specific is wanted from them; both cost a rewrite of `.bashrc` and the VPN alias generation. |

| Order | Prompt | Why |
|---|---|---|
| 1 | **starship** | Current. **Measured 2026-08-21, and it is now a live question rather than a default**: `starship prompt` costs **33.8 ms inside a git repo** and 14.0 ms outside one, on the 7900X desktop. That is paid after *every command*, in the directory type the author is nearly always in — `01-assessment.md` counts `git` 3897 times in shell history. Most of the git-repo penalty is starship shelling out to git (`git status --porcelain` alone is 14.3 ms), not starship itself. |
| 2 | Hand-rolled `PS1` with git status from a cheap `__git_ps1` | The fastest possible prompt; zero forks in the common case. **No longer hypothetical — candidate 1 has a number now.** 34 ms per prompt is the bar to beat, and it is the most-repeated latency cost on the machine. |

### Editor
| Order | Candidate | Why |
|---|---|---|
| 1 | **Neovim + the existing LazyVim data-science config** | It works, the keymaps are learned, and the whole DS layer is already written and documented. Port as-is first. |
| 2 | Same config, audited | Then measure `nvim --startuptime` and cut plugins that do not earn their milliseconds. Molten is loaded eagerly (`lazy = false`) by necessity — know what that costs. |
| 3 | Hand-rolled Neovim config | Only if LazyVim's startup proves unacceptable. Large effort, real speed win. |
| — | helix | Fast and batteries-included, but no Jupyter/molten equivalent. Not viable for this workflow. |

---

## Development

### Python environments — the highest-leverage swap available
| Order | Candidate | Why |
|---|---|---|
| 1 | **uv** | Already sitting in `~/.local/bin`. One to two orders of magnitude faster than conda for resolve+install, and the `~/.venvs/neovim` host env was *already* deliberately built conda-independent. Directly serves the speed KPI on the most-used workflow on the machine. |
| 2 | pixi | The escape hatch for genuinely conda-only packages: conda-forge ecosystem, Rust resolver, far faster than conda. |
| 3 | miniforge / conda | Fallback if an existing env cannot be reproduced any other way. Seven envs exist today, so plan an explicit migration rather than assuming they port. |

Whatever wins must still register Jupyter kernels the molten/venv-selector setup
can find — that is the acceptance test.

### Containers
| Order | Candidate | Why |
|---|---|---|
| 1 | **docker + docker-compose, socket-activated, on its own btrfs subvolume** | `docker-compose` files are in active use, and the subvolume trick is already solved in the predecessor. Socket activation removes ~1.9s from boot and the idle daemon. |
| 2 | podman + podman-docker + podman-compose | No resident daemon at all, rootless — the priority-2 winner on paper. Risk is compose-file compatibility with whatever the work repos expect. Try it *after* the machine is otherwise stable. |

### Other dev tooling
Keep as-is, all cheap and all in use: `git`, `github-cli`, `lazygit`,
`lazydocker`, `direnv`, `zoxide`, `fd`, `ripgrep`, `bat`, `eza`, `jq`, `yq`,
`postgresql` (client), `tmux`, ~~`mise` (node)~~ **Arch `nodejs`**, `just`/`make`.

**"All cheap" was an assumption and it is now measured wrong for two of them**
(2026-08-21, [`benchmarks/3.4.shell-startup.md`](../benchmarks/3.4.shell-startup.md)).
Of the desktop's 272 ms per-terminal `.bashrc` cost, **`mise activate` is 117 ms**
— the single largest item, paid on every terminal to manage a *node* version —
and `direnv hook` is 15 ms. Neither is a package-size or RAM question; both do
eager work at shell start. **Contrast `conda.sh`, which costs 0.3 ms** because it
only defines a function and defers `conda shell.bash hook` (2341 ms) until
`conda activate` is actually called. That lazy shape is what Phase 4 should copy,
and **`mise` was re-decided on 2026-08-21 and is dropped entirely** (`CHOICES.md`
`node-runtime`): the author never runs node himself, so per-project version
pinning — `mise`'s whole purpose — buys nothing. **Node itself stays**, because
`pyright-langserver` is `#!/usr/bin/env node` and four agent CLIs are npm
packages. Arch's `nodejs` package puts it on `PATH` for **0 ms**, against
0.75 ms for shims and 143 ms for `mise activate`.
**Agent CLIs: `claude` only** (settled 2026-08-21, `CHOICES.md` `agent-clis`).
`codex`, `opencode`, `gemini` and `copilot` are dropped at the author's
direction — he wants no LLM application other than Claude, and all four were
Omarchy inheritances. `claude` installs outside pacman; record how, so it is
reproducible. Note all four dropped tools were npm packages that ran
`mise use -g node@latest` on first use, so this removes the agent tooling's
node dependency entirely.

### AUR helper
`yay` (current) or `paru`. Functionally equivalent; keep `yay` and spend the
decision budget elsewhere.

---

## Network, monitoring, ops

| Slot | Order |
|---|---|
| Network | **`systemd-networkd` + `iwd` + `systemd-resolved`** (current, leanest) → NetworkManager (only if a VPN GUI or captive portals become a problem) |
| VPN | **`openvpn` + the generated `v<letter>` aliases** (port as-is) → WireGuard where the endpoint supports it (much faster, but not a unilateral choice — it depends on what the remote side offers) |
| Firewall | ~~`ufw`~~ → **`nftables`**, settled on hardware 2026-08-18. This row's original ranking was stale: `ufw` is a Python wrapper generating what Arch's shipped `/etc/nftables.conf` already contains. `CHOICES.md` `firewall`. |
| Bluetooth | **`bluez` + `bluetui`** — no GUI applet, no extra daemon |
| System monitor | **`btop`** (in use) → `htop` |
| Disk | **port the disk-monitor subsystem whole**: user timer, `disk-usage-alert`, the root-owned read-only snapshot helper + narrow sudoers entry, `diskcheck`, `emergency-clean`, `ncdu`/`dust` |

---

## GUI applications

| Slot | Order | Notes |
|---|---|---|
| Browser | **brave-bin** → chromium → firefox | **Settled 2026-08-20, see `CHOICES.md` `browser` / `browser-fallback`**: brave-bin is a hard requirement (author's favourite), chromium is the deliberate small fallback, firefox is not installed. The wrapper *is* redundant — confirmed by reading `/usr/bin/brave`, which sources `~/.config/brave-flags.conf` itself. What is **not** settled is whether Brave gets GPU acceleration on niri + NVIDIA; that is the open test on the ledger row. |
| Passwords | **`rbw` + browser extension** → Bitwarden desktop | `rbw` is a small Rust CLI that pairs with fuzzel for a picker. The desktop app is Electron; the browser extension covers the actual daily use. |
| File manager | **`yazi`** → thunar → nautilus | This is a several-daemon decision, not an app decision: nautilus drags in `gvfs` (5 services), `localsearch` indexing, and `at-spi`. `yazi` is a terminal file manager with none of that. Keep one lightweight GUI only if drag-and-drop into other apps turns out to matter. |
| Images | **`imv`** (current, tiny) | Keep. |
| Video | **`mpv`** (current) | Keep — nothing beats it on weight or quality. |
| PDF | **`zathura` + `zathura-pdf-mupdf`** → papers/evince | Vim keybinds, tiny. |
| Music | **`spotify-player`** (Rust TUI, ~30 MB) → `cliamp` (already installed) → `mpd`+`ncmpcpp` → Spotify desktop | The Spotify desktop client was holding ~1.1 GB across two processes at measurement time. This is the single largest RAM win in the app list. |
| Calculator | **`qalc`** (CLI, in use) → gnome-calculator | |
| Chat | Signal desktop | Electron, ~800 MB across two processes. No lighter viable client. Keep it, but never autostart it. |

---

## Theming

| Order | Approach | Why |
|---|---|---|
| 1 | **One `palette.toml` + a small generator script** that writes each app's config fragment | ~50 lines of shell, runs on demand, zero resident cost, and it is exactly how the `daemon` theme's `colors.toml` already works. Palette change propagates everywhere with one command. |
| 2 | Hand-written per-app color blocks | What the theme originally was before it was consolidated. Rejected — it drifts. |
| — | A theming *daemon* or a live-reload watcher | Rejected outright by priority 2. |

Starting point: keep `daemon`'s structure (`#0f0f0f` base, zero rounding,
2px border, 3px gaps) and swap the crimson/orange accent for the bunny neon.
Rice with shaders, ASCII, and wallpaper — not with processes.
