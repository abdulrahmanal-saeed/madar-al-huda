# P01-08 — Offline Qibla geometry foundation

Status: **IN_PROGRESS — calculation code and automated tests, not a published compass**.
Issue: [#23](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/23).

This task reuses the Flutter shell, existing Qibla route `/worship/qibla`, current identity and content gate. It does **not** rebuild the Qibla UI or request location/sensor permission.

## What is implemented

- Pure Dart `QiblaBearing.calculate(GeoCoordinate)`: initial spherical **great-circle** bearing clockwise from **geographic/true north**, normalized to [0,360).
- Approximate Kaaba coordinates: **21.4225° N, 39.8262° E**. Reference: [Kaaba coordinates](https://en.wikipedia.org/wiki/Kaaba).
- Four city-**centre** manual presets: Dubai, Abu Dhabi, Cairo, Alexandria, using the existing P00-10 stable city IDs and IANA time zones. The centre is not the person's exact position: accuracy can vary between city centre and the actual neighbourhood.
- Input validation for invalid or non-finite latitude/longitude, and explicit failure for origin at the Kaaba, antipodal point and geographic poles where true-north bearing is not unique.
- No network, GPS permission, background tracking, external SDK, magnetic heading or persistent history.

The [Egyptian General Survey Authority](https://www.esa.gov.eg/qebla.aspx) states that direction follows the **great-circle arc** and is measured relative to geographic north. Independent approximate spot checks: [London 119.0° and reference algorithm](https://qibladaily.com/qibla/how-it-is-calculated) and [New York ~58°](https://quranshield.app/tools/qibla-direction).

## Manual city centres (approximate values, geometry only)

| Preset | Bearing clockwise from TRUE north |
|---|---:|
| Dubai | 258.2° |
| Abu Dhabi | 260.2° |
| Cairo | 136.1° |
| Alexandria | 135.4° |

A bearing is **not** a compass needle direction while the device rotates. A sensor-referenced UI must obtain the device heading and handle magnetic declination, device calibration, metal interference and absent/unreliable sensors. Without that, show a numeric heading with clear true-north context; do not present it as a validated live compass.

## Remaining before P01-08 DONE

1. Manual city selection UI and optionally precise location opt-in (with explicit permission/reason and manual fallback).
2. Compass sensor adapter or clearly marked **no-sensor** mode; accurate true/magnetic north handling and calibration instructions, device-specific accuracy tests.
3. Arabic and English widget tests and real device tests including absent sensor, airplane mode and accessibility.
4. Update the existing `AppSection.qibla` publication gate only in a reviewed PR with full acceptance evidence. The Qibla screen currently remains a transparent development placeholder.

No UI, logo, Quran text or prayer times changed in this contribution.
