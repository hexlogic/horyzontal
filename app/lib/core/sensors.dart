import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Magnetic heading of the device top edge, degrees; [accuracy] in degrees,
/// negative when the platform says the compass needs calibration.
class HeadingReading {
  const HeadingReading(this.magnetic, this.accuracy);
  final double magnetic, accuracy;

  bool get needsCalibration => accuracy < 0 || accuracy > 20;
}

const _headingChannel = EventChannel('horyzontal/heading');

/// Sensors fail for good (no magnetometer, permission denied): no retries,
/// so the error reaches the UI instead of an endless loading state.
Duration? _noRetry(int count, Object error) => null;

final headingProvider = StreamProvider.autoDispose<HeadingReading>(retry: _noRetry, (ref) {
  return _headingChannel.receiveBroadcastStream().map((e) {
    final m = (e as Map<Object?, Object?>);
    return HeadingReading(
      (m['heading'] as num).toDouble(),
      (m['accuracy'] as num?)?.toDouble() ?? -1,
    );
  });
});

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.permanentlyDenied);
  final bool permanentlyDenied;
}

/// Asks for when-in-use permission if needed. Never background location.
Future<void> ensureLocationPermission() async {
  if (!await Geolocator.isLocationServiceEnabled()) throw const LocationUnavailable(false);
  var p = await Geolocator.checkPermission();
  if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
  if (p == LocationPermission.deniedForever) throw const LocationUnavailable(true);
  if (p == LocationPermission.denied || p == LocationPermission.unableToDetermine) {
    throw const LocationUnavailable(false);
  }
}

LocationSettings get _settings => switch (defaultTargetPlatform) {
  // Plain GNSS through LocationManager, no Google Play location services.
  TargetPlatform.android => AndroidSettings(
    accuracy: LocationAccuracy.best,
    forceLocationManager: true,
  ),
  TargetPlatform.iOS => AppleSettings(
    accuracy: LocationAccuracy.best,
    pauseLocationUpdatesAutomatically: false,
  ),
  _ => const LocationSettings(accuracy: LocationAccuracy.best),
};

Future<Position> currentPosition() async {
  await ensureLocationPermission();
  return Geolocator.getCurrentPosition(locationSettings: _settings);
}

final positionProvider = StreamProvider.autoDispose<Position>(retry: _noRetry, (ref) async* {
  await ensureLocationPermission();
  final last = await Geolocator.getLastKnownPosition();
  if (last != null) yield last;
  yield* Geolocator.getPositionStream(locationSettings: _settings);
});
