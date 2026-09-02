# MegaUltraBunny (MUB) — research + measured prototypes (overnight 2026-08-25)

The optional maximum-cool theme for beefy machines (64 GB / RTX 4090).
Ground rules (author, 2026-08-21 + 2026-08-24 night): **MUB is the single
licensed exception to Fast & Light** — idle RAM and GPU may be spent on
cool — but it must cost **zero when not switched on** (no boot cost, no
autostart), every package is itemised, and it is strictly a stretch goal.
Prior art groundwork: `research-arch-dotfiles-2026-08-24.md` (13-repo
survey) and `research/ricing-cost-audit-2026-08-24.md` (technique audit) —
this file goes deeper on the maximum-cool end and adds tonight's
hands-on numbers.

**Constraint added by the author 2026-08-25, and it is the binding one:** *"I don't want
MUB installing a ton of crap that only gets used with its theme. A few packages is fine,
but I don't want to compromise the integrity of the non-meme machine."* Read together
with the zero-when-off rule above, that sets the shape of any future MUB row: a handful
of packages at most, each one itemised and justified on the base machine's terms as well
as MUB's, and nothing that a `pacman -Qe` audit of a non-MUB BunnE would find
surprising. **Consequence applied the same day:** every MUB package installed for the
overnight exploration is swept from `bunne-test` — `cava`, `fastfetch`, `gpupaper`,
`matugen`, `dms-shell` (which had silently pulled the whole Hyprland library stack back
in via `dms-shell-hyprland`, reversing the closed `compositor-cleanup` decision). The
measurements below survive the sweep; the packages do not. MUB is parked until the base
rice is finished.

## Measured prototypes (all run tonight on `arch-bunny`, artifacts in `benchmarks/raw/mub-*`)

### 1. Neon gradient focus ring — FREE, and arguably not even MUB-only

niri renders `active-gradient` natively (CSS-style linear-gradient, oklch
interpolation available, `relative-to="workspace-view"` for a whole-desktop
sweep). Prototyped pink→cyan at 45°
(`active-gradient from="#ff2ec4" to="#00ffd5" angle=45
relative-to="workspace-view"`) — screenshot
`benchmarks/raw/mub-gradient-ring.png`. **Zero packages, zero resident
cost, same GPU pass as the solid ring.** This is config-only cool; the
default theme could adopt a subtler variant without touching priority 2 at
all. Box config reverted after the shot.

### 2. kitty `cursor_trail` — pay-per-use eye candy (the audit's "no published numbers", now measured)

`instruments`-grade log: `benchmarks/raw/mub-cursortrail.log`. Conditions
(10 s windows, i915 render-engine ns summed over deduplicated DRM clients):

| condition | CPU (one core) | GPU render / 10 s | PSS |
|---|---|---|---|
| plain kitty, cursor moving 50/s | 4.4% | 1,058 ms | ~258 MB* |
| trail=3, cursor moving 50/s | 5.8% | 2,242 ms | ~258 MB* |
| trail=3, idle | 0.2% | 46 ms | ~258 MB* |
| plain, idle | 0.2% | 46 ms | ~260 MB* |

*PSS here is file-heavy (page-cache accounting per 4.14); the point is the
delta ≈ 0.

**Verdict: idle cost is exactly zero; while the cursor moves it ~doubles
kitty's GPU render time and adds ~1.4pp CPU.** Perfect MUB profile
(`cursor_trail 3` + decay in the MUB kitty include). Open question before
any *default*-theme use: whether the trail adds keystroke-to-glyph latency
— needs the input-to-photon rig, not settled here.

### 3. GLSL shader wallpaper — the MUB centerpiece, fully priced

