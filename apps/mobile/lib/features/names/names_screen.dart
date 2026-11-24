import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/content/managed_library.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/localization/search_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/widgets/orbit_motif.dart';
import '../../core/widgets/responsive_content.dart';
import '../quran/data/mushaf_edition.dart';

/// A text written on the dashboard in Arabic and, optionally, English.
typedef NameText = ({String ar, String en});

const NameText _noText = (ar: '', en: '');

/// One of the Names of Allah as written on the dashboard
/// («أسماء الله الحسنى»).
class DivineName {
  const DivineName({
    required this.id,
    required this.number,
    required this.name,
    required this.transliteration,
    required this.meaningAr,
    required this.meaningEn,
    this.vocalized = '',
    this.description = _noText,
    this.evidence = _noText,
    this.impact = _noText,
    this.dua = _noText,
    this.source,
  });

  final String id;
  final int number;

  /// The name without vowel marks, as typed and searched.
  final String name;

  /// The name with its vowel marks, shown when written.
  final String vocalized;
  final String transliteration;
  final String meaningAr;
  final String meaningEn;

  /// The detailed explanation.
  final NameText description;

  /// A verse or narration the name comes from.
  final NameText evidence;

  /// What believing in the name brings to a believer's life.
  final NameText impact;
  final NameText dua;
  final Uri? source;

  String get display => vocalized.isNotEmpty ? vocalized : name;

  String meaning(String language) =>
      language == 'en' && meaningEn.isNotEmpty ? meaningEn : meaningAr;
}

NameText _pair(Object? value) =>
    (ar: _text(value, 'ar'), en: _text(value, 'en'));

String _text(Object? value, String key) {
  if (value is! Map) return '';
  final text = value[key];
  return text is String ? text.trim() : '';
}

/// The names published in the library feed, in their dashboard order.
List<DivineName> divineNamesFrom(Map<String, Object?>? feed) {
  final library = feed?['library'];
  final rows = library is Map ? library['names'] : null;
  if (rows is! List) return const [];
  final names = <DivineName>[];
  for (final row in rows.whereType<Map<Object?, Object?>>()) {
    final name = _text(row['title'], 'ar');
    final meaning = _text(row['body'], 'ar');
    if (name.isEmpty || meaning.isEmpty) continue;
    final source = Uri.tryParse('${row['source'] ?? ''}');
    names.add(
      DivineName(
        id: '${row['id'] ?? names.length}',
        number: row['number'] is int ? row['number']! as int : names.length + 1,
        name: name,
        transliteration: _text(row['title'], 'en'),
        meaningAr: meaning,
        meaningEn: _text(row['body'], 'en'),
        vocalized: row['vocalized'] is String
            ? (row['vocalized']! as String).trim()
            : '',
        description: _pair(row['description']),
        evidence: _pair(row['evidence']),
        impact: _pair(row['impact']),
        dua: _pair(row['dua']),
        source: source != null && source.scheme == 'https' ? source : null,
      ),
    );
  }
  return names;
}

final divineNamesProvider = Provider<AsyncValue<List<DivineName>>>(
  (ref) => ref.watch(managedLibraryProvider).whenData(divineNamesFrom),
);

String _digits(int value, String language) {
  final text = '$value';
  if (language != 'ar') return text;
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  return text.split('').map((d) => arabic[int.parse(d)]).join();
}

class NamesScreen extends ConsumerStatefulWidget {
  const NamesScreen({super.key});

  @override
  ConsumerState<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends ConsumerState<NamesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final value = ref.watch(divineNamesProvider);
    final names = value.asData?.value ?? const <DivineName>[];
    final needle = normalizeSearch(_query);
    final shown = needle.isEmpty
        ? names
        : names
              .where(
                (name) =>
                    normalizeSearch(name.name).contains(needle) ||
                    normalizeSearch(name.transliteration).contains(needle) ||
                    normalizeSearch(name.meaning(language)).contains(needle),
              )
              .toList();
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.namesTitle)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ResponsiveContent(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _NamesHero(),
                    if (names.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        key: const Key('names-search'),
                        onChanged: (text) => setState(() => _query = text),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: l10n.namesSearch,
                          isDense: true,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(28)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (value.isLoading && names.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (names.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  l10n.namesComingSoon,
                  key: const Key('names-empty'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.xxl,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: width >= 840
                      ? 4
                      : width >= 560
                      ? 3
                      : 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.95,
                ),
                itemCount: shown.length,
                itemBuilder: (context, index) =>
                    _NameCard(name: shown[index], language: language),
              ),
            ),
        ],
      ),
    );
  }
}

