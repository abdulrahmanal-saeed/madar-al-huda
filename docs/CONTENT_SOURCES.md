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
