# Technical architecture — P00-05 design baseline (mobile shell P00-06 implemented)

**Reviewed architecture pack:** [docs/architecture/README.md](architecture/README.md). This design establishes the trust boundaries, ERD, role matrix, and versioned data invariants, but has not been deployed to any Supabase project.

## Monorepo
- **`apps/mobile`:** Flutter + Dart.
- **`hosting/`:** the PHP + SQLite admin that is actually deployed. Its feeds and deploy steps are in [hosting/README.md](../hosting/README.md).
- **`supabase`:** the edge function and planned schema.
- **`docs`** and **`AI_BRIDGE`**.

The Next.js CMS (`apps/admin`) and the Supabase CMS schema below are the long-term design. Today the hosted PHP admin fills that role: a single owner account, draft and publish with history, and confirmation steps.

## Implemented beyond the P00-06 shell (November 2026)
- **Hosted library feed:** the app reads one feed (`managedLibraryProvider`) for adhkar, duas, reciters, fiqh, articles, lessons, the theme (`appearance.theme`) and the Library sections (`appearance.sections`). It is cached on the device, refreshed on resume and every 15 minutes, and capped at 4 MB.
- **Reminders** (`features/reminders`) are planned on the device a week ahead from the prayer schedule and scheduled with `flutter_local_notifications`. They use exact alarms when the user allows them, and everything is opt-in.
- **Time-aware home** (`features/worship/domain/worship_moment.dart`) and **Ramadan mode** (`features/ramadan`) are derived from the same prayer schedule and the civil Hijri calendar.
- **Download center** (`features/downloads`) groups recitation, story and library downloads. Tafsir and hadith remain online only until their rights allow storage.

## Mobile module boundaries
- `core`: localization, typography, routing, persistence, logging, dependency injection.
- `quran`: surahs/ayahs, search, bookmarks, reading position, translations, tafsir.
- `recitation`: provider adapters, playback, playlist, timing metadata, lawful cache.
- `worship`: location choice, calculation settings, prayer times, Qibla, local reminders.
- `library`: hadith, fiqh, supplications and citations.
- `learning`: courses, articles, stories and quizzes.
- `account`: guest data, optional auth and explicit sync.

### Implemented in P00-06 (`apps/mobile`)
- Feature-first layout: `lib/app` (root widget, GoRouter, tab shell), `lib/core` (theme, localization, routing catalog, storage, content gates, shared widgets), `lib/features/<feature>/{presentation,domain,data,application}`.
- State: Riverpod `Notifier` for settings; storage injected via `keyValueStoreProvider` (overridden at start-up and in tests).
- Navigation: `StatefulShellRoute.indexedStack` with five branches (Home, Quran, Worship, Library, Learning); Settings on the root navigator.
- Content gating: `AppSection.status` (`ContentStatus`) — gated sections render only a status panel; a test fails if any section becomes `available` without an explicit, reviewed allow-list entry.
- Storage: preferences via `KeyValueStore` (allow-listed keys, schema version). Quran bookmark/last-read **contracts only** (`AyahRef` always carries an edition id); Drift is deferred to P01-03.
- No permissions in the main Android manifest; enforced by `apps/mobile/tool/policy_checks.sh` in CI.
- Details: [`apps/mobile/README.md`](../apps/mobile/README.md).

## Offline-first boundaries
- Ship a checked, immutable source Quran text dataset and metadata under a validated applicable license.
- Local Drift/SQLite stores reading position, settings, bookmarks and licensed cacheable content.
- Network sync is optional; never block prayer calculations because a backend is unavailable.
- Audio URLs and expiration rules are controlled by provider-specific adapters; streaming does not imply downloadable.
- Search index may strip/normalize only **derived** tokens; immutable Quran display text is retained.

## Backend and CMS
- Supabase Postgres/Auth/Storage is proposed; select exact version after docs/changelog review.
- Only publication-approved rows are publicly readable; drafts/reviews stay server-side.
- Enable RLS on exposed tables. User data policies check `auth.uid() = user_id`; role authorization uses server-controlled claims/role tables, never editable user metadata.
- Do not expose service-role credentials in Flutter, Next.js public bundles, or GitHub. Use environment secrets in deployment.
- Review actions write immutable audit events; withdrawals propagate to client content indices.

## Prayer/location
- Resolve location with user permission; always offer manual city.
- Calculate times locally with configurable method, Asr school, latitude handling and manual adjustment.
- Test Dubai, Abu Dhabi, Cairo and Alexandria against matching calculation parameters and official references.
- Time-zone and DST changes trigger recomputation; high-latitude behavior is explicit.
- Qibla compass requires calibration guidance and must disclose unreliable sensor readings.

## Operations
- Unit tests for source integrity, prayer math scenarios, bilingual layouts and RLS.
- CI: format, analyze, unit tests, secret scanning and content attribution checks.
- Do not automatically release religious content after AI drafting; scholarly and language approvals are separate.
