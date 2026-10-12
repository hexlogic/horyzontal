import 'package:flutter/material.dart';

import '../../core/labels.dart';
import '../../l10n/app_localizations.dart';

/// Versions with release notes, newest first; the notes live in the ARB
/// file, one line per item.
const releaseVersions = ['0.3.0', '0.2.0', '0.1.0'];

List<String> releaseNotes(AppLocalizations l, String version) => switch (version) {
      '0.3.0' => l.notes030,
      '0.2.0' => l.notes020,
      '0.1.0' => l.notes010,
      _ => '',
    }
        .split('\n')
        .where((s) => s.isNotEmpty)
        .toList();

class WhatsNewPage extends StatelessWidget {
  const WhatsNewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.whatsNew)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final version in releaseVersions) ...[
            Text(l.aboutVersion(version), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final n in releaseNotes(l, version))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [const Text('•  '), Expanded(child: Text(n))],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
