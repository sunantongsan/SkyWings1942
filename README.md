# Xian of Clans — 0.53 production and formations

See [0.53 changes](xian/RELEASE-v053.md) for independent fighter halls, jade speedups and four new defenses, and [0.52 changes](xian/RELEASE-v052.md) for player raids and revenge. The sections below describe the initial prototype history.

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
