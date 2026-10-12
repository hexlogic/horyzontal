import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/labels.dart';
import '../../core/widgets/point_input.dart';
import 'map_focus.dart';

/// Coordinate search in any system, with paste and "my location".
Future<void> showSearchSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _SearchSheet(),
    );

class _SearchSheet extends ConsumerStatefulWidget {
  const _SearchSheet();

  @override
  ConsumerState<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<_SearchSheet> {
  PointValue? _point;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = _point;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.searchCoordinates, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          PointInput(onChanged: (v) => setState(() => _point = v)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(l.addPointHere),
                  onPressed: p == null
                      ? null
                      : () {
                          context.pop();
                          context.go('/map/new?lat=${p.wgs.lat}&lon=${p.wgs.lon}');
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.travel_explore),
                  label: Text(l.showOnMap),
                  onPressed: p == null
                      ? null
                      : () {
                          ref.read(mapFocusProvider.notifier).show(MapFocus(p.wgs, marker: true));
                          context.pop();
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
