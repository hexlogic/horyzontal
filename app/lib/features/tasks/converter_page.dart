import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../core/widgets/point_input.dart';
import '../../core/widgets/point_results.dart';

class ConverterPage extends ConsumerStatefulWidget {
  const ConverterPage({super.key});

  @override
  ConsumerState<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends ConsumerState<ConverterPage> {
  PointValue? _point;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = _point;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.taskConverter),
        actions: [
          if (p != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: l.share,
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: pointAsText(l, p.wgs, ref.read(settingsProvider).geoFormat)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PointInput(onChanged: (v) => setState(() => _point = v)),
          if (p != null) ...[
            const SizedBox(height: 8),
            Text(l.results, style: Theme.of(context).textTheme.titleSmall),
            PointResults(wgs: p.wgs),
          ],
        ],
      ),
    );
  }
}
