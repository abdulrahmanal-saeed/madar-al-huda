import 'dart:typed_data';

/// Uses the published QCF V4 dark palette as the default in a copy of the font.
/// Flutter's font loader does not expose OpenType palette selection.
ByteData qcfDarkPalette(Uint8List lightFont) {
  final darkFont = Uint8List.fromList(lightFont);
  final data = ByteData.sublistView(darkFont);
  if (data.lengthInBytes < 12) {
    throw const FormatException('Incomplete Tajweed font');
  }

  const cpalTag = 0x4350414c;
  const headTag = 0x68656164;
  final tableCount = data.getUint16(4);
  int? paletteEntry;
  int? adjustmentOffset;
  for (
    var entry = 12;
    entry < 12 + tableCount * 16 && entry + 16 <= data.lengthInBytes;
    entry += 16
  ) {
    final offset = data.getUint32(entry + 8);
    final length = data.getUint32(entry + 12);
    if (offset + length > data.lengthInBytes) {
      throw const FormatException('Invalid Tajweed font table');
    }
    switch (data.getUint32(entry)) {
      case cpalTag when length >= 16 && offset.isEven:
        paletteEntry = entry;
      case headTag when length >= 12:
        adjustmentOffset = offset + 8;
    }
  }
  if (paletteEntry == null || adjustmentOffset == null) {
    throw const FormatException('Tajweed palette is unavailable');
  }
  final palette = data.getUint32(paletteEntry + 8);
  final lightIndex = data.getUint16(palette + 12);
  final darkIndex = data.getUint16(palette + 14);
  final entries = data.getUint16(palette + 2);
  if (palette % 4 != 0 ||
      data.getUint16(palette + 4) < 2 ||
      entries == 0 ||
      darkIndex + entries > data.getUint16(palette + 6)) {
    throw const FormatException('Invalid Tajweed dark palette');
  }

  // The first palette index is the high half of an aligned 32-bit word.
  // The same change appears in CPAL's table checksum and in the font sum.
  final delta = (darkIndex - lightIndex) << 16;
  final checksum = paletteEntry + 4;
  data.setUint16(palette + 12, darkIndex);
  data.setUint32(checksum, (data.getUint32(checksum) + delta) & 0xffffffff);
  data.setUint32(
    adjustmentOffset,
    (data.getUint32(adjustmentOffset) - 2 * delta) & 0xffffffff,
  );
  return data;
}
