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


## v0.6 — Gold industry, builders and defense AI

A Gold Refinery costs 1500 Metal + 350 Oil (40 seconds). Build it after an Oil Processor. A mining vehicle costs 600 Metal + 150 Oil (15 seconds). Each completed refinery supports three miners; working miners generate 2 Gold/second each, including capped offline catch-up. Original refinery, tracked mining vehicle, construction drone and Missile Bastion GLBs are generated by the asset pipeline.

Gold unlocks construction drones 2–10 for 200, 400, 800, 1500, 2500, 4000, 6000, 9000 and 13000 Gold. Each drone supports one concurrent building/upgrade. Pending jobs reserve power and a building cannot start a second upgrade while busy. Saves preserve miners, gold, drones and all deadlines, and v0.5 saves default to one drone and zero gold.

Missile Bastion costs 1200 Metal + 200 Oil. Laser Towers and Bastions acquire targets, aim, fire and damage units. Galaxy worlds progress from level 1 to 15; every three levels adds a Bastion. Units have health and losing all deployed units ends the raid. DEFENSE DRILL spawns practice intruders at the player's towers without damaging colony structures; these are local AI exercises, not online attacks.

The old 18×15 placement boundary and 300-building save cap are removed. Camera movement extends the terrain surface and distant building visuals are culled. There is no gameplay building-count cap, but device RAM, floating-point precision and simulation cost still impose practical limits; this is not a claim of infinite Android capacity.


## v0.7 — Star ranks and universal five-star defense

Existing models now show gold star ranks above every building, including AI buildings. Ranks one through five show individual stars; higher ranks use a compact star × level label. Unfinished construction displays CONSTRUCTING and never unlocks firing early. Selected building details show weapon unlock status, per-shot damage and range.

Every completed building at level five or higher automatically acquires and fires at invading units. Laser Towers and Missile Bastions retain their early-level weapons. Per-shot damage rises with every level, with an additional veteran bonus from five stars onward. Civilian buildings fire from their existing structures without new models. This applies to both enemy outposts and the local home-defense drill. Existing save levels remain authoritative; no save reset is required.

QA checks the unlock threshold for all 12 building types, higher-rank damage, unfinished construction, the real 4→5 upgrade deadline, a Core damaging an intruder, visible rank text and save/reload persistence.


## v0.8 — Mobile scrolling, squad placement and weapon visuals

Scrollable building/unit/help menus now capture finger gestures over their content, apply inertial scrolling and activate a card only on an undragged release. Emulated mouse events are suppressed inside these touch lists to prevent duplicate actions.

Before an AI raid, choose a unit type and squad size (1, 4, 8 or up to 24), then tap a valid outer edge for each group. Multiple groups can approach from different directions. UNDO SQUAD removes the latest group and restores its available deployment count. ATTACK begins the battle only after at least one unit is placed. The total field limit remains 24 and fleet stock retains the existing practice-mode persistence.

Lasers are brighter and last longer. Missile Bastions and missile/bomber unit types show moving emissive homing rockets, exhaust and impact flashes, with a 64-projectile visual cap and cleanup. Visual rockets accompany the existing combat damage calculation; they do not change damage into a delayed impact mechanic.

QA exercises raw Android touch scrolling over cards without purchases, single-tap purchase, separate squads/types/locations, undo, empty-army rejection and moving projectile cleanup, alongside previous economy/save/combat tests.


## v0.9 — Ground forces and destruction presentation

Ten original GLBs replace the placeholder ground units: Battle Tank, Siege Tank, Artillery, Rocket Launcher, Mech Warrior, Sniper, Shield Drone, Repair Drone, Assault Soldier and Elite Commander. Troop cards and deployment choices show portraits rendered from those same models. Ground troops deploy at ground height; support drones hover and aircraft retain their flight height. Ground formation spacing and attack ranges differ from aircraft.

Infantry/mechs have alternating leg movement. Vehicle turrets aim and weapons recoil with muzzle flashes. Destroyed units and buildings become darkened wrecks, collapse, scatter debris and burn with smoke for up to twelve seconds. A twelve-wreck cap and scene-change cleanup bound rendering costs. Existing aircraft models and support-unit combat roles remain the prototype versions.

QA checks model and portrait imports, grounded placement, articulated walking, cannon recoil, destruction starting only once, collapsed structures and complete wreck/particle cleanup, alongside existing colony, touch, deployment and battle tests.