/// The verse the names are introduced with (Al-A'raf 180), read from the
/// bundled Mushaf text.
class _NamesHero extends ConsumerWidget {
  const _NamesHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final verse = ref
        .watch(mushafEditionProvider)
        .asData
        ?.value
        .surahs[6]
        .verses[179];
    return ClipRRect(
      borderRadius: AppRadii.xlAll,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [BrandColors.primaryGreen, BrandColors.heroGreenEnd],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: OrbitMotif(color: BrandColors.goldBright),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Text(
                    l10n.namesTitle,
                    textAlign: TextAlign.center,
                    style: AppTheme.headingStyle(FontWeight.w600)
                        .copyWith(fontSize: 30, color: BrandColors.ivory),
                  ),
                  if (verse != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      verse,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: AppTheme.quranFontFamily,
                        fontSize: 19,
                        height: 1.9,
                        color: BrandColors.goldBright,
                      ),
                    ),
                    Text(
                      l10n.namesVerseReference,
                      style: const TextStyle(
                        color: BrandColors.ivory,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({required this.name, required this.language});

  final DivineName name;
  final String language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      key: ValueKey('name-${name.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => NameDetailScreen(name: name)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: BrandColors.mutedGold),
                ),
                child: SizedBox.square(
                  dimension: 30,
                  child: Center(
                    child: Text(
                      _digits(name.number, language),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: BrandColors.mutedGold,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name.display,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: AppTheme.quranFontFamily,
                    fontSize: 30,
                    height: 1.4,
                    color: scheme.primary,
                  ),
                ),
              ),
              if (name.transliteration.isNotEmpty)
                Text(
                  name.transliteration,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const Spacer(),
              Text(
                name.meaning(language),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NameDetailScreen extends StatelessWidget {
  const NameDetailScreen({required this.name, super.key});

  final DivineName name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    Widget block(String title, String body, {TextDirection? direction}) => Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: BrandColors.mutedGold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              body,
              textDirection: direction,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.namesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: AppRadii.xlAll,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BrandColors.primaryGreen,
                          BrandColors.heroGreenEnd,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: OrbitMotif(color: BrandColors.goldBright),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: AppSpacing.lg,
                          ),
                          child: Column(
                            children: [
                              Text(
                                _digits(name.number, language),
                                style: const TextStyle(
                                  color: BrandColors.goldBright,
                                ),
                              ),
                              Text(
                                name.display,
                                key: const Key('name-detail-title'),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: AppTheme.quranFontFamily,
                                  fontSize: 52,
                                  height: 1.5,
                                  color: BrandColors.ivory,
                                ),
                              ),
                              if (name.transliteration.isNotEmpty)
                                Text(
                                  name.transliteration,
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(
                                    color: BrandColors.goldBright,
                                    letterSpacing: 1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                block(l10n.namesMeaning, name.meaningAr),
                if (language == 'en' && name.meaningEn.isNotEmpty)
                  block(
                    'Meaning',
                    name.meaningEn,
                    direction: TextDirection.ltr,
                  ),
                // Explanations follow the reader's language; the evidence
                // and the supplication keep their Arabic wording too.
                for (final (title, text, keepArabic) in [
                  (l10n.namesDescription, name.description, false),
                  (l10n.namesEvidence, name.evidence, true),
                  (l10n.namesImpact, name.impact, false),
                  (l10n.namesDua, name.dua, true),
                ])
                  if (text.ar.isNotEmpty || text.en.isNotEmpty)
                    if (language == 'en' && text.en.isNotEmpty)
                      block(
                        title,
                        keepArabic && text.ar.isNotEmpty
                            ? '${text.ar}\n\n${text.en}'
                            : text.en,
                      )
                    else
                      block(title, text.ar.isNotEmpty ? text.ar : text.en),
                if (name.source case final source?)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () =>
                          launchUrl(source, mode: LaunchMode.inAppBrowserView),
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: Text(l10n.namesSource),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
