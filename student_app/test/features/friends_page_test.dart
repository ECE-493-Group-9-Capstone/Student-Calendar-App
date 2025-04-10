import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/friends/friends_page.dart';
import '../mock.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });
  group('FriendsPage', () {
    testWidgets('renders FriendsPage', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const FriendsPage(),
      ));
      expect(find.byType(FriendsPage), findsOneWidget);
    });
  });
}
