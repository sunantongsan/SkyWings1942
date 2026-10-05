# Realistic artwork, v0.43

Generated with the built-in imagegen tool for this project. Original generation
identifiers are recorded in sources.json. Runtime WebP files preserve alpha and
source dimensions (Godot WebP quality 0.90). No paid asset service is required.

Art direction / prompt specification:
"Photorealistic pre-rendered strategy game sprite; orthographic isometric front
right view, camera elevated 40 degrees; warm daylight from upper left; realistic
wood, stone, metal, fabric and adult human anatomy; entire subject isolated on a
truly transparent background; no cartoon, chibi, low-poly toy proportions, text,
labels or backdrop. Humor comes from the requested absurd real-world objects."
Upgrade sheets request ten distinct levels in five columns/two rows; actor sheets
request eight frames in four columns/two rows. atlas.json records the selected
rectangles; these are texture views, not copies of the image. Kitchen and tower
row boundaries are adjusted to the generated content. The original full-size
single-object concepts informed the sheets; only runtime-used assets are shipped.

The fixed game camera makes this a 2.5D art path, not freely rotatable 3D models.
Collision, wall adjacency, combat and server resource values remain separate.
All active building types except walls use the new artwork; walls use textured
3D geometry so connected segments remain correct. Character, carpenter, tree,
ruin, terrain and masonry art is replaced as well. Primitive model generators
remain as a development fallback and retain their unit coverage. The new default
renderer has separate integration tests in tests/realistic_art.gd.

Current visual limitations to review on a phone:
- Generated walking loops need further animation cleanup; combat uses the existing
  combat effects plus pose feedback, not a new fully rigged sword swing.
- The pump operator and slingshot defenders are baked into their building images.
- Storage artwork depicts representative contents; StorageAmount and the HUD use
  the exact live quantity. The photo does not simulate a continuously rising
  fluid surface or individually count pills.
- Ten generated upgrade images are distinct, but details such as the exact visible
  number of defenders/storeys should be checked artistically at each level.

Do not describe these assets as new fully rigged 3D models or claim the art pass
has completed every animation/detail. Inspect the actual game capture and APK.
