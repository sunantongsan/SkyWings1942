## v0.40 living resource buildings

- Gatherers now render at 50% scale; combat disciples retain their original size. Compact builders sit on a scaffold platform and saw a plank while construction is active.
- Kitchen is a Chinese inn, adding one compact floor per level (1–10). The food store is a tinted clear shopping bag with two handles and up to 24 pieces of food based on capacity utilization.
- The well is a hand pump with a synchronized operator, bucket and water stream. Pipe diameter and platform decoration increase each level.
- The elixir furnace is a tiered Chinese incense burner (one tier per level) with continuously rising/fading smoke. The water store is a clear capped bottle with a visible fill level, increasing size, ribbing and ornament.
- Local visual animation is isolated from static mesh batching and works in home, raids and practice without affecting simulation or save keys. Home food/water fill refreshes at 1% steps on server sync; raid models retain the existing approximate storage visualization (only elixir fill is supplied by raid snapshots).
- Verified all level silhouettes/footprints, empty/half/full storage, surviving animated meshes, pump/saw/smoke movement, and the existing Godot regression suite. OpenGL screenshots and regenerated menu icons reviewed. Physical Android device performance still needs a phone check.

# Xian of Clans — playable online prototype v0.37

Open `xian/project.godot` in Godot 4.4.1. The new standalone entry point exports only Xian assets; Galaxy models/scripts remain in git history/workspace for reference and are not part of this APK. Package `com.xianofclans.strategy` installs separately from Galaxy to preserve the old save.

## Implemented
- Thai interface, email signup/signin through Supabase Auth, persisted refresh sessions, network error handling and idempotent retries.
- Name your sect; choose bamboo forest or mountain plateau. Orthographic low-poly 3D, touch placement/moving, camera pan and zoom.
- 14 building types, construction/upgrades with server timestamps and limited builders, builder houses unlock from 2 to 10 with hall level.
- Water/rice/spirit stones with capacities and up to 8 hours of offline production, cosmetic porters, cloud persistence.
- Three troop types and serial training queue, Sword Training Courtyard capacity, higher-unit unlock requirements.
- Server-resolved automatic 25-second raids against bots and eligible player bases. Preview enemy resources, capped percentage loot, four-hour defense shield, 24-hour starter shield, shield removed on attack, defense report. Troops committed to a raid are consumed. Jade is never looted.
- Original GhostMatch3 Android minigame, local account-scoped progress; ads and sect rewards are not connected.
- Daily check-in: 5 jade; every seventh cumulative check-in 20. Exchange jade for resources; finish construction for 1 jade per 5 minutes remaining.

## Explicit prototype limitations
- Online raids retain the server-side power/defense simulation. Offline practice has local spatial troop AI and per-unit deployment, with no online rewards. Human troops use animated Godette without a backpack; beasts use procedural animal geometry.
- No live ad inventory, ad payouts, cash purchase or monetization is enabled. The ad button explicitly says unavailable. A verified provider callback and the owner's production IDs must be integrated before rewarded jade can be enabled.
- No claim of production-scale/load validation. Backend uses player-row locks and per-account serialization. Public signup rate limits remain Supabase defaults. Profile and receipt retention/abuse monitoring need production review.
- Email signup requires confirmation in the existing Supabase project. Existing authenticated accounts can sign in. New accounts are not auto-confirmed.
- Stores currently receive production directly on server; carrier walks are cosmetic and do not affect throughput. Producers do not hold a separately lootable buffer yet.
- Art, tactical combat, sound, tutorials and phone performance need player review. This is an initial playable build, not a finished commercial release.

## Server
`backend/xian_schema.sql` is the complete idempotent deployment snapshot. Applied through Supabase migrations to the user's existing project, isolated in `xian_private`. No old game tables modified. `public.xian_action` is a security-invoker facade over an ownership-checked private dispatcher. Private tables have RLS, no client grants, and intentional default-deny policies. Only the public publishable key is in the client; no service key.

`backend/test_server.sql` runs in a transaction and rolls back its two fixture auth users and all game state. Tests construction locks, daily reward/idempotency, production after completion, table isolation, real-player raid deduction/shield, jade immunity and payout replay. Never run fixtures as live player accounts.

