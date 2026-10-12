import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../settings.dart';
import 'ids.dart';
import 'model.dart';

final repositoryProvider = Provider<Repository>((ref) => Repository(ref.watch(databaseProvider)));

/// Layers with the newest changes first; archived ones only when asked.
final layersProvider = StreamProvider.family<List<MapLayer>, bool>(
  (ref, archived) => ref.watch(repositoryProvider).watchLayers(archived: archived),
);

/// Features of visible, non-archived layers: what the map shows.
final visibleFeaturesProvider = StreamProvider<List<MapFeature>>(
  (ref) => ref.watch(repositoryProvider).watchFeatures(visibleOnly: true),
);

/// Features of one layer, archived or not.
final layerFeaturesProvider = StreamProvider.family<List<MapFeature>, String>(
  (ref, id) => ref.watch(repositoryProvider).watchFeatures(layerId: id),
);

/// Every feature not in an archived layer: what the journal lists.
final allFeaturesProvider = StreamProvider<List<MapFeature>>(
  (ref) => ref.watch(repositoryProvider).watchFeatures(),
);

class Repository {
  Repository(this.db, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;

  // --- Layers ---------------------------------------------------------------

  Stream<List<MapLayer>> watchLayers({bool archived = false}) {
    final q = db.select(db.layers)
      ..where((t) => t.archived.equals(archived))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return q.watch().map((rows) => rows.map(_layer).toList());
  }

  Future<List<MapLayer>> layers({bool includeArchived = true}) async {
    final q = db.select(db.layers)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (!includeArchived) q.where((t) => t.archived.equals(false));
    return (await q.get()).map(_layer).toList();
  }

  Future<MapLayer?> layer(String id) async {
    final row = await (db.select(db.layers)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _layer(row);
  }

  Future<MapLayer> createLayer(String name, {int? color, String? id}) async {
    final now = _now();
    final layer = MapLayer(
      id: id ?? newId(),
      name: name,
      color: color ?? 0xFF1565C0,
      visible: true,
      archived: false,
      createdAt: now,
      updatedAt: now,
    );
    await db.into(db.layers).insert(_layerCompanion(layer));
    return layer;
  }

  Future<void> saveLayer(MapLayer layer) =>
      db.into(db.layers).insertOnConflictUpdate(_layerCompanion(layer.copyWith(updatedAt: _now())));

  Future<void> setLayerVisible(String id, bool visible) => (db.update(db.layers)
        ..where((t) => t.id.equals(id)))
      .write(LayersCompanion(visible: Value(visible)));

  Future<void> setLayerArchived(String id, bool archived) => (db.update(db.layers)
        ..where((t) => t.id.equals(id)))
      .write(LayersCompanion(archived: Value(archived), updatedAt: Value(_now())));

  Future<void> deleteLayer(String id) => (db.delete(db.layers)..where((t) => t.id.equals(id))).go();

  /// The layer new objects go to: the most recently updated non-archived
  /// one, created as [nameIfNone] on first use.
  Future<MapLayer> defaultLayer(String nameIfNone) async {
    final existing = await layers(includeArchived: false);
    return existing.firstOrNull ?? await createLayer(nameIfNone);
  }

  // --- Features -------------------------------------------------------------

  Stream<List<MapFeature>> watchFeatures({bool visibleOnly = false, String? layerId}) {
    final q = db.select(db.features).join([
      innerJoin(db.layers, db.layers.id.equalsExp(db.features.layerId)),
    ])..orderBy([OrderingTerm.desc(db.features.updatedAt)]);
    // A single layer is shown even from the archive.
    if (layerId == null) q.where(db.layers.archived.equals(false));
    if (visibleOnly) q.where(db.layers.visible.equals(true));
    if (layerId != null) q.where(db.features.layerId.equals(layerId));
    return q.watch().map((rows) => rows.map((r) => _feature(r.readTable(db.features))).toList());
  }

  Future<List<MapFeature>> featuresOf(String layerId) async {
    final rows = await (db.select(db.features)
          ..where((t) => t.layerId.equals(layerId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_feature).toList();
  }

  Future<MapFeature?> feature(String id) async {
    final row = await (db.select(db.features)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _feature(row);
  }

  Stream<MapFeature?> watchFeature(String id) => (db.select(db.features)
        ..where((t) => t.id.equals(id)))
      .watchSingleOrNull()
      .map((r) => r == null ? null : _feature(r));

  /// Inserts or replaces [f] and bumps its layer, so recently touched layers
  /// sort first.
  Future<void> saveFeature(MapFeature f, {bool touch = true}) => db.transaction(() async {
        final now = _now();
        final saved = touch ? f.copyWith(updatedAt: now) : f;
        await db.into(db.features).insertOnConflictUpdate(_featureCompanion(saved));
        await (db.update(db.layers)..where((t) => t.id.equals(f.layerId)))
            .write(LayersCompanion(updatedAt: Value(now)));
      });

  Future<void> deleteFeature(String id) =>
      (db.delete(db.features)..where((t) => t.id.equals(id))).go();

  DateTime now() => _now();

  // --- Mapping --------------------------------------------------------------

  static MapLayer _layer(LayerRow r) => MapLayer(
        id: r.id,
        name: r.name,
        color: r.color,
        visible: r.visible,
        archived: r.archived,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  static LayersCompanion _layerCompanion(MapLayer l) => LayersCompanion.insert(
        id: l.id,
        name: l.name,
        color: Value(l.color),
        visible: Value(l.visible),
        archived: Value(l.archived),
        createdAt: l.createdAt,
        updatedAt: l.updatedAt,
      );

  static MapFeature _feature(FeatureRow r) => MapFeature(
        id: r.id,
        layerId: r.layerId,
        kind: FeatureKind.values.byName(r.kind),
        vertices: MapFeature.decodeVertices(r.geometry),
        name: r.name,
        description: r.description,
        author: r.author,
        sidc: r.sidc,
        color: r.color,
        radius: r.radius,
        extra: r.extra == null ? const {} : (jsonDecode(r.extra!) as Map<String, Object?>),
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  static FeaturesCompanion _featureCompanion(MapFeature f) => FeaturesCompanion.insert(
        id: f.id,
        layerId: f.layerId,
        kind: f.kind.name,
        name: Value(f.name),
        description: Value(f.description),
        author: Value(f.author),
        sidc: Value(f.sidc),
        color: Value(f.color),
        radius: Value(f.radius),
        geometry: MapFeature.encodeVertices(f.vertices),
        extra: Value(f.extra.isEmpty ? null : jsonEncode(f.extra)),
        createdAt: f.createdAt,
        updatedAt: f.updatedAt,
      );
}
