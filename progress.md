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

## Generated sprite and difficulty pass

- Generated a new top-down crimson future-bike sprite, removed its chroma-key background, and trimmed transparent padding to a 290x1087 RGBA asset.
- Replaced the wide vector fairing with the generated sprite while preserving lean, jump, shadow, and crash feedback.
- Narrowed the collision body from 44 to 30 logical pixels and shortened it from 108 to 96.
- Increased the opening spawn delay from 0.8s to 1.1s and relaxed the traffic interval from 1.05s/0.52s minimum to 1.25s/0.68s minimum.
- Verify sprite clarity at neutral and full lean, then rerun normal-collision and jump-clear regressions.
- Generated sprite passed screenshot inspection at full lean; it reads clearly without the previous wide silhouette.
- Normal collision regression passed (lives 3 to 2 after 250 frames).
- Timed jump-clear regression passed (`clears=1`, `jumps=1`, lives remains 3).

## Cyber traffic and road pass

- Generated and keyed four overhead traffic sprites: blue Model 3, white Model Y, gold Cybercab, and silver Cybertruck.
- Replaced generic colored traffic rectangles with rotating generated vehicle types and type-specific dimensions.
- Rebuilt the daytime road as a dark cyberpunk city route with moving building strips, cyan/magenta edge rails, and violet lane light trails.
- Verify every traffic model appears, transparent edges remain clean on the dark road, and steering/jump/collision behavior is unchanged.
- Traffic montage and gameplay screenshots passed alpha-edge and silhouette inspection for all four models.
- Early gameplay shows Model 3 then Model Y; later jump capture shows Cybercab and Cybertruck.
- Normal collision still reduces lives from 3 to 2; jump clear still records `clears=1`, `jumps=1`, with 3 lives.

## Generated city and curved-road pass

- Generated a restrained top-down cyberpunk megacity background with rooftops, machinery, wet concrete, and sparse cyan/magenta light.
- Replaced the procedural neon-box side scenery with a compressed scrolling WebP city texture.
- Added a gentle scrolling S-curve shared by road geometry, lane markings, traffic lanes, player bounds, and observable game state.
- Verify curve readability, traffic alignment, player bounds, collision, and jump clear.
- Curved-road gameplay screenshot passed: road shape is readable, generated city sides remain subdued, and traffic follows lane curvature.
- Center-lane collision passed on the moving curve (lives 3 to 2).
- Curved-road jump clear passed (`clears=1`, `jumps=1`, lives remains 3).

## Automatic level pass

- Added four distance-driven stages: straight onboarding, gentle bends, faster esses, and a wide hairpin district.
- Level progression is automatic and shown in the HUD plus a short stage banner.
- Generated a restrained wet-asphalt texture and replaced neon road rails with metal guard edges, pale lane paint, and sparse amber reflectors.
- One `roadCenter(y)` contract continues to own road rendering, traffic paths, collision alignment, and player bounds across all levels.
- Verify the simplified road surface, straight Level 1, automatic transition, later curve amplitudes, collision, and jump clear.
- Level 1 screenshot passed: straight, quiet wet-asphalt surface with subdued metal/amber edges.
- Automatic transition reached Level 2 at the configured distance with 3 lives intact.
- Added a two-second smooth road-shape blend so existing traffic does not jump sideways when a new level begins; transition capture observed `roadBlend=0.4` mid-blend.
- Level 1 collision passed (lives 3 to 2) and jump clear passed (`clears=1`, lives remains 3).
