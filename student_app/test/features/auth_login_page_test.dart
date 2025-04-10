import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/auth/auth_login_page.dart';
import '../mock.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });
  group('AuthLoginPage', () {
    testWidgets('renders AuthLoginPage', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AuthLoginPage(),
      ));
      expect(find.byType(AuthLoginPage), findsOneWidget);
    });
  });
}
