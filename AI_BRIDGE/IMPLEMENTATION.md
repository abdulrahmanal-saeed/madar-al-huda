# Implementation log

## 2026-11-23 — Typography and startup screen
- Branch `phase-02/design-typography` uses the owner-specified font roles from the design handoff. Reem Kufi 3.0 styles headings and both wordmarks. Amiri 1.003 styles hadith text and the dedication. Amiri Quran and IBM Plex Sans Arabic continue as the Quran and UI fonts.
- The Flutter startup screen uses the supplied orbit motif and bilingual wordmark. It displays the Arabic dedication in either locale, with an English meaning in the English locale. The screen is dismissible by tapping and automatically closes after 1.8 seconds. The current route builds below the splash so links resume where requested.
- Publisher binaries and OFL notices are bundled. Physical-device startup and the remaining screen designs are separate from this typography change.

## 2026-11-23 — P02-03 and P02-04 bilingual adhkar content
- Branch `phase-02/adhkar-content` prepares the five owner-selected sections. The [catalog](../docs/content/adhkar/catalog.json) includes Arabic and English editorial labels, reference IDs, documented counts, and the local routine completion copy.
- `python docs/content/adhkar/verify_catalog.py --sources` passed against the existing Tanzil asset, the QuranEnc 1.0.21 database, HadeethEnc Arabic 1.8.0 and English 1.25.0, and both Hisn indexes. The Arabic-only hadith on sleep and waking has a linked English source and separately marked draft meanings.
- The design handoff, in-app flow validation and final content and language reviews remain open. There are no Flutter UI or runtime changes in this PR.

## 2026-11-23 — P02-05 daily Quran reading goal
- Branch `phase-02/daily-reading-plan` stacks over PR #28 for access to the pinned 604-page Mushaf. D-21 allows preview implementation and technical checks while the parent reader is under review.
- The worship screen opens a daily reading plan with an editable page target, an exact link to the next Mushaf page, and an explicit action to mark the session read. A versioned, edition-bound record keeps the current goal and progress on the device. The card is preview-gated.
- The widget suite covers editing and reopening progress in Arabic and English. Android device QA remains open.

