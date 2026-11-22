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

On 2026-11-23, the authenticated Quran Foundation prelive catalog supplied English Ibn Kathir (Abridged), resource 169, and Mishari Alafasy chapter recitation, resource 7. The source was verified on the running preview for tafsir of 1:1 and 2:255 and both chapter audio URLs. The preview is limited to the prelive dataset. [Quran Foundation developer terms](https://api-docs.quran.foundation/legal/developer-terms/)

## 2026-11-23 — Production and queued sources

- Quran Foundation Production returned all 114 chapter counts matching Tanzil. Arabic tafsir for 112:1 responded for Ibn Kathir (14) and al-Tabari (15). Maher Al-Muaiqly (159), Hafs murattal, returned an audio/mpeg byte range for chapter 112. Provider access is evidenced; publication and device review remain pending. Al-Banna and Islam Sobhi were absent from the account’s chapter-reciter catalog at validation.
- [QuranEnc](https://quranenc.com/en/home/api/index.html.md): Rowwad English edition `english_rwwad` returned four records for Al-Ikhlas without authentication, and the provider catalog reported version 1.0.21. Preserve verbatim text, footnotes, source and version and check provider updates.
- [HadeethEnc](https://new.hadeethenc.com/en/home): public categories and hadith 4315 returned Arabic and English records. Preserve the provider text, explanation, source grading, and release attribution. Record the content version and complete final review before publication.
- [Sunnah.com](https://sunnah.com/developers): optional additional provider, pending its API key and written reuse terms. Store the eventual key as `SUNNAH_API_KEY` on Supabase.
- [Cairo Quran Radio](https://misrquran.gov.eg/): official outbound listening destination. In-app streaming is pending an authorized endpoint and evidence of permitted reuse.

The private dua preview links 40 independently selected references in eight themes to the pinned Tanzil text. English meanings and footnotes load on demand from QuranEnc by verse identity. [Quran.com’s themes](https://quran.com/ar/duas) informed the index; its editorial copy is not ingested. Coverage of its full collection is not yet recorded. The Cairo radio card opens the official website in the browser.
