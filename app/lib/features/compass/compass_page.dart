import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/labels.dart';
import '../../core/sensors.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/copy_tile.dart';
import 'compass_rose.dart';

enum NorthReference { magnetic, truth }

final northReferenceProvider = NotifierProvider<_NorthReference, NorthReference>(
  _NorthReference.new,
);

class _NorthReference extends Notifier<NorthReference> {
  @override
  NorthReference build() => NorthReference.truth;
  void set(NorthReference v) => state = v;
}

class CompassPage extends ConsumerStatefulWidget {
  const CompassPage({super.key});

  @override
  ConsumerState<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends ConsumerState<CompassPage> {
  /// Unwrapped rotation of the card, so that 359° -> 1° turns 2°, not 358°.
  double _turns = 0;
  double? _lastHeading;

  double _unwrap(double heading) {
    final last = _lastHeading;
    _lastHeading = heading;
    if (last == null) return _turns = -heading / 360;
    return _turns -= normalizeSignedDegrees(heading - last) / 360;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final north = ref.watch(northReferenceProvider);
    final heading = ref.watch(headingProvider);
    final position = ref.watch(positionProvider);
    final pos = position.value;
    final wgs = pos == null ? null : Geodetic(pos.latitude, pos.longitude, pos.altitude);
    final year = decimalYear(DateTime.now());
    final declination = wgs == null
        ? null
        : Wmm.wmm2025.at(wgs.lat, wgs.lon, wgs.h, year).declination;

    final reading = heading.value;
    double? shown;
    if (reading != null) {
      shown = north == NorthReference.truth && declination != null
          ? normalizeDegrees(reading.magnetic + declination)
          : reading.magnetic;
    }
    final turns = shown == null ? _turns : _unwrap(shown);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.tabCompass)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Center(
            child: SegmentedButton<NorthReference>(
              segments: [
                ButtonSegment(value: NorthReference.truth, label: Text(l.compassTrue)),
                ButtonSegment(value: NorthReference.magnetic, label: Text(l.compassMagnetic)),
              ],
              selected: {north},
              onSelectionChanged: (s) => ref.read(northReferenceProvider.notifier).set(s.single),
            ),
          ),
          if (north == NorthReference.truth && declination == null && reading != null)
            _Note(text: l.trueNorthNeedsLocation, icon: Icons.info_outline),
          const SizedBox(height: 16),
          Text(
            shown == null ? '—' : formatAngle(shown, settings.angleOutput),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Icon(Icons.arrow_drop_down, size: 40, color: colors.error),
          LayoutBuilder(
            builder: (context, c) {
              final size = (c.maxWidth - 48).clamp(200.0, 420.0);
              return Center(
                child: SizedBox.square(
                  dimension: size,
                  child: AnimatedRotation(
                    turns: turns,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: CustomPaint(
                      painter: CompassRosePainter(
                        format: settings.angleOutput,
                        colors: colors,
                        cardinals: const ['Пн', 'Сх', 'Пд', 'Зх'],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          ...heading.when(
            data: (r) => [
              if (r.needsCalibration) _Note(text: l.compassLowAccuracy, icon: Icons.warning_amber),
              if (!r.needsCalibration)
                _Note(
                  text: l.compassAccuracy(r.accuracy.toStringAsFixed(0)),
                  icon: Icons.explore_outlined,
                ),
            ],
            loading: () => const [],
            error: (e, _) => [_Note(text: l.noCompass, icon: Icons.explore_off_outlined)],
          ),
          if (!Wmm.wmm2025.isValidAt(year)) _Note(text: l.wmmExpired, icon: Icons.warning_amber),
          ..._positionInfo(context, position, wgs, declination, settings),
        ],
      ),
    );
  }

  List<Widget> _positionInfo(
    BuildContext context,
    AsyncValue<Position> position,
    Geodetic? wgs,
    double? declination,
    AppSettings settings,
  ) {
    final l = context.l10n;
    if (position.hasError) {
      return [
        _Note(text: l.locationDenied, icon: Icons.location_off_outlined),
        Center(
          child: TextButton(onPressed: Geolocator.openAppSettings, child: Text(l.openSettings)),
        ),
      ];
    }
    final p = position.value;
    if (p == null || wgs == null) return [_Note(text: l.locating, icon: Icons.location_searching)];

    final grid = settings.system.isGrid ? settings.system : CoordinateSystem.sk42Gk;
    final convergence = grid.grid!.convergence(grid.datum.fromWgs84Geodetic(wgs));
    final altitude = _altitude(l, p);
    final angle = settings.angleOutput;
    String signed(double d) =>
        formatAngle(d, angle, signed: true, decimals: angle == AngleFormat.dms ? 0 : 1);
    return [
      CopyTile(
        label: '${systemName(l, settings.system)} · ${l.accuracy(p.accuracy.toStringAsFixed(0))}',
        value: formatPoint(wgs, settings.system, settings.geoFormat),
      ),
      if (altitude != null) CopyTile(label: l.altitude, value: altitude),
      if (declination != null) CopyTile(label: l.declination, value: signed(declination)),
      CopyTile(label: '${l.convergence} (${systemName(l, grid)})', value: signed(convergence)),
    ];
  }

  /// iOS reports altitude above mean sea level, Android above the WGS 84
  /// ellipsoid; the latter is corrected with EGM2008 where the grid covers.
  String? _altitude(AppLocalizations l, Position p) {
    if (!p.hasAltitude && p.altitude == 0) return null;
    final acc = p.altitudeAccuracy > 0
        ? ' ${l.accuracy(p.altitudeAccuracy.toStringAsFixed(0))}'
        : '';
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return '${l.altitudeMsl(p.altitude.toStringAsFixed(0))}$acc';
    }
    final n = Geoid.egm2008Ukraine.undulation(p.latitude, p.longitude);
    if (n == null) return '${l.altitudeEllipsoid(p.altitude.toStringAsFixed(0))}$acc';
    return '${l.altitudeMsl((p.altitude - n).toStringAsFixed(0))}$acc';
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      ListTile(dense: true, leading: Icon(icon), title: Text(text));
}
