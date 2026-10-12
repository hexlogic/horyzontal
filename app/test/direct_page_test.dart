import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/features/tasks/direct_page.dart';

import 'helpers.dart';

void main() {
  testWidgets('direct problem on the plane in СК-42 and in kilometres', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(const DirectPage()));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '50.4501, 30.5234'); // СК-42: 5593957 6324233
    await tester.enterText(fields.at(1), '1');
    await tester.tap(find.text('км'));
    await tester.enterText(fields.at(2), '90');
    await tester.pumpAndSettle();
    expect(find.textContaining('СК-42, прямокутні, зона 6'), findsOneWidget);
    expect(find.text('5593957 6325233'), findsOneWidget);
    expect(find.text('270.00°'), findsOneWidget); // back grid bearing
  });
}
