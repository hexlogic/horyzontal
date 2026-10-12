import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import 'hold_button.dart';
import 'wipe.dart';

class WipePage extends ConsumerStatefulWidget {
  const WipePage({super.key});

  @override
  ConsumerState<WipePage> createState() => _WipePageState();
}

class _WipePageState extends ConsumerState<WipePage> {
  bool _packs = false;
  bool _wiping = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.emergencyWipe)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.wipeText),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _packs,
            onChanged: (v) => setState(() => _packs = v ?? false),
            title: Text(l.wipePacks),
          ),
          const SizedBox(height: 24),
          if (_wiping)
            const Center(child: CircularProgressIndicator())
          else
            HoldButton(
              label: l.wipeHold,
              onConfirmed: () {
                setState(() => _wiping = true);
                emergencyWipe(ref.read(databaseProvider), packs: _packs);
              },
            ),
        ],
      ),
    );
  }
}
