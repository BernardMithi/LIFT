import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:lift/app/app.dart';

void main() {
  testWidgets('app smoke test renders bottom navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const ui.Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const LiftApp());
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Guides'), findsOneWidget);
    expect(find.text('Workouts'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
  });
}
