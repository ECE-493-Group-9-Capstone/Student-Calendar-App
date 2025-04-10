import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:student_app/features/home/home_page.dart';
import 'package:student_app/utils/social_graph.dart';
import 'package:student_app/services/firebase_service.dart';
import '../mock.dart';

import 'home_page_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseService>(),
])
void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('HomePage', () {
    testWidgets('renders HomePage', (tester) async {
      // Mock FirebaseService
      final mockFirebaseService = MockFirebaseService();

      // Stub methods for FirebaseService
      when(mockFirebaseService.getAllUsers()).thenAnswer((_) async => []);
      when(mockFirebaseService.getUserFriends(any)).thenAnswer((_) async => []);

      // Initialize SocialGraph with the mocked FirebaseService
      SocialGraph(firebaseService: mockFirebaseService);

      // Wrap HomePage in MaterialApp to provide Directionality
      await tester.pumpWidget(MaterialApp(
        home: HomePage(),
      ));

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
