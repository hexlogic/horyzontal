import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_services.dart';
import 'core/router.dart';
import 'core/settings.dart';
import 'features/security/lock_screen.dart';
import 'l10n/app_localizations.dart';

const _seed = Color(0xFF3A5A40);

/// Five tabs with Ukrainian labels ("Налаштування") need a smaller label
/// font than Material's default to stay on one line.
ThemeData _theme(Brightness b) => ThemeData(
      colorSchemeSeed: _seed,
      brightness: b,
      navigationBarTheme: const NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, letterSpacing: 0)),
      ),
    );

class HoryzontalApp extends ConsumerStatefulWidget {
  const HoryzontalApp({super.key});

  @override
  ConsumerState<HoryzontalApp> createState() => _HoryzontalAppState();
}

class _HoryzontalAppState extends ConsumerState<HoryzontalApp> {
  final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: themeMode,
      locale: const Locale('uk'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) => LockGate(child: AppServices(child: child!)),
    );
  }
}
