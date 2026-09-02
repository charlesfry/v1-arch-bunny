# Brief: ASCII rabbit flip-books

A self-contained task. Everything you need is in this file, `check.sh` next to it,
and the reference photos named below. **The author is away — do not ask questions,
do not wait for approval.** Where this brief is ambiguous, take the narrower
reading and record the call you made in `INDEX.md`.

Read `/home/char/github/arch-bunny/CLAUDE.md` first for the house style. The one
line that matters most here: **parsimony — every character must earn its place.**

## What you are making

Small ASCII animations of rabbits, stored as plain text frames, for terminal
ricing on a bunny-themed Arch config. Decision context is `CHOICES.md`, slot
`ascii-bunnies` (status `deferred`). Your output is *art assets only*. Nothing
you write will run at boot.

Deliverable, in `assets/ascii/rabbits/`:

```
<animation-name>/001.txt, 002.txt, ...   one directory per animation
INDEX.md                                 the catalogue, format below
```

## Hard rules — a violation makes the asset unusable, not merely worse

1. **Printable ASCII only** (0x20–0x7E). No Unicode, no braille, no box-drawing
   characters, no emoji. The terminal font is Fragment Mono with ligatures
   disabled; anything outside ASCII is not guaranteed to have a glyph.
2. **No color and no ANSI escape sequences.** Colour is applied at render time
   from the project's single palette file. A frame that carries its own colour
   creates a second source of truth and will be rejected outright.
3. **Every frame in one animation is exactly the same width and height**, space-padded
   to the full width on every line. The player overwrites frames in place; a
   short line leaves the previous frame's pixels on screen.
4. **Frames numbered `001.txt` upward, contiguous**, three digits, no gaps.
5. **Original work.** Do not copy ASCII art from the internet, and do not fetch
   anything — you have no network for this task. Draw it yourself.
6. **Do not use a generator** — no `figlet`, `toilet`, `cowsay`, `chafa`,
   `img2txt`, `jp2a`. Do not install any package. Photo-converted ASCII is mush
   at these sizes; this is hand-drawn line art.
7. **Write only inside `assets/ascii/rabbits/`.** Do not modify any other file in
   this repo, do not touch `~/github/gamedata` (read-only reference), and **do not
   `git add`, `git commit`, or `git push`.** The author reviews before anything
   is committed.
8. **`./check.sh <dir>` must exit 0 for every animation** before you are done.

## Size — terminals are not a fixed size

This is the constraint that shapes the whole deliverable. The window these play
in can be anything from a narrow split pane to a full screen, so:

- **Never bake terminal-sized frames.** A bunny hopping *across the screen* is
  the player's job at runtime — it knows `$COLUMNS` and can shift a sprite. Your
  frames hold the bunny, not the journey.
- **The standard box is 12 wide × 6 tall.** Every animation in the core list uses
  it. That fits any terminal anyone will realistically open.
- A **larger set, maximum 36 × 14**, is optional stretch work — only start it once
  the 12×6 set is complete and good, and mark the minimum size in `INDEX.md`,
  because the player must check the window and fall back.
- Within a movement cycle, keep the bunny on a **consistent baseline and facing a
  consistent direction**, so the player can translate the sprite sideways without
  it appearing to limp or slide.

## Reference photos — use them

`~/github/gamedata/img/bunny/` holds 68 real rabbit photos, and
`manifest.json` in that directory describes every one with a `mood` tag. **Read the
manifest first** (it is cheap), then open **no more than six images** — you are
after silhouettes, not a survey. These are the useful ones:

| File | Why |
|---|---|
| `bun57.webp` | Profile, both ears straight up — the core side-view sprite |
| `bun3.webp` | Profile, watchful — side view, different ear set |
| `bun25.jpeg` | Front-on, enormous ears bolt upright — the front-view sprite |
| `bun8.webp` | Ears fully erect, alert — the ear-up pose |
| `bun54.jpeg` | Caught mid-motion, front paws forward — the hop |
| `bun17.jpeg` | Standing upright on hind legs, sentinel posture — the alert pose |
| `bun1.jpeg` | Loafing in a bed — the resting/idle static |

Look at the actual proportions: ear length relative to head, how the hindquarters
sit higher than the shoulders in a loaf, where the eye falls. Getting those right
is what separates a rabbit from a generic blob with two lines on top.

## The animation list

Do them in this order. **Stop when quality drops — a short set of good ones beats
the full list padded with mush.** Six excellent animations is a complete success.

