import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/labels.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget tile(IconData icon, String title, String subtitle, String path) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(path),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.tabTasks)),
      body: ListView(
        children: [
          tile(Icons.swap_horiz, l.taskConverter, l.taskConverterSubtitle, '/tasks/converter'),
          tile(Icons.architecture, l.taskAngles, l.taskAnglesSubtitle, '/tasks/angles'),
          tile(Icons.call_made, l.taskDirect, l.taskDirectSubtitle, '/tasks/direct'),
          tile(Icons.straighten, l.taskInverse, l.taskInverseSubtitle, '/tasks/inverse'),
        ],
      ),
    );
  }
}
