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
  late Future<_UpdateStatus?> _status;
  late final AppLifecycleListener _lifecycle;
  bool _changingPermission = false;

  @override
  void initState() {
    super.initState();
    _status = _check();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _status = _check());

  Future<_UpdateStatus?> _check() async {
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
        return _UpdateStatus(channel, notifications, null, true);
      }
      final update = response.statusCode == 200
          ? _PublishedUpdate.parse(
              jsonDecode(utf8.decode(response.bodyBytes)),
              installed,
            )
          : null;
      return _UpdateStatus(
        channel,
        notifications,
        update,
        response.statusCode != 200,
      );
    } catch (_) {
      return _UpdateStatus(channel, notifications, null, true);
    }
  }

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

  Future<void> _download(_UpdateStatus status, int code, bool ar) async {
    final uri = Uri.https(_host, '/admin/', {'apk': '${status.channel}-$code'});
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Show a retryable message for unsupported browsers.
    }
    if (mounted) {
      _message(ar ? 'تعذّر فتح رابط التنزيل.' : 'Could not open the download.');
    }
  }

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
                    onPressed: () => _download(status, update.code, ar),
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

class _UpdateStatus {
  const _UpdateStatus(
    this.channel,
    this.notifications,
    this.available,
    this.unreachable,
  );

  final String channel;
  final bool notifications;
  final _PublishedUpdate? available;
  final bool unreachable;
}

class _PublishedUpdate {
  const _PublishedUpdate(
    this.code,
    this.name,
    this.arabicNotes,
    this.englishNotes,
  );

  final int code;
  final String name;
  final String arabicNotes;
  final String englishNotes;

  static _PublishedUpdate? parse(Object? value, int installed) {
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
    return _PublishedUpdate(
      code,
      name,
      notes['ar'] as String,
      notes['en'] as String,
    );
  }
}
