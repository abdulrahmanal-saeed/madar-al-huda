"""Stage the public landing page with the app's existing brand assets."""

from argparse import ArgumentParser
from hashlib import sha256
from pathlib import Path
import shutil


ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "hosting/web"
ASSETS = ROOT / "apps/mobile/assets"
BRAND_FILES = {
    "brand/logo-dark.png": "mark.png",
    "brand/book-dark.png": "mushaf.png",
    "brand/shortcuts/qa_1_book_light.png": "reading.png",
    "brand/shortcuts/qa_2_compass_light.png": "prayer.png",
    "brand/shortcuts/qa_5_sun_light.png": "remembrance.png",
    "brand/shortcuts/qa_7_story_light.png": "library.png",
    "fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Regular.ttf": "arabic-regular.ttf",
    "fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Bold.ttf": "arabic-bold.ttf",
    "fonts/ibm_plex_sans_arabic/OFL.txt": "ibm-plex-license.txt",
    "fonts/reem_kufi/ReemKufi.ttf": "kufi.ttf",
    "fonts/reem_kufi/OFL.txt": "reem-kufi-license.txt",
}


def main() -> None:
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    destination = parser.parse_args().destination
    files = destination / "madar-web"
    files.mkdir(parents=True, exist_ok=False)
    landing = (WEB / "index.html").read_text(encoding="utf-8")
    for name in ("brand.css", "landing.css"):
        css = (WEB / "madar-web" / name).read_bytes()
        (files / name).write_bytes(css)
        href = f"madar-web/{name}"
        landing = landing.replace(f'href="{href}"', f'href="{href}?v={sha256(css).hexdigest()[:12]}"')
    (destination / "index.html").write_text(landing, encoding="utf-8", newline="\n")
    for source, target in BRAND_FILES.items():
        shutil.copyfile(ASSETS / source, files / target)


if __name__ == "__main__":
    main()
