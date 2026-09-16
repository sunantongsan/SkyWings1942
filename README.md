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


### v0.10 production facilities

- Star Hangar produces aircraft and armed support drones; it also produces construction drones (Gold unlock price, 15-second job, maximum 10).
- New original Vehicle Factory GLB produces Battle Tank (level 1), Artillery (2), Siege Tank (3), Rocket Launcher (4), and Mining Vehicles (1, also requires Gold Refinery).
- New original Barracks GLB produces Assault Soldier (1), Sniper (2), Mech Warrior (3), Elite Commander (5).
- Aircraft unlock across Hangar levels 1–7; Shield/Repair Drones unlock at level 2. Their current combat behavior is unchanged; specialized support abilities remain prototype work.
- One serial production line per facility type; the three lines run concurrently. Additional buildings of the same type do not add lines. Highest completed, non-upgrading building level controls new orders. Already accepted jobs continue during upgrades.
- Locked cards show the required facility level. Select an industrial building and tap PRODUCE, or use FLEET tabs. Existing units and accepted jobs remain valid on upgrading from v0.9; no save reset.
- Construction drone and mining vehicle timers persist and share their matching production line. Offline catch-up retains the existing eight-hour resource cap.


### v0.11 GODOT Coin and reinforcements (updated in v0.12)

GODOT Coin is an offline in-game currency. Claim 20 once per UTC day in the Coin menu (tap the GODOT COIN resource card, or BUILD → GODOT COIN). It uses device time and the local save; authoritative clock/anti-tamper validation requires a future online backend. Coins are not a blockchain token.

Spend 1 Coin per remaining minute (rounded up) to finish a selected building job or the next unit on one production line. Later jobs on that line move forward without completing for free. Exchange 10 Coins for 1,000 Metal, Oil, Credits, or Crystal.

Tap a rock or tree directly → review cost → REMOVE. Clearing costs 100 Metal and 50 Oil, occupies one free construction drone, and takes 20 seconds. The drone flies to the target and uses a work beam; the obstacle disappears with an effect only on completion. Active jobs persist and finish during offline catch-up. Each obstacle has a deterministic 25% drop chance for 1–5 Coins; removal persists across returning home and reloading. No repeat rewards or obstacle respawn in this version.

The right-hand battle roster shows portraits and remaining reserves from the stock present at raid start. Tap a portrait, select squad size, then tap an outer edge to deploy before or during combat. Accepted reinforcements are charged once; deployed troops are consumed for the raid, and unused reserves remain at home. From v0.13 there is no active-unit deployment cap: ALL RESERVES sends every remaining unit of the selected type. Very large armies can affect performance on lower-end devices. Undo is available only before ATTACK. Retreat and the 150-second battle timer still apply.


v0.12 adds an original SVG coin emblem and a seventh resource card showing GODOT COIN and its live balance. Clearing shares the same ten-drone limit as building and upgrades. Repeated orders, busy drones and insufficient resources never charge again.


### v0.13 placement and army behavior

Green/red terrain overlays show valid/blocked building locations and the exact permitted raid deployment bands. The cursor footprint uses the same validation as the actual placement action, including spacing, builders, resources and reserves. Moving an existing building also shows its valid footprint. Touch-down previews the point; a stationary release places it, while drags pan and pinch zoom remains available.

Deployment formations stay inside the permitted bands instead of expanding away from the battlefield. All remaining units can deploy before or during an assault. Aircraft use their actual -Z nose direction; ground troops use +Z. Each unit immediately excludes destroyed targets and aims its turret after turning the body.


### v0.14 health and work progress

Direct obstacle selection opens a compact removal panel and selection ring. Selection is free; REMOVE spends Metal/Oil and assigns a free drone. Selecting an active removal shows its progress with repeat ordering disabled. The old clearing menu remains available.

Screen-projected health bars track current/max HP for home and enemy buildings, deployed units and drill enemies. Bars turn amber/red as HP falls and disappear for destroyed entities. Cyan work bars cover building construction/upgrades and obstacle clearing; a scrollable ACTIVE JOBS panel includes every building, clearing, training, mining-vehicle and construction-drone timer, distinguishing queued from active work. Raids show a time-remaining bar. Existing save timers drive the UI, including offline catch-up and Coin speed-ups.


### v0.15 Godot fantasy faction and placement visibility

Deployment colors are now drawn by the terrain shader (green outer bands, red forbidden center/outside), with a visible grid and boundary. They do not rely on a transparent MultiMesh overlay. Raid entry closes home menus; depleted troop selections advance to an available reserve type. Colors remain while reinforcements are available, before and after ATTACK, and disappear on returning home.

Full-health home buildings hide health bars unless selected. Damaged buildings and combat units retain bars. Construction/upgrade progress remains visible.

The Godot faction joins the existing colony after the Core upgrade tutorial: build Godot Citadel → Astral Well → Summoning Sanctum / Runebolt Spire. Original GLBs use ivory moonstone, gold ribs, amethyst crystals, pointed arches and animated rune rings. Each asset has its own model and Godot-rendered portrait.

| Building | Metal / Oil | Build time | Function |
|---|---:|---:|---|
| Godot Citadel | 1800 / 300 | 50s | Unlocks Godot structures; retaliates from 5 stars |
| Astral Well | 1000 / 150 | 30s | Produces 220 Power per level |
| Summoning Sanctum | 1500 / 250 | 45s | Independent unit production line |
| Runebolt Spire | 1300 / 200 | 35s | Auto-targeting arcane bolt defense from level 1 |

Sanctum levels 1 / 2 / 3 unlock Rune Guardian (armored lancer), Crystal Golem (slow heavy attacker), and Starweaver (long-range mage). Animated limbs, traveling violet bolts, recoil and existing wreck effects work in real battles. Noctis, Nebularis, Ruins and Wormhole have Godot AI outposts with increasing difficulty. This is an allied buildable faction set, not a replacement for the original starting tutorial or an online faction system. Old 20-unit saves migrate to 23 units without resetting progress.


### v0.16 Scrappy Galaxy cartoon art

The Galaxy faction now uses original exaggerated cartoon proportions: broad torsos and short legs for infantry, compact tank hulls with oversized muzzles, and big-nosed aircraft with tiny tails. All fourteen Galaxy buildings have authored corrugated-zinc roof sections with rust, overlapping patches, bolts and ragged edges; exposed mechanisms and Godot-faction architecture remain recognizable. These are standalone GLBs with per-part materials and animation pivots, not painted scene atlases.

Attack Pigeon is a new Star Hangar level-1 unit, available after the existing Core-upgrade mission. Cost: 40 Credits + 5 Oil, training time 3 seconds on the shared Hangar production line. Stats: 90 HP, damage parameter 5, speed 4.2, airborne height 3.2. It flaps articulated wings and fires a tiny energy cannon; it is reusable until destroyed, not a self-destruct unit. Production cards, progress bars and charging use the same cost/time functions. Existing saves with 20 or 23 unit slots extend to 24 while preserving inventory and queues.

CI verifies pigeon costs, duration, halfway progress, save/reload, model portrait, wing animation, forward orientation and movement; screenshots 32–34 show actual Godot models and the home colony. This is the first scrappy-cartoon art pass, with existing combat rules retained.
