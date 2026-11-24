/// Zakat on money, gold, silver and trade goods: a simple estimate, not a
/// ruling. Amounts are in the user's own currency.
enum NisabBasis { gold, silver }

/// The commonly used nisab weights, in grams of pure metal.
const goldNisabGrams = 85.0;
const silverNisabGrams = 595.0;
const zakatRate = 0.025;

class ZakatInput {
  const ZakatInput({
    this.cash = 0,
    this.gold24 = 0,
    this.gold21 = 0,
    this.gold18 = 0,
    this.silver = 0,
    this.tradeGoods = 0,
    this.owedToYou = 0,
    this.debts = 0,
    this.goldPrice = 0,
    this.silverPrice = 0,
    this.basis = NisabBasis.gold,
  });

  final double cash;

  /// Grams of gold by karat.
  final double gold24;
  final double gold21;
  final double gold18;

  /// Grams of silver.
  final double silver;
  final double tradeGoods;

  /// Debts others owe you that you expect to receive.
  final double owedToYou;

  /// What you owe and must pay now.
  final double debts;

  /// Price of one gram of 24-karat gold and of pure silver.
  final double goldPrice;
  final double silverPrice;
  final NisabBasis basis;

  double get pureGoldGrams => gold24 + gold21 * 21 / 24 + gold18 * 18 / 24;
}

class ZakatResult {
  const ZakatResult({
    required this.wealth,
    required this.nisab,
    required this.due,
  });

  /// Zakatable wealth after debts.
  final double wealth;

  /// The nisab in currency, or null without the metal price.
  final double? nisab;
  final double due;

  bool get reachesNisab => nisab != null && wealth >= nisab!;
}

ZakatResult calculateZakat(ZakatInput input) {
  final wealth =
      input.cash +
      input.pureGoldGrams * input.goldPrice +
      input.silver * input.silverPrice +
      input.tradeGoods +
      input.owedToYou -
      input.debts;
  final price = input.basis == NisabBasis.gold
      ? input.goldPrice
      : input.silverPrice;
  final grams = input.basis == NisabBasis.gold
      ? goldNisabGrams
      : silverNisabGrams;
  final nisab = price > 0 ? price * grams : null;
  final positive = wealth > 0 ? wealth : 0.0;
  return ZakatResult(
    wealth: positive,
    nisab: nisab,
    due: nisab != null && positive >= nisab ? positive * zakatRate : 0,
  );
}
