# v0.46 — signature skills and breach regression

The offline wall bug was a scene-lifecycle error: restarting/changing a level queued the old battlefield children for deletion, then terrain batching traversed those old wall meshes and baked their geometry into the new landscape. Detach old children before deferred destruction; generate/batch terrain inside a dedicated Terrain node. Destroyed wall nodes now detach immediately, and the navigation cell opens. Other buildings retain ruins.

Ground actors now use one identity-stable contact pose with continuous, distance-driven 2D deformation: opposite support/swing feet, counter-motion of arms and small body lift. Four-legged actors use a gentler phase pattern. Feet baselines account for transparent padding. The simulation-to-render position is smoothed; idle actors do not walk in place. This is still 2.5D deformation, not skeletal 3D animation.

## Skills implemented in the offline simulation
| Unit | Skill / targeting | HP | Armor | Speed (cells/s) |
|---|---|---:|---:|---:|
| Dragon | Cone fire and 2-second burn, prioritizes defenses | 700 | 18% | 1.4 |
| Thief | Wall climbing, prioritizes stores, steals finite practice supplies | 220 | 5% | 2.2 |
| Divine turtle | Ranged energy sphere, slow heavy defense | 1700 | 55% | 0.55 |
| Sword immortal | Crimson/gold robes, aura, piercing sword wave | 650 | 30% | 1.6 |
| Divine tiger | Hunts defenders, including flying units; leap against airborne prey | 850 | 20% | 2.8 |
| Stone warrior | Smashes the first building/wall blocking its direct route; slam splash | 2200 | 60% | 0.65 |
| Phoenix | Flying fireball with area explosion | 2200 | 15% | 1.8 |
| Deity | Flying, three-target chain lightning, twice swordsman sprite height | 3600 | 72% | 1.2 |

Practice bases from tier 3 include defending warriors so anti-unit targeting is exercised. Every damage path applies armor. Fire, pierce, splash and chain attacks affect enemies only. Practice theft never grants online currency. Targets are cleared on restart/exit to avoid cyclic references persisting across sessions.

Native effects distinguish breath, energy sphere, sword crescent, claw streaks, ground slam, fireball and lightning. Both online and offline presentations share these effects; online attack cadence uses the per-unit cooldowns. **Online PvP still uses its existing server-authoritative aggregate combat resolution; the per-unit targeting/status simulation above is offline, not an online combat-engine rewrite.**

Validation: thirteen Godot suites, including level restart/mesh-count regression, actual wall node removal and walkable breach, storage theft, obstacle-first stone targeting, airborne tiger target, cone burn, piercing, splash, three-target lightning and health/armor relationships. Native renderer captures and a locomotion video inspected. Android device performance remains unmeasured.
