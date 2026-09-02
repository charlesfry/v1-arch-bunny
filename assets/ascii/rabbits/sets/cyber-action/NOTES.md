# Set: cyber-action

Action cyber-bunnies. Heroic and deliberately ridiculous, drawn straight — a tiny fluffy
animal with a laser is only funny if nobody in the frame thinks it is funny.

Every frame here uses the canonical side profile from `BRIEF.md`, mirrored to face right
(see *Calls made* below). Ears are `|\|\` up, `\ \` back, `/|/|` blown forward, `\_\_` flat;
the head is always `/  o  )`; the base always closes with `\__/\__/`.

| Animation | Frames | Canvas | Delay (ms) | Loops | Description |
|---|---|---|---|---|---|
| laser-shot | 6 | 24x10 | 140 | no | Bunny on a scrap crate braces, fires a beam right, and is thrown off its feet by its own recoil |
| robot-smash | 8 | 36x12 | 160 | no | A boxy robot walks in, the bunny leaps, the head comes off, the torso tears in two, bunny lands on the wreck |
| scrap-dig | 6 | 24x10 | 120 | yes | Bunny burrowing head-first into an angular scrap heap, ears flat back, junk arcing out behind it |
| carrot-blade | 5 | 24x10 | 110 | yes | A carrot with a leafy hilt and an energy blade, swung overhead through to the ground and snapped back |
| mech-suit | 5 | 24x10 | 180 | yes | Bunny piloting a walking mech, ears visible through the cockpit canopy, reactor light sweeping the chest |
| shield-up | 5 | 24x10 | 120 | no | A hard-edged energy shield grows from a seam, snaps open, deflects incoming fire. Held on the last frame |

`robot-smash` needs a 36-column window; everything else fits 24. All six exit 0 under
`./check.sh`.

## The two-subject problem

Every frame in this set holds a bunny *and* a machine, and at this resolution they merge into
one unreadable mass unless kept apart. Two rules did the work:

- **Vocabulary split.** Bunny is `/ \ ( ) o _`; machine is `| [ ] = + - *`. Held to strictly
  enough that the eye separates them even where they touch. The only deliberate crossing is
  `carrot-blade`, where the joke *is* one object made of both — soft `\|/` fronds, hard
  `+====>` blade.
- **A real gap in columns.** Where the two subjects meet, there is a channel of at least two
  empty columns and the impact lives inside it as sparks. `robot-smash` frame 5 was redrawn
  for exactly this: the bunny's nose now stops at column 20, the robot's head starts at 23,
  and the burst occupies 22.

## What I rejected, and why

- **laser-shot v1** — bunny standing on flat ground: four dead rows at the top of every frame,
  and the closing frame was the opening frame shifted one column, so nothing had happened.
  Rejected. Put the bunny on a scrap crate and made the recoil *launch* it, which fills the
  vertical and turns "recoil" into the punchline.
- **laser-shot barrel `_[+]==` running straight into the beam** — fired frames read as one
  long horizontal bar, so the beam did not register as a beam. Added a `|` muzzle plate:
  `_[+]=|======`.
- **robot-smash v1 sparks** — placed by eye, they landed on the bunny's eye (turning `o` into
  `*`) and on the robot's own outline, where they read as printed decals rather than impact.
  All spark positions are now checked against both sprites' extents.
- **robot-smash v2 frame 7** — the two torso halves sat three columns apart on the same row and
  read as one intact torso with a spark on it; the falling head overlapped the right half.
  Rejected. Halves now separated by four columns *and* offset by a row, head moved clear.
- **scrap-dig v1 occlusion** — clipping the bunny at one fixed column produced a straight
  vertical cut, which reads as a rendering bug, and left a void wherever the pile did not
  actually reach that column. Rejected. Occlusion is now per-row, following the pile's real
  left profile, so the bunny disappears under a slope.
- **scrap-dig v2 pile** — face too shallow; six to eight empty columns between the bunny's cut
  edge and the nearest junk. Steepened the profile (cols 17/15/13/11/10 by row).
- **carrot-blade v1 hilt** — the fronds `\|/` sat flush against the feet `\__/\__/` and read as
  part of the bunny, and the vertical blade was glued to the side of the head. Moved the hilt
  two columns right and added a `_` paw so the sword is *held* rather than fused.
- **Fronds that rotate with the blade** — tried, rejected. Four hand-placed frond clusters, one
  per pose; in the low pose they collided with the blade and in every pose they read as
  clutter rather than leaves. The fronds are now a fixed tuft at the hilt, which is also how a
  real grip works.
- **mech-suit body bob** — shifting the whole mech up a row on the passing frames. With the feet
  pinned to the ground line this read as flicker, the same failure `BRIEF.md` records for
  breathing-by-deleting-the-chin. Rejected in favour of a reactor light sweeping the chest
  panel: five distinct beats, silhouette never moves.
- **mech-suit 4-beat walk padded to five frames** — the repeated frame produced a visible hitch
  in the loop. Rejected; drew five genuinely distinct leg poses instead (close, spread, wide,
  rear foot lifting, foot swinging through).
- **shield-up v1** — a bunny raising a shield against nothing. Four empty rows and no reason for
  the shield to exist. Rejected. Added incoming fire entering from the right over two frames,
  which gives the shield a job and fills the canvas.
- **shield-up hollow panel `|    |`** — read as an empty box. Added a double centre spine
  `| || |`, which also makes the panel continuous with the seam it grew from.

## What I could not make work

Stated plainly rather than quietly dropped.

- **carrot-blade has no true downswing.** With the hilt on the body row and only one row between
  the feet and the ground, there is no room for a four-cell diagonal below horizontal. The
  follow-through is a shallow ground-skim (`\===>` on row 8) instead of a 45-degree chop. The
  consequence is that frame 4 to frame 5 — blade snapping back overhead — is the largest step
  in the cycle. The loop step (5 back to 1) is the *smallest*, so the quality bar's loop rule
  holds, but the recovery reads as a snap rather than a sweep. Deliberate, not an oversight.
- **scrap-dig's deepest frame (004) is the weakest thing in the set.** The bunny's body is a
  hollow `(        )`; clipping away the `)` leaves roughly five empty columns under the belly
  with nothing bounding them. Steepening the pile reduced the gap but could not close it
  without burying the bunny entirely. It reads as "face jammed in the junk", but it is the one
  frame I would redraw first given more time.
- **The carrot in carrot-blade rests entirely on `\|/`.** The blade itself is machine
  vocabulary, which is the gag, but it means a reader who does not take `\|/` for leaves sees
  a sword and no carrot. I could not find a 24-wide arrangement that both tapers like a carrot
  and reads as a blade; taper attempts (`+=--->`, `+==->`) just looked like a broken beam.
- **robot-smash frames 3 to 4** is a four-row, five-column jump. Poses only, no in-between. With
  eight frames total I spent them on the destruction rather than the arc, per the instruction
  that the coming-apart is the showpiece.

## Calls made where the brief was open

- **Mirroring.** `BRIEF.md` states the canonical side profile faces right, but its `(  o  \`
  construction — rounded face on the left, sloped neck on the right — reads head-left. Every
  animation in this set fires, leaps, digs or blocks to the *right*, so I mirrored the
  canonical sprite character for character (reverse the row, swap `(`/`)` and `/`/`\`),
  giving `/  o  )` with the nose on the right. Same animal, same construction, same closed
  base; only the facing changed. The ear glyph mirrors to `|\|\`, and the *unmirrored* `/|/|`
  is reused as the ears-blown-forward pose, so both proven ear shapes are still in use.
- **Canvas.** 24x10 everywhere except `robot-smash`, which took the full 36x12 allowance because
  a robot worth destroying has to be tall enough that a 5-row bunny looks outmatched.
- **`*` as a character.** Not in the brief's edge-building list, but sparks and muzzle glow are
  points of light, not edges, and no other printable character reads as one. Used sparingly
  and never as fill.
- **Ground line.** A row of `_` at the bottom of every animation. It is an edge (the floor), and
  without it the recoil launch in `laser-shot` and the leap in `robot-smash` have nothing to
  measure height against.

## Method

Every animation went through at least three build-and-read revision passes against the five
quality criteria, using `./check.sh --show` and reading the boxed output back. Frames were
composed with a throwaway Python sprite compositor kept in the session scratchpad, **not** in
this repo — it exists only so that sprite placement, per-row occlusion and spark positions
could be checked against each other's extents rather than counted by hand.
