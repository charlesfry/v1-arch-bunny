# Bunny wordmark

Hand-drawn letterforms on a fixed column grid (B at 0, u at 6, n at 11, n at 16,
E at 21), 24x4. **The two `n`s carry the ears** — that is the whole idea, and it
is why the wordmark is a bunny rather than a word with a rabbit next to it.
The `B`'s counter holds an eye.

| Variant | Frames | Canvas | Loops | Description |
|---|---|---|---|---|
| `wordmark` | 6 | 24x4 | yes | The second `n`'s ear twitches, then the first tips |
| `wordmark-blink` | 4 | 24x4 | yes | Ears still, the `B`'s eye blinks |

Both animate deliberately: a static logo would fail the validator's two-frame
minimum, and the greeter wants something alive. The motion is kept to a single
character so it never distracts.

## Notes

- **No generator was used**, per the house rule. Several drafts that looked like
  `figlet` output were discarded — they were legible but generic, and they had
  no place to put the ears.
- **A draft using `‾` (overline) was caught by `check.sh`** as non-ASCII. It
  looked right in a terminal and would have broken on any font without the
  glyph; this is exactly the failure the ASCII-only rule exists to prevent.
- **24 columns wide**, so it fits comfortably in any terminal. A larger hero
  lockup pairing this with the 12x6 side sprite is still unbuilt.
