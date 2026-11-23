# مدار الهدى | Madar Al-Huda

**A free, bilingual Islamic companion for Quran, knowledge, and worship.**

> **Status:** development builds only, not a store release. The signed Dev channel (Obtainium) carries the working app; release builds keep every section behind its content gate until sources and reviews are signed off (see [plan/TRACKER.md](plan/TRACKER.md)).
>
> **In the Dev channel today:**
> - **Quran:** the verified Tanzil Mushaf (index, search, bookmarks), with reading settings, tafsir and recitations, and offline downloads.
> - **Daily worship:** prayer times for the UAE and Egypt, Qibla, adhkar and Quranic duas, a time-aware home card, opt-in reminders, and Ramadan mode.
> - **Library:** hadith, prophet stories, and the Cairo Quran radio.
> - **Download center** for offline use.
> - **Hosted admin:** a PHP dashboard at `quran.abdulrahmanalsaeed.com/admin` that publishes the library, theme and sections the app reads.

## Product commitments

- **Platforms:** Android first; Flutter architecture ready for iOS.
- **Languages:** Arabic (RTL) and English (LTR) from the first release.
- **Quran:** Reading and audio recitations with sourced tafsir and English meanings.
- **Knowledge:** Hadith, du'a, adhkar, comparative fiqh across the four Sunni madhhabs, lessons, prophetic stories, and articles.
- **Daily worship:** Prayer times, Qibla, and configurable reminders; initial verification markets: United Arab Emirates and Egypt.
- **Business model:** Always free and without advertising.
- **Privacy:** Guest-first, no account needed for basic use; offline access wherever legally and technically permitted.

## Selected initial content (rights pending verification)

- **Reciters:** Maher Al-Muaiqly, Mahmoud Ali Al-Banna, Islam Sobhi.
- **Tafsir:** Jami' al-Bayan (al-Tabari), Tafsir al-Qur'an al-'Azim (Ibn Kathir).

**Important:** Do not ingest or redistribute content before checking the precise source, edition, integrity, reuse rights, and attribution. No unreviewed religious rulings should be published.

## Stack

**Implemented:**
- **App:** Flutter 3.50 (`apps/mobile`, Riverpod, go_router, flutter_local_notifications).
- **Admin:** a PHP 8 + SQLite dashboard (`hosting/admin`, deployed to Hostinger; see [hosting/README.md](hosting/README.md)).
- **Supabase:** an edge function for tafsir and recitation metadata.
- **CI:** GitHub Actions (`.github/workflows/mobile-ci.yml`) runs Flutter checks, PHP lint and tests, and the Android build.

**Planned:**

Flutter/Dart mobile app · Drift/SQLite local storage · Supabase/PostgreSQL backend · Next.js admin CMS. Actual versions and integrations will be pinned and validated during implementation.

## Project roadmap and task tracking

**Start with [plan/README.md](plan/README.md)** to see all seven phases, the [59-task tracker](plan/TRACKER.md), acceptance criteria, risks, and release gates. `plan/TRACKER.md` is the authoritative task status board. `AI_BRIDGE/` tracks handoffs between implementation and review agents.

## Project docs

See the Phase 0 foundation branch/PR for the PRD, brand, architecture, data model, editorial policy, source register, and work plan.

## Security

Never commit credentials, service-role keys, provider API secrets, user location histories, or copyrighted content not licensed for redistribution.

## License

Source-code license: **undecided**. All rights reserved until the owner selects a license. Rights to Quran text editions, recitations, tafsir, books, translations, and other third-party assets are separate from code licensing.
