# Content and license verification register — NOT approvals

**No source in this table is marked approved for redistribution yet.** Technical accessibility != reuse permission. Confirm actual provider terms and digital edition before ingestion.

| Content | Preferred candidate | Status | Required proof |
|---|---|---|---|
| Quran text | Tanzil / verified Uthmani edition | Official verbatim-use terms documented; pinned export and structural checks complete | Keep the pinned manifest and app credit; complete independent publication review |
| Quran meaning EN | QuranEnc / an authorized English translator | Pending | Edition/license, attribution, updates, lawful offline scope |
| Tafsir | al-Tabari — Jami' al-Bayan | Pending | Edition/source provenance, reproduction rights, verse mapping |
| Tafsir | Ibn Kathir — Tafsir al-Qur'an al-'Azim | Pending | Edition/source provenance, reproduction rights, verse mapping |
| Recitation | Maher Al-Muaiqly | Pending | Owner/provider, stream rights, background mode, caching/download |
| Recitation | Mahmoud Ali Al-Banna | Pending | Owner/provider, stream rights, cache duration |
| Recitation | Islam Sobhi | Pending | Owner/provider, stream rights, cache duration |
| Hadith | HadeethEnc / other licensed corpus | Pending | Text/translation rights, exact grading citations and updates |
| Adhkar and supplications | HadeethEnc, Hisn al-Muslim, Tanzil and QuranEnc | Editorial draft, versions and links verified | Verify digital reuse rights for the Hisn edition and translation before bundling. Review wording, variants, counts and language before publication under D-21. |
| Fiqh | Authoritative works per Sunni madhhab | Pending | Editions/rights and approved scholarly review |
| Prayer times | Local calculation with verified parameters | Technical validation pending | UAE/Egypt official comparison fixtures |

## License register fields
source URL; legal owner; text/audio edition; permission evidence/date; allowed languages; commercial restriction; API attribution; offline caching rights; expiry; derivative works restriction; revocation process; reviewer.

## Mandatory gates
- Never rewrite Quran ayahs or quietly replace edition text.
- Do not publish AI-created hadith, tafsir or fiqh rulings as sourced facts.
- Cite source, edition and location for jurisprudence. If several views exist, include distinctions.
- Separate original editorial text from third-party quotation and protected translation.
- For audio, stream until downloading/storage is explicitly authorized.
- Keep a documented takedown process for disputed rights or religious accuracy.

## 2026-11-22 — Tanzil official text licence audit (P00-07)

