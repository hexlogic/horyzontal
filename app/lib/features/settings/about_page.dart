import 'package:flutter/material.dart';

import '../../core/labels.dart';

/// Version string, injected at build time with `--dart-define=APP_VERSION=`.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    Widget section(String title, String text) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.appTitle, style: theme.textTheme.headlineSmall),
          Text(l.aboutVersion(appVersion), style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(l.aboutDescription),
          const SizedBox(height: 8),
          Text(l.aboutLicense),
          section(l.aboutTransforms, l.aboutTransformsText),
          section(l.aboutData, l.aboutDataText),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: l.appTitle,
              applicationVersion: appVersion,
            ),
            child: Text(MaterialLocalizations.of(context).viewLicensesButtonLabel),
          ),
        ],
      ),
    );
  }
}
