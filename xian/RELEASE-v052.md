# Xian of Clans 0.52 — player raids

- Raid menu scouts real players, including offline owners. Offline campaign stays in its own menu. No eligible opponent shows an empty result rather than substituting a bot.
- Player raids deduct 60% of water, rice and pills (rounded down to whole units) once per raid, independent of damage ratio; jade is untouched. Existing combat, garrison and four-hour shield remain.
- After battle, the owner’s next request starts one 20-second repair timer for all buildings. Rubble, smoke, scaffolds and workers appear, then the original layout and levels return. Repair is free and does not refund loot.
- Up to 20 defense reports retain attacker identity and losses. Revenge scouts the report’s actual attacker, respecting shields and availability.
- Backend migration preserves the currently deployed beta reward and retired-building refund behavior and guards against replacing a changed dispatcher. Its fixture tests run before commit.

Validation: Godot import/smoke and player raid UI test; authenticated dispatcher fixture tests cover offline targeting, exact losses, jade immunity, duplicate requests, repair start/deadline, unchanged balances, revenge identity, invalid reports and shield handling.