- [Official text licence](https://tanzil.net/docs/Text_License): CC BY 3.0 with explicit permission to distribute the **verbatim** Quran text in applications. Do not alter the text. Provide visible Tanzil credit/link and reproduce the official copyright notice with redistributed copies.
- [Official text download](https://tanzil.net/pub/download/index.php) lists v1.1, February 2021. Exact Uthmani export options, immutable source bytes, independent SHA-256, edition-specific ayah counts and app attribution are **still unverified**.
- This licence does **not** automatically grant rights to English translations, al-Tabari/Ibn Kathir digital editions, or reciters' audio, playback/caching or downloading. Those require separate provider permission checks.

**R-01 remains OPEN and P00-07 BLOCKED** until the exact source manifest and other launch rights are evidenced. [Issue #26](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/26). No Quran text has been imported.

## P01 preview source manifest

| Asset | Origin and options | SHA-256 |
|---|---|---|
| Tanzil Uthmani 1.1 text | [Official download](https://tanzil.net/pub/download/index.php?marks=true&sajdah=true&tatweel=true&quranType=uthmani&outType=txt-2&agree=true), text with surah and ayah numbers, marks, sajdah, and tatweel | `6933e133dd56db778c801bf738848454e43648105a151e8d84d86a7cae39ec5f` |
| Tanzil v1.0 metadata | [Original XML](https://tanzil.net/res/text/metadata/quran-data.xml) | `8867c1d88191472adec9db694b3cd9f135b1a2ef580574d32cf888dcb22c5c7a` |
| Amiri Quran 1.003 | [Publisher release](https://github.com/aliftype/amiri/releases/tag/1.003), SIL OFL, bundled with its notice | `e2a47644762d16bdfb6d33e0d8db8c6ff30beae84150ef5a705316bbd829455c` |

The reader checks the original UTF-8 files against their hashes and verifies every chapter, verse key and declared count against the supplied metadata. The source file retains its copyright block and the reader links to Tanzil. Independent publication and device typography reviews remain open. Quran Foundation resources are streamed or fetched on demand. Quran Foundation prelive provides only two chapters for integration checks. Record the exact digital edition or recording and approval for each production resource before enabling its ID.

On 2026-11-23, the authenticated Quran Foundation prelive catalog supplied English Ibn Kathir (Abridged), resource 169, and Mishari Alafasy chapter recitation, resource 7. The source was verified on the running preview for tafsir of 1:1 and 2:255 and both chapter audio URLs. The preview is limited to the prelive dataset. [Quran Foundation developer terms](https://api-docs.quran.foundation/legal/developer-terms/)

## 2026-11-23 — Production and queued sources

- Quran Foundation Production returned all 114 chapter counts matching Tanzil. Arabic tafsir for 112:1 responded for Ibn Kathir (14) and al-Tabari (15). Maher Al-Muaiqly (159), Hafs murattal, returned an audio/mpeg byte range for chapter 112. Provider access is evidenced; publication and device review remain pending. Al-Banna and Islam Sobhi were absent from the account’s chapter-reciter catalog at validation.
- [QuranEnc](https://quranenc.com/en/home/api/index.html.md): Rowwad English edition `english_rwwad` returned four records for Al-Ikhlas without authentication, and the provider catalog reported version 1.0.21. Preserve verbatim text, footnotes, source and version and check provider updates.
- [HadeethEnc](https://new.hadeethenc.com/en/home): public categories and hadith 4315 returned Arabic and English records. Preserve the provider text, explanation, source grading, and release attribution. Record the content version and complete final review before publication.
- [Sunnah.com](https://sunnah.com/developers): optional additional provider, pending its API key and written reuse terms. Store the eventual key as `SUNNAH_API_KEY` on Supabase.
- [Cairo Quran Radio](https://misrquran.gov.eg/home) publishes a live HTTPS HLS feed in its own player. The site presented a rolling manifest and downloadable media segments when verified on 2026-11-23. The private Android preview can set `MADAR_CAIRO_RADIO_URL` to the verified feed to play directly through the shared background audio session. Audio is streamed from the broadcaster on demand. Builds without a configured feed open the broadcaster’s official player.
- Keep the native feed out of public releases until the station confirms third-party playback and attribution. The privacy policy does not document those terms. The [official Android listing](https://play.google.com/store/apps/details?id=com.mcit.holyquranradio) publishes the station's contact address.

The dua preview now links 75 entries across 109 unique verses in the pinned Tanzil edition. The selection uses eight original themes. All verse references resolve against Tanzil. The [Eqtidaa supplications book](https://doa.eqtidaa.com/ar/download/interactive/book/doa-ar?download=true) provided an additional editorial reference. The English meanings and footnotes load from QuranEnc with edition attribution. The app links to [Quran.com’s original groups](https://quran.com/ar/duas) for browsing their full editorial collection.

## 2026-11-23 — Bilingual adhkar content handoff

- [Content catalog and verification](content/adhkar/README.md) cover daily remembrance, the user's remembrance routine, Hisn topics, hadith on the merits of remembrance and Quranic supplications. The catalog keeps editorial labels and suggestions distinct from publisher text.
- The [HadeethEnc publisher](https://hadeethenc.com/ar) permits republication under its published conditions, including unaltered content, source credit, version notice and updates. The official CSV notices identify Arabic 1.8.0 and English 1.25.0. The selected records, source grades and takhrij fields were checked in those releases. Bukhari 6324 has an Arabic HadeethEnc record (65913); the English fallback is a separately labeled draft meaning with an original reference link.
- Hisn al-Muslim's Arabic and English website indexes were matched by chapter link. The [1436 AH print edition](https://d1.islamhouse.com/data/ar/ih_books/single_01/ar_Hisn_Almuslim1436.pdf#page=2) records conditions for printing and free distribution. The handoff links to publisher pages while digital reuse scope for in-app bundling stays open (R-12).
- The pinned Tanzil asset and the publisher's Rowwad English translation database cover all references in the handoff. The QuranEnc terms require preservation of the translation and version with attribution.


## Recitation downloads and publisher verification

The coverage in [Yousef Heiba's Al-Banna catalog](https://quran.yousefheiba.com/api/reciterAudio?reciter_id=121) and [Islam Sobhi catalog](https://quran.yousefheiba.com/api/reciterAudio?reciter_id=253) was intersected with the corresponding Hafs murattal editions in the [MP3Quran developer catalog](https://www.mp3quran.net/ar/api). The app offers 114 surahs for Al-Banna and 93 for Islam Sobhi. Full-file SHA-256 comparisons matched both sources for Al-Banna 1, 112 and 114, Islam Sobhi 1 and 114, and Al-Muaiqly 1 and 112. The first 8 MB also matched for Islam Sobhi 36.

The app connects directly to the corresponding MP3Quran publisher assets for these editions. [MP3Quran's published rights notice](https://www.mp3quran.net/privacy-en.html) permits developers to copy publisher material and use its links. The reciter and publisher appear with the recordings. Downloads are individually requested, stored in the app's private audio library, and deletable from the reader or the downloads list.

The existing Quran Foundation operation supplies verse timestamps and its chapter recording when available. Those requests remain streamed. The separately licensed MP3Quran edition is used for offline chapter playback, including Al-Muaiqly. The app does not apply Quran Foundation timestamps to a different publisher recording. [Quran Foundation audio terms](https://api-docs.quran.com/legal/developer-terms/#storage-and-offline-copies)
