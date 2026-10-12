import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../core/widgets/copy_tile.dart';
import '../../core/widgets/date_time_input.dart';
import '../../core/widgets/point_input.dart';
import '../../l10n/app_localizations.dart';
import 'problem_widgets.dart';
import 'problems.dart';

/// How far ahead the event list looks.
const skyEventSpan = Duration(hours: 48);

/// "1 д 03:05:09" or "03:05:09".
String formatCountdown(Duration d, AppLocalizations l) {
  String two(int v) => v.toString().padLeft(2, '0');
  final s = d.inSeconds;
  final hms = '${two(s ~/ 3600 % 24)}:${two(s ~/ 60 % 60)}:${two(s % 60)}';
  final days = s ~/ 86400;
  return days > 0 ? '${l.skyDays(days)} $hms' : hms;
}

String skyEventName(AppLocalizations l, SkyEvent e) => switch ((e.body, e.kind)) {
  (SkyBody.sun, SkyEventKind.rise) => l.skySunrise,
  (SkyBody.sun, SkyEventKind.set) => l.skySunset,
  (SkyBody.sun, SkyEventKind.transit) => l.skySunTransit,
  (SkyBody.moon, SkyEventKind.rise) => l.skyMoonrise,
  (SkyBody.moon, SkyEventKind.set) => l.skyMoonset,
  (SkyBody.moon, SkyEventKind.transit) => l.skyMoonTransit,
  (_, SkyEventKind.civilDawn) => l.skyCivilDawn,
  (_, SkyEventKind.civilDusk) => l.skyCivilDusk,
  (_, SkyEventKind.nauticalDawn) => l.skyNauticalDawn,
  (_, SkyEventKind.nauticalDusk) => l.skyNauticalDusk,
  (_, SkyEventKind.astronomicalDawn) => l.skyAstronomicalDawn,
  (_, SkyEventKind.astronomicalDusk) => l.skyAstronomicalDusk,
};

String moonPhaseName(AppLocalizations l, MoonPhase p) => switch (p) {
  MoonPhase.newMoon => l.phaseNew,
  MoonPhase.waxingCrescent => l.phaseWaxingCrescent,
  MoonPhase.firstQuarter => l.phaseFirstQuarter,
  MoonPhase.waxingGibbous => l.phaseWaxingGibbous,
  MoonPhase.fullMoon => l.phaseFull,
  MoonPhase.waningGibbous => l.phaseWaningGibbous,
  MoonPhase.lastQuarter => l.phaseLastQuarter,
  MoonPhase.waningCrescent => l.phaseWaningCrescent,
};

/// Sun and Moon at a place and moment: azimuth, altitude, phase, and the
/// next rises, sets, culminations and twilights with a countdown.
class SkyPage extends ConsumerStatefulWidget {
  const SkyPage({super.key, this.clock = DateTime.now});

  /// Injected in tests.
  final DateTime Function() clock;

  @override
  ConsumerState<SkyPage> createState() => _SkyPageState();
}

class _SkyPageState extends ConsumerState<SkyPage> {
  PointValue? _place;
  DateTime? _moment;
  bool _utc = false;
  AngleKind _kind = AngleKind.trueAzimuth;
  late AngleFormat _format = ref.read(settingsProvider).angleOutput;
  late DateTime _now = widget.clock();
  Timer? _ticker;

