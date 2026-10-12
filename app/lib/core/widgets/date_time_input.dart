import 'package:flutter/material.dart';

import '../labels.dart';

String _two(int v) => v.toString().padLeft(2, '0');

/// dd.MM.yyyy HH:mm:ss of [t] in local time, or in UTC when [utc].
String formatMoment(DateTime t, {required bool utc, bool seconds = true}) {
  final x = utc ? t.toUtc() : t.toLocal();
  final time = '${_two(x.hour)}:${_two(x.minute)}${seconds ? ':${_two(x.second)}' : ''}';
  return '${_two(x.day)}.${_two(x.month)}.${x.year.toString().padLeft(4, '0')} $time';
}

/// A moment: "now" (null, follows the clock) or a picked date and time,
/// read and shown in local time or UTC. Years are not limited.
class DateTimeInput extends StatelessWidget {
  const DateTimeInput({
    super.key,
    required this.value,
    required this.now,
    required this.utc,
    required this.onChanged,
    required this.onUtcChanged,
  });

  /// Null means now.
  final DateTime? value;
  final DateTime now;
  final bool utc;
  final ValueChanged<DateTime?> onChanged;
  final ValueChanged<bool> onUtcChanged;

  DateTime _shown(DateTime t) => utc ? t.toUtc() : t.toLocal();

  DateTime _compose(DateTime date, TimeOfDay time, int second) => utc
      ? DateTime.utc(date.year, date.month, date.day, time.hour, time.minute, second)
      : DateTime(date.year, date.month, date.day, time.hour, time.minute, second);

  Future<void> _pickDate(BuildContext context) async {
    final cur = _shown(value ?? now);
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(cur.year, cur.month, cur.day),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (d == null) return;
    onChanged(_compose(d, TimeOfDay(hour: cur.hour, minute: cur.minute), cur.second));
  }

  Future<void> _pickTime(BuildContext context) async {
    final cur = _shown(value ?? now);
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur.hour, minute: cur.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null) return;
    onChanged(_compose(cur, t, 0));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final shown = value ?? now;
    return InputDecorator(
      decoration: InputDecoration(labelText: l.skyMoment, border: const OutlineInputBorder()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value == null ? '${l.skyNow} · ${formatMoment(shown, utc: utc)}' : formatMoment(shown, utc: utc),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(l.skyPickDate),
                onPressed: () => _pickDate(context),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(l.skyPickTime),
                onPressed: () => _pickTime(context),
              ),
              if (value != null)
                TextButton(onPressed: () => onChanged(null), child: Text(l.skyNow)),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l.skyLocalTime)),
                  const ButtonSegment(value: true, label: Text('UTC')),
                ],
                selected: {utc},
                showSelectedIcon: false,
                onSelectionChanged: (s) => onUtcChanged(s.single),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
