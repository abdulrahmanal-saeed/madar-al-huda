import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/quran/data/tajweed_palette.dart';

void main() {
  test('the dark font selects the official colors and keeps the font sum', () {
    final original = ByteData(96)
      ..setUint16(4, 2)
      ..setUint32(12, 0x4350414c)
      ..setUint32(16, 0x0003001a)
      ..setUint32(20, 44)
      ..setUint32(24, 32)
      ..setUint32(28, 0x68656164)
      ..setUint32(36, 76)
      ..setUint32(40, 20)
      ..setUint16(46, 2)
      ..setUint16(48, 2)
      ..setUint16(50, 4)
      ..setUint32(52, 16)
      ..setUint16(58, 2)
      ..setUint32(60, 0x000000ff)
      ..setUint32(64, 0x32c2feff)
      ..setUint32(68, 0xffffffff)
      ..setUint32(72, 0xdefffeff)
      ..setUint32(84, 0xabcdef00);
    final dark = qcfDarkPalette(original.buffer.asUint8List());
    expect(original.getUint16(56), 0);
    expect(dark.getUint16(56), 2);
    expect(dark.getUint16(58), 2);
    expect(dark.getUint32(16), original.getUint32(16) + (2 << 16));
    expect(dark.getUint32(84), original.getUint32(84) - (4 << 16));
    expect(dark.getUint32(68), original.getUint32(68));
  });
}
