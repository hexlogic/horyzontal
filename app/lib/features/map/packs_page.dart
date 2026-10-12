import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import 'packs.dart';

/// Per-region download state, kept while the app runs so leaving the
/// screen does not cancel a download.
class DownloadState {
  const DownloadState({this.received = 0, this.total = 0, this.error, this.active = false});
  final int received, total;
  final Object? error;
  final bool active;
}

final downloadsProvider = NotifierProvider<Downloads, Map<String, DownloadState>>(Downloads.new);

class Downloads extends Notifier<Map<String, DownloadState>> {
  final _cancel = <String, bool>{};

  @override
  Map<String, DownloadState> build() => {};

  void _set(String id, DownloadState s) => state = {...state, id: s};

  Future<void> start(RemoteRegion r) async {
    if (state[r.id]?.active == true) return;
    _cancel[r.id] = false;
    final net = ref.read(netProvider);
    final dir = await ref.read(packStoreProvider).dir();
    var done = 0;
    _set(r.id, DownloadState(total: r.bytes, active: true));
    try {
      for (final f in r.files) {
        await for (final p in downloadFile(net, f, dir)) {
          if (_cancel[r.id] == true) throw const _Cancelled();
          _set(r.id, DownloadState(received: done + p.received, total: r.bytes, active: true));
        }
        done += f.bytes;
      }
      state = {...state}..remove(r.id);
    } on _Cancelled {
      state = {...state}..remove(r.id);
    } catch (e) {
      _set(r.id, DownloadState(received: done, total: r.bytes, error: e));
    }
    ref.invalidate(packsProvider);
  }

  /// Stops after the current chunk; the .part file stays for resuming.
  void cancel(String id) => _cancel[id] = true;
}

class _Cancelled implements Exception {
  const _Cancelled();
}

String formatBytes(AppLocalizations l, int bytes) => bytes >= 1e9
    ? l.gigabytes((bytes / 1e9).toStringAsFixed(1))
    : l.megabytes((bytes / 1e6).toStringAsFixed(bytes >= 1e8 ? 0 : 1));

class PacksPage extends ConsumerWidget {
  const PacksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final installed = ref.watch(packsProvider).value ?? const <PackFile>[];
    final regions = ref.watch(regionsProvider).value ?? const <Region>[];
    final manifest = s.offlineOnly ? null : ref.watch(manifestProvider);
    final downloads = ref.watch(downloadsProvider);
    final remote = {for (final r in manifest?.value ?? const <RemoteRegion>[]) r.id: r};
    final byRegion = <String, List<PackFile>>{};
    for (final p in installed) {
      (byRegion[p.regionId] ??= []).add(p);
    }
    final known = {for (final r in regions) r.id};
    final other = installed.where((p) => !known.contains(p.regionId)).toList();
    final total = installed.fold(0, (s, p) => s + p.bytes);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.offlinePacks),
        actions: [
          IconButton(
            tooltip: l.importPack,
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () => _import(context, ref),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l.packsSummary(installed.length, formatBytes(l, total))),
            subtitle: Text(s.offlineOnly
                ? l.packsOfflineOnly
                : manifest!.hasError
                    ? l.packsManifestError
                    : manifest.isLoading
                        ? l.packsLoading
                        : l.packsBuild(remote.values.firstOrNull?.build ?? '—')),
          ),
          for (final r in regions)
            _RegionTile(
              region: r,
              installed: byRegion[r.id] ?? const [],
              remote: remote[r.id],
              download: downloads[r.id],
            ),
          if (other.isNotEmpty) ...[
            ListTile(title: Text(l.packsOther, style: Theme.of(context).textTheme.titleSmall)),
            for (final p in other)
              ListTile(
                leading: Icon(p.kind == PackKind.basemap ? Icons.map_outlined : Icons.terrain_outlined),
                title: Text(p.name),
                subtitle: Text(formatBytes(l, p.bytes)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref, p.name, [p]),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.packsAttribution, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  static Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final picked = await FilePicker.pickFiles();
    for (final f in picked) {
      if (f.path == null) continue;
      final p = await ref.read(packStoreProvider).import(f.path!);
      if (p == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.notAPack(f.name))));
      }
    }
    ref.invalidate(packsProvider);
  }

  static Future<void> _delete(BuildContext context, WidgetRef ref, String name, List<PackFile> files) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deletePackQuestion(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    for (final f in files) {
      await ref.read(packStoreProvider).delete(f);
    }
    ref.invalidate(packsProvider);
  }
}

class _RegionTile extends ConsumerWidget {
  const _RegionTile({required this.region, required this.installed, this.remote, this.download});

  final Region region;
  final List<PackFile> installed;
  final RemoteRegion? remote;
  final DownloadState? download;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final d = download;
    final size = installed.fold(0, (s, p) => s + p.bytes);
    final hasBasemap = installed.any((p) => p.kind == PackKind.basemap);
    final hasDem = installed.any((p) => p.kind == PackKind.dem);
    final r = remote;
    final upToDate = r != null &&
        r.files.every((f) => installed.any((p) => p.name == f.name && p.bytes == f.bytes));

    Widget? trailing;
    String subtitle;
    if (d != null && d.active) {
      subtitle = l.downloading(formatBytes(l, d.received), formatBytes(l, d.total));
      trailing = IconButton(
        icon: const Icon(Icons.close),
        tooltip: l.cancel,
        onPressed: () => ref.read(downloadsProvider.notifier).cancel(region.id),
      );
    } else if (installed.isNotEmpty) {
      subtitle = [
        formatBytes(l, size),
        if (!hasDem) l.packNoHeights,
        if (r != null && !upToDate) l.packUpdate,
      ].join(' · ');
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (r != null && !upToDate)
            IconButton(
              icon: const Icon(Icons.system_update_alt),
              tooltip: l.packUpdate,
              onPressed: () => ref.read(downloadsProvider.notifier).start(r),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l.delete,
            onPressed: () => PacksPage._delete(context, ref, region.name, installed),
          ),
        ],
      );
    } else {
      subtitle = r == null ? l.packNotAvailable : formatBytes(l, r.bytes);
      trailing = r == null
          ? null
          : IconButton(
              icon: const Icon(Icons.download),
              tooltip: l.download,
              onPressed: () => ref.read(downloadsProvider.notifier).start(r),
            );
    }
    if (d?.error != null) subtitle = '$subtitle · ${l.downloadFailed}';

    return ListTile(
      leading: Icon(
        hasBasemap ? Icons.offline_pin : Icons.map_outlined,
        color: hasBasemap ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(region.name),
      subtitle: d != null && d.active
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: d.total == 0 ? null : d.received / d.total),
              ],
            )
          : Text(subtitle),
      trailing: trailing,
    );
  }
}
