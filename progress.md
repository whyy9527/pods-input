Original prompt: 东西做得不错呀，可以加点游戏性吗？

## Goal

Turn the Web Racer sensor demo into a small arcade game while keeping AirPods tilt and explicit centering central to the experience.

## Current slice

- Add start/restart flow, obstacle dodging, score, speed progression, lives, and best score.
- Preserve keyboard fallback and the Center control.
- Add deterministic game-state and time-step hooks for browser testing.

## TODO

- Arcade loop implemented: start/restart, patterned traffic, score, speed progression, lives, crash feedback, best score, fullscreen.
- Playwright verified movement, collision/lives, scoring, game over, best score, and restart.
- Center was blocked by the start overlay; raised the persistent controls above the menu.
- Corrected Center interaction verified; command reached PodsInput.
- Long idle hardware session exposed repeated recovery churn; added exponential watchdog backoff.
- Fullscreen verified through the persistent button (`fullscreen: true`).
- Final regression passed for movement, scoring, speed progression, collision/lives, game over, best-score persistence, restart, Center, and fullscreen.

## Follow-ups

- Test difficulty and steering comfort with several people before tuning constants.
- Consider sound and collectible power-ups only after the one-minute core loop feels good.

## Motorcycle pass

- Replaced the player car with a narrower top-down motorcycle and rider.
- Added smoothed visual banking tied to the same AirPods/keyboard steering value.
- Kept obstacle traffic as cars and narrowed the player collision body.
- Verify left/right banking screenshots and collision regression.
- Left/right banking screenshots passed independently (`lean=-0.75` and `lean=+0.75`).
- Narrow motorcycle collision regression passed (center impact reduced lives from 3 to 2).
- Review added tabular HUD numerals and 40px minimum control hit areas.

## Futuristic fairing pass

- Reworked the player into a low-slung crimson future bike inspired by the visual language of Kaneda's motorcycle.
- Added a wide integrated fairing, mostly enclosed wheels, dark cockpit, side pods, white decals, and yellow console detail.
- Kept original vector geometry and no external film assets or logos.
- Neutral and left-banked silhouettes passed screenshot inspection.
- Wider collision regression passed (center impact reduced lives from 3 to 2).
- Final review found no protocol, game-loop, or UI regressions.

## Jump pass

- Added upward head-flick detection using a 220ms relative pitch window instead of drift-prone absolute pitch.
- Initial live threshold: pitch delta below -4.5 degrees.
- Added Space fallback, 0.85s jump arc, 1.1s cooldown, airborne collision bypass, shadow/scale feedback, and 25-point vehicle-clear bonus.
- Verify takeoff/apex/landing, collision bypass, cooldown, and ordinary collision regression.
- Apex visual passed (`jumpHeight=90`).
- First clear attempt was confounded by live asynchronous tilt during deterministic stepping.
- Test mode now zeroes live tilt and exposes `clears`; real-time play remains unchanged.
- Clear bonus triggered, exposing a landing-tail bug where the same cleared car could collide again.
- Cleared (`jumped`) obstacles now skip all later collision checks.
- Deterministic clear passed (`clears=1`, lives=3); no-jump collision passed (lives=2).
- Added observable `jumps` count for live AirPods gesture verification.
- First live gesture did not cross -4.5 degrees; lowered threshold to -2.5 based on measured ~3-degree gesture and sub-0.5-degree idle noise.
- Five-second idle test produced no false jump.
- Live browser capture did not observe a deliberate flick (range -0.16 to +0.74 degrees), so hardware trigger direction/threshold remains a user-playtest item.
- Work review passed with hardware gesture tuning explicitly retained as residual risk rather than reported as verified.
