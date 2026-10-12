import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal_spike/map/dem_reader.dart';

/// Compares heights read from the generated pack with bilinear samples of the
/// original Copernicus 1" grid (test/fixtures/kyiv-dem-reference.csv).
/// The packs aren't committed: build them with tools/map-pipeline/build_dem.py.
void main() {
  final out = '../tools/map-pipeline/out';
  final packs = Directory(out).existsSync()
      ? Directory(out)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('kyiv-dem-') && f.path.endsWith('.pmtiles'))
          .toList()
      : <File>[];
  final ref = File('test/fixtures/kyiv-dem-reference.csv')
      .readAsLinesSync()
      .skip(1)
      .map((l) => l.split(',').map(double.parse).toList())
      .toList();

  for (final pack in packs) {
    test('heights from ${pack.uri.pathSegments.last} match the source', () async {
      final reader = await DemReader.open(pack.path);
      final errors = <double>[];
      final sw = Stopwatch()..start();
      for (final r in ref) {
        final h = await reader.elevation(r[0], r[1]);
        expect(h, isNotNull, reason: '${r[0]}, ${r[1]}');
        errors.add((h! - r[2]).abs());
      }
      final ms = sw.elapsedMilliseconds;
      await reader.close();
      errors.sort();
      final mean = errors.reduce((a, b) => a + b) / errors.length;
      final p95 = errors[(errors.length * 0.95).floor()];
      // ignore: avoid_print
      print('${pack.uri.pathSegments.last}: mean ${mean.toStringAsFixed(2)} m, '
          'p95 ${p95.toStringAsFixed(2)} m, max ${errors.last.toStringAsFixed(2)} m, '
          '${ref.length} points in $ms ms');
      expect(mean, lessThan(1.5));
      expect(p95, lessThan(5));
    });
  }

  test('outside the pack is null', () async {
    if (packs.isEmpty) return;
    final reader = await DemReader.open(packs.first.path);
    expect(await reader.elevation(48.0, 24.0), isNull);
    await reader.close();
  });
}
