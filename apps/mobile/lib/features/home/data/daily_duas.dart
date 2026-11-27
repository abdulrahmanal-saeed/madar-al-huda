import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/devotional_recording.dart';
import '../../../core/content/managed_library.dart';

typedef DailyDua = ({
  String id,
  String ar,
  String en,
  String sourceAr,
  String sourceEn,
});

const bundledDailyDuas = <DailyDua>[
  (
    id: 'good-world-hereafter',
    ar: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    en: 'Our Lord, grant us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
    sourceAr: 'البقرة: ٢٠١',
    sourceEn: 'Quran 2:201',
  ),
  (
    id: 'repentance',
    ar: 'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
    en: 'Our Lord, we have wronged ourselves. If You do not forgive us and have mercy on us, we will surely be among the losers.',
    sourceAr: 'الأعراف: ٢٣',
    sourceEn: 'Quran 7:23',
  ),
  (
    id: 'steadfastness',
    ar: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ',
    en: 'Our Lord, do not let our hearts stray after You have guided us, and grant us mercy from Yourself. You are the Bestower.',
    sourceAr: 'آل عمران: ٨',
    sourceEn: 'Quran 3:8',
  ),
  (
    id: 'parents',
    ar: 'رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    en: 'My Lord, have mercy on them both as they raised me when I was small.',
    sourceAr: 'الإسراء: ٢٤',
    sourceEn: 'Quran 17:24',
  ),
  (
    id: 'knowledge',
    ar: 'رَبِّ زِدْنِي عِلْمًا',
    en: 'My Lord, increase me in knowledge.',
    sourceAr: 'طه: ١١٤',
    sourceEn: 'Quran 20:114',
  ),
  (
    id: 'ease',
    ar: 'رَبِّ اشْرَحْ لِي صَدْرِي ۝ وَيَسِّرْ لِي أَمْرِي ۝ وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي ۝ يَفْقَهُوا قَوْلِي',
    en: 'My Lord, expand my breast, ease my task for me, and loosen a knot from my tongue so that they may understand my speech.',
    sourceAr: 'طه: ٢٥–٢٨',
    sourceEn: 'Quran 20:25–28',
  ),
  (
    id: 'provision',
    ar: 'رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
    en: 'My Lord, I am in need of whatever good You send down to me.',
    sourceAr: 'القصص: ٢٤',
    sourceEn: 'Quran 28:24',
  ),
  (
    id: 'acceptance',
    ar: 'رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ',
    en: 'Our Lord, accept this from us. You are the All-Hearing, the All-Knowing.',
    sourceAr: 'البقرة: ١٢٧',
    sourceEn: 'Quran 2:127',
  ),
  (
    id: 'family',
    ar: 'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
    en: 'Our Lord, grant us joy in our spouses and offspring, and make us an example for those mindful of You.',
    sourceAr: 'الفرقان: ٧٤',
    sourceEn: 'Quran 25:74',
  ),
  (
    id: 'mercy',
    ar: 'رَبِّ اغْفِرْ وَارْحَمْ وَأَنْتَ خَيْرُ الرَّاحِمِينَ',
    en: 'My Lord, forgive and have mercy; You are the best of those who show mercy.',
    sourceAr: 'المؤمنون: ١١٨',
    sourceEn: 'Quran 23:118',
  ),
  (
    id: 'guidance-piety',
    ar: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
    en: 'O Allah, I ask You for guidance, piety, chastity, and sufficiency.',
    sourceAr: 'صحيح مسلم: ٢٧٢١',
    sourceEn: 'Sahih Muslim 2721',
  ),
  (
    id: 'wellbeing',
    ar: 'اللَّهُمَّ اغْفِرْ لِي وَارْحَمْنِي وَاهْدِنِي وَعَافِنِي وَارْزُقْنِي',
    en: 'O Allah, forgive me, have mercy on me, guide me, grant me well-being, and provide for me.',
    sourceAr: 'صحيح مسلم: ٢٦٩٧',
    sourceEn: 'Sahih Muslim 2697b',
  ),
];

/// An absent, empty, or malformed feed uses the curated offline list.
List<DailyDua> decodeDailyDuas(Object? raw) {
  if (raw is! List || raw.isEmpty) return bundledDailyDuas;
  final result = <DailyDua>[];
  final ids = <String>{};
  final texts = <String>{};
  try {
    for (final row in raw) {
      final data = row as Map<String, Object?>;
      final wording = data['wording'] as Map<String, Object?>;
      final source = data['source'] as Map<String, Object?>;
      final dua = (
        id: (data['id'] as String).trim(),
        ar: (wording['ar'] as String).trim(),
        en: (wording['en'] as String).trim(),
        sourceAr: (source['ar'] as String).trim(),
        sourceEn: (source['en'] as String).trim(),
      );
      if (dua.id.isEmpty ||
          dua.ar.isEmpty ||
          dua.en.isEmpty ||
          dua.sourceAr.isEmpty ||
          dua.sourceEn.isEmpty ||
          !ids.add(dua.id) ||
          !texts.add(dua.ar)) {
        return bundledDailyDuas;
      }
      result.add(dua);
    }
  } on Object {
    return bundledDailyDuas;
  }
  return List.unmodifiable(result);
}

final dailyDuasProvider = FutureProvider.autoDispose<List<DailyDua>>((
  ref,
) async {
  final feed = await ref.watch(managedLibraryProvider.future);
  return decodeDailyDuas(feed?['dailyDuas']);
});

DailyDua dailyDuaForCivilDay(DateTime day, List<DailyDua> entries) {
  final list = entries.isEmpty ? bundledDailyDuas : entries;
  final offset = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(2026, 1, 1)).inDays;
  return list[offset % list.length];
}

/// Audio metadata is additive, so text-only feeds and bundled entries work.
final dailyDuaRecordingsProvider = Provider<Map<String, DevotionalRecording>>((
  ref,
) {
  final feed = ref.watch(managedLibraryProvider).asData?.value;
  final entries = feed?['dailyDuas'];
  return {
    if (entries is List)
      for (final row in entries)
        if (row is Map && row['id'] is String)
          row['id'] as String: ?devotionalRecording(row['recording']),
  };
});
