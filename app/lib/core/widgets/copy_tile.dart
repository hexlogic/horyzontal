import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../labels.dart';

/// A label and a value; tapping copies the value.
class CopyTile extends StatelessWidget {
  const CopyTile({super.key, required this.label, required this.value, this.dense = false});

  final String label, value;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: dense,
      title: Text(label, style: theme.textTheme.labelMedium),
      subtitle: SelectableText(
        value,
        style: theme.textTheme.titleMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy_outlined),
        tooltip: context.l10n.copy,
        onPressed: () => copyToClipboard(context, value),
      ),
      onTap: () => copyToClipboard(context, value),
    );
  }
}

Future<void> copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(context.l10n.copied), duration: const Duration(seconds: 1)),
    );
}
