import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/calendar/calendar_page.dart';
import '../mock.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('CalendarPage', () {
    testWidgets('renders CalendarPage', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: CalendarPage(),
      ));
      expect(find.byType(CalendarPage), findsOneWidget);
    });
  });
}