| # | Name | Frames | Loops | Notes |
|---|---|---|---|---|
| 1 | `sit` | 1 (static) | — | The hero pose. Everything else is derived from it. |
| 2 | `ear-twitch` | 3–4 | yes | One ear flicks and returns. Tiny motion, high charm. |
| 3 | `hop` | 4–6 | yes | Crouch → launch → airborne → land. Poses only; the player moves it. |
| 4 | `nose-wiggle` | 2–4 | yes | Two or three characters change. The smallest possible animation. |
| 5 | `alert` | 4–5 | no | Relaxed → ears snap upright. Ends held on the alert pose. |
| 6 | `wash-face` | 5–6 | yes | Both paws up over the ears and down again. |
| 7 | `thump` | 4 | no | Hind foot lifts and strikes. |
| 8 | `loaf` | 3 | yes | Barely-moving breathing cycle for a resting bunny. |

## Quality bar — this is what "the best ones" means

Judge every animation against all five. Any one of them failing means the
animation is not ready.

1. **It reads as a rabbit in under a second, and the ears are the tell.** At 12×6
   the ears are the only feature that survives. If the silhouette could equally
   be a cat or a mouse, it has failed.
2. **The silhouette persists across frames.** Consecutive frames must look like
   the same animal moving — change one to three features per frame, never redraw
   from scratch. Popping and morphing is the characteristic failure of
   hand-drawn flip-books and it is instantly visible.
3. **The motion reads without colour and without a caption.**
4. **Loops close cleanly** where the table says `yes`: the step from the last
   frame back to the first must be no larger than any step inside the cycle.
5. **No filler.** Line art, not halftone — build edges from `/ \ | _ ( ) ^ ~ - . '`
   and avoid dense shading fills (`#`, `@`, `%`, `8`). If a character does not
   describe an edge, delete it.

## How to work — the required review loop

Hand-drawn ASCII does not come out right the first time. For each animation:

1. Draw the frames.
2. Run `./check.sh --show <dir>`. It validates and then prints every frame inside
   a box so you can see the true extents.
3. **Read your own output against the five criteria above.** This is the whole
   point of the loop — a text animation is one of the few things you can genuinely
   review by reading it back.
4. Fix and repeat. **At least two revision passes before you accept anything.**

You may write throwaway helper scripts (a composer that pads lines, a differ that
shows which characters changed between frames) — put them in the session
scratchpad directory, **not** in this repo.

## `INDEX.md` — the catalogue you must leave behind

One table, plus a short notes section. The author reads this first on return.

```
| Animation | Frames | Canvas | Delay (ms) | Loops | Description |
|---|---|---|---|---|---|
| ear-twitch | 4 | 12x6 | 120 | yes | Sitting bunny, left ear flicks once |
```

Then, under a `## Notes` heading:

- **What you rejected and why**, one line each. A catalogue of only the winners
  throws away the expensive half of the information — this repo records rejections
  as a rule, not as an afterthought.
- **Anything you could not make work.** Say so plainly. This project's standing
  rule is *fail loudly, do not degrade silently*: an animation quietly omitted is
  indistinguishable from one that was never attempted. If `thump` never read as a
  thump, write that down.
- Any ambiguity in this brief and the call you made.

## Out of scope — do not do these

- **Do not write the player.** How these get displayed (shell greeter, idle
  screensaver, lock screen, keybind) is a deferred decision recorded in
  `CHOICES.md`; it is Phase 4 work and not yours.
- **Do not edit `CHOICES.md`, `docs/`, `README.md`, or anything outside this
  directory.**
- Do not add colour, a config format, a manifest schema, or a build step.

## Canonical base sprites — start from these, do not reinvent them

These two are **proven**: drawn, animated, and validated at 12x6 in this repo.
Every set should be recognisably the same animal, so build from these rather than
inventing a new rabbit. The first attempt at a front view failed by drawing the
head as a rectangle with the ears floating detached above it — it read as an owl.
That is the mistake these exist to prevent.

```
front view (12x6)          side profile (12x6, facing right)
   /| |\                      /|/|
   || ||                     / / |
  /     \                   (  o  \
 ( o   o )                 (        )
  \  v  /                   \__/\__/
   \___/
```

What makes them work, and what you must preserve:

- **The ears attach to the head.** They rise from the crown as a connected pair;
  they are never floating strokes above a separate shape.
- **The skull is curved, never a box.** `/     \` and `( )` for the sides. A
  straight horizontal top edge kills it instantly.
- **One eye in profile, two head-on**, and the muzzle sits below and between.
- **The base closes.** `\___/` or `\__/\__/` — an open-bottomed bunny reads as a
  smear.

Motions proven to read at this size, and how they are done:

- **Blink** — swap `o` for `-`. Instant and unmistakable; the cheapest life you
  can buy, and the right default idle.
- **Ear twitch** — fold ONE ear (`/| |\` to `/|  \` to `/|`, with the stem row
  following) while the other stays put. Asymmetry is what reads as alive.
- **Head tilt** — shift the whole sprite one column and pull in the far side
  (`)` closes, `\___/` becomes `\__/`). Do not sprinkle apostrophes and commas
  around a static head; that reads as artifacts, not motion.
- **Breathing** — do not attempt it by deleting and restoring the chin. That
  reads as flicker. Use a blink or an ear instead.
