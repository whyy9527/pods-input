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
