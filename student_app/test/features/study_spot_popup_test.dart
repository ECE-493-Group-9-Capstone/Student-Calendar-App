import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/map/study_spot_popup.dart';
import '../mock.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });
  group('StudySpotPopup', () {
    testWidgets('renders StudySpotPopup', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudySpotPopup(
            studySpot: {},
          ),
        ),
      );
      expect(find.byType(StudySpotPopup), findsOneWidget);
    });
  });
}
