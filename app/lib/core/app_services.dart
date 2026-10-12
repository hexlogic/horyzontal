import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;

import '../features/exchange/import_flow.dart';
import '../features/security/lock.dart';
import '../features/settings/about_page.dart';
import '../features/settings/whats_new_page.dart';
import 'labels.dart';
import 'router.dart';
import 'settings.dart';

const _security = MethodChannel('horyzontal/security');

/// App-wide side effects of settings and OS events: screenshot protection,
/// offline-only mode for MapLibre, files shared to the app, first-run
/// privacy notice, "what's new" after an update, and a cover over the UI
/// while the app is inactive (the app switcher snapshot).
class AppServices extends ConsumerStatefulWidget {
  const AppServices({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppServices> createState() => _AppServicesState();
}

class _AppServicesState extends ConsumerState<AppServices> {
  StreamSubscription<Object?>? _incoming;
  final _pendingFiles = <String>[];
  late final AppLifecycleListener _lifecycle;
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _applySecure(s.screenshotProtection);
    maplibre.setOffline(s.offlineOnly).catchError((_) {});
    _incoming = incomingChannel.receiveBroadcastStream().listen((path) {
      if (path is String) {
        _pendingFiles.add(path);
        _drainFiles();
      }
    }, onError: (_) {});
    _lifecycle = AppLifecycleListener(
      onInactive: () => setState(() => _covered = true),
      onHide: () => setState(() => _covered = true),
      onShow: () => setState(() => _covered = false),
      onResume: () => setState(() => _covered = false),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstRun());
  }

  @override
  void dispose() {
    _incoming?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _applySecure(bool on) {
    if (Platform.isAndroid) _security.invokeMethod('setSecure', on).catchError((_) {});
  }

  /// Imports wait until the app is unlocked.
  Future<void> _drainFiles() async {
    if (ref.read(lockProvider).locked) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    while (_pendingFiles.isNotEmpty) {
      final path = _pendingFiles.removeAt(0);
      if (!ctx.mounted) return;
      await importPath(ctx, ref, path);
    }
  }

  Future<void> _firstRun() async {
    final s = ref.read(settingsProvider);
    final ctl = ref.read(settingsProvider.notifier);
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    if (!s.privacyNoticeSeen) {
      await showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (context) {
          final l = context.l10n;
          return AlertDialog(
            title: Text(l.privacyTitle),
            content: SingleChildScrollView(child: Text(l.privacyText)),
            actions: [
              TextButton(
                onPressed: () {
                  ctl.update((s) => s.copyWith(offlineOnly: true, onlineMap: false));
                  Navigator.pop(context);
                },
                child: Text(l.privacyOfflineOnly),
              ),
              FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.privacyOk)),
            ],
          );
        },
      );
      await ctl.update((s) => s.copyWith(privacyNoticeSeen: true, lastSeenVersion: appVersion));
      return;
    }
    if (s.lastSeenVersion != appVersion) {
      await ctl.update((s) => s.copyWith(lastSeenVersion: appVersion));
      if (!ctx.mounted || releaseNotes.first.$1 != appVersion) return;
      await Navigator.of(ctx).push(MaterialPageRoute<void>(builder: (_) => const WhatsNewPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider.select((s) => s.screenshotProtection), (_, v) => _applySecure(v));
    ref.listen(settingsProvider.select((s) => s.offlineOnly),
        (_, v) => maplibre.setOffline(v).catchError((_) {}));
    ref.listen(lockProvider.select((s) => s.locked), (_, locked) {
      if (!locked) _drainFiles();
    });
    return Stack(
      children: [
        widget.child,
        if (_covered)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Center(child: Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.outline)),
            ),
          ),
      ],
    );
  }
}
