import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../security/lock.dart';

/// monobank jar for donations; the row stays hidden while this is empty.
/// The app only hands the link to the browser, it never calls it itself.
const donateUrl = String.fromEnvironment('DONATE_URL');

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final pin = ref.watch(lockProvider.select((x) => x.pinEnabled));
    final ctl = ref.read(settingsProvider.notifier);

    Future<void> choose<T>(
      String title,
      List<T> values,
      T current,
      String Function(T) name,
      AppSettings Function(AppSettings, T) apply,
    ) async {
      final v = await showDialog<T>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(title),
          children: [
            RadioGroup<T>(
              groupValue: current,
              onChanged: (v) => Navigator.pop(context, v),
              child: Column(
                children: [
                  for (final x in values) RadioListTile<T>(value: x, title: Text(name(x))),
                ],
              ),
            ),
          ],
        ),
      );
      if (v != null) await ctl.update((s) => apply(s, v));
    }

    Widget option<T>(
      String title,
      List<T> values,
      T current,
      String Function(T) name,
      AppSettings Function(AppSettings, T) apply,
    ) => ListTile(
      title: Text(title),
      subtitle: Text(name(current)),
      onTap: () => choose(title, values, current, name, apply),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.tabSettings)),
      body: ListView(
        children: [
          _Header(l.settingsCoordinates),
          option(
            l.defaultSystem,
            CoordinateSystem.values,
            s.system,
            (v) => systemName(l, v),
            (s, v) => s.copyWith(system: v),
          ),
          option(
            l.geoFormat,
            GeoFormat.values,
            s.geoFormat,
            (v) => geoFormatName(l, v),
            (s, v) => s.copyWith(geoFormat: v),
          ),
          option(
            l.angleInput,
            AngleFormat.values,
            s.angleInput,
            (v) => angleFormatName(l, v),
            (s, v) => s.copyWith(angleInput: v),
          ),
          option(
            l.angleOutput,
            AngleFormat.values,
            s.angleOutput,
            (v) => angleFormatName(l, v),
            (s, v) => s.copyWith(angleOutput: v),
          ),
          ListTile(
            title: Text(l.callsign),
            subtitle: Text(s.callsign.isEmpty ? l.callsignHint : s.callsign),
            onTap: () => _editCallsign(context, ref, s.callsign),
          ),
          option(
            l.theme,
            ThemeMode.values,
            s.themeMode,
            (v) => _themeName(l, v),
            (s, v) => s.copyWith(themeMode: v),
          ),
          _Header(l.settingsMap),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: Text(l.offlinePacks),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/packs'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.cloud_off),
            title: Text(l.offlineOnly),
            subtitle: Text(l.offlineOnlyHint),
            value: s.offlineOnly,
            onChanged: (v) => ctl.update((s) => s.copyWith(offlineOnly: v)),
          ),
          _Header(l.settingsSecurity),
          if (!pin)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l.pinEnable),
              subtitle: Text(l.pinOff),
              onTap: () => context.go('/settings/pin/enable'),
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.lock),
              title: Text(l.pinChange),
              subtitle: Text(l.pinOn),
              onTap: () => context.go('/settings/pin/change'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_open),
              title: Text(l.pinDisable),
              onTap: () => context.go('/settings/pin/disable'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(l.biometrics),
              subtitle: Text(l.biometricsSubtitle),
              value: s.biometrics,
              onChanged: (v) => _setBiometrics(context, ref, v),
            ),
            option(
              l.lockAfter,
              AppSettings.lockOptions,
              s.lockAfter,
              (v) => _lockName(l, v),
              (s, v) => s.copyWith(lockAfter: v),
            ),
          ],
          if (Platform.isAndroid)
            SwitchListTile(
              secondary: const Icon(Icons.screenshot_monitor_outlined),
              title: Text(l.screenshotProtection),
              subtitle: Text(l.screenshotProtectionHint),
              value: s.screenshotProtection,
              onChanged: (v) => ctl.update((s) => s.copyWith(screenshotProtection: v)),
            ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            title: Text(l.emergencyWipe),
            subtitle: Text(l.emergencyWipeHint),
            onTap: () => context.go('/settings/wipe'),
          ),
          _Header(l.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.about),
            onTap: () => context.go('/settings/about'),
          ),
          ListTile(
            leading: const Icon(Icons.new_releases_outlined),
            title: Text(l.whatsNew),
            onTap: () => context.go('/settings/whats-new'),
          ),
          if (donateUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: Text(l.donate),
              subtitle: Text(l.donateHint),
              onTap: () => launchUrl(Uri.parse(donateUrl), mode: LaunchMode.externalApplication),
            ),
        ],
      ),
    );
  }

  Future<void> _setBiometrics(BuildContext context, WidgetRef ref, bool on) async {
    if (on) {
      final reason = context.l10n.biometricReason;
      final lock = ref.read(lockProvider.notifier);
      lock.authenticating = true;
      try {
        // Confirm once so that a device without enrolled biometrics is caught here.
        final ok = await LocalAuthentication().authenticate(
          localizedReason: reason,
          biometricOnly: true,
        );
        if (!ok) return;
      } on LocalAuthException {
        return;
      } finally {
        lock.authenticating = false;
      }
    }
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(biometrics: on));
  }

  Future<void> _editCallsign(BuildContext context, WidgetRef ref, String current) async {
    final l = context.l10n;
    final controller = TextEditingController(text: current);
    final v = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.callsign),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 32,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(helperText: l.callsignHint),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
    if (v == null) return;
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(callsign: v.trim()));
  }

  static String _themeName(AppLocalizations l, ThemeMode m) => switch (m) {
    ThemeMode.system => l.themeSystem,
    ThemeMode.light => l.themeLight,
    ThemeMode.dark => l.themeDark,
  };

  static String _lockName(AppLocalizations l, Duration d) => d == Duration.zero
      ? l.lockImmediately
      : d.inMinutes >= 1
      ? l.lockMinutes(d.inMinutes)
      : l.lockSeconds(d.inSeconds);
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
