import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../quran/domain/quran_search_text.dart';
import '../domain/zakat.dart';

/// Keeps a number's own direction inside a sentence.
String isolate(String text) => '\u2068$text\u2069';

/// Reads a typed amount in Western or Arabic digits, with either decimal
/// separator. Empty or invalid input counts as zero.
double parseAmount(String text) {
  final normalized = quranSearchText(text)
      .replaceAll('٫', '.')
      .replaceAll(RegExp(r'[,،٬\s]'), '');
  final value = double.tryParse(normalized);
  return value == null || value < 0 ? 0 : value;
}

/// A simple zakat estimate on money, gold, silver and trade goods. Nothing
/// typed here is saved.
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _fields = <String, TextEditingController>{
    for (final key in [
      'cash',
      'gold24',
      'gold21',
      'gold18',
      'silver',
      'trade',
      'owed',
      'debts',
      'goldPrice',
      'silverPrice',
    ])
      key: TextEditingController(),
  };
  NisabBasis _basis = NisabBasis.gold;

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  double _value(String key) => parseAmount(_fields[key]!.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final money = NumberFormat('#,##0.##', numberLocale(language));
    final result = calculateZakat(
      ZakatInput(
        cash: _value('cash'),
        gold24: _value('gold24'),
        gold21: _value('gold21'),
        gold18: _value('gold18'),
        silver: _value('silver'),
        tradeGoods: _value('trade'),
        owedToYou: _value('owed'),
        debts: _value('debts'),
        goldPrice: _value('goldPrice'),
        silverPrice: _value('silverPrice'),
        basis: _basis,
      ),
    );

    Widget field(String key, String label, {String? hint, IconData? icon}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: TextField(
            key: ValueKey('zakat-$key'),
            controller: _fields[key],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: label,
              helperText: hint,
              prefixIcon: icon == null ? null : Icon(icon),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        );

    Widget group(String title, List<Widget> children) => Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );

    final String verdict;
    if (result.nisab == null) {
      verdict = l10n.zakatNeedPrice;
    } else if (result.reachesNisab) {
      verdict = l10n.zakatDue;
    } else {
      verdict = l10n.zakatBelowNisab;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.zakatTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            key: const Key('zakat-result'),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            color: result.reachesNisab
                ? scheme.primary
                : scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: result.reachesNisab
                      ? scheme.onPrimary
                      : scheme.onSurface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verdict,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: result.reachesNisab ? scheme.onPrimary : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      money.format(result.due),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: result.reachesNisab ? scheme.onPrimary : null,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.zakatWealth(isolate(money.format(result.wealth))),
                    ),
                    if (result.nisab != null)
                      Text(
                        l10n.zakatNisab(isolate(money.format(result.nisab))),
                      ),
                  ],
                ),
              ),
            ),
          ),
          group(l10n.zakatPrices, [
            SegmentedButton<NisabBasis>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: NisabBasis.gold,
                  label: Text(l10n.zakatBasisGold),
                ),
                ButtonSegment(
                  value: NisabBasis.silver,
                  label: Text(l10n.zakatBasisSilver),
                ),
              ],
              selected: {_basis},
              onSelectionChanged: (value) =>
                  setState(() => _basis = value.single),
            ),
            const SizedBox(height: AppSpacing.md),
            field('goldPrice', l10n.zakatGoldPrice, icon: Icons.sell_outlined),
            field(
              'silverPrice',
              l10n.zakatSilverPrice,
              icon: Icons.sell_outlined,
            ),
          ]),
          group(l10n.zakatAssets, [
            field(
              'cash',
              l10n.zakatCash,
              hint: l10n.zakatCashHint,
              icon: Icons.payments_outlined,
            ),
            field('gold24', l10n.zakatGold('24')),
            field('gold21', l10n.zakatGold('21')),
            field('gold18', l10n.zakatGold('18')),
            field('silver', l10n.zakatSilver),
            field(
              'trade',
              l10n.zakatTrade,
              hint: l10n.zakatTradeHint,
              icon: Icons.storefront_outlined,
            ),
            field('owed', l10n.zakatOwed, icon: Icons.call_received),
          ]),
          group(l10n.zakatLiabilities, [
            field(
              'debts',
              l10n.zakatDebts,
              hint: l10n.zakatDebtsHint,
              icon: Icons.call_made,
            ),
          ]),
          Card(
            margin: EdgeInsets.zero,
            color: scheme.tertiaryContainer,
            child: ListTile(
              leading: Icon(
                Icons.info_outline,
                color: scheme.onTertiaryContainer,
              ),
              title: Text(
                l10n.zakatDisclaimer,
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
