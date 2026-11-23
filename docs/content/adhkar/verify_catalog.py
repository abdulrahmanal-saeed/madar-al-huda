#!/usr/bin/env python3
"""Check the adhkar content handoff and, optionally, its publisher references."""

import argparse
import csv
import hashlib
import io
import json
import re
import sqlite3
import unicodedata
from pathlib import Path
from urllib.request import Request, urlopen
from zipfile import ZipFile


def read_url(url):
    request = Request(url, headers={"User-Agent": "Madar Al-Huda source verification"})
    with urlopen(request, timeout=30) as response:
        return response.read()


def plain_arabic(text):
    # For matching the two draft extracts only. Source text stays untouched.
    return " ".join(
        "".join(
            char for char in text if unicodedata.category(char) not in ("Mn", "Cf")
        ).split()
    )


def translated_text(value):
    assert set(value) == {"ar", "en"} and all(value.values()), value


def verify_source_editions(catalog, hadith_ids, chapter_ids, verse_ids):
    provider = catalog["sources"]["hadeethEnc"]
    exceptions = {int(key) for key in provider["exceptions"]}
    for locale, release in provider["releases"].items():
        raw = read_url(release["url"])
        rows = csv.reader(io.StringIO(raw.decode("utf-8-sig"), newline=""))
        notice = next(rows)[0]
        assert f"(v{release['version']})" in notice, f"Review new {locale} edition"
        fields = next(rows)
        records = {row[0]: dict(zip(fields, row)) for row in rows if row}
        required = hadith_ids - exceptions if locale == "en" else hadith_ids
        for hadith in required:
            row = records[str(hadith)]
            assert all(row[field].strip() for field in ("hadith_text", "grade", "takhrij")), hadith
        if locale == "ar":
            for entry in catalog["daily"]["entries"]:
                if "wording" in entry:
                    source = records[str(entry["hadith"])]["hadith_text"]
                    assert plain_arabic(entry["wording"]["ar"]) in plain_arabic(source), entry["id"]
        print(f"HadeethEnc {locale} {release['version']}: {len(required)} records.")

    for locale, url in catalog["hisn"]["indexUrls"].items():
        page = read_url(url).decode("utf-8")
        links = {
            int(number)
            for number in re.findall(rf'href=["\'](?:https://hisnmuslim\.com)?/i/{locale}/(\d+)["\']', page)
        }
        assert links == chapter_ids | {catalog["hisn"]["duplicatedChapter"]["id"]}, locale
        print(f"Hisn {locale}: {len(chapter_ids)} chapter links and the indexed alias.")

    spec = catalog["quranDuas"]
    translation = next(
        entry
        for entry in json.loads(
            read_url("https://quranenc.com/api/v1/translations/list/en")
        )["translations"]
        if entry["key"] == spec["englishTranslationKey"]
    )
    assert translation["version"] == spec["englishTranslationVersion"], "Review new QuranEnc edition"
    with ZipFile(io.BytesIO(read_url(translation["database_url"]))) as archive:
        with sqlite3.connect(":memory:") as db:
            db.deserialize(archive.read(f"{spec['englishTranslationKey']}.sqlite"))
            translated_verses = {
                (surah, ayah)
                for surah, ayah in db.execute(
                    "SELECT sura, aya FROM translations WHERE length(trim(translation)) > 0"
                )
            }
            assert verse_ids <= translated_verses, sorted(verse_ids - translated_verses)
    print(f"QuranEnc {translation['version']}: {len(verse_ids)} distinct verses have meanings.")


def main():
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument("--sources", action="store_true", help="check current publisher editions")
    here = Path(__file__).resolve().parent
    root = here.parents[2]
    catalog = json.loads((here / "catalog.json").read_text(encoding="utf-8"))
    assert catalog["schemaVersion"] == 1 and catalog["status"] == "editorial_draft"
    for title in catalog["sections"].values():
        translated_text(title)
    for title in catalog["routine"]["completionLabels"].values():
        translated_text(title)

    groups = catalog["daily"]["groups"]
    group_ids = [group["id"] for group in groups]
    assert len(group_ids) == len(set(group_ids)) == 5
    assert group_ids == catalog["routine"]["eligibleGroups"]
    entries = {entry["id"]: entry for entry in catalog["daily"]["entries"]}
    assert len(entries) == len(catalog["daily"]["entries"])
    assert set(entries) == {item for group in groups for item in group["entries"]}

    source_rows = [*entries.values(), *catalog["merits"]]
    hadith_ids = {
        item["hadith"] for row in source_rows for item in row.get("variants", [row])
    }
    for group in groups:
        assert len(group["entries"]) == len(set(group["entries"])), group["id"]
    for row in source_rows:
        for item in row.get("variants", [row]):
            assert all(type(step["count"]) is int and step["count"] > 0 for step in item.get("repeat", [])), row["id"]
    topics = catalog["hisn"]["topics"]
    chapters = [chapter for topic in topics for chapter in topic["chapterIds"]]
    alias = catalog["hisn"]["duplicatedChapter"]
    assert len(chapters) == len(set(chapters))
    assert set(chapters) == set(range(133)) - {alias["id"]}
    assert alias["canonicalId"] in chapters
    for topic in topics:
        hadith_ids.update(topic.get("hadiths", []))

    spec = catalog["quranDuas"]
    index = (root / spec["appIndex"]).read_text(encoding="utf-8")
    index_topics = set(re.findall(r"DuaTopic\.(\w+):", index))
    assert index_topics == {topic["id"] for topic in spec["topics"]}
    for item in [*groups, *source_rows, *topics, *spec["topics"]]:
        translated_text(item["title"])
    ranges = [
        tuple(map(int, numbers))
        for numbers in re.findall(r"surah: (\d+), first: (\d+), last: (\d+)", index)
    ]
    assert len(ranges) == spec["cardCount"]
    dua_verses = {(surah, ayah) for surah, first, last in ranges for ayah in range(first, last + 1)}
    assert len(dua_verses) == spec["verseCount"]
    all_verses = dua_verses | {
        (surah, ayah)
        for row in source_rows
        for surah, first, last in row.get("quran", [])
        for ayah in range(first, last + 1)
    }
    mushaf = root / "apps/mobile/assets/quran/uthmani.txt"
    raw = mushaf.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == "6933e133dd56db778c801bf738848454e43648105a151e8d84d86a7cae39ec5f"
    verses = {
        (int(fields[0]), int(fields[1]))
        for line in raw.decode("utf-8").splitlines()
        if (fields := line.split("|", 2))[0].isdigit()
    }
    assert all_verses <= verses
    print(f"{len(groups)} daily groups, {len(entries)} distinct daily entries, "
          f"{len(hadith_ids)} hadith references, {len(chapters)} Hisn links, "
          f"{len(catalog['merits'])} merits and {len(ranges)} Quranic supplications verified.")
    if args.parse_args().sources:
        verify_source_editions(catalog, hadith_ids, set(chapters), all_verses)


if __name__ == "__main__":
    main()
