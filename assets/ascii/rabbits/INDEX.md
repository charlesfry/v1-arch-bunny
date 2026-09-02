# ASCII rabbit animations

Frame files for the `ascii-bunnies` slot in `CHOICES.md` (status `deferred`).
**Art assets only** — nothing here runs, and no player exists yet. Rules and the
canonical base sprites are in [`BRIEF.md`](BRIEF.md); [`check.sh`](check.sh)
validates a directory.

Frames are `NNN.txt`, contiguous from `001`, every frame in one animation the
same width and height, space-padded, printable ASCII only, no colour. Colour is
applied at render time from the project palette, so a frame never carries its own.

**Frames are sprite-sized, never terminal-sized.** A bunny travelling across the
screen is the player's job at runtime from `$COLUMNS`; 12x6 fits any window
anyone will realistically open.

## Core — side profile, 12x6

The workhorse set. Everything else derives from this sprite.

| Animation | Frames | Loops | Description |
|---|---|---|---|
| `sit` | 4 | yes | The idle. One slow blink per cycle |
| `ear-twitch` | 6 | yes | Front ear folds down and returns |
| `alert` | 4 | no | Ears pinned back snapping upright, held |
| `loaf` | 4 | yes | Flat loafing pose with a blink |
| `hop` | 4 | yes | Crouch, launch, airborne, land — in place |

## `sets/front-view` — head-on, 12x6

| Animation | Frames | Loops | Description |
|---|---|---|---|
| `sit-front` | 4 | yes | Idle with a slow blink |
| `ear-twitch-front` | 6 | yes | Right ear folds over and returns |
| `head-tilt` | 4 | no | Leans right, held |
| `alert-front` | 4 | no | Ears rise to bolt upright, held |
| `nose-wiggle-front` | 4 | yes | Muzzle shifts side to side |

## `sets/motion` — 12x6

| Animation | Frames | Loops | Description |
|---|---|---|---|
| `binky` | 6 | no | The joy-leap with a mid-air twist |
| `stretch` | 5 | no | Front paws forward, body extends long |
| `flop` | 5 | no | Sitting to flopped flat on one side, held |
| `perk` | 4 | no | Flopped back up to sitting, held |
| `dash` | 4 | yes | Low run, ears pinned back, legs gathering |
| `dig` | 4 | yes | Front paws scrabbling, debris flying |

## `sets/glyphs` — micro, max 3 rows

Eight glyphs for prompts, spinners and progress indicators. See
[`sets/glyphs/NOTES.md`](sets/glyphs/NOTES.md) for the shared vocabulary and the
rejections.

## `sets/cyberpunk` — 24x10, one piece at 36x12

Six pieces built on the canonical front sprite. See
[`sets/cyberpunk/NOTES.md`](sets/cyberpunk/NOTES.md). `netrunner` (bunny at a
terminal, body hidden behind the desk edge) and `neon-rain` (skyline, sparse
rain, a BUNNY sign, wet ground) are the strongest. **`neon-rain` needs 36
columns and has no fallback** — a player must check `$COLUMNS`.

## `sets/logo` — 24x4

The Bunny wordmark, ears carried by the two `n`s. See
[`sets/logo/NOTES.md`](sets/logo/NOTES.md).

## Notes

- **`rejected/` holds culled work, which is never deleted.** A ledger of only
  the winners throws away the expensive half of the information, and it lets any
  call recorded here be overruled.
- **`rejected/front-view-v1`** — the first head-on set. Rejected at the sprite
  level, not for polish: the head was a rectangle with the ears floating
  detached above it, which reads as an owl. `head-tilt` conveyed its tilt by
  sprinkling apostrophes around a static head, which reads as artifacts, and
  `sit-front`'s "breathing" deleted the chin and restored it, which reads as
  flicker. Redrawn from the canonical sprite.
- **`rejected/glyphs-v1`** — `prompt-sigil` was `^o^`, a smiley rather than a
  rabbit; `tail-flick` failed twice and should not be retried at this scale.
  Reasons in `sets/glyphs/NOTES.md`.
- **Still missing:** the large 36x14 screensaver set, a hero portrait, and a
  lockup pairing the wordmark with the side sprite. `sets/cyber-action` was in
  progress at the time of writing.