`gpupaper` 0.1.3 (AUR, wgpu, GLSL/WGSL fragment shaders as a layer
surface; ships 36 example shaders). Wrote `bunne-grid.frag` — matte #0f0f0f,
neon pink→cyan synthwave floor grid scrolling slowly, soft pulsing horizon
glow, faint scanlines — screenshot `benchmarks/raw/mub-shader-wall.png`,
shader deposited alongside. First-try render on eDP-1. Renders on **i915**
(fdinfo ground truth); the dGPU stayed at P8 (a transient 20 W reading
settled to 11.4 W — watch it, don't trust one sample).

The cost, decomposed — and the ICD-enumeration story strikes again, in
Vulkan form:

| launch env | PSS | anon | nvidia maps | CPU (one core) |
|---|---|---|---|---|
| default | 326.9 MB | 45.4 MB | ~90 (both stacks incl. `/dev/nvidiactl` 42.5 MB) | 3.4% @ vsync-60 |
| `VK_DRIVER_FILES=intel` | 224.0 MB | 24.1 MB | 47 (EGL half remains) | 3.2% @ 30 fps |
| + `__EGL_VENDOR_LIBRARY_FILENAMES=mesa` | **131.0 MB** | 15.5 MB | **0** | ~3% |

So the honest hybrid-laptop price is **~131 MB PSS + ~3% of one core**
(remaining bulk: LLVM 84 MB + gallium — mesa's shader stack, the true
floor for any GL/VK client); the unpinned default wastes +196 MB on
double-ICD enumeration. Notes: the pin here is **per-app in the MUB launch
line**, not the global pin the author declined for kitty; on the 4090
target the nvidia stack IS the working set, so expect a different (likely
~200+ MB) figure there — re-measure in Phase 6 if MUB ships. The fps cap
barely moved CPU (3.4→3.2%) — most of the cost is not per-frame; worth a
second look if the number ever matters. Relaunch command:
`gpupaper eDP-1 ~/mub/bunne-grid.frag` (box keeps the shader; wall stopped
after measurement).

### 4. ASCII bunny flip-book player — the `ascii-bunnies` row's design rule, proven

`benchmarks/raw/mub-bunne-hop.sh`: 4-frame pure-ASCII hop cycle, bash
builtins only. The row demanded a fork-free player ("no animation may own
a process that outlives it") — **proven by strace census: exactly 1 clone
for an entire multi-cycle run** (the init `exec 9<> <(:)` whose held pipe
makes `read -t` a fork-free sleep), zero forks per frame, exits cleanly.
Timing exact: 25 frames × 90 ms = 2,265 ms wall (~0.6 ms/frame overhead).
Player + frames are repo-shippable shapes when the row un-defers (Phase 4
step 5, after the idle-RAM number is hit — unchanged).

### 5. fastfetch with a bunny ASCII logo — 2.5 ms, budgeted

The audit's "fastfetch allowed but budgeted" now has its number:
`fastfetch --logo <bunny.txt> --structure title:os:kernel:uptime:memory`
runs in **2.5 ms ± 0.5** (hyperfine, n=10, warm). The 4-line ASCII bunny
renders next to the fetch block (logo file on the box at
`~/mub/bunne-logo-real.txt`). Even in the strict per-terminal bucket this
is affordable; as MUB opt-in it's free guilt. Also: gpupaper ships a
`matrix.frag` — digital-rain wall screenshot deposited as a gallery
alternative (`benchmarks/raw/mub-matrix-wall.png`).

## Cost ledger so far (MUB switched ON, everything measured tonight)

| piece | resident | per-use |
|---|---|---|
| gradient ring | 0 | 0 (same pass as solid) |
| cursor trail | 0 | ~2× kitty GPU render while cursor moves |
| shader wallpaper | ~131 MB PSS + ~3% core (hybrid, pinned) | — |
| bunny flip-books | 0 (process exits) | ~0.6 ms/frame print |
| fastfetch bunny fetch | 0 | 2.5 ms per terminal open (opt-in) |

**MUB switch mechanism (sketch, undecided):** a `bunne-rice mub|default`
script — swaps the kitty include, the niri ring block, starts/stops
gpupaper, points the palette file — one-shot, no daemon. The palette-
generator half (matugen/wallust templating) is already a Phase-4 candidate
in the dotfiles research; MUB rides the same mechanism with a second
palette. Packages so far: `gpupaper` (AUR) only; everything else is config.

## Palette pipeline eval (doubles as the C10 Phase-4 candidate eval — measured)

The dotfiles research named "matugen and wallust, the two live engines" as
the palette-templating candidates. Tonight's hands-on **corrects that for
this repo's actual need** (a hand-designed static palette, not
wallpaper-extracted):

- **wallust has left the official repos** — only `wallust-git` remains in
  the AUR (+3 votes). Provenance downgrade since the research was written.
- **matugen graduated to `extra` (4.2.0)** — but it is a Material-You
  *generator*, and it tones/harmonizes even `custom_colors` through its
  tonal system: the hand-picked `#ff2ec4` comes out `#fab1d9` (pastel),
  **`blend = false` does not stop it**, and no `.source` passthrough
  exists in the template context (probed; "Value does not exist"). For an
  exact hand palette, matugen fights its own grain — the brittleness
  doctrine's textbook mismatch. One-shot runtime 13.1 ms ± 0.1.
- **The 5-line `envsubst` templater wins**: palette as an env file
  (`~/.config/bunne/palette.env`), templates with `${BUNNE_PINK}` holes,
  `envsubst < tmpl > out` per app + reload hooks. **Exact colors, 2.3 ms
  ± 0.1, zero new packages** (gettext is base-adjacent). This is also the
  MUB switch mechanism for free: two palette files, one render loop, one
  `SIGUSR1`/`makoctl reload`/`niri msg action load-config-file` hook set.

Verdict for the author: skip the engines; the C10 "one palette source"
requirement is a dozen lines of envsubst. matugen stays the right tool for
wallpaper-derived theming — a thing this repo deliberately doesn't do
(the palette is designed, not extracted). matugen left installed on the
test box for play; removable.

### 6. niri custom window-open shader — the catalog's #1, validated on hardware

niri's config accepts **custom GLSL for window open/close/resize
animations** (documented `open_color(coords_geo, size_geo)` entry point +
`niri_clamped_progress`). Wrote a "neon materialize": a blazing pink→cyan
scanline sweeps down the new window with a fading neon body — mid-animation
frame captured at `benchmarks/raw/mub-open-shader-frame.png`, zero shader
errors in the journal, `niri validate` clean. **Zero packages, GPU cost
only while a window is opening.** The open-shader is procedural (draws
instead of the window during the animation, alpha-blended by progress —
it cannot sample the window texture; resize shaders can). Config fragment
lives in the raw frame's sidecar note; box config reverted.

### 7. Audio-reactive desktop: `kitten panel --edge=background` + cava — validated

kitty's panel kitten draws a kitty surface as the desktop background (niri
listed "fully working" in kitty's own docs). cava (extra 0.10.7) with
`gradient_color` in the bunny palette, fed a synthetic sine over its FIFO
input (no audio played — it was 00:30): **mirrored neon spectrum bars
rising from the desktop floor** — `benchmarks/raw/mub-cava-panel.png`.
Price: one more kitty instance (~54 MB anon floor + shared maps; measured
259 MB PSS with the usual file-backed caveat) + cava at **4.0% of one core
while fed**, ~0 when silent. Zero new packages beyond cava. For real use
it reads the PipeWire monitor instead of the FIFO.

### 8. Window-close "de-rez" shader — the open shader's companion, validated

Same interface (`close_color`), reversed sweep: the window collapses
downward behind a falling neon line. Frame:
`benchmarks/raw/mub-close-shader-frame.png`. Zero packages; config
reverted after capture.

### 9. DankMaterialShell measured — the first mega-shell RAM number anyone has

The catalog's own gap ("no published numbers for ANY shell") filled:
`extra/dms-shell 1.5.3` launched first-try on niri (`dms run` — full bar
with workspaces/clock/weather/tray/battery + Material onboarding;
screenshot `benchmarks/raw/mub-dms-shell.png`). Cost after 30 s settle:

| process | PSS |
|---|---|
| quickshell (`qs -p /usr/share/quickshell/dms`) | 441.4 MB — **277.9 MB Pss_Anon** (real QML heap) + 164.4 MB file |
| dms helper daemon | 44.3 MB |
| **total** | **~486 MB PSS, 0.0% idle CPU** |

Caveats: minutes-old session (quickshell has an open long-uptime leak
issue, #678 — expect growth, re-measure over hours before adopting);
unconfigured defaults. **Verdict shape: the full-dashboard path exists,
is niri-first and official-repo, and costs ~half a GB — inside MUB's
license on a 64 GB box, categorically outside the default theme** (~80%
of the entire current session budget). dms-shell left installed (not
running, nothing enabled) for the author's own play; removable in one
command.

## Composed scene (all measured pieces together)

`benchmarks/raw/mub-composed-scene.png`: shader wall + neon gradient ring +
MUB-palette kitty (envsubst colors, cursor_trail on) running the bunny
fetch and flip-book. Total marginal cost of everything visible: **~131 MB
PSS + ~3% of one core** (the wall) — every other element is free or
pay-per-use.

## Web catalog (deep-dive research agent, 2026-08-25 — verified against archlinux.org/AUR same night)

Three cross-corrections from tonight's hands-on before the catalog: (1) the
agent's palette suggestion (matugen) is **refuted for this repo's
hand-designed palette** — measured above, it tones custom colors and
envsubst wins; (2) gpupaper's "no published numbers" cell is now filled by
our own measurement (131–327 MB PSS decomposition above); (3) its
swaylock-effects "avoid — unowned code in the auth path" verdict matches
the provenance call made here independently.

### The agent's shortlist (top cool-per-complexity)

1. **niri custom animation shaders + v26.04 blur** — niri config accepts
   custom GLSL for window open/close/resize animations (in-tree examples);
   blur via `ext-background-effect`. Zero packages, GPU only while
   animating. *(Prototyped below.)*
2. **gpupaper** (AUR 0.1.3) — Shadertoy-compatible GLSL wallpaper;
   single-author/young is the named risk; shaderbg / neowall are fallbacks.
   *(Prototyped + priced above.)*
3. **`kitten panel --edge=background` running cava** (cava is
   extra/0.10.7) — audio-reactive desktop from software already in the
   rice; kitty docs list niri "fully working". *(Probed below.)*
4. **kitty `cursor_trail`** — one conf line. *(Priced above.)*
5. **swaylock-plugin** (AUR -git, mstoeckl, active Aug 2026) — runs any
   layer-shell wallpaper program as the lock background (shader lock
   screen); self-labelled experimental → MUB-only, plain swaylock stays
   the recovery path. swaylock-effects itself is dead upstream (twice) —
   avoid.
6. **mpvpaper** (AUR 1.9, active) — video wallpaper with documented
   `--auto-pause` self-throttling; also audio-reactive via mpv lavfi.
7. **DankMaterialShell** — **extra/dms-shell 1.5.3, niri-first** (bar,
   launcher, dashboard, notification center, lock, theming; deps
   quickshell+dgop). The one-package mega-shell path if MUB ever means a
   full dashboard takeover. Noctalia (AUR -git, niri-first, v5 beta) is
   the alternative. No published RAM numbers for ANY shell — measure
   before adopting (quickshell has an open long-uptime leak issue #678).
8. Palette half: superseded by tonight's envsubst verdict (above).

### Other catalog notes worth keeping (full agent tables in the session log)

- **eww is maintenance-mode** (last release 2024) — the ecosystem moved to
  Quickshell/Astal; skip.
- **swww is archived on GitHub** — its successor **awww is in extra**
  (0.12.1) for animated transitions; wpaperd (extra) for cycling. MUB
  wants shaders, so these are side notes.
- **shiftpaper** (AUR 0.1.0, 2026): parallax depth-estimation wallpaper —
  genuinely novel "holo" effect, on-theme, young.
- **windowtolayer** (AUR 0.3.1): any Wayland window becomes the wallpaper
  → unlocks projectM-as-desktop (extra/projectm) on the 4090.
- **linux-wallpaperengine**: highest ceiling, but requires owning Steam
  Wallpaper Engine — breaks clean itemization; excluded.
- **vicinae** (AUR, weekly releases): Raycast-style launcher, niri
  documented, resident server — a MUB-mode fuzzel upgrade candidate,
  measure before adopting.
- **wayneko** (AUR -git): neko sprite running along the screen bottom —
  **resprite it as a bunny**; peak whimsy, trivial cost.
- **tte / terminaltexteffects** (AUR): `fastfetch | tte decrypt` login
  flourish; cbonsai/unimatrix (custom charsets → bunny-glyph rain);
  cool-retro-term (extra) as a dedicated CRT terminal — kitty refuses
  arbitrary shaders by design, ghostty (extra) is the shader-terminal if
  ever wanted, itemized as MUB-only.
- **swaync** (extra 0.12.6): CSS-themable notification center — the
  MUB-mode mako replacement candidate; resident, measure first.
- Toggle prior art: symlink-flip + live reload is settled art (kitty
  SIGUSR1, `makoctl reload`, niri auto-reload + `include optional=true`
  since 26.04) — matches the envsubst switcher sketch above.
