# Changelog

## 0.1.0-beta.1 — 2026-09-21

First distribution beta, following local prototypes.

- Mark Zygor's recommended reward with its silver gear-and-Z emblem.
- Keep the recommendation distinct from Dialogue UI's existing upgrade arrows.
- Show whether the recommendation is an equipment upgrade or vendor value.
- Cache scoring and clear markers when quests, equipment, or specialization change.
- Retry delayed item information with a bounded polling window.
- Add `/duizygor` diagnostics and pause on compatibility failures.

Validation: Lua 5.1 syntax check and 12 mocked behavior tests pass. Recommendation
and silver emblem verified in-game by the author. Broader theme/size and gamepad
coverage remain unverified.