## Validation
- Godot headless import and `res://tests/smoke.gd`.
- Actual-engine captures via `res://tests/capture.gd` use clearly isolated fixture state.
- Supabase server test transaction passes.
- Build pipeline: `.github/workflows/xian-android.yml`. Android SDK tools 35; prebuilt Godot template targets Android 34 (not a Play Store submission), Godot 4.4.1, JDK 17, arm64, Internet permission. Uses a debug signature; not a Play Store release signature.

## Asset provenance
- Donor building/character provenance is in the 0.35 section and bundled credits. Courtyard, beast, icon and scenery use original procedural geometry / SVG.
- `disciple-reference.jpg`: supplied by project owner in this conversation.
- Noto Sans Thai: SIL Open Font License, included alongside font.


## Account update 0.33

Email auth reuses the original cultivation game's Supabase project. Existing email/password accounts remain valid; characters and balances are not migrated into the new strategy economy. Signup validates email, password and confirmation locally, disables duplicate submissions, displays status inside the form and offers confirmation resend. Confirmation remains enabled on the shared backend.

Android Google login reuses the original browser OAuth callback `com.sunantongsan.thegang://auth-callback` with per-attempt S256 PKCE, a ten-minute expiry and one-use verifier. Select **Xian of Clans** if Android asks which installed game should open the link. If Android kills the game while the browser is open, restart Google login. No client secret or service-role key is embedded. Actual Google consent and return require a device/account test; automated tests cover callback validation and replay rejection.

Native callback source: `native/xian/src`. Extract Godot 4.4.1 `android_source.zip` into `xian/android/build`, run `python3 tools/prepare_xian_android.py`, then use the Android Gradle export. CI does this automatically.

Google Play Games is NOT enabled yet. It is distinct from Google account login. Required setup: the game's Play Games project ID, Android OAuth credential for `com.xianofclans.strategy` with the installed APK signing SHA-1, a game-server OAuth client, and enabled test accounts in Play Console. Never use an unverified player ID to access a Supabase save. Reuse of the old Google OAuth backend does not automatically register this Android package with Play Games.

## Mobile building update 0.34

- Pinch the map with two fingers to zoom; the +/− controls and mouse wheel also work.
- Swipe menus vertically to scroll with inertia. A vertical swipe never places a building.
- Drag a building card sideways out of the construction menu, position it on the map and release to build. Alternatively select the card, then drag on the map. Green means an empty buildable cell; red means occupied or outside the 16×16 base. The server still checks workers, resources and limits.
- The cancel button clears placement. Existing buildings can be moved using their Move action and the same preview.
- Fourteen building types have distinct silhouettes/details and matching rendered thumbnails. Run `res://tests/render_buildings.gd` with a display to regenerate the icons after model changes.
- Ground extends continuously under the base and scenery; the base no longer sits on a raised slab.
- `res://tests/touch_build.gd` covers pinch without accidental builds, occupied/out-of-bounds rejection, drag from cards and vertical menu scrolling. Real-device feel remains a device test.

## Original game/assets integration 0.35

The old Godot match-3 screen is removed. Android opens the original GhostMatch3 Java Canvas game (120 levels, specials, level map, skeleton/skull art) inside the same APK, with an explicit Return to Sect button. Godot resumes and syncs the sect on return. Ghost progress is local to this APK and namespaced by the authenticated account ID; it does not import saves from a separate installed GhostMatch3 app or sync level progress across devices. Ads and sect-currency rewards are not connected in this integration. No client-reported score is trusted for online rewards. The old server match RPCs remain for old clients but this app no longer calls them.

Godette from The Gang replaces human disciples and carriers, with the backpack removed and the original walk/idle animations. Human flying units use the same character on a donor sword; divine-beast units retain their animal form. Buildings now use The Gang's Chinese palace/pavilion/gate/wall assets and Hitherton houses, with normalized footprints and purpose markers. House surfaces are recolored for small-screen contrast. Menus use freshly rendered model thumbnails.

Credits/licenses are included in the APK and accessible from the sect panel. `native/xian/ghost-source.json` pins original Ghost art with SHA-256 hashes. `tools/prepare_xian_android.py` invokes `fetch_ghost_assets.py` before copying native sources/resources into the Android template. Native Ghost code compiles with the Android SDK and does not include an ad SDK.

