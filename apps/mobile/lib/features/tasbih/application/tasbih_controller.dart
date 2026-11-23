import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';

/// Common phrases of remembrance; `null` counts without a phrase.
const tasbihPhrases = <({String ar, String en})?>[
  (ar: 'سُبْحَانَ اللَّهِ', en: 'Subhan Allah'),
  (ar: 'الْحَمْدُ لِلَّهِ', en: 'Alhamdulillah'),
  (ar: 'اللَّهُ أَكْبَرُ', en: 'Allahu akbar'),
  (ar: 'لَا إِلَٰهَ إِلَّا اللَّهُ', en: 'La ilaha illa Allah'),
  (ar: 'أَسْتَغْفِرُ اللَّهَ', en: 'Astaghfirullah'),
  (ar: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ', en: 'Allahumma salli ala Muhammad'),
  null,
];

/// Targets offered; 0 counts without a target.
const tasbihGoals = [33, 99, 100, 0];

class TasbihState {
  const TasbihState({
    this.phrase = 0,
    this.goal = 33,
    this.count = 0,
    this.day = '',
    this.today = 0,
    this.total = 0,
  });

  /// Index into [tasbihPhrases].
  final int phrase;

  /// One of [tasbihGoals].
  final int goal;

  /// The current round.
  final int count;

  /// Local day (yyyy-mm-dd) that [today] belongs to.
  final String day;
  final int today;
  final int total;

  bool get reachedGoal => goal > 0 && count >= goal;

  TasbihState copyWith({
    int? phrase,
    int? goal,
    int? count,
    String? day,
    int? today,
    int? total,
  }) => TasbihState(
    phrase: phrase ?? this.phrase,
    goal: goal ?? this.goal,
    count: count ?? this.count,
    day: day ?? this.day,
    today: today ?? this.today,
    total: total ?? this.total,
  );
}

String tasbihDay(DateTime now) =>
    '${now.year}-${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}';

final tasbihProvider = NotifierProvider<TasbihController, TasbihState>(
  TasbihController.new,
);

/// The counter, kept on the device so a round survives closing the app.
class TasbihController extends Notifier<TasbihState> {
  static const key = 'tasbih.v1';
  DateTime Function() clock = DateTime.now;
  Future<void> _save = Future.value();

  @override
  TasbihState build() {
    final raw = ref.watch(keyValueStoreProvider).getString(key);
    try {
      final data = jsonDecode(raw ?? '{}') as Map<String, Object?>;
      int read(String name, int fallback, [bool Function(int)? valid]) {
        final value = data[name];
        return value is int && value >= 0 && (valid?.call(value) ?? true)
            ? value
            : fallback;
      }

      final day = data['day'] is String ? data['day']! as String : '';
      final current = tasbihDay(clock());
      return TasbihState(
        phrase: read('phrase', 0, (v) => v < tasbihPhrases.length),
        goal: read('goal', 33, tasbihGoals.contains),
        count: read('count', 0),
        day: current,
        // A new day starts today's tally from zero.
        today: day == current ? read('today', 0) : 0,
        total: read('total', 0),
      );
    } on Object {
      return TasbihState(day: tasbihDay(clock()));
    }
  }

  /// Counts one; returns true when this tap completes the goal.
  bool increment() {
    final current = tasbihDay(clock());
    final sameDay = state.day == current;
    final next = state.copyWith(
      count: state.count + 1,
      day: current,
      today: (sameDay ? state.today : 0) + 1,
      total: state.total + 1,
    );
    _set(next);
    return next.goal > 0 && next.count == next.goal;
  }

  void reset() => _set(state.copyWith(count: 0));

  void choosePhrase(int index) => _set(state.copyWith(phrase: index, count: 0));

  void chooseGoal(int goal) => _set(state.copyWith(goal: goal));

  void _set(TasbihState next) {
    state = next;
    final store = ref.read(keyValueStoreProvider);
    _save = _save
        .then(
          (_) => store.setString(
            key,
            jsonEncode({
              'phrase': next.phrase,
              'goal': next.goal,
              'count': next.count,
              'day': next.day,
              'today': next.today,
              'total': next.total,
            }),
          ),
        )
        .then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }
}
