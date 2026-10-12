import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horyzontal/core/db/database.dart';
import 'package:horyzontal/core/secure_store.dart';
import 'package:horyzontal/core/settings.dart';
import 'package:horyzontal/features/security/lock.dart';
import 'package:horyzontal/features/security/pin_store.dart';
import 'package:horyzontal/l10n/app_localizations.dart';

const testKey = '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';

/// [child] (or [router]) inside a localized MaterialApp with an in-memory
/// encrypted database and secure store.
Widget testApp(
  Widget? child, {
  AppSettings settings = const AppSettings(),
  MemorySecureStore? store,
  bool pinEnabled = false,
  GoRouter? router,
}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true; // one per test
  final s = store ?? MemorySecureStore();
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(AppDatabase.memory(testKey)),
      initialSettingsProvider.overrideWithValue(settings),
      secureStoreProvider.overrideWithValue(s),
      pinStoreProvider.overrideWithValue(PinStore(s, iterations: 10)),
      initialPinEnabledProvider.overrideWithValue(pinEnabled),
    ],
    child: router != null
        ? MaterialApp.router(
            locale: const Locale('uk'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: _delegates,
            routerConfig: router,
          )
        : MaterialApp(
            locale: const Locale('uk'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: _delegates,
            home: child,
          ),
  );
}

const _delegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
