import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'map/map_page.dart';
import 'transfer/transfer_page.dart';

/// Spike-only remote control for runs on real phones without touching the
/// screen (release builds, so timings are realistic).
///
/// Task source: iOS — Documents/autotest.json (put there with
/// `devicectl device copy to`); Android — intent extra `autotest`
/// (`am start … --es autotest '<json>'`). Every line also goes to
/// Documents/autotest.log and to the console with an `[autotest]` prefix.
///
/// Tasks:
///   {"do":"map","lat":50.45,"lon":30.52,"zoom":14,"bench":true}
///   {"do":"host","send":true,"mb":10,"hotspot":true}
///   {"do":"client","invite":"{...}","mb":10}
abstract final class Autotest {
  static const _ch = MethodChannel('horyzontal/wifi');
  static File? _log;
  static Future<void> _pending = Future.value();

  /// Writes are chained: callers don't await, and parallel appends clobber each other.
  static Future<void> log(String line) {
    final t = DateTime.now().toIso8601String().substring(11, 23);
    // ignore: avoid_print
    print('[autotest] $t $line');
    return _pending = _pending.then((_) async {
      try {
        _log ??= File('${(await getApplicationDocumentsDirectory()).path}/autotest.log');
        await _log!.writeAsString('$t $line\n', mode: FileMode.append, flush: true);
      } catch (_) {}
    });
  }

  static Future<Map<String, dynamic>?> _takeTask() async {
    String? raw;
    if (Platform.isAndroid) {
      raw = await _ch.invokeMethod<String>('autotestTask');
    } else {
      final f = File('${(await getApplicationDocumentsDirectory()).path}/autotest.json');
      if (await f.exists()) {
        raw = await f.readAsString();
        await f.delete();
      }
    }
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> runIfRequested({
    required MapPageState map,
    required TransferPageState transfer,
    required void Function(int) selectTab,
  }) async {
    final task = await _takeTask();
    if (task == null) return;
    await log('task ${jsonEncode(task)}');
    try {
      switch (task['do']) {
        case 'map':
          selectTab(0);
          await _map(map, task);
        case 'host':
          selectTab(1);
          await transfer.runHostWith(
            hostSends: task['send'] as bool? ?? true,
            megabytes: task['mb'] as int? ?? 10,
            hotspot: task['hotspot'] as bool? ?? Platform.isAndroid,
          );
        case 'client':
          selectTab(1);
          await transfer.runClientWith(
            task['invite'] as String,
            megabytes: task['mb'] as int? ?? 10,
            joinOnce: task['joinOnce'] as bool? ?? false,
          );
      }
    } catch (e, st) {
      await log('FAILED $e\n$st');
    }
    await log('done');
  }

  static Future<void> _map(MapPageState map, Map<String, dynamic> task) async {
    final styleMs = await map.goOfflineAndWait();
    await log('offline style loaded in $styleMs ms');
    await map.moveTo(
      (task['lat'] as num? ?? 50.45).toDouble(),
      (task['lon'] as num? ?? 30.52).toDouble(),
      (task['zoom'] as num? ?? 11).toDouble(),
    );
    final reader = map.reader;
    if (task['bench'] != true || reader == null) return;

    var maxErr = 0.0, sumErr = 0.0;
    final sw = Stopwatch()..start();
    for (final (lat, lon, ref) in _reference) {
      final h = await reader.elevation(lat, lon);
      final err = (h! - ref).abs();
      maxErr = err > maxErr ? err : maxErr;
      sumErr += err;
    }
    await log('elevation: ${_reference.length} points in ${sw.elapsedMilliseconds} ms, '
        'mean err ${(sumErr / _reference.length).toStringAsFixed(2)} m, max ${maxErr.toStringAsFixed(2)} m');

    // Cold then warm: a 40 km line across Kyiv and a 120 km one across the oblast.
    for (final (name, a, b, c, d) in [
      ('Kyiv 40 km', 50.40, 30.25, 50.47, 30.80),
      ('Kyiv 40 km again', 50.40, 30.25, 50.47, 30.80),
      ('oblast 120 km', 49.6, 30.0, 50.6, 31.0),
      ('oblast 120 km again', 49.6, 30.0, 50.6, 31.0),
    ]) {
      final t = Stopwatch()..start();
      final p = await reader.profile(a, b, c, d, samples: 256);
      final valid = p.whereType<double>();
      await log('profile $name: 256 points in ${t.elapsedMilliseconds} ms, '
          'min ${valid.reduce((x, y) => x < y ? x : y).toStringAsFixed(0)} '
          'max ${valid.reduce((x, y) => x > y ? x : y).toStringAsFixed(0)} m');
    }
  }

  /// Bilinear samples of the source Copernicus grid (test/fixtures).
  static const _reference = [
    (49.698294, 30.050720, 199.90), (50.378562, 29.884425, 185.43),
    (50.474007, 31.156153, 103.35), (50.580875, 29.889741, 140.05),
    (49.534990, 30.243055, 209.93), (49.393309, 29.513174, 246.49),
    (50.491123, 30.355953, 181.11), (50.552151, 31.780809, 130.16),
    (49.857852, 29.911733, 184.19), (49.721393, 29.474973, 240.25),
    (49.830331, 29.537519, 226.76), (50.039752, 31.114278, 96.19),
    (49.665254, 30.331319, 162.70), (51.418450, 30.026977, 107.73),
    (50.628771, 31.150700, 104.01), (50.918088, 29.744351, 176.70),
    (50.075010, 29.721537, 182.30), (49.237516, 29.915124, 251.80),
    (49.805659, 30.169928, 151.90), (51.433532, 29.861850, 117.99),
    (50.114012, 31.172532, 101.87), (50.266439, 31.936634, 127.30),
    (49.754754, 30.020791, 189.65), (49.793606, 30.895122, 122.41),
  ];
}
