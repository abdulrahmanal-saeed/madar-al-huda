#!/usr/bin/env python3
"""Zero-dependency brand CI check. Run from project root."""
from pathlib import Path
import json, re, struct, subprocess, sys, zlib, xml.etree.ElementTree as ET
root = Path(__file__).resolve().parents[2]
d = root / 'design/brand'
subprocess.run([sys.executable, str(d / 'generate_palette.py'), '--check'], check=True)
res = root / 'apps/mobile/android/app/src/main/res'
colors = (root / 'apps/mobile/lib/core/theme/brand_colors.dart').read_text(encoding='utf-8')
values = json.loads((d / 'tokens.json').read_text(encoding='utf-8'))['colors']
for key in ('primaryGreen', 'mutedGold', 'ivory', 'darkInk'):
    assert re.search(r'\b'+key+r'\s*=\s*Color\('+values[key].replace('#','0xFF')+r'\)', colors), key
for path in ('icon-master.svg','icon-monochrome.svg','wordmark-ar.svg','wordmark-en.svg'):
    e = ET.parse(d / path).getroot()
    assert e.tag.endswith('svg') and e.attrib.get('viewBox'), path
for name in ('ic_launcher_foreground.xml','ic_launcher_monochrome.xml'):
    ET.parse(res / 'drawable' / name)
ET.parse(res / 'mipmap-anydpi-v26/ic_launcher.xml')
license_text=(root/'apps/mobile/assets/fonts/ibm_plex_sans_arabic/OFL.txt').read_text(encoding='utf-8').upper()
assert 'SIL OPEN FONT LICENSE' in license_text
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    data=(res / ('mipmap-'+density) / 'ic_launcher.png').read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    assert struct.unpack('>II',data[16:24]) == (size,size)
    # Validate every chunk CRC and the actual decoded pixel stream.
    pos = 8
    idat = bytearray()
    seen_ihdr = False
    while pos < len(data):
        length = struct.unpack('>I',data[pos:pos+4])[0]
        typ = data[pos+4:pos+8]
        payload = data[pos+8:pos+8+length]
        checksum = struct.unpack('>I',data[pos+8+length:pos+12+length])[0]
        assert checksum == zlib.crc32(typ+payload) & 0xffffffff, (density,typ)
        if typ == b'IHDR':
            assert length == 13, p
            assert payload[8:13] == b'\x08\x02\x00\x00\x00', p
            seen_ihdr = True
        if typ == b'IDAT':
            idat.extend(payload)
        pos += 12+length
        if typ == b'IEND':
            break
    assert seen_ihdr and pos == len(data), p
    pixels = zlib.decompress(bytes(idat))
    assert len(pixels) == size*(1+3*size), p
    assert all(pixels[row*(1+3*size)] == 0 for row in range(size)), p
print('Brand palette, vectors, font license, PNG CRC/decompression and densities verified.')
