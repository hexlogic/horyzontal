import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/features/tasks/sky_page.dart';
import 'package:horyzontal/l10n/app_localizations_uk.dart';

import 'helpers.dart';

void main() {
  testWidgets('Sun and Moon over Kyiv with the countdown to sunrise', (tester) async {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(SkyPage(clock: () => DateTime.utc(2026, 10, 12))));
    await tester.pumpAndSettle();
    expect(find.text('Вкажіть місце, щоб побачити Сонце й Місяць'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '50.4501, 30.5234');
    await tester.tap(find.text('UTC'));
    await tester.pump();
    expect(find.text('Зараз · 12.10.2026 00:00:00'), findsOneWidget);
    // Sunrise about 04:15 UTC; the countdown runs from 00:00:00.
    final sunrise = find.ancestor(of: find.text('Схід Сонця'), matching: find.byType(ListTile));
    expect(find.descendant(of: sunrise.first, matching: find.textContaining('12.10.2026 04:15')), findsOneWidget);
    final countdown = find.byWidgetPredicate((w) => w is Text && RegExp(r'^04:1[45]:\d\d$').hasMatch(w.data ?? ''));
    expect(find.descendant(of: sunrise.first, matching: countdown), findsOneWidget);
    expect(find.textContaining('Молодий місяць, росте'), findsOneWidget);
    expect(find.text('Схід Сонця'), findsNWidgets(2)); // today and tomorrow

    // The timer must not outlive the page.
    await tester.pumpWidget(const SizedBox());
  });

  test('countdown format', () {
    final l = AppLocalizationsUk();
    expect(formatCountdown(const Duration(hours: 3, minutes: 5, seconds: 9), l), '03:05:09');
    expect(formatCountdown(const Duration(days: 1, hours: 2, seconds: 1), l), '1 д 02:00:01');
  });
}
