import 'package:flutter/material.dart';

import '../../core/labels.dart';

/// Release notes, newest first. Shown once after an update.
const releaseNotes = <(String, List<String>)>[
  ('0.2.0', [
    'Мапа: онлайн OpenFreeMap і офлайн-пакети областей з рельєфом, кілька пакетів одночасно',
    'Об\'єкти з умовними знаками НАТО APP-6, шари, журнал з фільтрами й пошуком',
    'Обмін: QR для точок, шари по Wi-Fi без інтернету, файли .hrz, KML/KMZ, GPX, CoT і пакети даних ATAK',
    'Безпека: розмиття в перемикачі застосунків, заборона знімків екрана (Android), екстрене видалення, режим «Тільки офлайн»',
  ]),
  ('0.1.0', [
    'Конвертер координат WGS 84, СК-42, УСК-2000, UTM, MGRS і кутів',
    'Пряма й обернена геодезичні задачі, компас з істинною північчю',
    'PIN-код, біометрія, зашифрована база',
  ]),
];

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
          for (final (version, notes) in releaseNotes) ...[
            Text(l.aboutVersion(version), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final n in notes)
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
