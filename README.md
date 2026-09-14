# GALAXY 1942 — Homeworld 3D

Android landscape base-building prototype in Godot 4.4.1 / GDScript.
The original Android Canvas version remains on `legacy-android-canvas`.

## New commander flow (v0.4)

Welcome → choose one of 15 homeworlds → confirm an empty colony → follow 13 missions.
Build Galactic Core, Fusion Reactor, Metal Extractor, Resource Vault,
Oil Processor, Crystal Mine, Star Hangar, Laser Tower, Research Lab and
Shield Generator in that order. Then upgrade the Core, train 8 Fighters and
win a first raid. Guided landing sites and locked future buildings prevent
accidental sequence skips. All worlds receive the same landing supplies.

Production requires the relevant building. Power comes from reactors and is
used by the colony. Returning from a raid restores the selected homeworld.
Progress, resources, buildings, levels, units and tutorial state save locally
on actions, every 10 seconds and when the app pauses. A last-good backup
allows recovery if the primary save is damaged. Saves are on this device;
uninstalling/clearing app data removes them. There is no cloud sync.

## Current visual build

- Ten original GLB building designs with separated moving parts and PBR materials.
- Terrain shader, surrounding ridges, rocks and alien vegetation.
- Directional shadows, emissive accents, animated shields, rotating defenses,
  extraction smoke, patrol ships, weapon beams and destruction particles.
- Landscape HUD, five resource cards, touch pan / pinch zoom and scrollable menus.
- Individual transparent building icons rendered from the same in-game GLBs.

## Open and test

Download the **GALAXY1942-Godot-Source** artifact from the newest successful
GitHub Actions run. Extract its ZIP, then open `project.godot` in Godot 4.4.1.
It contains the complete project and individual `.glb` models.
The old root `godot_project.zip` is historical and is not the current build.

For developers: `python3 tools/assemble_godot.py --output game` assembles the
same project. The asset generator uses only Python's standard library.
`godot_override/` contains runtime source. `godot_src/` holds project/export settings.

GitHub Actions renders the real scene, tests construction, upgrades, training,
raid victory and reward settlement, then exports a debug APK. It uploads
screenshots, the APK and the complete editable project as separate artifacts.

## Scope and performance

This is a visual vertical slice, not a completed online game. Multiplayer,
server validation and cloud saves are not implemented. Ten flight
unit types currently share the original fighter mesh; ground troop art remains
prototype quality. Check frame rate and heat on a physical Android device.

The GLB generator records triangle counts and authorship in
`assets/models/manifest.json`. Its highest-detail building is about 4,400 triangles.
Art assets are authored for this project; no third-party game artwork is used.


## v0.5 — Colony production and deployment

Buildings now take 8–45 seconds to construct. One construction drone handles a building or upgrade at a time. Upgrades take 30 seconds per current level. Metal is charged once when work starts; construction unlocks production and tutorial progress only at completion. Existing v0.4 colonies migrate without resetting.

Choose any clear grid location in the colony. Mission landing rings suggest layouts but are optional. Select a completed building and MOVE to relocate it for free. Buildings cannot overlap.

The Star Hangar queues up to 20 units, sequentially, at 5 + 2 × unit-index seconds each. Credits and Oil are charged on enqueue. Only finished units enter stock. Raids show an AI outpost first; tap an outer map edge to deploy up to 24 units of the types actually trained. The current combat prototype still preserves fleet stock after raids and does not implement individual unit losses or full RTS command selection.

Construction, upgrades and training use persisted completion timestamps. Offline resource catch-up is calculated chronologically and capped at eight hours, including facilities that finish while away. Returning cannot award the same elapsed interval twice. Clock rollback does not award negative time. Local timestamps are not cheat-resistant server time.

**Connectivity:** this APK is an offline single-player build with AI raids. It does not yet provide player accounts, cloud saves, matchmaking, asynchronous player-base raids, or real-time network battles. A server-authoritative service is required before those can be advertised as online features. Red Alert and Clash of Clans are gameplay references; GALAXY 1942 assets, names and interfaces remain original.

QA covers unfinished building production, busy builders, restart during work, sequential training completion, offline cap and duplicate catch-up, relocation collision, actual trained unit types, invalid deployment zones and the full colony-to-victory flow.
