import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

class BasmalaLine extends StatelessWidget {
  const BasmalaLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontFamily: AppTheme.quranFontFamily,
        fontSize: 24,
        height: 1.6,
      ),
    ),
  );
}
