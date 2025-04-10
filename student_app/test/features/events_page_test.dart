import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/events/events_page.dart';
import '../mock.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });
  group('EventsPage', () {
    testWidgets('renders EventsPage', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const EventsPage(),
      ));
      expect(find.byType(EventsPage), findsOneWidget);
    });
  });
}
