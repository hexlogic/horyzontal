import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sources/area_download.dart';

/// The area the map showed when it last stopped moving: what "download the
/// visible area" takes.
final visibleBoundsProvider = NotifierProvider<VisibleBounds, Bounds?>(VisibleBounds.new);

class VisibleBounds extends Notifier<Bounds?> {
  @override
  Bounds? build() => null;
  void set(Bounds b) => state = b;
}
