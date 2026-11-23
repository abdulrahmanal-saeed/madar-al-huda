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
  Future<void> _writes = Future.value();

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
    return _save(
      (plan) => (pagesPerSession: pagesPerSession, pagesRead: plan.pagesRead),
    );
  }

  Future<void> completeSession() => _save(
    (plan) => (
      pagesPerSession: plan.pagesPerSession,
      pagesRead: plan.endPage(totalPages),
    ),
  );

  Future<void> completePage(int oneBasedPage) => _save(
    (plan) => oneBasedPage == plan.pagesRead + 1
        ? (pagesPerSession: plan.pagesPerSession, pagesRead: oneBasedPage)
        : plan,
  );

  Future<void> startAgain() =>
      _save((plan) => (pagesPerSession: plan.pagesPerSession, pagesRead: 0));

  Future<void> _save(DailyReadingPlan Function(DailyReadingPlan) update) {
    final operation = _writes.then((_) async {
      final plan = update(state);
      if (plan == state) return;
      await ref
          .read(keyValueStoreProvider)
          .setString(
            key,
            '${MushafEdition.id}|${plan.pagesPerSession}|${plan.pagesRead}',
          );
      state = plan;
    });
    _writes = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
