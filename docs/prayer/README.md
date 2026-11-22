# P00-10 — Official prayer-time reference fixtures (in progress)

Task: [Issue #21](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/21).

**This is a reference source pack, not a working prayer calculator.** Only official publisher values are allowed as expected results. The user-facing prayer-time section remains gated pending P01-07 calculation, official comparisons and error handling.

## Source-backed data

The machine-readable fixture [official-2026-11-22.json](reference/official-2026-11-22.json) contains local-clock times for the Egyptian General Survey Authority's **2026-11-22** timetable, as transcribed on 2026-11-22:

| City / TZ | Fajr | Sunrise | Dhuhr | Asr | Maghrib | Isha | Source |
|---|---:|---:|---:|---:|---:|---:|---|
| Cairo, Africa/Cairo | 04:55 | 06:26 | 11:41 | 14:36 | 16:56 | 18:17 | [Egyptian General Survey Authority](https://www.esa.gov.eg/praytimes.aspx) |
| Alexandria, Africa/Cairo | 05:01 | 06:33 | 11:46 | 14:39 | 16:59 | 18:21 | [Egyptian General Survey Authority](https://www.esa.gov.eg/praytimes.aspx) |
| Dubai, Asia/Dubai | — | — | — | — | — | — | [Official Dulook DXB / IACAD](https://ipt.iacad.gov.ae/) — **pending dated values** |
| Abu Dhabi, Asia/Dubai | — | — | — | — | — | — | [Awqaf UAE](https://www.awqaf.gov.ae/) — **pending dated values** |

**Unknowns:** The captured official Egyptian table does not separately specify every computation parameter (e.g. detailed solar angles, Asr rule). Do not claim a mathematical comparison is complete until parameters are documented. The official source page may change daily; preserve source evidence with access date and, if available, a stable authority-published archived timetable. This project does not reproduce a whole authority table.

## Time-zone and DST reference checks

- The **IANA time-zone ID**, not a hardcoded UTC offset, is part of the record.
- `Asia/Dubai`: UTC+04:00 year round (test Jan, Jul, Nov).
- `Africa/Cairo`: 2026-04-23 UTC+02, 2026-04-24 UTC+03; 2026-10-29 UTC+03, 2026-10-30 UTC+02; Nov 22 UTC+02. Avoid comparing times without selecting the correct local date and time zone. DST source: [Egypt State Information Service](https://sis.gov.eg/en/media-center/news/egypt-gets-ready-to-turn-back-the-clocks-as-daylight-saving-time-ends-this-week/) and [timeanddate 2026](https://www.timeanddate.com/time/change/egypt?year=2026).
- Use noon local for DST fixture checks to avoid duplicated/missing hours during transitions.
- Different Asr juristic settings and manually adjusted schedules must not be silently compared as equivalent.

## Verification and completion

Run `python3 docs/prayer/check_reference_fixtures.py`, which verifies format, city IDs, chronology, official source provenance fields and UTC offset transitions. It explicitly verifies that **the two UAE expected time sets are absent**, preventing accidental invention and false acceptance.

**Still open before P00-10 DONE:** (1) official date-stamped Dubai and Abu Dhabi expected timetable values with authority/parameter evidence, (2) calculation engine with method/Asr/rounding rules, (3) justified minute tolerance and independent numerical comparisons for all four cities, including DST, (4) device/manual fallback and error checks. The code checker is not a prayer calculation and does not certify actual religious times.
