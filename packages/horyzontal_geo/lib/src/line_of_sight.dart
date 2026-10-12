import 'dart:math' as math;

import 'ellipsoid.dart';

/// Refraction coefficient for visible light, the usual geodetic value.
const refractionOptical = 0.13;

/// Refraction coefficient of the standard radio atmosphere ("4/3 Earth").
const refractionRadio = 0.25;

/// Gaussian mean radius of curvature at latitude [lat], metres.
double gaussianRadius(double lat, [Ellipsoid e = Ellipsoid.wgs84]) {
  final s = math.sin(lat * math.pi / 180);
  return e.a * math.sqrt(1 - e.e2) / (1 - e.e2 * s * s);
}

/// How far the Earth's surface rises above the chord between two points
/// [d1] and [d2] metres away, with refraction coefficient [k].
double earthBulge(double d1, double d2, {double k = refractionOptical, double radius = 6371008.8}) =>
    d1 * d2 * (1 - k) / (2 * radius);

/// Radius of the first Fresnel zone, metres, [d1] and [d2] metres from the
/// ends, at [frequencyHz].
double fresnelRadius(double d1, double d2, double frequencyHz) {
  final lambda = 299792458 / frequencyHz;
  return math.sqrt(lambda * d1 * d2 / (d1 + d2));
}

class LosSample {
  const LosSample(this.distance, this.terrain, this.bulge, this.ray, this.fresnel);

  /// From the first point, metres.
  final double distance;

  /// Height of the ground, metres; null where it is unknown.
  final double? terrain;

  /// Rise of the ground due to the Earth's curvature, metres.
  final double bulge;

  /// Height of the line of sight, metres.
  final double ray;

  /// First Fresnel zone radius, metres, when a frequency was given.
  final double? fresnel;

  /// Ground with the curvature, as the ray sees it.
  double? get obstacle => terrain == null ? null : terrain! + bulge;

  /// Ray above the ground, metres; negative where the ground blocks it.
  double? get clearance => terrain == null ? null : ray - obstacle!;
}

class LosResult {
  const LosResult({
    required this.samples,
    required this.complete,
    required this.minClearance,
    required this.worstIndex,
    required this.firstObstruction,
    required this.minFresnelRatio,
  });

  final List<LosSample> samples;

  /// No gaps in the terrain between the ends.
  final bool complete;

  /// Smallest clearance between the ends, metres (infinite if there are no
  /// samples between them).
  final double minClearance;

  /// Index of the sample with [minClearance], -1 if none.
  final int worstIndex;

  /// Distance of the first sample that blocks the ray, metres.
  final double? firstObstruction;

  /// Smallest clearance in Fresnel radii, when a frequency was given.
  final double? minFresnelRatio;

  bool get visible => minClearance >= 0;

  /// 60% of the first Fresnel zone free: the usual radio link criterion.
  bool get fresnelClear => (minFresnelRatio ?? double.infinity) >= 0.6;
}

/// Line of sight between antennas [mastA] and [mastB] metres above the ground
/// at the ends of a profile ([distances] along it, [terrain] heights). Null
/// when the ground height at either end is unknown.
LosResult? lineOfSight({
  required List<double> distances,
  required List<double?> terrain,
  required double mastA,
  required double mastB,
  double k = refractionOptical,
  double? frequencyHz,
  double radius = 6371008.8,
}) {
  assert(distances.length == terrain.length && distances.length >= 2);
  final t0 = terrain.first, t1 = terrain.last;
  if (t0 == null || t1 == null) return null;
  final total = distances.last;
  final hA = t0 + mastA, hB = t1 + mastB;
  final samples = <LosSample>[];
  var complete = true, minClearance = double.infinity, worst = -1;
  double? first, minRatio;
  for (var i = 0; i < distances.length; i++) {
    final d = distances[i];
    final end = i == 0 || i == distances.length - 1;
    final fresnel = frequencyHz == null || end ? null : fresnelRadius(d, total - d, frequencyHz);
    final s = LosSample(
      d,
      terrain[i],
      earthBulge(d, total - d, k: k, radius: radius),
      total == 0 ? hA : hA + (hB - hA) * d / total,
      fresnel,
    );
    samples.add(s);
    if (end) continue;
    final c = s.clearance;
    if (c == null) {
      complete = false;
      continue;
    }
    if (c < minClearance) {
      minClearance = c;
      worst = i;
    }
    if (c < 0) first ??= d;
    if (fresnel != null && fresnel > 0) {
      final r = c / fresnel;
      if (minRatio == null || r < minRatio) minRatio = r;
    }
  }
  return LosResult(
    samples: samples,
    complete: complete,
    minClearance: minClearance,
    worstIndex: worst,
    firstObstruction: first,
    minFresnelRatio: minRatio,
  );
}
