#!/usr/bin/env python3
"""Static reference and zoneinfo checks for P00-10; NOT a prayer calculation."""
import json
import re
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

source = Path(__file__).resolve().parent / "reference/official-2026-11-22.json"
fixture = json.loads(source.read_text(encoding="utf-8"))
assert fixture["schema_version"] == 1
assert fixture["fields"] == ["fajr","sunrise","dhuhr","asr","maghrib","isha"]
cities = fixture["cities"]
by_id = {x["city_id"]: x for x in cities}
assert len(cities) == len(by_id) == 4
assert set(by_id) == {"cairo-eg","alexandria-eg","dubai-ae","abu-dhabi-ae"}
for city in cities:
    assert city["date"] == "2026-11-22"
    assert city["source_url"].startswith("https://")
    assert city["source_access_date"] == "2026-11-22"
    assert city["time_zone"] == ("Africa/Cairo" if city["country"] == "EG" else "Asia/Dubai")
    tz = ZoneInfo(city["time_zone"])
    assert tz is not None
    times = city["local_times"]
    if city["country"] == "EG":
        assert city["source_status"] == "official_transcribed"
        assert city["source_url"] == "https://www.esa.gov.eg/praytimes.aspx"
        assert set(times) == set(fixture["fields"])
        values = []
        for key in fixture["fields"]:
            time = times[key]
            assert re.fullmatch(r"(?:[01][0-9]|2[0-3]):[0-5][0-9]",time), (city["city_id"],key,time)
            hours,minutes = map(int,time.split(":"))
            values.append(hours*60+minutes)
        assert values == sorted(values) and len(set(values)) == 6
    else:
        assert city["source_status"] == "pending_official_dated_timetable"
        assert times is None, "UAE expected times MUST NOT be invented while pending official data"

def offset(tz_name,day):
    return datetime.fromisoformat(f"{day}T12:00:00").replace(tzinfo=ZoneInfo(tz_name)).utcoffset()

hours=lambda n: timedelta(hours=n)
for day in ("2026-01-15","2026-07-15","2026-11-22"):
    assert offset("Asia/Dubai",day)==hours(4), day
for day,expected in (("2026-04-23",2),("2026-04-24",3),("2026-10-29",3),("2026-10-30",2),("2026-11-22",2)):
    assert offset("Africa/Cairo",day)==hours(expected), day
print("P00-10: 2 Egyptian official-source rows validated; 2 UAE cities explicitly pending; DST/time zones verified.")
