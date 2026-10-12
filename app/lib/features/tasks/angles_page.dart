import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../core/widgets/angle_input.dart';
import '../../core/widgets/copy_tile.dart';

class AnglesPage extends ConsumerStatefulWidget {
  const AnglesPage({super.key});

  @override
  ConsumerState<AnglesPage> createState() => _AnglesPageState();
}

class _AnglesPageState extends ConsumerState<AnglesPage> {
  late AngleFormat _format = ref.read(settingsProvider).angleInput;
  double? _degrees;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = _degrees;
    return Scaffold(
      appBar: AppBar(title: Text(l.taskAngles)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AngleInput(
            label: l.angle,
            format: _format,
            onFormatChanged: (f) => setState(() => _format = f),
            onChanged: (v) => setState(() => _degrees = v),
          ),
          if (d != null) ...[
            const SizedBox(height: 8),
            for (final f in AngleFormat.values)
              CopyTile(
                label: angleFormatName(l, f),
                value: formatAngle(
                  d,
                  f,
                  decimals: f == AngleFormat.deg360 ? 4 : (f == AngleFormat.dms ? 1 : null),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
