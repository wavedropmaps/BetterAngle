# Dive / glide transition handling

When Fortnite switches between skydiving and gliding, the camera's turn rate
changes over roughly 700 ms (diving turns ~9% faster at the same
sensitivity — `AngleLogic::kDiveMultiplier`). Mouse movement inside that
window can't be converted to degrees with a single fixed scale, so BetterAngle
offers two ways to handle it. The choice is in **General → Dive / glide
transitions** and is saved in `settings.json` as `inputLockMode`.

## Block input (`inputLockMode: 0`, default)

`BlockInput(TRUE)` freezes all keyboard and mouse input for 700 ms on every
transition (300 ms after alt-tabbing back into Fortnite). Nothing moves, so
the angle stays exact.

Known cost — **ghost walking**: Windows discards key releases that happen while
input is blocked. If you let go of W during the freeze, the game still thinks
W is held when input resumes. Earlier versions tried to repair this by
re-sending synthetic key-ups (`SendInput`), polling key state and similar;
none of that was reliable and it was removed. Low-level hooks
(`WH_KEYBOARD_LL` / `WH_MOUSE_LL`, v5.0.19) were rolled back the same day.

## Blend (`inputLockMode: 1`)

Input is never blocked or injected. Instead `AngleLogic::SetDivingState`
eases the degrees-per-count scale linearly from the old value to the new one
over `transitionBlendMs` (default 700 ms, adjustable 100–2000 ms). Movement
during the window is counted at the interpolated scale.

If the mouse moves while a blend is in progress the reading contains
estimated movement: the HUD label changes to **~ ESTIMATED ANGLE** (amber)
until the angle is zeroed. With no movement during the window the angle is
exact. Worst-case error is a fraction of the ~9% scale difference applied
only to movement made during the window.

After alt-tabbing back in, blend mode ignores BetterAngle's own copy of mouse
deltas for 300 ms instead of freezing input.

## Tuning the blend duration

Match `transitionBlendMs` to how long the camera takes to settle: turn at a
steady rate through a transition, then compare the HUD against the in-game
compass. If the HUD overshoots going into a dive, lengthen the blend; if it
undershoots, shorten it.
