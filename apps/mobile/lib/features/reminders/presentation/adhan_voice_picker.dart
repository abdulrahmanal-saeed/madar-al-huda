import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/reminder_scheduler.dart';
import '../domain/reminder_settings.dart';

class AdhanVoicePicker extends StatefulWidget {
  const AdhanVoicePicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final AdhanVoice value;
  final ValueChanged<AdhanVoice> onChanged;

  @override
  State<AdhanVoicePicker> createState() => _AdhanVoicePickerState();
}

class _AdhanVoicePickerState extends State<AdhanVoicePicker> {
  @override
  void dispose() {
    _preview(null);
    super.dispose();
  }

  Future<void> _preview(String? sound) async {
    try {
      await worshipAlarms.invokeMethod<void>('preview', sound);
    } catch (_) {
      if (sound != null && mounted) {
        final ar = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ar ? 'تعذر تشغيل المعاينة' : 'Preview unavailable'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return ExpansionTile(
      key: const ValueKey('adhan-voice-picker'),
      leading: const Icon(Icons.record_voice_over_outlined),
      title: Text(ar ? 'صوت الأذان' : 'Adhan voice'),
      subtitle: Text(ar ? widget.value.ar : widget.value.en),
      onExpansionChanged: (open) {
        if (!open) _preview(null);
      },
      children: [
        for (final voice in AdhanVoice.values)
          ListTile(
            leading: Icon(
              voice == widget.value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(ar ? voice.ar : voice.en),
            selected: voice == widget.value,
            onTap: () => widget.onChanged(voice),
            trailing: IconButton(
              tooltip: ar ? 'معاينة' : 'Preview',
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () => _preview(voice.sound),
            ),
          ),
        ListTile(
          title: Text(ar ? 'الفجر · مسجد مالمو' : 'Fajr · Malmö Mosque'),
          trailing: IconButton(
            tooltip: ar ? 'معاينة الفجر' : 'Preview Fajr',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () => _preview('adhan_fajr'),
          ),
        ),
        TextButton(
          onPressed: () => _preview(null),
          child: Text(ar ? 'إيقاف المعاينة' : 'Stop preview'),
        ),
        TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (context) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final (title, path, license) in [
                    ('Andrewler', 'Azan.ogg', 'CC BY-SA 4.0'),
                    (
                      'Seyfula Islam',
                      'Adhan,_Great_Mosque_of_Mecca_-_Jan_21,_2013.webm',
                      'CC BY 3.0',
                    ),
                    (
                      'Islamic Center Malmö',
                      'Eid_al-Fitr_Fajr_azan_at_Malmö_Mosque_-_19_August_2012.webm',
                      'CC BY 3.0',
                    ),
                  ])
                    ListTile(
                      title: Text(title),
                      subtitle: Text('$license · MP3'),
                      onTap: () => launchUrl(
                        Uri.https('commons.wikimedia.org', '/wiki/File:$path'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                ],
              ),
            ),
          ),
          child: Text(ar ? 'مصادر التسجيلات' : 'Recording sources'),
        ),
      ],
    );
  }
}
