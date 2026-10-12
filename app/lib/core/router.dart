import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../features/compass/compass_page.dart';
import '../features/exchange/scan_page.dart';
import '../features/exchange/transfer/transfer_page.dart';
import '../features/journal/journal_page.dart';
import '../features/layers/layer_page.dart';
import '../features/layers/layers_page.dart';
import '../features/map/map_page.dart';
import '../features/map/packs_page.dart';
import '../features/sources/source_edit_page.dart';
import '../features/sources/sources_page.dart';
import '../features/map/tools/los_page.dart';
import '../features/map/tools/profile_page.dart';
import '../features/objects/feature_editor_page.dart';
import '../features/objects/feature_sheet.dart';
import '../features/objects/symbol_picker_page.dart';
import '../features/security/pin_setup_page.dart';
import '../features/security/wipe_page.dart';
import '../features/settings/about_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/whats_new_page.dart';
import '../features/tasks/angles_page.dart';
import '../features/tasks/converter_page.dart';
import '../features/tasks/direct_page.dart';
import '../features/tasks/inverse_page.dart';
import '../features/tasks/sky_page.dart';
import '../features/tasks/tasks_page.dart';
import 'data/model.dart';
import 'labels.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() => GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/map',
      // Anything unknown (an odd link handed over by the OS) lands on the map.
      redirect: (_, state) => state.uri.scheme == 'file' ? '/map' : null,
      errorBuilder: (_, _) => const MapPage(),
      routes: [
        // Full-screen pickers that return a value to whoever pushed them.
        GoRoute(
          path: '/symbol',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, s) => SymbolPickerPage(initial: s.uri.queryParameters['sidc']),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _Shell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/map',
                builder: (_, _) => const MapPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, s) => FeatureEditorPage(
                      initial: Geodetic(
                        double.parse(s.uri.queryParameters['lat']!),
                        double.parse(s.uri.queryParameters['lon']!),
                      ),
                    ),
                  ),
                  // A polyline or polygon drawn with a map tool: vertices in extra.
                  GoRoute(
                    path: 'shape',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, s) => FeatureEditorPage(
                      kind: FeatureKind.values.byName(s.uri.queryParameters['kind']!),
                      vertices: s.extra! as List<Geodetic>,
                    ),
                  ),
                  GoRoute(
                    path: 'profile',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, s) => ProfilePage(path: s.extra! as List<Geodetic>),
                  ),
                  GoRoute(
                    path: 'los',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, s) {
                      final ab = s.extra! as List<Geodetic>;
                      return LosPage(a: ab[0], b: ab[1]);
                    },
                  ),
                  GoRoute(path: 'packs', builder: (_, _) => const PacksPage()),
                  GoRoute(
                    path: 'sources',
                    builder: (_, _) => const SourcesPage(base: '/map/sources'),
                    routes: [
                      GoRoute(path: 'edit', builder: (_, s) => SourceEditPage(id: s.uri.queryParameters['id'])),
                    ],
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/journal',
                builder: (_, _) => const JournalPage(),
                routes: [
                  GoRoute(
                    path: 'object/:id',
                    builder: (_, s) => FeaturePage(id: s.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, s) => FeatureEditorPage(id: s.pathParameters['id']),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'layers',
                    builder: (_, _) => const LayersPage(),
                    routes: [
                      GoRoute(path: ':id', builder: (_, s) => LayerPage(id: s.pathParameters['id']!)),
                    ],
                  ),
                  GoRoute(path: 'scan', builder: (_, _) => const ScanPage()),
                  GoRoute(
                    path: 'transfer',
                    builder: (_, s) => TransferPage(
                      layerIds: s.uri.queryParameters['layers']?.split(',') ?? const [],
                    ),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/tasks',
                builder: (_, _) => const TasksPage(),
                routes: [
                  GoRoute(path: 'converter', builder: (_, _) => const ConverterPage()),
                  GoRoute(path: 'angles', builder: (_, _) => const AnglesPage()),
                  GoRoute(path: 'direct', builder: (_, _) => const DirectPage()),
                  GoRoute(path: 'inverse', builder: (_, _) => const InversePage()),
                  GoRoute(path: 'sky', builder: (_, _) => const SkyPage()),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/compass', builder: (_, _) => const CompassPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsPage(),
                routes: [
                  GoRoute(path: 'about', builder: (_, _) => const AboutPage()),
                  GoRoute(path: 'whats-new', builder: (_, _) => const WhatsNewPage()),
                  GoRoute(path: 'packs', builder: (_, _) => const PacksPage()),
                  GoRoute(
                    path: 'sources',
                    builder: (_, _) => const SourcesPage(base: '/settings/sources'),
                    routes: [
                      GoRoute(path: 'edit', builder: (_, s) => SourceEditPage(id: s.uri.queryParameters['id'])),
                    ],
                  ),
                  GoRoute(path: 'wipe', builder: (_, _) => const WipePage()),
                  GoRoute(
                    path: 'pin/:mode',
                    builder: (_, state) => PinSetupPage(
                      mode: PinSetupMode.values.byName(state.pathParameters['mode']!),
                    ),
                  ),
                ],
              ),
            ]),
          ],
        ),
      ],
    );

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.map_outlined), label: l.tabMap),
          NavigationDestination(icon: const Icon(Icons.list_alt), label: l.tabJournal),
          NavigationDestination(icon: const Icon(Icons.calculate_outlined), label: l.tabTasks),
          NavigationDestination(icon: const Icon(Icons.explore_outlined), label: l.tabCompass),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l.tabSettings),
        ],
      ),
    );
  }
}
