import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/map/map_page.dart';
import '../mock.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('MapPage', () {
    testWidgets('renders MapPage', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MapPage(),
      ));
      expect(find.byType(MapPage), findsOneWidget);
    });
  });
}
