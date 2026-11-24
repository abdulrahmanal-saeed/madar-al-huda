import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import 'daily_reading_plan.dart';

String dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

DateTime _dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

/// Pages read on each day, kept on the device for the last [keepDays] days.
final readingLogProvider = NotifierProvider<ReadingLog, Map<String, int>>(
  ReadingLog.new,
);

class ReadingLog extends Notifier<Map<String, int>> {
  static const key = 'worship.readingLog.v1';
  static const keepDays = 120;
  Future<void> _writes = Future.value();

  @override
  Map<String, int> build() {
    final raw = ref.watch(keyValueStoreProvider).getString(key);
    if (raw == null) return const {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final MapEntry(:key, :value) in data.entries)
          if (value is int &&
              value > 0 &&
              RegExp(r'^\d{4}-\d\d-\d\d$').hasMatch(key))
            key: value,
      };
    } on Object {
      return const {};
    }
  }

  Future<void> record(int pages, {DateTime? now}) {
    if (pages <= 0) return Future.value();
    final today = dayKey(now ?? DateTime.now());
    final operation = _writes.then((_) async {
      final cutoff = dayKey(
        _dateOnly(now ?? DateTime.now())
            .subtract(const Duration(days: keepDays)),
      );
      final log = {
        for (final MapEntry(:key, :value) in state.entries)
          if (key.compareTo(cutoff) > 0) key: value,
      };
      log[today] = (log[today] ?? 0) + pages;
      await ref.read(keyValueStoreProvider).setString(key, jsonEncode(log));
      state = log;
    });
    _writes = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}

extension ReadingStats on Map<String, int> {
  int pagesOn(DateTime day) => this[dayKey(day)] ?? 0;

  /// Days in a row with reading, ending today, or yesterday while today's
  /// reading has not started yet.
  int streak(DateTime now) {
    var day = _dateOnly(now);
    if (pagesOn(day) == 0) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (pagesOn(day) > 0) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Pages for the last [days] days, oldest first.
  List<int> lastDays(DateTime now, int days) => [
    for (var i = days - 1; i >= 0; i--)
      pagesOn(_dateOnly(now).subtract(Duration(days: i))),
  ];
}

/// Finishing the Quran in a chosen number of days, from [start].
class KhatmaGoal {
  const KhatmaGoal({required this.days, required this.start});

  final int days;
  final DateTime start;

  DateTime get end => start.add(Duration(days: days - 1));

  int daysLeft(DateTime now) =>
      math.max(1, end.difference(_dateOnly(now)).inDays + 1);

  /// Pages for today so the khatma ends on time, counted from where today
  /// began.
  int todayTarget({
    required int pagesRead,
    required int readToday,
    required DateTime now,
  }) {
    final remaining =
        DailyReadingPlanController.totalPages - (pagesRead - readToday);
    if (remaining <= 0) return 0;
    return (remaining / daysLeft(now)).ceil();
  }
}

final khatmaGoalProvider = NotifierProvider<KhatmaGoalController, KhatmaGoal?>(
  KhatmaGoalController.new,
);

class KhatmaGoalController extends Notifier<KhatmaGoal?> {
  static const key = 'worship.khatmaGoal.v1';
  static const choices = [7, 10, 15, 30, 60];

  @override
  KhatmaGoal? build() {
    final raw = ref.watch(keyValueStoreProvider).getString(key);
    final parts = raw?.split('|');
    if (parts == null || parts.length != 2) return null;
    final days = int.tryParse(parts[0]);
    final start = DateTime.tryParse(parts[1]);
    if (days == null || days < 1 || days > 366 || start == null) return null;
    return KhatmaGoal(days: days, start: _dateOnly(start));
  }

  /// Starts a goal today and sets the daily wird to match it.
  Future<void> choose(int days, {DateTime? now}) async {
    final today = _dateOnly(now ?? DateTime.now());
    final goal = KhatmaGoal(days: days, start: today);
    final plan = ref.read(dailyReadingPlanProvider);
    final remaining = DailyReadingPlanController.totalPages - plan.pagesRead;
    await ref
        .read(keyValueStoreProvider)
        .setString(key, '$days|${dayKey(today)}');
    state = goal;
    if (remaining > 0) {
      await ref
          .read(dailyReadingPlanProvider.notifier)
          .setPace(math.max(1, (remaining / days).ceil()));
    }
  }

  Future<void> clear() async {
    await ref.read(keyValueStoreProvider).remove(key);
    state = null;
  }
}
