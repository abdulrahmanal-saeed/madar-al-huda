# Offline city list

`cities.json` lists every place of 15,000+ people (and every capital) from
[GeoNames](https://www.geonames.org) `cities15000`, under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Arabic country
names come from Unicode CLDR. The app uses it, on the device only, to search
cities and to name a GPS position and pick its time zone.

Format: `zones` (IANA names), `countries` (`code: [English, Arabic]`) and
`cities` rows, largest first:
`[geonameId, name, asciiName or "", arabicName or "", country, lat, lng, zoneIndex, thousandsOfPeople]`.

Regenerate with `tool/build_cities.py <geonames folder> assets/location/cities.json`
after downloading `cities15000.zip` and `countryInfo.txt` from
https://download.geonames.org/export/dump/ (needs `pip install babel`).
