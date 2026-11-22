# Madar Al-Huda brand source kit — P00-03

**Current creative direction and logo approved by owner 2026-11-22; no redesign.** Legal trademark/package checks remain separate [R-10 / Issue #19](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/19).

Original icon: book and orbit, representing knowledge and guidance, without religious script. Files: [icon-master.svg](icon-master.svg), [icon-monochrome.svg](icon-monochrome.svg), [wordmark-ar.svg](wordmark-ar.svg), [wordmark-en.svg](wordmark-en.svg), [tokens.json](tokens.json). Source SVGs remain editable; wordmark exports require IBM Plex Sans Arabic.

## Color and readability
Deep green `#173F39`, muted gold `#C7A86D`, ivory `#F8F5ED`, dark ink `#263B38`. Muted gold is decorative only on ivory; use `#6E5420` for gold-like readable text there. Existing Flutter tests enforce AA contrast on text pairs.

## Type
UI in both Arabic and English uses IBM Plex Sans Arabic (regular, medium, semibold, bold), bundled with [OFL-1.1](https://github.com/IBM/plex/blob/master/packages/plex-sans-arabic/LICENSE.txt), copy in `apps/mobile/assets/fonts/ibm_plex_sans_arabic/OFL.txt`. Inter is not bundled. Quran needs a separately validated licensed Uthmani text font (not fulfilled in this task).

## Android assets
Vector adaptive foreground and white monochrome themed icon in Android res/drawable. Raster legacy icons at mdpi=48, hdpi=72, xhdpi=96, xxhdpi=144, xxxhdpi=192. The design is non-directional and must not flip in RTL. Color source tokens mirror Flutter `BrandColors`.

Run: `python3 design/brand/check_assets.py` to validate shared palette, SVG/XML parsing, font license and native raster sizes.

## Open
- Owner visual signoff completed 2026-11-22; independent formal trademark investigation remains open under R-10/O-01.
- Candidate Android package identifier ownership O-08.
- iOS icon exports and store screenshots in future iOS phase.
