# Xian of Clans — playable online prototype v0.32

Open `xian/project.godot` in Godot 4.4.1. The new standalone entry point exports only Xian assets; Galaxy models/scripts remain in git history/workspace for reference and are not part of this APK. Package `com.xianofclans.strategy` installs separately from Galaxy to preserve the old save.

## Implemented
- Thai interface, email signup/signin through Supabase Auth, persisted refresh sessions, network error handling and idempotent retries.
- Name your sect; choose bamboo forest or mountain plateau. Orthographic low-poly 3D, touch placement/moving, camera pan and zoom.
- 14 building types, construction/upgrades with server timestamps and limited builders, builder houses unlock from 2 to 10 with hall level.
- Water/rice/spirit stones with capacities and up to 8 hours of offline production, cosmetic porters, cloud persistence.
- Three troop types and serial training queue, dorm capacity, higher-unit unlock requirements.
- Server-resolved automatic 25-second raids against bots and eligible player bases. Preview enemy resources, capped percentage loot, four-hour defense shield, 24-hour starter shield, shield removed on attack, defense report. Troops committed to a raid are consumed. Jade is never looted.
- Server-owned 8x8 match-3 board, adjacent swaps, matching, gravity/cascades, 20 moves, 300-point goal; reshuffle costs one move. First 10 wins per Bangkok calendar day award 100 water, 100 rice, 2 jade, subject to storage limits.
- Daily check-in: 5 jade; every seventh cumulative check-in 20. Exchange jade for resources; finish construction for 1 jade per 5 minutes remaining.

## Explicit prototype limitations
- Combat is a server-side power/defense simulation with cosmetic animation, not spatial troop AI or manual per-unit deployment. Air/wall/ward interactions affect server defense calculations. Beasts and disciples currently use simple original procedural models, not a finished animated reproduction of the provided portrait. The user's image is shown in recruitment UI as reference.
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
- Buildings, characters, icon and scenery: original procedural geometry / SVG.
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
