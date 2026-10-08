# Xian of Clans 0.53 — production and formations

- Up to five fighter halls unlock at sect hall levels 1, 3, 5, 7 and 9. Each has a stable ID and independent serial queue; multiple halls run concurrently. Existing jobs keep their completion time and are assigned to the first legacy hall.
- Tap a troop portrait to queue one or use +5. Queue tabs show each hall, progress, pause/resume, cancellation and jade completion. Rapid taps are buffered while a request is in flight; failed requests stop subsequent buffered commands. Troop unlocks depend on the selected hall.
- Cancellation refunds the paid resources; overflow stays in an account reserve until storage space opens. Paused jobs do not complete offline or enter the garrison.
- Jade completes building construction/upgrades, one soldier or a whole selected queue, post-raid repair, and the raid result wait. Price is one jade per started five minutes, minimum one. Server calendar/check-in boundaries and combat weapon cooldowns are game rules, not paid countdowns.
- Three placeable formations: storm (hall 2, radius 3.2), sword (hall 3, radius 2.8), fire (hall 4, radius 2.6). Each activates once per battle and deals area damage for four seconds. Repaired bases rearm them.
- Lightning tower (hall 4) attacks ground/air enemies within 5.2 cells every two seconds. Custom original meshes and bounded storm/sword/fire/lightning effects; no Red Alert assets copied.
- Online raids retain the existing automated power simulation. The new server-side defense pass checks ten approach lanes, armor and range and emits authoritative effect events; it is not the offline spatial troop AI. Offline campaign formations use actual unit positions. New defenses appear progressively in the 90-stage campaign.
- Includes 0.52 player raids, 60% resource loss excluding jade, 20-second owner-triggered repair, history and revenge.

Validation: rolled-back server fixture tests for unlock limits, parallel queues, serial ordering, pause/resume, selected-hall unlocks, refunds, jade charges, idempotency, repair/raid speedups, range/activation; Godot smoke, new UI/combat tests, previous raid tests and campaign regressions. Android CI runs the existing validation suite and captures production/formation screenshots before export.

Reference: Red Alert 2 original manual, production portraits, queues, pause/resume/cancel; adapted for mobile and independent halls requested by the owner: https://manualzz.com/doc/24314810/westwood-studios-red-alert-2-user-manual