## Sword courtyard and offline practice 0.36

- `training` keeps its stable database ID and becomes **ลานฝึกกระบี่** (Sword Training Courtyard). The old Arena mesh and thumbnail are replaced by an open stone 2×2 courtyard with dummies, sword rack, flags and visible garrison. Higher levels add rack swords; level 5 changes flag/border colors.
- Level 1–10 capacity is 20, 40, 60, 80, 100, 120, 140, 160, 180, 200 units. Each troop occupies one slot; queued troops count toward the limit. Completed courtyard and recruitment gate are required. Dorms are residential buildings and no longer add combat slots. Existing troops/queues are never discarded if over capacity.
- Client and server reject overlapping footprints and courtyard positions beyond cell 14. On sync, a legacy yard expands in place or moves to the nearest free 2×2 plot. If an old base has no free plot, it temporarily retains a compact 1×1 footprint and shows a relocation prompt; all buildings, levels, jobs and troops survive. Moving it requires a full 2×2 plot.
- **บอทออฟไลน์** is available even at login. Twelve progressively defended bases, 180-second battles, tap green perimeter to deploy a selected unit. Ground units route around obstacles and breach walls; flying swords bypass walls and attack at range; divine beasts cross walls and prioritize defenses. Towers target ground/air; wards inflict splash damage with an air bonus.
- Practice armies are supplied per base (22–30 units). The simulation runs locally at a fixed step, separate from online troops/economy. One star each for hall destruction, 50%, and 100% non-wall destruction. At least one star unlocks the next base. Best stars are saved on this device only. No Supabase login/network/reward call is needed.
- `backend/courtyard_update.sql` is the deployed function-only migration. `backend/test_courtyard.sql` rolls back all fixtures and covers migration, collision, boundaries, 20/40 capacity, over-cap preservation, recruitment and full-board fallback. `tests/practice.gd` covers path obstruction, wall breach, air/beast targeting, combat damage and all 12 battle endings. `tests/capture_practice.gd` verifies login access, deployment, return and screenshots.
- Android v36 remains a signed debug/sideload build, not a Play Store release. Desktop rendering and automated simulation pass; final touch feel and performance on the owner's physical phone remain to be tried.
- Database advisory review: Xian tables intentionally deny direct access with RLS and no policies; only the authenticated dispatcher has access. Existing shared-project GraphQL notices on unrelated games and leaked-password protection remain outside this change. References: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy and https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## Swords, divine dragon and connected walls 0.37

- Human combat disciples now hold a visible sword on Godette's `prop.R` grip bone. The donor one-handed idle and light attack clips animate the full body and sword. Imported clips contain skeleton tracks only; donor gameplay/audio callbacks and root motion are removed. Workers/carriers remain unarmed. Offline strikes apply damage after a 0.3-second windup; online raid visuals also play attacks.
- The old procedural beast is replaced with **มังกรเทวะ**, Quaternius Dragon_Evolved from The Gang's monster manifest, with its original idle, travel and Headbutt clips. Stats and anti-defense priority are preserved. Model provenance/checksum and modifications are in the bundled credits.
- Adjacent wall cells automatically join, including corners, T junctions and cross junctions. Select Walls and drag a straight line on the ground to build up to 16 segments at once. Direction is inferred from drag or constrained with the 90° button. Each segment costs 5 water / 5 rice; the server checks the whole line and commits all or none, with the existing 80-wall limit and request idempotency.
- Select a placed wall to rotate its contiguous straight run 90° around that segment, or move the whole run. At junctions the saved orientation chooses the branch. A move/rotation that crosses another structure or the map boundary is rejected without changing anything. The original single-building Move action still works. These are original grid editing controls inspired by base-building games, not imported proprietary game code.
- Offline bases use connected perimeters, interior compartments, alternating orientations, paved approaches, lanterns and bamboo/rock scenery. Destroyed wall connections update locally to show breaches. Original local stars persist; the 12 maps have been rearranged.
- Default village zoom increases from size 48 to 34 (about 41% larger on screen); practice zoom from 64 to 42 (about 52%). Human models increase from 1.6 to 2.15 world units. Practice supports one-finger drag to pan, two-finger pinch to zoom, tap-release deployment, mouse drag/wheel and a full-base overview button. These settings improve readability; they do not claim an exact pixel match to another game.
- Validation: client wall topology/row preview tests, original touch regression, dedicated practice gesture tests, donor skeleton/weapon binding checks, actual-engine idle/attack captures, twelve-base battle simulations, and rolled-back server wall tests covering row charges, replay, rotation, movement, collision and atomic rejection. APK remains a debug-signed arm64 sideload build; physical-phone performance and game balance still need player feedback.

