import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../../core/sensors.dart';
import '../../core/settings.dart';
import '../../core/widgets/copy_tile.dart';
import '../../core/widgets/point_results.dart';
import '../../l10n/app_localizations.dart';
import '../exchange/qr_share.dart';
import '../map/map_focus.dart';
import 'feature_text.dart';
import 'symbol_icons.dart';

final _featureProvider = StreamProvider.autoDispose.family<MapFeature?, String>(
  (ref, id) => ref.watch(repositoryProvider).watchFeature(id),
);

/// Object card in a bottom sheet over the map.
Future<void> showFeatureSheet(BuildContext context, String id) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scroll) => FeatureDetails(id: id, scroll: scroll, inSheet: true),
      ),
    );

/// Object card as a page (from the journal).
class FeaturePage extends StatelessWidget {
  const FeaturePage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.object)),
        body: FeatureDetails(id: id),
      );
}

class FeatureDetails extends ConsumerWidget {
  const FeatureDetails({super.key, required this.id, this.scroll, this.inSheet = false});

  final String id;
  final ScrollController? scroll;
  final bool inSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = ref.watch(_featureProvider(id)).value;
    if (f == null) return const Center(child: CircularProgressIndicator());
    final s = ref.watch(settingsProvider);
    final layers = ref.watch(layersProvider(false)).value ?? const [];
    final layer = layers.where((x) => x.id == f.layerId).firstOrNull;
    final pos = ref.watch(positionProvider).value;
    final theme = Theme.of(context);

    String? distance;
    if (pos != null) {
      final r = Geodesic.wgs84.inverse(pos.latitude, pos.longitude, f.position.lat, f.position.lon);
      distance = '${formatDistance(l, r.s12)} · ${formatAngle(r.azi1, s.angleOutput)}';
    }

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ListTile(
          leading: f.sidc != null
              ? SymbolView(f.sidc!, height: 44)
              : Icon(_kindIcon(f.kind), color: Color(f.color ?? layer?.color ?? 0xFF1565C0)),
          title: Text(f.name.isEmpty ? l.unnamed : f.name, style: theme.textTheme.titleLarge),
          subtitle: Text([_kindName(l, f.kind), if (layer != null) layer.name].join(' · ')),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ActionChip(
              avatar: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l.edit),
              onPressed: () {
                if (inSheet) context.pop();
                context.go('/journal/object/$id/edit');
              },
            ),
            if (!inSheet)
              ActionChip(
                avatar: const Icon(Icons.map_outlined, size: 18),
                label: Text(l.showOnMap),
                onPressed: () {
                  ref.read(mapFocusProvider.notifier).show(MapFocus(f.position, featureId: f.id));
                  context.go('/map');
                },
              ),
            if (f.kind == FeatureKind.point) ...[
              ActionChip(
                avatar: const Icon(Icons.directions_outlined, size: 18),
                label: Text(l.route),
                onPressed: () => _route(context, f.position),
              ),
              ActionChip(
                avatar: const Icon(Icons.share_outlined, size: 18),
                label: Text(l.share),
                onPressed: () => SharePlus.instance.share(ShareParams(text: featureShareText(l, f, s))),
              ),
              ActionChip(
                avatar: const Icon(Icons.qr_code_2, size: 18),
                label: Text(l.qrCode),
                onPressed: () => showPointQr(context, f),
              ),
            ],
            ActionChip(
              avatar: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
              label: Text(l.delete),
              onPressed: () => _delete(context, ref, f),
            ),
          ],
        ).paddingSymmetric(16),
        if (distance != null) CopyTile(label: l.distanceAzimuthFromMe, value: distance),
        if (f.kind == FeatureKind.point) ...[
          if (f.position.h != 0) CopyTile(label: l.altitude, value: l.metres(f.position.h.toStringAsFixed(0))),
          if (f.radius != null) CopyTile(label: l.radius, value: l.metres(f.radius!.toStringAsFixed(0))),
          PointResults(wgs: f.position),
        ] else
          ListTile(title: Text(l.vertices(f.vertices.length))),
        if (f.description.isNotEmpty)
          ListTile(title: Text(l.description, style: theme.textTheme.labelMedium), subtitle: Text(f.description)),
        ListTile(
          dense: true,
          title: Text(l.created(formatDateTime(f.createdAt))),
          subtitle: Text([
            if (f.author.isNotEmpty) '${l.author}: ${f.author}',
            l.updated(formatDateTime(f.updatedAt)),
          ].join(' · ')),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, MapFeature f) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteObjectQuestion),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repositoryProvider).deleteFeature(f.id);
    if (context.mounted) context.pop();
  }

  /// Hands the destination to a maps app; the app itself makes no request.
  Future<void> _route(BuildContext context, Geodetic p) async {
    final l = context.l10n;
    final dest = '${p.lat},${p.lon}';
    final options = <(String, Uri)>[
      if (Platform.isIOS) (l.appleMaps, Uri.parse('maps://?daddr=$dest')),
      if (Platform.isIOS) (l.googleMaps, Uri.parse('comgooglemaps://?daddr=$dest')),
      if (Platform.isAndroid) (l.googleMaps, Uri.parse('google.navigation:q=$dest')),
      if (Platform.isAndroid) (l.otherMapsApp, Uri.parse('geo:$dest?q=$dest')),
    ];
    final available = [
      for (final o in options)
        if (await canLaunchUrl(o.$2)) o,
    ];
    if (!context.mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.noMapsApp)));
      return;
    }
    if (available.length == 1) {
      await launchUrl(available.single.$2);
      return;
    }
    final pick = await showModalBottomSheet<Uri>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in available)
              ListTile(title: Text(o.$1), onTap: () => Navigator.pop(context, o.$2)),
          ],
        ),
      ),
    );
    if (pick != null) await launchUrl(pick);
  }
}

IconData _kindIcon(FeatureKind k) => featureKindIcon(k);
String _kindName(AppLocalizations l, FeatureKind k) => featureKindName(l, k);

extension on Widget {
  Widget paddingSymmetric(double h) => Padding(padding: EdgeInsets.symmetric(horizontal: h), child: this);
}
