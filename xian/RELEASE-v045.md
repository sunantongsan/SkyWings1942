# Xian of Clans v0.45 — ten troops and wall management

- Single-cell artwork now fits a 2.45-unit width; courtyard is a depth-tested horizontal 2×2 floor. Troops use smaller consistent scales. Original grass retained.
- Destroyed walls disappear only at breached segments. Other destroyed buildings retain ruins/smoke. Offline navigation opens the breached cell.
- Wall actions support one, contiguous straight row, or all; deletion has a confirmation and no refund. Upgrade dialog shows eligible count and cost. Server validates snapshot, ownership, level, resources and duplicate requests atomically.
- Glass tiffin replaces foam food storage, with visible paddy rice and one stacked tier per level (1–10).
- Barracks unlocks swordsman, flying sword, dragon, thief, divine turtle, sword immortal, divine tiger, stone warrior, fire phoenix and deity at levels 1–10. All ten enter training queues, practice combat, village activity, raid power and 50%-per-type defense. Legacy three-slot armies preserve their counts.
- Barracks target levels 2–10 cost each of water/rice/elixir: 1,000; 5,000; 20,000; 75,000; 250,000; 750,000; 2,000,000; 5,000,000; 10,000,000. Storage/production at high levels scale to make these prices attainable.
- Bounded impact flashes, curved slash trails, sparks and ranged bolts appear on both attack/defense paths; sound towers retain expanding AoE rings.

Validation: Godot 4.4.1 import; eleven existing client suites plus ten-troop/effect-lifecycle tests; six transactional PostgreSQL suites including exact final price, new unlocks, legacy roster, garrison, wall selection, stale delete and replay. Actual Godot framebuffer captures reviewed for village, all troop types and ten glass tiers.

Known presentation limits: fixed-camera 2.5D cutouts, not fully rigged 3D. Storage contents are illustrative with numerical fullness; new attack poses use a procedural lunge/FX, not skeletal animation. Online raids remain the existing 25-second server-authoritative aggregate simulation. Android device performance and visual acceptance still require the user's device test. PR remains preview until that validation.
