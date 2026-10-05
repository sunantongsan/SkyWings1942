# Fixed-view rendering contract

The production engine is Godot 4.4.1 Compatibility. This is our documented implementation, not a claim to reproduce Supercell's private engine.

- scripts/iso_layout.gd owns the orthographic camera, grid scale and surface height. Village, practice and icon previews use it.
- Original building textures and character sizes are retained. Existing animated mesh buildings remain animated. They share the same world grid and depth buffer.
- realistic_art.gd chooses original artwork and atlas frame, supplies its contact anchor and keeps its aspect ratio.
- grounded_sprite.gdshader keeps screen-space artwork unchanged. For image pixels that would project below terrain, it moves the depth along the orthographic view ray to the common ground surface. It never disables depth testing.
- Foreground walls/actors still occlude buildings. Shadows are separate ground objects. Collision and placement use footprints, not image rectangles.
- Do not fix a clipped base by raising the entire artwork, shrinking its frame or turning off depth testing.
- The retired alternate architecture renderer is opt-in only; production uses original artwork.

## Release checks

ground_visibility.gd renders each active building at all supported levels, both with and without terrain. It compares solid artwork pixels, then verifies a foreground occluder hides the building and a background occluder does not. The JSON report records pixel differences. Screenshots for levels 1, 5 and 10 accompany the village/menu previews.

Other tests cover touch placement, wall management, original frame selection, troop scale/animation and responsive scene updates. Physical Android testing remains a separate check.

## Reference comparison

The user-approved Clash of Clans reference is a visual/usability benchmark: stable fixed view, readable footprints, intact bases, correct overlap and contextual building actions. It does not authorize replacing the original artwork or claiming engine parity. Our blue UI and existing building identities are retained.
