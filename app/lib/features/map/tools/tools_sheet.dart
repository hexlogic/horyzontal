import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/labels.dart';
import 'tool_panel.dart';
import 'tool_state.dart';

/// Picker of map tools; the chosen one starts empty.
Future<void> showToolsSheet(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final tool = await showModalBottomSheet<MapTool>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l.tools, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final t in MapTool.values)
            ListTile(
              leading: Icon(toolIcon(t)),
              title: Text(toolName(l, t)),
              onTap: () => Navigator.pop(context, t),
            ),
        ],
      ),
    ),
  );
  if (tool != null) ref.read(mapToolProvider.notifier).start(tool);
}
