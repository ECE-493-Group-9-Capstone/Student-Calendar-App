import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_app/main.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import './mock.dart';
import 'services/auth_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User])
void main() {
  setupFirebaseAuthMocks();

  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockUser.uid).thenReturn('test_uid');
    when(mockUser.email).thenReturn('test@example.com');
    when(mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => Stream.value(mockUser));
  });

  testWidgets('App initializes and displays AuthWrapper',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(AuthWrapper), findsOneWidget);
  });
}
