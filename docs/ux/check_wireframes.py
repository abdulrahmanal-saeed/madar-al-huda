#!/usr/bin/env python3
"""Validate 7 bilingual source SVG wireframes (not a runtime screenshot test)."""
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parent / "wireframes"
screens = ("home","quran","reader","player","prayer","library","learning")
expected = {f"{s}-{l}.svg" for s in screens for l in ("ar","en")}
actual = {p.name for p in root.glob("*.svg")}
assert actual == expected, f"Missing={expected-actual}; extra={actual-expected}"
ns = "{http://www.w3.org/2000/svg}"
for filename in sorted(expected):
    source = (root / filename).read_text(encoding="utf-8")
    svg = ET.fromstring(source)
    assert svg.tag == ns+"svg" and svg.attrib["viewBox"] == "0 0 390 844"
    assert svg.attrib["lang"] == filename[-6:-4], filename
    assert svg.find(ns+"title") is not None
    assert len(list(svg.iter(ns+"text"))) >= 8, filename
    assert "<script" not in source and "<image" not in source
    assert "بِسْمِ" not in source and "00:00" not in source
print(f"Validated {len(expected)} SVG files: 7 AR/EN pairs.")
