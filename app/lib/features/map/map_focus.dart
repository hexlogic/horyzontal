import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

/// A request from another screen to show a place on the map (journal "show
/// on map", search). The map consumes it and resets it to null.
class MapFocus {
  const MapFocus(this.point, {this.featureId, this.marker = false});
  final Geodetic point;
  final String? featureId;

  /// Drop a temporary search marker there.
  final bool marker;
}

final mapFocusProvider = NotifierProvider<MapFocusController, MapFocus?>(MapFocusController.new);

class MapFocusController extends Notifier<MapFocus?> {
  @override
  MapFocus? build() => null;
  void show(MapFocus f) => state = f;
  void consumed() => state = null;
}
