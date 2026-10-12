import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/compass/compass_page.dart';
import '../features/security/pin_setup_page.dart';
import '../features/settings/about_page.dart';
import '../features/settings/settings_page.dart';
import '../features/tasks/angles_page.dart';
import '../features/tasks/converter_page.dart';
import '../features/tasks/direct_page.dart';
import '../features/tasks/inverse_page.dart';
import '../features/tasks/tasks_page.dart';
import 'labels.dart';

/// Tabs of stage 1: tasks, compass, settings. Map and journal come in stage 2.
GoRouter buildRouter() => GoRouter(
  initialLocation: '/tasks',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tasks',
              builder: (_, _) => const TasksPage(),
              routes: [
                GoRoute(path: 'converter', builder: (_, _) => const ConverterPage()),
                GoRoute(path: 'angles', builder: (_, _) => const AnglesPage()),
                GoRoute(path: 'direct', builder: (_, _) => const DirectPage()),
                GoRoute(path: 'inverse', builder: (_, _) => const InversePage()),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/compass', builder: (_, _) => const CompassPage())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsPage(),
              routes: [
                GoRoute(path: 'about', builder: (_, _) => const AboutPage()),
                GoRoute(
                  path: 'pin/:mode',
                  builder: (_, state) =>
                      PinSetupPage(mode: PinSetupMode.values.byName(state.pathParameters['mode']!)),
                ),
              ],
            ),
          ],
        ),
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
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.calculate_outlined), label: l.tabTasks),
          NavigationDestination(icon: const Icon(Icons.explore_outlined), label: l.tabCompass),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l.tabSettings),
        ],
      ),
    );
  }
}
