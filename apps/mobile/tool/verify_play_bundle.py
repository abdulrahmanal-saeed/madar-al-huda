"""Fail closed on Play package, version, advertising permission and ELF alignment."""
import struct
import sys
import xml.etree.ElementTree as ET
import zipfile

bundle, manifest, version = sys.argv[1:]
root = ET.parse(manifest).getroot()
ns = "{http://schemas.android.com/apk/res/android}"
assert root.get("package") == "com.abdulrahmanalsaeed.madaralhuda", "wrong package"
assert root.get(ns + "versionCode") == version, "wrong version code"
assert int(root.find("uses-sdk").get(ns + "targetSdkVersion")) >= 36, "target SDK too low"
for element in root:
    if element.tag.startswith("uses-permission"):
        assert element.get(ns + "name") != "com.google.android.gms.permission.AD_ID", "advertising ID permission"
with zipfile.ZipFile(bundle) as archive:
    libraries = [n for n in archive.namelist() if n.endswith(".so") and "/lib/" in n]
    assert libraries, "native libraries missing"
    for name in libraries:
        if not any(abi in name.split("/") for abi in ("arm64-v8a", "x86_64")):
            continue
        elf = archive.read(name)
        assert elf[:4] == b"\x7fELF" and elf[4] == 2, name
        endian = "<" if elf[5] == 1 else ">"
        offset = struct.unpack_from(endian + "Q", elf, 32)[0]
        size, count = struct.unpack_from(endian + "HH", elf, 54)
        loads = 0
        for index in range(count):
            pos = offset + size * index
            if struct.unpack_from(endian + "I", elf, pos)[0] == 1:
                loads += 1
                alignment = struct.unpack_from(endian + "Q", elf, pos + 48)[0]
                assert alignment >= 16384, f"{name}: PT_LOAD alignment {alignment}"
        assert loads, f"{name}: no load segments"
print("Verified package, target SDK, version, AD_ID absence and 64-bit native ELF alignment.")
