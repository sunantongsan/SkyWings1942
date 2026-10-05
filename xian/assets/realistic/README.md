# Realistic artwork, v0.44

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
Buildings use prerendered artwork except the wall, well and ward. These use
textured 3D geometry for adjacency, articulated mechanisms and exact horn counts. Character, carpenter, tree,
ruin and masonry art is replaced as well. v44 restores the original grass ground. Primitive model generators
remain as a development fallback and retain their unit coverage. The new default
renderer has separate integration tests in tests/realistic_art.gd.

Current visual limitations to review on a phone:
- Generated walking loops need further cleanup. Human swordsmen now have attack
  and sleeping sequences; flying and dragon attacks still use pose/effect feedback.
- The well has a separately animated operator, linked lever, flowing stream and
  splash droplets. Slingshot defenders still use their prerendered building images.
- Storage artwork depicts representative contents; StorageAmount and the HUD use
  the exact live quantity. The photo does not simulate a continuously rising
  fluid surface or individually count pills.
- Ten generated upgrade images are distinct, but details such as the exact visible
  number of defenders/storeys should be checked artistically at each level.

Do not describe these assets as new fully rigged 3D models or claim the art pass
has completed every animation/detail. Inspect the actual game capture and APK.

## v44 source prompts (built-in imagegen)

- `pump_operator.webp`: photorealistic adult Thai man, straw hat, faded blue
  cotton shirt and rolled trousers, eight full-body pumping poses in a 4×2
  transparent sheet, hands gripping an invisible lever, fixed elevated camera.
- `fighter_actions.webp`: same red-robed swordsman as the walking reference;
  four sword-swing frames above four side-lying sleeping frames, transparent.
  Generated row boundary is y=550; runtime texture views preserve source pixels.
- `materials.webp`: five-column/two-row photographic material atlas, rotten
  bamboo, rusty zinc, fresh bamboo, hardwood, precast concrete, red brick,
  smooth concrete, reinforced concrete, steel, engraved gold, no labels.
- `pump_materials.webp`: three-column/two-row photographic surface atlas, blue
  PVC, forged iron, stainless steel, engraved silver, ruby, jade, no labels.

No AI-generated image is used to count horns. `sect_art.gd` constructs exactly
four horns per tier. See `tests/sect_life.gd` for default-renderer coverage.
