"""Prepare the Hostinger admin folder without committing a setup code."""

from argparse import ArgumentParser
import hashlib
import json
from pathlib import Path
import re
import secrets
import shutil


ROOT = Path(__file__).resolve().parents[1]


def seed() -> dict:
    mobile = ROOT / "apps/mobile"
    adhkar = json.loads((mobile / "assets/adhkar/catalog.json").read_text(encoding="utf-8"))
    dua_code = (mobile / "lib/features/adhkar/data/quran_dua_index.dart").read_text(encoding="utf-8")
    duas = {
        topic: [[int(n) for n in match] for match in re.findall(
            r"\(surah: (\d+), first: (\d+), last: (\d+)\)", body
        )]
        for topic, body in re.findall(r"DuaTopic\.(\w+): \[(.*?)\]", dua_code, re.S)
    }
    meta = (mobile / "assets/quran/metadata.xml").read_text(encoding="utf-8")
    counts = [int(n) for n in re.findall(r'<sura index="\d+" ayas="(\d+)"', meta)]
    if len(duas) != 8 or any(not ranges for ranges in duas.values()) or len(counts) != 114:
        raise ValueError("The bundled library sources do not match the admin seed schema")
    return {"library": {"version": 1, "adhkar": adhkar, "duas": duas}, "ayahCounts": counts}


def main() -> None:
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    parser.add_argument("private_code", type=Path)
    args = parser.parse_args()
    args.destination.mkdir(parents=True, exist_ok=False)
    for filename in ("index.php", "content.php", "storage.php", "stories.php", "dashboard.css"):
        shutil.copyfile(ROOT / "hosting/admin" / filename, args.destination / filename)

    data = json.dumps(seed(), ensure_ascii=False, separators=(",", ":"))
    (args.destination / "seed.php").write_text(
        "<?php\nreturn json_decode(<<<'MADAR_SEED'\n" + data
        + "\nMADAR_SEED, true, 64, JSON_THROW_ON_ERROR);\n", encoding="utf-8"
    )
    code = secrets.token_urlsafe(32)
    digest = hashlib.sha256(code.encode()).hexdigest()
    (args.destination / "setup-config.php").write_text(
        "<?php\nreturn '" + digest + "';\n", encoding="utf-8"
    )
    args.private_code.parent.mkdir(parents=True, exist_ok=True)
    with args.private_code.open("x", encoding="utf-8") as handle:
        handle.write(code + "\n")


if __name__ == "__main__":
    main()
