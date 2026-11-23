# Madar Al-Huda brand source kit — P00-03

**Launcher icon approved by owner 2026-11-22.** The typography and Flutter startup screen follow the updated design. Legal trademark/package checks remain separate [R-10 / Issue #19](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/19).

Launcher and splash mark: an eight-point star and open orbit from the updated design. Files: [icon-master.svg](icon-master.svg), [icon-monochrome.svg](icon-monochrome.svg), [wordmark-ar.svg](wordmark-ar.svg), [wordmark-en.svg](wordmark-en.svg), [tokens.json](tokens.json). The editable wordmarks use Reem Kufi for the name and IBM Plex Sans Arabic for the tagline.

## Color and readability
Deep green `#173F39`, muted gold `#C7A86D`, ivory `#F8F5ED`, dark ink `#263B38`. Muted gold is decorative only on ivory; use `#6E5420` for gold-like readable text there. Existing Flutter tests enforce AA contrast on text pairs.

## Type
UI label and body styles in both Arabic and English use IBM Plex Sans Arabic. Headings and the wordmark use Reem Kufi 3.0. The Mushaf text uses Amiri Quran 1.003, and hadith text and the startup dedication use Amiri 1.003. The original OFL notices are in `apps/mobile/assets/fonts/` and appear in the app's licences page. [Reem Kufi](https://github.com/aliftype/reem-kufi/releases/tag/v3.0) · [Amiri and Amiri Quran](https://github.com/aliftype/amiri/releases/tag/1.003) · [IBM Plex](https://github.com/IBM/plex)

## Android assets
Vector adaptive foreground and white monochrome themed icon in Android res/drawable. Raster legacy icons at mdpi=48, hdpi=72, xhdpi=96, xxhdpi=144, xxxhdpi=192. The design is non-directional and must not flip in RTL. Color source tokens mirror Flutter `BrandColors`.

Run: `python3 design/brand/check_assets.py` to validate shared palette, SVG/XML parsing, font license and native raster sizes.

## Open
- Owner visual signoff completed 2026-11-22; independent formal trademark investigation remains open under R-10/O-01.
- Candidate Android package identifier ownership O-08.
- iOS icon exports and store screenshots in future iOS phase.
