import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/ids.dart';
import '../../core/db/database.dart';
import '../../core/settings.dart';
import 'map_source.dart';

final sourcesRepositoryProvider = Provider<SourcesRepository>(
  (ref) => SourcesRepository(ref.watch(databaseProvider)),
);

/// User map sources, oldest first: later ones are drawn on top.
final sourcesProvider = StreamProvider<List<MapSource>>((ref) => ref.watch(sourcesRepositoryProvider).watch());

/// Hosts of the user's URL sources, for the network allow list.
final sourceHostsProvider = Provider<Set<String>>((ref) => {
  for (final s in ref.watch(sourcesProvider).value ?? const <MapSource>[]) ...sourceHosts(s),
});

class SourcesRepository {
  SourcesRepository(this.db, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;

  Stream<List<MapSource>> watch() {
    final q = db.select(db.tileSources)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_source).toList());
  }

  Future<List<MapSource>> all() async {
    final q = db.select(db.tileSources)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return (await q.get()).map(_source).toList();
  }

  Future<MapSource?> byId(String id) async {
    final row = await (db.select(db.tileSources)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _source(row);
  }

  /// A new source with a fresh id and the current time.
  MapSource create({
    required String name,
    required MapSourceKind kind,
    String? url,
    bool tms = false,
    List<String> subdomains = const [],
    String? file,
    int minZoom = 0,
    int maxZoom = 19,
    int tileSize = 256,
    String attribution = '',
    String? id,
  }) => MapSource(
    id: id ?? newId(),
    name: name,
    kind: kind,
    url: url,
    tms: tms,
    subdomains: subdomains,
    file: file,
    minZoom: minZoom,
    maxZoom: maxZoom,
    tileSize: tileSize,
    attribution: attribution,
    createdAt: _now(),
  );

  Future<void> save(MapSource s) => db.into(db.tileSources).insertOnConflictUpdate(
    TileSourcesCompanion.insert(
      id: s.id,
      name: s.name,
      kind: s.kind.name,
      url: Value(s.url),
      scheme: Value(s.tms ? 'tms' : 'xyz'),
      subdomains: Value(s.subdomains.join(',')),
      file: Value(s.file),
      minZoom: Value(s.minZoom),
      maxZoom: Value(s.maxZoom),
      tileSize: Value(s.tileSize),
      attribution: Value(s.attribution),
      enabled: Value(s.enabled),
      opacity: Value(s.opacity),
      createdAt: s.createdAt,
    ),
  );

  Future<void> setEnabled(String id, bool enabled) =>
      (db.update(db.tileSources)..where((t) => t.id.equals(id))).write(TileSourcesCompanion(enabled: Value(enabled)));

  Future<void> setOpacity(String id, double opacity) =>
      (db.update(db.tileSources)..where((t) => t.id.equals(id))).write(TileSourcesCompanion(opacity: Value(opacity)));

  Future<void> delete(String id) => (db.delete(db.tileSources)..where((t) => t.id.equals(id))).go();

  static MapSource _source(TileSourceRow r) => MapSource(
    id: r.id,
    name: r.name,
    kind: MapSourceKind.values.byName(r.kind),
    url: r.url,
    tms: r.scheme == 'tms',
    subdomains: r.subdomains.isEmpty ? const [] : r.subdomains.split(','),
    file: r.file,
    minZoom: r.minZoom,
    maxZoom: r.maxZoom,
    tileSize: r.tileSize,
    attribution: r.attribution,
    enabled: r.enabled,
    opacity: r.opacity,
    createdAt: r.createdAt,
  );
}
