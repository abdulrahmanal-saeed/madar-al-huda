"""Builds apps/mobile/assets/location/cities.json from GeoNames cities15000.

Usage: python -I build_cities.py <geonames dir> <output json>

Every place of 15,000+ people (and every capital), so users find their own
town anywhere in the world. Each row:
[id, name, asciiName|"", arabicName|"", country, lat, lng, zoneIndex, population/1000].
Data: GeoNames (https://www.geonames.org), CC BY 4.0. Arabic country names
come from Unicode CLDR via Babel.
"""
import json
import re
import sys

from babel import Locale

sys.stdout.reconfigure(encoding="utf-8")
source, output = sys.argv[1], sys.argv[2]
ARABIC = re.compile(r"^[ء-غف-يً-ْٰٱ \-ـ']+$")
PERSIAN = re.compile(r"[کگیپچژڈٹںےۀ]")
TASHKEEL = re.compile(r"[ً-ْٰ]")
PREFIXES = ("إمارة ", "مدينة ", "محافظة ", "ولاية ", "بلدية ")
OVERRIDES = {
    104515: "مكة المكرمة",
    109223: "المدينة المنورة",
    745044: "إسطنبول",
    292223: "دبي",
}


def score(name: str) -> int:
    value = 0
    if name.startswith(PREFIXES):
        value -= 5
    if TASHKEEL.search(name):
        value -= 3
    if "ى" in name[:-1]:
        value -= 3
    if name.endswith(("ى", "ه")):
        value -= 2
    if name.count("أ") > 1:
        value -= 3
    return value


def arabic_name(alternates: str) -> str:
    candidates = []
    for alternate in alternates.split(","):
        candidate = alternate.strip()
        if candidate and ARABIC.match(candidate) and not PERSIAN.search(candidate):
            candidates.append(candidate)
    if not candidates:
        return ""
    return max(enumerate(candidates), key=lambda item: (score(item[1]), -item[0]))[1]


zones = []
zone_index = {}
rows = []
with open(f"{source}/cities15000.txt", encoding="utf-8") as handle:
    for line in handle:
        cols = line.rstrip("\n").split("\t")
        geo_id, name, ascii_name, alternates = int(cols[0]), cols[1], cols[2], cols[3]
        lat, lng, country = float(cols[4]), float(cols[5]), cols[8]
        population = int(cols[14] or 0)
        zone = cols[17]
        if not zone:
            continue
        arabic = OVERRIDES.get(geo_id) or arabic_name(alternates)
        if zone not in zone_index:
            zone_index[zone] = len(zones)
            zones.append(zone)
        rows.append((population, [geo_id, name, "" if ascii_name == name else ascii_name,
                                  arabic, country, round(lat, 4), round(lng, 4),
                                  zone_index[zone], round(population / 1000)]))

rows.sort(key=lambda row: -row[0])
english = Locale("en").territories
arabic = Locale("ar").territories
codes = sorted({row[4] for _, row in rows})
SHORT = {"AE": ["UAE", "الإمارات"], "US": ["United States", "الولايات المتحدة"]}
countries = {code: SHORT.get(code) or [english.get(code, code), arabic.get(code, english.get(code, code))] for code in codes}
data = {
    "source": "GeoNames (geonames.org), CC BY 4.0; country names: Unicode CLDR",
    "zones": zones,
    "countries": countries,
    "cities": [row for _, row in rows],
}
with open(output, "w", encoding="utf-8") as handle:
    json.dump(data, handle, ensure_ascii=False, separators=(",", ":"))
with_arabic = sum(1 for _, row in rows if row[3])
print(len(rows), "cities,", with_arabic, "with Arabic names,", len(zones), "zones,",
      len(countries), "countries")
for geo_id in OVERRIDES:
    print(geo_id, [row for _, row in rows if row[0] == geo_id][:1])
print(countries.get("EG"), countries.get("AE"), countries.get("GB"))
