# Offline campaign v051

90 original, deterministic stages in nine regions. The ten encounter archetypes use open approaches, twin forts, outer rings, nested rings, three forts, a maze and four compartments. Each region changes positions, defenses, wall entrances, troops, guards and traps. Rotation always includes buildings, guards and traps. No base or character art is replaced.

Reference: Supercell's Single Player Attacks support page documents 90 villages, one star to unlock the next, unlimited retries to earn three stars, and no battle time limit: https://support.supercell.com/clash-of-clans/en/articles/single-player-attacks-2.html . These rules inform this campaign. Layouts, names, troop budgets, defense numbers and balance are original to Xian; this is not a claim of identical Clash of Clans layouts, internal technology or numerical difficulty.

## Rules and persistence

Open **ออฟไลน์** without signing in. Select a region and stage, inspect the defense list and suggested tactic, then attack. Every stage supplies its own army. One star each for the hall, 50% destruction and 100% destruction; walls and traps are excluded from the denominator. There is no time limit. End the battle to retain achieved stars, or abandon without recording. Unlocked stages can be replayed; only the best score is stored. The next stage requires at least one star in its predecessor.

This mode requires no connection and does not consume online troops, modify the player's village or award online currency. Match-3 beta jade rules are unchanged. Original 12-stage practice simulation remains available internally for regression testing.

`campaign_progress_v1.json` stores versioned stars and selected stage locally. Writes use a temporary file and atomic rename with a backup of the previous complete save. Corrupt primary data falls back to the backup. UI reports write failure. Clearing app data or uninstalling removes local progress; this campaign does not add cloud synchronization.

## Defenses

- Cannon: ground only, single target.
- Mortar: ground splash, cannot fire inside a two-cell minimum range.
- Anti-air crossbow: airborne units only.
- Flame tower: retains one target, ramps damage, resets its lock outside range.
- Storm tower: strikes one target and up to two nearby units.
- Existing archer and ward towers retain recognizable roles.
- Ground bombs and air mines trigger once per attack and affect only the matching altitude.

New mechanisms use real meshes, the existing material atlas and the same world grid/camera as village geometry. Existing building images and troop sizes are preserved. All campaign configuration is local in `campaign.gd`; combat is in `practice_sim.gd`, shared with the regression-tested practice mode.

## Verification

`tests/campaign.gd` checks all 90 distinct layouts, deterministic data, occupancy, deployment borders, no timeout, weapon altitude/minimum range, one-shot mines, slow-unit path progress, progression locks, best-score saves, backup recovery and UI navigation.

`tests/campaign_balance.gd` simulates split and focused attacks, trying additional approach directions where needed. The CI artifact contains per-stage stars, damage and elapsed time in `campaign-balance.json`. It requires at least one tested one-star attack per stage, so all progression gates are demonstrably reachable. It does not establish optimal player tactics or exact reference-game difficulty.

`tests/campaign_studio.gd` captures the map, final region, stages 1/30/60/90, results and five new defense models under real rendering. Existing art/ground, movement, touch and online UI regressions also remain in CI. Actual physical Android play is still needed for device-specific input/performance evaluation.
