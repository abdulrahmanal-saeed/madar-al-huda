import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../quran/data/mushaf_edition.dart';

final dailyReadingPlanProvider =
    NotifierProvider<DailyReadingPlanController, DailyReadingPlan>(
      DailyReadingPlanController.new,
    );

typedef DailyReadingPlan = ({int pagesPerSession, int pagesRead});

extension DailyReadingRange on DailyReadingPlan {
  int endPage(int totalPages) =>
      math.min(pagesRead + pagesPerSession, totalPages);

  int remainingSessions(int totalPages) =>
      (totalPages - pagesRead + pagesPerSession - 1) ~/ pagesPerSession;
}

class DailyReadingPlanController extends Notifier<DailyReadingPlan> {
  static const key = 'worship.dailyReadingPlan.v1';
  static const totalPages = 604;
  static const _initial = (pagesPerSession: 20, pagesRead: 0);
  bool _saving = false;

  @override
  DailyReadingPlan build() {
    final parts = ref.watch(keyValueStoreProvider).getString(key)?.split('|');
    if (parts == null || parts.length != 3 || parts.first != MushafEdition.id) {
      return _initial;
    }
    final pagesPerSession = int.tryParse(parts[1]);
    final pagesRead = int.tryParse(parts[2]);
    if (pagesPerSession == null ||
        pagesPerSession < 1 ||
        pagesPerSession > totalPages ||
        pagesRead == null ||
        pagesRead < 0 ||
        pagesRead > totalPages) {
      return _initial;
    }
    return (pagesPerSession: pagesPerSession, pagesRead: pagesRead);
  }

  Future<void> setPace(int pagesPerSession) {
    RangeError.checkValueInInterval(pagesPerSession, 1, totalPages);
    return _save((
      pagesPerSession: pagesPerSession,
      pagesRead: state.pagesRead,
    ));
  }

  Future<void> completeSession() {
    final plan = state;
    return _save((
      pagesPerSession: plan.pagesPerSession,
      pagesRead: plan.endPage(totalPages),
    ));
  }

  Future<void> startAgain() =>
      _save((pagesPerSession: state.pagesPerSession, pagesRead: 0));

  Future<void> _save(DailyReadingPlan plan) async {
    if (_saving || state == plan) return;
    _saving = true;
    try {
      await ref
          .read(keyValueStoreProvider)
          .setString(
            key,
            '${MushafEdition.id}|${plan.pagesPerSession}|${plan.pagesRead}',
          );
      state = plan;
    } finally {
      _saving = false;
    }
  }
}