## Unified village visuals 0.38

- Integrates the earlier `xian-visual-overhaul` work (construction scaffolds, hit flashes, rubble, lanterns and banners) with a shared visual style for village and offline battle. Offline practice uses the village's single sun/environment to avoid double lighting.
- Replaces the 256-piece ground checkerboard with a deterministic mipmapped grass/stone texture, framed trees and rocks. Immutable landscape geometry is merged by material; buildings, collisions, animated units and health bars remain separate.
- Recolors Chinese roof/plaster/wood materials; adds consistent stone foundations, resource accents and level trim. Water storage, spirit crystal storage and the archer tower now have original, distinct silhouettes. All 14 menu thumbnails are rendered from the actual game models.
- Shared Thai UI styling adds raised buttons, consistent disabled states and panel borders. Human units are larger, waiting disciples occasionally wobble, and village display units are spaced farther apart; dragons wait beside the courtyard. Display limits do not change the army count or combat units.
- Construction progress uses the catalog duration and current building level, matching the existing server duration formula, instead of an invented estimated total. No backend/schema/economy changes.
- Validation: Godot 4.4.1 import, smoke, auth, placement, wall, offline touch/simulation and donor animation regressions; actual OpenGL screenshots of village, mountain, placement, courtyard, offline battle and sword attacks. Physical Android FPS, battery use and touch feel still require a phone test. The APK remains an arm64 debug-signed sideload build.

## Elixir workshops and building levels 0.39

- `spring` is now the pill furnace (เตาหลอมโอสถ); `crystal` is a sheer cloth pill pouch (ถุงโอสถเซียน). Existing `stone` balances, production/capacity formulas, costs and loot are retained as pills. The pouch displays 0–24 pills according to shared storage fullness. Server-produced player raid snapshots include bounded `pill_fill` so attackers see the defender's actual fullness, not a constant decoration. Offline practice uses a decorative half-full pouch.
- New 1×1 `barracks` / หอฝึกนักสู้ produces the existing three fighter types: barracks and hall levels 1/2/3 unlock basic disciples/flying swords/divine dragons. Build a completed courtyard for capacity. Courtyard level affects capacity only (20 per level, up to 200); upgrading the barracks never increases storage. Existing armies and queued jobs are preserved and settle normally. The recruitment gate remains a separate existing building, but no longer gates production. Existing owners must build the new hall for new production.
- All 15 building types have visual progression at every level 1–10, using changing masonry, trim, increasing detail and tier additions (buttresses, side roofs, lanterns, finials and banners). Static opaque parts are merged per material, including material overrides; transparent pouch cloth stays separate. Footprints and server placement remain unchanged.
- A completed placement/move exits placement mode immediately, even while the server saves. The next one-finger drag pans. The explicit finish/pan button also cancels placement. Creating another wall row requires selecting Walls again; pinch still cancels a pending gesture without building. Moving buildings previews their actual level.
- Applied function-only Supabase migration `elixir_workshops`; no player rows rewritten. Tests in `backend/test_elixir_workshops.sql` cover preserved armies/queue, production/capacity, missing/unfinished barracks, level unlocks and idempotency, and empty/half/full pouch values. Original courtyard/server/wall rollback tests pass. Security advisor reports the existing intentional no-policy private-table notices and unrelated shared-project notices; no access grants added to player data. Reference: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy
- Client tests cover all 150 building/level combinations, translucent pill visibility, post-placement wall pan, existing gestures, donor animation and all offline maps. New thumbnails and comparison captures come from Godot OpenGL, not concept art. Android remains an arm64 debug-signed test APK; physical-phone frame rate is not measured here.
