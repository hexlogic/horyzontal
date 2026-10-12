import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../elevation.dart';

enum MapTool {
  ruler,
  polyline,
  polygon,
  profile,
  lineOfSight;

  /// Tools between two points: a third point replaces the second.
  bool get twoPoints => this == ruler || this == lineOfSight;

  bool get closed => this == polygon;

  /// Points needed before the tool has a result.
  int get minPoints => this == polygon ? 3 : 2;
}

class ToolState {
  const ToolState([this.tool, this.vertices = const []]);
  final MapTool? tool;
  final List<Geodetic> vertices;

  bool get active => tool != null;
  bool get ready => tool != null && vertices.length >= tool!.minPoints;
}

class ToolController extends Notifier<ToolState> {
  @override
  ToolState build() => const ToolState();

  void start(MapTool tool, [List<Geodetic> vertices = const []]) =>
      state = ToolState(tool, vertices);

  void add(Geodetic g) {
    final t = state.tool;
    if (t == null) return;
    final v = [...state.vertices];
    if (t.twoPoints && v.length == 2) v.removeLast();
    v.add(Geodetic(g.lat, g.lon));
    state = ToolState(t, v);
  }

  void undo() {
    if (state.vertices.isEmpty) return;
    state = ToolState(state.tool, state.vertices.sublist(0, state.vertices.length - 1));
  }

  void clear() => state = ToolState(state.tool);

  void close() => state = const ToolState();
}

final mapToolProvider = NotifierProvider<ToolController, ToolState>(ToolController.new);

/// Ground height at each vertex of the current tool, null where unknown or
/// without an elevation pack.
final toolHeightsProvider = FutureProvider<List<double?>>((ref) async {
  final vertices = ref.watch(mapToolProvider.select((s) => s.vertices));
  final dem = await ref.watch(demProvider.future);
  if (dem == null || vertices.isEmpty) return List.filled(vertices.length, null);
  return dem.sample(vertices);
});