  /// Events for the current place and start, recomputed when either changes
  /// or the first of them has passed.
  List<SkyEvent> _events = const [];
  Object? _eventsKey;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = widget.clock());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  List<SkyEvent> _eventsFor(Geodetic g, DateTime from) {
    // With "now" the list starts at the last whole minute, so it is not
    // rebuilt every second.
    final start = _moment ?? DateTime.fromMillisecondsSinceEpoch(from.millisecondsSinceEpoch ~/ 60000 * 60000);
    final key = (g.lat, g.lon, g.h, start);
    if (key != _eventsKey) {
      _eventsKey = key;
      _events = skyEvents(g, start, skyEventSpan);
    }
    return _events;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final place = _place;
    final moment = _moment ?? _now;
    final year = moment.toUtc().year;

    return Scaffold(
      appBar: AppBar(title: Text(l.taskSky)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PointInput(label: l.skyPlace, onChanged: (v) => setState(() => _place = v)),
          const SizedBox(height: 12),
          DateTimeInput(
            value: _moment,
            now: _now,
            utc: _utc,
            onChanged: (t) => setState(() => _moment = t),
            onUtcChanged: (v) => setState(() => _utc = v),
          ),
          const SizedBox(height: 12),
          AngleKindSelector(value: _kind, onChanged: (k) => setState(() => _kind = k)),
          const SizedBox(height: 12),
          OutputFormatSelector(value: _format, onChanged: (f) => setState(() => _format = f)),
          if (year < 1600 || year > 2600) _Note(l.skyAccuracy, Icons.info_outline),
          if (place == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(l.skyPlaceHint, textAlign: TextAlign.center),
            )
          else
            ..._results(context, place, moment, settings),
        ],
      ),
    );
  }

  List<Widget> _results(BuildContext context, PointValue place, DateTime moment, AppSettings settings) {
    final l = context.l10n;
    final g = place.wgs;
    final frame = planeFrameFor(place, settings.system);
    final magneticOk = Wmm.wmm2025.isValidAt(decimalYear(moment));
    final ctx = angleContextAt(g, frame, at: moment);
    final sun = sunPosition(g, moment), moon = moonPosition(g, moment);
    final events = _eventsFor(g, moment);

    String azimuth(double trueAz) => _kind == AngleKind.magnetic && !magneticOk
        ? '—'
        : formatAngle(ctx.fromTrue(trueAz).of(_kind), _format);
    String altitude(SkyPosition p) => formatAngle(p.apparentAltitude, _format, signed: true);

    final sunEvents = events.where((e) => e.body == SkyBody.sun && e.kind != SkyEventKind.transit);
    final polar = !sunEvents.any((e) => e.kind == SkyEventKind.rise || e.kind == SkyEventKind.set)
        ? (sun.altitude > sunRiseAltitude ? l.skyPolarDay : l.skyPolarNight)
        : null;
    final theme = Theme.of(context);

    Widget header(String title, IconData icon) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(children: [Icon(icon), const SizedBox(width: 8), Text(title, style: theme.textTheme.titleMedium)]),
    );

    return [
      if (_kind == AngleKind.magnetic && !magneticOk) _Note(l.wmmExpired, Icons.warning_amber),
      header(l.skySun, Icons.wb_sunny_outlined),
      CopyTile(label: angleKindName(l, _kind), value: azimuth(sun.azimuth)),
      CopyTile(label: l.skyAltitude, value: altitude(sun)),
      if (polar != null) _Note(polar, Icons.info_outline),
      header(l.skyMoon, Icons.nightlight_outlined),
      CopyTile(label: angleKindName(l, _kind), value: azimuth(moon.azimuth)),
      CopyTile(label: l.skyAltitude, value: altitude(moon)),
      ListTile(
        dense: true,
        title: Text(l.skyPhase, style: theme.textTheme.labelMedium),
        subtitle: Text(
          '${moonPhaseName(l, moon.phase)} · ${l.skyIllumination((moon.illumination * 100).round())}',
          style: theme.textTheme.titleMedium,
        ),
      ),
      header(l.skyEvents, Icons.timer_outlined),
      if (_moment != null && _moment!.isAfter(_now))
        ListTile(
          title: Text(l.skyToMoment),
          trailing: _Countdown(_moment!.difference(_now)),
        ),
      for (final e in events)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(e.body == SkyBody.sun ? Icons.wb_sunny_outlined : Icons.nightlight_outlined),
          title: Text(skyEventName(l, e)),
          subtitle: Text(
            '${formatMoment(e.time, utc: _utc)} · ${azimuth(e.position.azimuth)}',
            style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          ),
          trailing: e.time.isAfter(_now) ? _Countdown(e.time.difference(_now)) : null,
        ),
    ];
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown(this.left);
  final Duration left;

  @override
  Widget build(BuildContext context) => Text(
    formatCountdown(left, context.l10n),
    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text, this.icon);
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    ),
  );
}
