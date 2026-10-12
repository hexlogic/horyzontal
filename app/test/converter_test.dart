import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/features/tasks/angles_page.dart';
import 'package:horyzontal/features/tasks/converter_page.dart';

import 'helpers.dart';

void main() {
  testWidgets('coordinate converter shows the point in every system', (tester) async {
    await tester.pumpWidget(testApp(const ConverterPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '50.4501, 30.5234');
    await tester.pumpAndSettle();
    expect(find.text('5593957 6324233'), findsOneWidget); // СК-42 6°
    expect(find.text('36U UA 24182 91607'), findsOneWidget);
    expect(find.text('36U 324182 5591608'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'nonsense');
    await tester.pumpAndSettle();
    expect(find.text('Не вдалося розпізнати координати'), findsOneWidget);
    expect(find.text('5593957 6324233'), findsNothing);
  });

  testWidgets('angle converter', (tester) async {
    await tester.pumpWidget(testApp(const AnglesPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '90');
    await tester.pumpAndSettle();
    expect(find.text('15-00'), findsOneWidget);
    expect(find.text('16-00'), findsOneWidget);
    expect(find.text('90°00\'00.0"'), findsOneWidget);
  });
}