## 2026-11-22 — P00-07 Tanzil licence evidence only
- Verified [official Tanzil text license](https://tanzil.net/docs/Text_License) and [download description](https://tanzil.net/pub/download/index.php); recorded conditions in `docs/CONTENT_SOURCES.md` and Issue #26.
- No source Quran dataset was downloaded or imported, no SHA-256 or edition-specific totals asserted, and no recitation, translation or tafsir rights assumed. P00-07 remains BLOCKED and no content gate was opened.
- Documentation-only PR. Validation: standard CI on latest PR head; no local Flutter run claimed.

---

## 2026-11-22 — P01-08 Qibla geometry foundation
- Owner asked to continue features already planned without duplicating the logo, Flutter shell, Home UI or existing P00-10 reference fixtures.
- Pure Dart great-circle true-north bearing under `apps/mobile/lib/features/qibla/domain/qibla_bearing.dart`, four manual city-centre presets and deterministic test scenarios for London, NYC, Dubai, Abu Dhabi, Cairo and Alexandria, invalid coordinates, geographic poles and no-unique-bearing cases.
- Qibla screen stays gated; no GPS or compass permission; no sensor accuracy or on-device QA is claimed. **P01-08 is IN_PROGRESS, not DONE** until app UI and sensor/manual fallback are tested.
- Official IACAD Dulook DXB and UAE Awqaf pages were reviewed for P00-10; no dated city-specific Dubai/Abu Dhabi six-time timetable was retrievable from those pages, so no UAE expected prayer times were added. In contrast, P00-10 Egyptian official records remain in `docs/prayer/reference/official-2026-11-22.json`.
- Tests pending latest-head GitHub CI; no Flutter commands claimed as locally executed.

---

## 2026-11-22 — P00-10 official prayer-time references (partial)
- **Source:** Egyptian General Survey Authority official table dated 2026-11-22, https://www.esa.gov.eg/praytimes.aspx; local times transcribed for Cairo and Alexandria, not calculated by the app.
- **New:** docs/prayer/reference/official-2026-11-22.json, README.md and independent zero-dependency zoneinfo/format checker. Includes 2026 Egypt DST offset changes and UAE stable UTC+4.
- **Explicitly pending:** Official city/date-specific Dubai and Abu Dhabi timetables from IACAD/Awqaf. Official source calculation parameters, prayer algorithm tolerance, Flutter implementation, UI availability and manual device QA. P00-10 is IN_PROGRESS, P01-07 remains gated.
- **Test status:** GitHub CI required on PR, no claim of local Flutter execution.

---

## 2026-11-22 — P00-03 approval and P00-04 bilingual UX source
- **P00-03:** Owner approved the existing Arabic/English name and orbit/book logo; no assets, fonts, launcher icon or Flutter Home implementation were regenerated. Separate legal/store checks remain R-10 / Issue #19.
- **P00-04:** Created 14 editable SVG wireframes for Home, Quran hub, reader, recitations, prayer, library and learning (each AR/EN) under `docs/ux/wireframes/`; added route, state, localization, offline/gating and accessibility contract in `docs/ux/README.md`. Source checker `docs/ux/check_wireframes.py` added to existing policy CI job. No genuine religious material or calculated prayer times.
- **Testing evidence:** Pending the PR's GitHub Actions CI; do not claim locally executed Flutter tests. Manual AR/EN on-device and screen reader acceptance remains open under P00-06.

---

Implementation updates must include: task ID, branch, changed files, commands/tests actually run, known limitations and PR link.

---

## 2026-11-19 — P00-03 / MHD-010: original identity assets
- Created editable SVG icon, AR/EN wordmarks and monochrome source in `design/brand`, with brand JSON and a stdlib asset integrity validator.
- Added Android adaptive and monochrome vector assets, and regenerated all five legacy launcher PNG densities as opaque raster images. CI now validates brand colors, icon dimensions/XML and bundled IBM Plex Arabic OFL license.
- No Quran font, iOS artwork or trademark approval represented as complete. O-01 and O-08 require independent official name/ownership evidence. No mobile visual/device test claimed here.
- Issue #15. Status REVIEW pending independent feedback and merge.

---

## 2026-11-19 — P00-05 / MHD-009: architecture design and security contract
- Prepared ADR-0001, ERD, RLS policy matrix, threat model, reference SQL blueprint (not a migration), and links to existing Flutter shell / edition-aware AyahRef.
- Verified Supabase RLS and API-security docs plus November 2026 changelog (supabase-flutter v3). No Supabase version pinned or deployment performed.
- Review required: check projection publishing rules, composite verse references, RLS grants, ownership checks, future migration/test plan. No live SQL, pgTAP or device tests claimed.
- Issue #13. See `docs/architecture/README.md` and the P00-05 PR.

---

## 2026-11-19 — P00-11 / MHD-008: automatic updates for dev builds (Obtainium)

| Field | Value |
|---|---|
| PR | [#6](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/6) (draft) |
| Task | `P00-11` (new; owner request on 2026-11-19: "make it update automatically so I don't download a new APK every time") — `REVIEW` |
| Branch | `phase-00/p00-11-dev-updates`, **stacked on PR #5** (which is stacked on #4). Merge order: #4 → #5 → this. |
| Decision | D-17. The owner chose Obtainium + GitHub Releases over Shorebird and an in-app updater, so the app needs no new permissions or SDKs. |

**Problem found:** every CI debug APK is signed with a new random debug key, so Android refuses to install a new build over an old one. Any auto-update needs a fixed signing key.

**Changes**
- `apps/mobile/android/app/build.gradle.kts`: `MADAR_CHANNEL=dev` adds the app id suffix `.dev` and a version suffix. Signing comes from `MADAR_SIGNING_*` environment variables, and a dev build without them fails. Default builds are unchanged.
- `.github/workflows/dev-release.yml` (new): triggered by `workflow_run` after `Mobile CI` succeeds for a push to `main`, or by manual dispatch. It checks the secrets, builds a signed release APK, verifies package, version and signature with `aapt2`/`apksigner`, publishes a prerelease `v<ver>-dev.<run>` with the SHA-256 values, and keeps the newest 10 dev releases.
- `docs/DEV_UPDATES.md` (new, Arabic + English): secret setup, Obtainium setup, release timing.
- Tracker: new row `P00-11`; Phase 00 counts are now 11 tasks / 59 total (TRACKER, ROADMAP, PHASE_00, README, plan/README). D-17 and the changelog are updated.
- A dev signing key (PKCS12, RSA 4096, alias `madar-dev`, valid 25 years) was generated in the session scratchpad and handed to the owner privately. Its certificate SHA-256 is `6C:70:46:D0:F4:77:91:45:2D:A9:55:C3:9B:17:10:AD:DD:2F:A0:42:37:3C:29:78:2E:69:2A:08:04:2F:3E:E3`. **Not committed.**

**Commands actually run (local, Flutter 3.50.0)**
| Check | Result |
|---|---|
| `MADAR_CHANNEL=dev flutter build apk --release` without signing vars | Fails as intended: "MADAR_CHANNEL=dev requires MADAR_SIGNING_* variables." |
| Same build with a throwaway test key | Built (52.3 MB). `aapt2`: package `com.abdulrahmanalsaeed.madaralhuda.dev`, versionCode 7, versionName `0.1.0-dev.7`, no `uses-permission` except the AndroidX internal receiver permission. `apksigner`: cert matches the test key |
| Same build using the **real secret values**, decoded from base64 exactly as CI does | Built. Signature SHA-256 `6c7046d0…3ee3` matches the dev key |
| `flutter build apk --debug` (default) | Unchanged: `com.abdulrahmanalsaeed.madaralhuda`, 0.1.0 |
| actionlint 1.7.12 on both workflows | OK |
| Release-notes heredoc, cleanup filter and version parsing simulated in bash | Correct: only `vX.Y.Z-dev.N` tags are deleted |
| gitleaks (`dir`) | No leaks |

**Not verified:** the workflow itself can't run until it is on `main` (`workflow_run` and manual dispatch only work from the default branch) and the 3 secrets are added. The first real publish, and an Obtainium install plus in-place update on a phone, still need to be checked after merge.

---

## 2026-11-19 — P00-09 / MHD-007: QA rules, Definition of Done, PR template

| Field | Value |
|---|---|
| Task | `P00-09` — `REVIEW` (not merged) |
| PR | [#5](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/5) (draft) |
| Branch | `phase-00/p00-09-qa-dod`, **stacked on PR #4** (`claude/serene-galileo-f2ia01`), because it builds on that CI and edits the same tracker/AI_BRIDGE files. Merge #4 first, then retarget to `main`. |
| Approval | Owner approved starting P00-09 in a separate branch/PR. Dependency `P00-05` (architecture approval) is still `TODO`, so the DoD is marked *proposed* and will be revised if P00-05 changes the rules. |

**Summary**
- `plan/DEFINITION_OF_DONE.md`: status-transition rules (TODO → IN_PROGRESS → REVIEW → DONE / BLOCKED), plus done checklists per task type: all tasks, app code, religious content, calculations, docs and release. Also covers automated gates (it *references* the three existing CI jobs and adds none), required reviews and what counts as evidence, and severity and merge rules. It notes an owner action: protect `main` and require the three checks plus one review.
- `docs/QA_CHECKLIST.md`: manual QA sections A–H (install/launch offline with no permission prompt, language and RTL, navigation and state, theme/motion/text size, TalkBack, content integrity, privacy/permissions, persistence robustness), a results-table format, and the Phase 0 gate 1 sign-off.
- `.github/pull_request_template.md`: task/tracker fields, an evidence table ("commands actually run"), screenshots, manual QA, the DoD checklist, a religious-content gate, risks, and reviewer notes.
- Linked from `plan/WORKFLOW.md`, `plan/TEST_STRATEGY.md` and `plan/README.md`; tracker, changelog, TASKS (MHD-007) and REVIEW checklist updated.

**Not duplicated:** the secret scan, policy checks, format/analyze/test and APK build stay only in `.github/workflows/mobile-ci.yml`.

**Commands run:** documentation-only change, so no app tests were needed. I checked that every relative link in the changed Markdown files resolves (script output below), that the CI job names in DoD §3 match the workflow file, and ran gitleaks (`git` and `dir`: no leaks). CI will run on the PR because the branch contains `apps/mobile`.

---

## 2026-11-19 — P00-06 review fix: settings persistence race (PR #4)

| Field | Value |
|---|---|
| Task | `P00-06` / MHD-001 — still `REVIEW` (not merged) |
| Branch / PR | `claude/serene-galileo-f2ia01` → [PR #4](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/4) (draft, kept open for re-review) |
| Finding | [Review comment](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/4#issuecomment-7008108058): `SettingsController._update` restored the whole previous `AppSettings` on failure and writes were not serialized. A failed theme save could roll back a successful language change, and rapid edits of one setting could persist out of order. The schema marker was written *after* the value, so a marker failure left disk changed while the UI rolled back. |

**Fix**
- `settings_controller.dart`: all saves go through one **serialized queue** (strict request order, one write in flight). A queued save **superseded** by a newer request for the same field is skipped (the latest value wins). On failure, only the **failed field** reverts, to its **last persisted value**, and only if the request is still the latest for that field. Superseded failures change nothing and don't surface an error. The controller tracks a `_persisted` snapshot and per-field revisions, and guards on `ref.mounted`.
- `settings_repository.dart`: the schema marker is written **before** the value and only when missing or outdated. A marker failure therefore means the value was never written, so rollback keeps UI and disk consistent.

**Regression tests** (`test/features/settings/settings_concurrency_test.dart`, 11 tests). They use a `ControlledStore` whose writes complete only when the test settles them, so every interleaving is deterministic:
the review scenario (theme fails while language succeeds), the inverse case, serialization (never more than one write in flight, in order), rapid same-field changes with coalescing, a superseded in-flight failure, a latest failure reverting to the last *persisted* value, rapid toggles ending in failure, marker failure leaving disk and UI unchanged, the marker written once and first, no-op re-selection, and a fixed mixed success/failure schedule ending with UI == disk.
Plus one widget test (`localization_and_theme_test.dart`) with three rapid taps through the Settings UI, checking that both the theme and language end up persisted and shown.

**Proof the tests catch the bug:** with the previous controller swapped back in, the review-scenario test fails with `Expected: AppLanguage.arabic, Actual: AppLanguage.system` ("successful language change must survive the theme rollback"). With the previous controller and repository, 10 of 11 concurrency tests fail. With the fix, all pass.

**Commands run (apps/mobile)**
| Command | Result |
|---|---|
| `flutter pub get --enforce-lockfile` | OK |
| `flutter gen-l10n` + diff | Up to date |
| `dart format --output=none --set-exit-if-changed lib test` | Clean |
| `flutter analyze --fatal-infos` | No issues |
| `flutter test --coverage` | **93 passed** (81 → 93); 97.3 % lines; `settings_controller.dart` and `settings_repository.dart` 100 % |
| `flutter build apk --debug` | Built |
| `./tool/policy_checks.sh` | Passed |
| gitleaks 8.30.1 (`git`, `dir`) | No leaks |

Changed files: `apps/mobile/lib/features/settings/application/settings_controller.dart`, `apps/mobile/lib/features/settings/data/settings_repository.dart`, `apps/mobile/test/features/settings/settings_concurrency_test.dart` (new), `apps/mobile/test/app/localization_and_theme_test.dart`, `apps/mobile/README.md`, `AI_BRIDGE/IMPLEMENTATION.md`, `AI_BRIDGE/REVIEW.md`.

Remaining before merge: re-review of this fix, a green CI run on the new head, and the on-device/emulator check in both languages.

---

## 2026-11-19 — P00-06 / MHD-001: Flutter Android skeleton + AR/EN localization

| Field | Value |
|---|---|
| Task | `P00-06` (tracker) / `MHD-001` / [Issue #2](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/2) |
| Status | `REVIEW` — PR open, not merged |
| Branch | `claude/serene-galileo-f2ia01` (session-assigned branch; `plan/WORKFLOW.md` suggests `phase-00/p00-06-…`) |
| Agent | Claude Code (coding agent) |
| PR | [#4](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/4) (draft) |

### Dependency note
`P00-06` depends on `P00-03` (final identity) and `P00-05` (ERD/architecture approval), both still `TODO`. Per the owner's instruction, the skeleton was built on the **provisional** tokens in `docs/BRAND.md` and the **proposed** architecture in `docs/ARCHITECTURE.md` (decision D-16). Colours, font, launcher icon and app ID are isolated in `lib/core/theme/`, `android/app/src/main/res/` and `build.gradle.kts`, so finalising P00-03/P00-05 does not require restructuring.

### Summary
- New Flutter app in `apps/mobile` (Flutter 3.50.0 stable, Dart 3.14.0), feature-first structure, Riverpod 3 + go_router 18, exact-pinned dependencies, committed `pubspec.lock`.
- Five-tab shell (Home, Quran, Worship, Library, Learning) using `StatefulShellRoute.indexedStack` (per-tab stacks retained; re-tap returns to root); `NavigationRail` at ≥ 600 dp.
- Section screens: Read the Quran, Recitations, Tafsir, Prayer Times, Qibla, Adhkar & Dua, Hadith, Comparative Fiqh, Articles, Lessons & Quizzes, Stories of the Prophets, plus Settings and a 404 page.
- **No religious content.** Every section is gated by `ContentStatus` and shows a neutral, labelled status panel (awaiting source verification / audio rights / scholarly review / editorial review / calculation validation / in development). A test fails if any section becomes ungated without an explicit allow-list change. Home shows only greeting, tagline, today's Gregorian date (device clock, `intl`), shortcuts and two notices.
- Arabic (RTL) + English (LTR) via ARB/gen-l10n; follows device language (Arabic → Arabic, anything else → English, D-13); override in Settings; persisted.
- Light/Dark/System theme, "Reduce motion" (disables page transitions and sets `disableAnimations`), all persisted locally via `shared_preferences` behind a `KeyValueStore` interface with an allow-list and schema version. Corrupt values fall back to defaults; save failures roll back and show a localized message.
- Storage contracts for Quran bookmarks / last-read (`AyahRef` always carries an edition id) — interfaces only; Drift deferred to P01-03.
- Design system: brand colours as Material 3 `ColorScheme`s (light/dark), spacing/radius/breakpoint tokens, reusable widgets (`HubScaffold`, `SectionCard`, `SectionDetailScaffold`, `ContentStatusPanel`, `StatusPill`, `IconBadge`, `OrbitMotif`, `ResponsiveContent`). IBM Plex Sans Arabic bundled (OFL 1.1, licence shown on the licences page).
- Android: app ID `com.abdulrahmanalsaeed.madaralhuda` (candidate, O-08 open), localized launcher label, `supportsRtl`, Android 13 per-app language config, locale filter (ar/en), brand splash colours, provisional adaptive + legacy icons, `allowBackup=false`, **no permissions** in the main manifest. iOS: same bundle ID, display name, `CFBundleLocalizations` ar/en, provisional icons (not built/tested).
- CI (`.github/workflows/mobile-ci.yml`): gitleaks (checksum-verified binary, full history), policy checks, `pub get --enforce-lockfile`, stale-l10n check, `dart format`, `flutter analyze --fatal-infos`, `flutter test --coverage`, debug APK build + artifact. Actions pinned by SHA. Dependabot for pub/gradle/actions.

### Changed files
- `apps/mobile/**` — new Flutter project (lib, test, android, ios, assets, tool, pubspec, l10n.yaml, analysis_options.yaml, README).
- `.github/workflows/mobile-ci.yml`, `.github/dependabot.yml` — new.
- `docs/screenshots/p00-06/*.png` — 5 reference screenshots (AR/EN, light/dark).
- `plan/TRACKER.md` (P00-06 → REVIEW), `plan/DECISIONS.md` (D-12…D-16), `plan/CHANGELOG.md`, `docs/PHASE_0.md`, `docs/ARCHITECTURE.md`, `README.md`.
- `AI_BRIDGE/TASKS.md`, `AI_BRIDGE/IMPLEMENTATION.md`, `AI_BRIDGE/REVIEW.md`.

### Commands actually executed (in the cloud container, Linux x64)
Toolchain installed for this session: Flutter 3.50.0 stable (`flutter_linux_3.50.0-stable.tar.xz`), Android cmdline-tools, `platforms;android-36`, `build-tools;36.0.0`, `ndk;28.2.13676358` (CMake 3.22.1 auto-installed by Gradle), OpenJDK 21.0.13, Gradle 9.5.0 wrapper.

All run from `apps/mobile/`:

| Command | Result |
|---|---|
| `flutter pub get --enforce-lockfile` | OK |
| `flutter gen-l10n` then compare generated files | Unchanged (stable output) |
| `dart format --output=none --set-exit-if-changed lib test` | 0 changed |
| `flutter analyze --fatal-infos` | **No issues found** |
| `flutter test --coverage` | **81 tests, all passed**; line coverage 97.3 % (928/954, incl. generated l10n) |
| `flutter build apk --debug` | **Built** `build/app/outputs/flutter-apk/app-debug.apk` (first attempts hit HTTP 429 from Maven Central; succeeded on retry) |
| `aapt2 dump badging app-debug.apk` | package `com.abdulrahmanalsaeed.madaralhuda`, versionName 0.1.0, minSdk 24, targetSdk 36, labels en "Madar Al-Huda" / ar "مدار الهدى", locales en+ar. Permissions: `INTERNET` comes only from the debug manifest (Flutter tooling); main manifest has none |
| `./tool/policy_checks.sh` | Passed; negative test (ads SDK, location permission, `^` version, tracked `.jks`) → all four reported, exit 1 |
| `gitleaks dir .` and `gitleaks git .` (v8.30.1, checksum verified) | No leaks found |

**GitHub Actions (PR #4), [run 44515769187](https://github.com/abdulrahmanal-saeed/madar-al-huda/actions/runs/44515769187) on `8d2b11a`: all 3 jobs passed** — Secrets & policy; Format, analyze & test; Android debug build (APK uploaded as artifact `madar-al-huda-debug-apk`). Run 1 was cancelled by the concurrency group when the next commit was pushed.

Visual check: screens were rendered through a temporary golden test with the real fonts loaded (AR/EN × light/dark × Home/Worship/Prayer Times/Settings). It found and fixed one bug (component text styles had no font size → tiny app-bar titles; now covered by a regression test). The temporary test was removed; 5 screenshots are kept in `docs/screenshots/p00-06/`.

### Not verified / remaining issues
- **No emulator or physical device run.** Acceptance asks for both locales verified on-device or emulator (Phase 0 gate 1) — still needed. Widget tests cover RTL/LTR, mirroring, persistence and text scaling.
- iOS not built (no macOS); structure only.
- Screen-reader (TalkBack) pass not performed; semantics labels are set on cards and headers.
- Brand assets, font choice, icon and app ID are provisional (P00-03, O-01, O-08).
- `material_ui` (decoupled Material) is new in Flutter 3.4x; generated `app_localizations.dart` still imports deprecated `flutter_localizations` delegates (excluded from analysis; the app uses `material_ui`'s delegates).

### Suggested next task
`P00-09` — QA rules & Definition of Done (PR template, DoD checklist, CI as required check, review checklist), building directly on this CI. Then `P00-10` — prayer fixtures for Dubai, Abu Dhabi, Cairo, Alexandria; this needs **official published reference timetables** (UAE: IACAD/Awqaf; Egypt: Egyptian General Authority of Survey) with documented parameters before any expected values are written. Both formally depend on `P00-05` (architecture approval).

---

## 2026-11-19 — Foundation
- Established initial repository documentation and Phase 0 planning branch.

## P01 prayer, Qibla and unified Quran preview

- Branch `phase-01/prayer-qibla-quran` implements one location selection, offline prayer calculation, Android Qibla heading, and one verse reader with sourced audio and tafsir integration.
- Published source status is still gated by the [prayer references](../docs/prayer/README.md), [source register](../docs/CONTENT_SOURCES.md), and device acceptance. Debug builds exercise the complete UI; reviewed preview distribution can opt in via a dart-define.
- Supabase preview function and rate-limit migration were deployed. Verified gateway authentication, input rejection, two prelive chapters, and service-role-only execution of the rate-limit RPC.

### 2026-11-23 — Paginated reader and Android preview

- PR #28 adds continuous 604-page reading from the pinned Tanzil metadata, verse-key navigation, local search, bookmarks and cursor restoration. Both language variants exercise long-press on 2:255 and bookmarking in a widget test. QuranEnc English meaning and version are queried when needed.
- A private preview has 40 linked Quranic supplications in eight topics and a bilingual HadeethEnc browser. The Cairo radio card opens the broadcaster’s official site. The broadcaster’s permission for playback inside third-party apps is pending.
- Prayer tests rerun the dated Egypt and UAE comparisons from the repository fixtures and verify Cairo DST and next-day rollover. Device-specific Qibla calibration and TalkBack checks are pending.
- Analysis reported no issues and 112 Flutter tests passed locally after adding the preview. The dev workflow accepts the validated public Quran configuration. The .preview APK and public .dev release use separate distribution paths. D-21 reserves religious approval for the final whole-app review.

### 2026-11-23 — Worship follow-up

- P02-03 expands the Quranic supplications index to 75 entries and adds Arabic text, surah and verse-reference search. P02-04 adds the saved filter backed by the edition-specific Quran bookmark repository.
- P02-09 opens the broadcaster’s official live page inside the app. The app pauses an active Quran recitation before opening the embedded player and offers an explicit browser retry if launch fails. The broadcaster’s public controls played and paused live media in Chrome. Android and native background playback are separate verification items under P02-09.
- The staged Obtainium release follows D-21 and uses the existing signed development workflow once the eligible changes are reviewed and on main.
