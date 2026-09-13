# GALAXY 1942 — Homeworld 3D

Android landscape base-building prototype in Godot 4.4.1 / GDScript.
The original Android Canvas version remains on `legacy-android-canvas`.

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
server validation and durable player progress are not implemented. Ten flight
unit types currently share the original fighter mesh; ground troop art remains
prototype quality. Check frame rate and heat on a physical Android device.

The GLB generator records triangle counts and authorship in
`assets/models/manifest.json`. Its highest-detail building is about 4,400 triangles.
Art assets are authored for this project; no third-party game artwork is used.
