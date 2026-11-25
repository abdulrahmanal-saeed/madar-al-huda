import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

const _updates = MethodChannel('madar/updates');
const _host = 'quran.abdulrahmanalsaeed.com';
const _maxUpdateFeedBytes = 64 * 1024;

class SettingsUpdates extends StatefulWidget {
  const SettingsUpdates({super.key});

  @override
  State<SettingsUpdates> createState() => _SettingsUpdatesState();
}

class _SettingsUpdatesState extends State<SettingsUpdates> {
  late Future<AppUpdateStatus?> _status;
  late final AppLifecycleListener _lifecycle;
  bool _changingPermission = false;

  @override
  void initState() {
    super.initState();
    _status = _checkAppUpdate();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _status = _checkAppUpdate());

  Future<void> _setNotifications(bool enabled, bool ar) async {
    setState(() => _changingPermission = true);
    try {
      final allowed = await _updates.invokeMethod<bool>(
        'notifications',
        enabled,
      );
      if (mounted && enabled && allowed != true) {
        _message(
          ar
              ? 'اسمح بإشعارات مدار الهدى من إعدادات Android.'
              : 'Allow Madar Al-Huda notifications in Android settings.',
        );
      }
    } on PlatformException {
      if (mounted) {
        _message(
          ar ? 'تعذّر ضبط الإشعارات.' : 'Could not change notifications.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _changingPermission = false);
        _refresh();
      }
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _status,
    builder: (context, snapshot) {
      final status = snapshot.data;
      if (status == null) return const SizedBox.shrink();
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      final update = status.available;
      final notes = ar ? update?.arabicNotes : update?.englishNotes;
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: Text(ar ? 'تحديث التطبيق' : 'App update'),
            subtitle: Text(
              update != null
                  ? '${update.name}${notes?.isNotEmpty == true ? '\n$notes' : ''}'
                  : status.unreachable
                  ? (ar
                        ? 'تعذّر التحقق من التحديثات.'
                        : 'Could not check for updates.')
                  : (ar ? 'لا يوجد تحديث جديد.' : 'No update available.'),
            ),
            trailing: update == null
                ? IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: ar ? 'تحقق من التحديثات' : 'Check for updates',
                    onPressed:
                        snapshot.connectionState == ConnectionState.waiting
                        ? null
                        : _refresh,
                  )
                : TextButton(
                    onPressed: () => _downloadAppUpdate(
                      context,
                      status.channel,
                      update.code,
                      ar,
                    ),
                    child: Text(ar ? 'تنزيل' : 'Download'),
                  ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(ar ? 'إشعارات التحديثات' : 'Update notifications'),
            subtitle: Text(
              ar ? 'يتحقق Android من التحديثات دوريًا عندما يتاح الاتصال.' : 'Android checks periodically when an internet connection is available.',
            ),
            value: status.notifications,
            onChanged: _changingPermission
                ? null
                : (value) => _setNotifications(value, ar),
          ),
        ],
      );
    },
  );
}

Future<AppUpdateStatus?> _checkAppUpdate() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  Map<String, Object?>? info;
  try {
    info = await _updates.invokeMapMethod<String, Object?>('installed');
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
  final channel = info?['channel'];
  final installed = info?['code'];
  if (channel is! String ||
      !const {'dev', 'preview'}.contains(channel) ||
      installed is! int) {
    return null;
  }
  final notifications = info?['notifications'] == true;
  try {
    final response = await http
        .get(
          Uri.https(_host, '/admin/', {
            'feed': 'updates',
            'channel': channel,
          }),
        )
        .timeout(const Duration(seconds: 8));
    // The update notice is a few hundred bytes; anything far larger is not
    // a genuine response and is treated like an unreachable server.
    if (response.bodyBytes.length > _maxUpdateFeedBytes) {
      return AppUpdateStatus(channel, notifications, null, true);
    }
    final update = response.statusCode == 200
        ? PublishedAppUpdate.parse(
            jsonDecode(utf8.decode(response.bodyBytes)),
            installed,
          )
        : null;
    return AppUpdateStatus(
      channel,
      notifications,
      update,
      response.statusCode != 200,
    );
  } catch (_) {
    return AppUpdateStatus(channel, notifications, null, true);
  }
}

Future<void> _downloadAppUpdate(
  BuildContext context,
  String channel,
  int code,
  bool ar,
) async {
  final uri = Uri.https(_host, '/admin/', {'apk': '$channel-$code'});
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Show a retryable message for unsupported browsers.
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ar ? 'تعذّر فتح رابط التنزيل.' : 'Could not open the download.',
        ),
      ),
    );
  }
}

/// The home notice uses the same channel and version-code check as Settings.
class HomeUpdateBanner extends StatefulWidget {
  const HomeUpdateBanner({super.key, this.check = _checkAppUpdate});

  final Future<AppUpdateStatus?> Function() check;

  @override
  State<HomeUpdateBanner> createState() => _HomeUpdateBannerState();
}

class _HomeUpdateBannerState extends State<HomeUpdateBanner> {
  late Future<AppUpdateStatus?> _status;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _status = widget.check();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _status = widget.check());

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _status,
    builder: (context, snapshot) {
      final status = snapshot.data;
      final update = status?.available;
      if (snapshot.connectionState != ConnectionState.done ||
          status == null ||
          status.unreachable ||
          update == null) {
        return const SizedBox.shrink();
      }
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ar ? 'تحديث جديد متاح' : 'New update available',
                  style: theme.textTheme.titleMedium,
                ),
                Text(update.name),
                const SizedBox(height: 8),
                Text(
                  ar
                      ? 'يتوفر إصدار جديد من مدار الهدى. يمكنك التحديث من الإعدادات ← تحديث التطبيق، أو الضغط على الزر التالي.'
                      : 'A new version of Madar Al-Huda is available. Update from Settings → App update, or use the button below.',
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _downloadAppUpdate(
                    context,
                    status.channel,
                    update.code,
                    ar,
                  ),
                  icon: const Icon(Icons.system_update_outlined),
                  label: Text(ar ? 'تحديث الآن' : 'Update now'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class AppUpdateStatus {
  const AppUpdateStatus(
    this.channel,
    this.notifications,
    this.available,
    this.unreachable,
  );

  final String channel;
  final bool notifications;
  final PublishedAppUpdate? available;
  final bool unreachable;
}

class PublishedAppUpdate {
  const PublishedAppUpdate(
    this.code,
    this.name,
    this.arabicNotes,
    this.englishNotes,
  );

  final int code;
  final String name;
  final String arabicNotes;
  final String englishNotes;

  static PublishedAppUpdate? parse(Object? value, int installed) {
    if (value is! Map<String, Object?> || value['version'] != 1) {
      throw const FormatException('Unexpected release feed');
    }
    final release = value['release'];
    if (release == null) return null;
    if (release is! Map<String, Object?>) {
      throw const FormatException('Unexpected release');
    }
    final code = release['code'];
    final name = release['name'];
    final notes = release['notes'];
    if (code is! int ||
        code < 1 ||
        code > 2100000000 ||
        name is! String ||
        name.isEmpty ||
        name.length > 80 ||
        notes is! Map<String, Object?>) {
      throw const FormatException('Invalid release metadata');
    }
    if (code <= installed) return null;
    return PublishedAppUpdate(
      code,
      name,
      notes['ar'] as String,
      notes['en'] as String,
    );
  }
}
