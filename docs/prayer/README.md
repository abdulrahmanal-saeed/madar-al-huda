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

## Initial UAE source inspection on 2026-11-22

[Dubai IACAD Dulook DXB](https://ipt.iacad.gov.ae/) confirms an official prayer-time application, and [UAE Awqaf](https://www.awqaf.gov.ae/) is an official authority, but their publicly indexed pages did **not** expose a reliably captured **2026-11-22 dated six-time schedule** for both Dubai and Abu Dhabi during this review. It would be unsafe to infer official expected times from third-party calculations or the app under test. The UAE fields remain `null`, and P00-10 is still **IN_PROGRESS**. [P01-07 Issue #24](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/24) tracks the eventual method-aware calculation engine; P01-08 Qibla geometry is unrelated to this prayer-time validation gate.

## P01 preview comparison

The Android preview runs Adhan Dart 2.0.1 with the Egyptian and Dubai parameter sets. These comparisons use standard Asr, the four preset city centres, and the selected city's local date. Signed differences below are calculated minutes minus reference minutes.

| City | Reference date | Fajr | Sunrise | Dhuhr | Asr | Maghrib | Isha |
|---|---|---:|---:|---:|---:|---:|---:|
| Cairo | 2026-11-22 | 0 | 0 | +1 | 0 | 0 | 0 |
| Alexandria | 2026-11-22 | +1 | 0 | +1 | 0 | 0 | 0 |
| Abu Dhabi | 2026-02-18 | 0 | — | 0 | +3 | 0 | 0 |

The Abu Dhabi comparison uses the [Sheikh Zayed Grand Mosque Centre Ramadan 1447 calendar](https://www.szgmc.gov.ae/en/worshippers/ramadan-kareem), which lists five prayers. The original fixture records the sources available at that time. The follow-up below adds dated UAE rows and a separate comparison against the federal authority.

## UAE follow-up on 2026-11-23

[Comparison data](reference/uae-2026-11-comparison.json) records five November dates for each city, in local time, from the official-calendar mode of [Salat Calendar for Dubai](https://www.salatcalendar.com/index.php/offical/city/69) and [Salat Calendar for Abu Dhabi](https://www.salatcalendar.com/index.php/offical/city/36). The [International Astronomical Center](https://astronomycenter.net/?l=ar) runs Salat Calendar with sponsorship from Dubai IACAD. The publisher describes this mode as near-matching the official timetables. Select the monthly view to reproduce the sample.

| City | Largest absolute difference across five dates | Standard Asr |
|---|---:|---|
| Dubai | 2 minutes | App 2 minutes later on each sampled date |
| Abu Dhabi | 3 minutes | App 2–3 minutes later on the sampled dates |

The [UAE Awqaf prayer service](https://www.awqaf.gov.ae/prayer-times) published dated rows for Al Rashidiya (Dubai) and Al Mushrif (Abu Dhabi) on November 23. Against Al Rashidiya, the app's sunrise was one minute later and Asr two minutes later. Against Al Mushrif, sunrise and Dhuhr were one minute later and Asr three minutes later. The app uses city-centre coordinates, and the authority service uses the selected districts. The calculated UAE profile in the preview remains subject to broader seasonal and regional verification before release.
