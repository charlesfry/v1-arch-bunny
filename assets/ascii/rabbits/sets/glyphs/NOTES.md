# Micro-glyphs — max 3 rows

Tiny bunny motifs for places a 12x6 sprite will never fit: a shell prompt, a
spinner, a progress indicator. At this size you have around a dozen characters
total, so every one is load-bearing.

**The shared vocabulary**, kept deliberately consistent with the canonical 12x6
sprite in `BRIEF.md` so the machine reads as one design: upright ears are `| |`,
the head is `(o)`, and a fold or droop bends ONE ear while the other stays put.

| Glyph | Frames | Size | Loops | Description |
|---|---|---|---|---|
| spinner-ears | 4 | 3x1 | yes | One fixed ear, one rotating through `\| / - \` |
| prompt-sigil | 4 | 3x1 | yes | `/o\` prompt marker with a slow blink |
| blink-cursor | 2 | 3x1 | yes | Ears stay, the cursor bar blinks |
| hop-track | 8 | 6x1 | yes | Bunny crossing a fixed-width track |
| ear-flick-mini | 6 | 3x2 | yes | Right ear folds and returns |
| perk-mini | 3 | 3x2 | no | Ears splayed down rising to upright, held |
| chew-mini | 4 | 4x2 | yes | Jaw works: `.` `_` `.` `-` |
| hop-mini | 4 | 3x3 | yes | Whole bunny leaves the ground, ears intact |

## Notes

- **`tail-flick` rejected, twice.** At one row the tail can only appear and
  disappear, which reads as flicker rather than motion — the exact failure the
  brief warns about. A tail needs somewhere to move *to*, and there is no room
  for that beside a head at this scale. Both attempts are in
  `rejected/glyphs-v1/`. Do not retry it at 1-2 rows.
- **`prompt-sigil` was redrawn.** The first version was `^o^`, which reads as a
  smiley emoticon, not a rabbit — `^` is not an ear when there is no head under
  it. `/o\` puts the ears either side of the eye, which is the only arrangement
  that works in a single row.
- **`hop-mini` uses all three rows on purpose.** A bounce needs the sprite to
  leave the ground, and at two rows the ears have to be sacrificed to make
  space — which loses the one feature that says "rabbit".
- **`spinner-ears` and `hop-track` are kept from the first pass** unchanged; the
  spinner in particular is the best idea in the set, since it works as an
  ordinary spinner even for someone who never notices the ear.
