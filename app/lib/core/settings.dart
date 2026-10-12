import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import 'db/database.dart';

/// User preferences, persisted in the encrypted database.
@immutable
class AppSettings {
  const AppSettings({
    this.system = CoordinateSystem.wgs84,
    this.geoFormat = GeoFormat.degrees,
    this.angleInput = AngleFormat.deg360,
    this.angleOutput = AngleFormat.deg360,
    this.callsign = '',
    this.themeMode = ThemeMode.system,
    this.biometrics = false,
    this.lockAfter = const Duration(seconds: 30),
    this.offlineOnly = false,
    this.onlineMap = true,
    this.screenshotProtection = false,
    this.privacyNoticeSeen = false,
    this.lastSeenVersion = '',
    this.camera = const MapCamera(48.9, 31.2, 5.3),
    this.symbolFavorites = const [],
    this.symbolRecent = const [],
  });

  final CoordinateSystem system;
  final GeoFormat geoFormat;
  final AngleFormat angleInput, angleOutput;
  final String callsign;
  final ThemeMode themeMode;
  final bool biometrics;
  final Duration lockAfter;

  /// No network at all: no online tiles, no pack downloads.
  final bool offlineOnly;

  /// Online OpenFreeMap basemap instead of the offline packs.
  final bool onlineMap;

  /// Android FLAG_SECURE: no screenshots, blank in the app switcher.
  final bool screenshotProtection;
  final bool privacyNoticeSeen;

  /// App version whose "what's new" the user has seen.
  final String lastSeenVersion;
  final MapCamera camera;

  /// SIDCs starred in the symbol picker, and the last ones used.
  final List<String> symbolFavorites, symbolRecent;

  static const lockOptions = [
    Duration.zero,
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  AppSettings copyWith({
    CoordinateSystem? system,
    GeoFormat? geoFormat,
    AngleFormat? angleInput,
    AngleFormat? angleOutput,
    String? callsign,
    ThemeMode? themeMode,
    bool? biometrics,
    Duration? lockAfter,
    bool? offlineOnly,
    bool? onlineMap,
    bool? screenshotProtection,
    bool? privacyNoticeSeen,
    String? lastSeenVersion,
    MapCamera? camera,
    List<String>? symbolFavorites,
    List<String>? symbolRecent,
  }) => AppSettings(
    system: system ?? this.system,
    geoFormat: geoFormat ?? this.geoFormat,
    angleInput: angleInput ?? this.angleInput,
    angleOutput: angleOutput ?? this.angleOutput,
    callsign: callsign ?? this.callsign,
    themeMode: themeMode ?? this.themeMode,
    biometrics: biometrics ?? this.biometrics,
    lockAfter: lockAfter ?? this.lockAfter,
  );

  Map<String, String> toMap() => {
    'system': system.name,
    'geoFormat': geoFormat.name,
    'angleInput': angleInput.name,
    'angleOutput': angleOutput.name,
    'callsign': callsign,
    'themeMode': themeMode.name,
    'biometrics': biometrics.toString(),
    'lockAfterSeconds': lockAfter.inSeconds.toString(),
  };

  /// Unknown or missing values fall back to defaults, so old and new app
  /// versions can read each other's settings.
  factory AppSettings.fromMap(Map<String, String> m) {
    const d = AppSettings();
    T pick<T extends Enum>(List<T> values, String key, T fallback) =>
        values.where((v) => v.name == m[key]).firstOrNull ?? fallback;
    final lock = int.tryParse(m['lockAfterSeconds'] ?? '');
    return AppSettings(
      system: pick(CoordinateSystem.values, 'system', d.system),
      geoFormat: pick(GeoFormat.values, 'geoFormat', d.geoFormat),
      angleInput: pick(AngleFormat.values, 'angleInput', d.angleInput),
      angleOutput: pick(AngleFormat.values, 'angleOutput', d.angleOutput),
      callsign: m['callsign'] ?? d.callsign,
      themeMode: pick(ThemeMode.values, 'themeMode', d.themeMode),
      biometrics: m['biometrics'] == 'true',
      lockAfter: lock == null ? d.lockAfter : Duration(seconds: lock),
      offlineOnly: m['offlineOnly'] == 'true',
      onlineMap: m['onlineMap'] != 'false',
      screenshotProtection: m['screenshotProtection'] == 'true',
      privacyNoticeSeen: m['privacyNoticeSeen'] == 'true',
      lastSeenVersion: m['lastSeenVersion'] ?? '',
      camera: MapCamera.decode(m['camera']) ?? d.camera,
      symbolFavorites: _codes(m['symbolFavorites']),
      symbolRecent: _codes(m['symbolRecent']),
    );
  }

  @override
  bool operator ==(Object other) => other is AppSettings && _mapEquals(toMap(), other.toMap());

  @override
  int get hashCode => Object.hashAll(toMap().values);
}

/// Map view to restore on the next launch.
@immutable
class MapCamera {
  const MapCamera(this.lat, this.lon, this.zoom);
  final double lat, lon, zoom;

  String encode() => '$lat,$lon,$zoom';

  static MapCamera? decode(String? s) {
    final p = s?.split(',').map(double.tryParse).toList();
    if (p == null || p.length != 3 || p.contains(null)) return null;
    return MapCamera(p[0]!, p[1]!, p[2]!);
  }
}

List<String> _codes(String? s) =>
    s == null || s.isEmpty ? const [] : s.split(',').where((c) => RegExp(r'^\d{20,30}$').hasMatch(c)).toList();

bool _mapEquals(Map<String, String> a, Map<String, String> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

/// Overridden in `main` with the opened database.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

/// Settings read at startup, overridden in `main`.
final initialSettingsProvider = Provider<AppSettings>((ref) => const AppSettings());

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  Future<void> update(AppSettings Function(AppSettings) change) async {
    final next = change(state);
    final before = state.toMap();
    state = next;
    final db = ref.read(databaseProvider);
    for (final e in next.toMap().entries) {
      if (before[e.key] != e.value) await db.writeSetting(e.key, e.value);
    }
  }
}
