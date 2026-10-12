import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

enum FeatureKind { point, polyline, polygon }

@immutable
class MapLayer {
  const MapLayer({
    required this.id,
    required this.name,
    required this.color,
    required this.visible,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id, name;
  final int color;
  final bool visible, archived;
  final DateTime createdAt, updatedAt;

  MapLayer copyWith({String? name, int? color, bool? visible, bool? archived, DateTime? updatedAt}) =>
      MapLayer(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        visible: visible ?? this.visible,
        archived: archived ?? this.archived,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// A point, polyline or polygon. Vertices are WGS 84; [Geodetic.h] is the
/// altitude above mean sea level when known, 0 when unknown. Formats with
/// ellipsoidal heights (CoT `hae`) convert with EGM2008.
@immutable
class MapFeature {
  const MapFeature({
    required this.id,
    required this.layerId,
    required this.kind,
    required this.vertices,
    required this.createdAt,
    required this.updatedAt,
    this.name = '',
    this.description = '',
    this.author = '',
    this.sidc,
    this.color,
    this.radius,
    this.extra = const {},
  });

  final String id, layerId;
  final FeatureKind kind;
  final List<Geodetic> vertices;
  final String name, description, author;
  final String? sidc;
  final int? color;
  final double? radius;

  /// Fields kept from imports, e.g. `cotUid`, `cotType`.
  final Map<String, Object?> extra;
  final DateTime createdAt, updatedAt;

  Geodetic get position => vertices.first;

  MapFeature copyWith({
    String? layerId,
    List<Geodetic>? vertices,
    String? name,
    String? description,
    String? author,
    String? Function()? sidc,
    int? Function()? color,
    double? Function()? radius,
    Map<String, Object?>? extra,
    DateTime? updatedAt,
  }) =>
      MapFeature(
        id: id,
        layerId: layerId ?? this.layerId,
        kind: kind,
        vertices: vertices ?? this.vertices,
        name: name ?? this.name,
        description: description ?? this.description,
        author: author ?? this.author,
        sidc: sidc == null ? this.sidc : sidc(),
        color: color == null ? this.color : color(),
        radius: radius == null ? this.radius : radius(),
        extra: extra ?? this.extra,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static String encodeVertices(List<Geodetic> v) => jsonEncode([
        for (final p in v) [p.lat, p.lon, if (p.h != 0) p.h],
      ]);

  static List<Geodetic> decodeVertices(String json) => [
        for (final p in jsonDecode(json) as List<Object?>)
          switch (p! as List<Object?>) {
            [final num lat, final num lon] => Geodetic(lat.toDouble(), lon.toDouble()),
            [final num lat, final num lon, final num h, ...] =>
              Geodetic(lat.toDouble(), lon.toDouble(), h.toDouble()),
            _ => throw const FormatException('Bad vertex'),
          },
      ];
}
