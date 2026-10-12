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
  });

  final CoordinateSystem system;
  final GeoFormat geoFormat;
  final AngleFormat angleInput, angleOutput;
  final String callsign;
  final ThemeMode themeMode;
  final bool biometrics;
  final Duration lockAfter;

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
    );
  }

  @override
  bool operator ==(Object other) => other is AppSettings && _mapEquals(toMap(), other.toMap());

  @override
  int get hashCode => Object.hashAll(toMap().values);
}

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
