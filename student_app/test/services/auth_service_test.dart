import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:student_app/services/auth_service.dart';

// Generate mocks for FirebaseAuth and GoogleSignIn
@GenerateMocks([
  FirebaseAuth,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  User,
  UserCredential
])
import 'auth_service_test.mocks.dart';

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthService authService;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    authService = AuthService(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('AuthService', () {
    test('loginWithGoogle returns user data on successful login', () async {
      final mockGoogleSignInAccount = MockGoogleSignInAccount();
      final mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication)
          .thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.idToken).thenReturn('mockIdToken');
      when(mockGoogleSignInAuthentication.accessToken)
          .thenReturn('mockAccessToken');
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.displayName).thenReturn('Test User');
      when(mockUser.email).thenReturn('testuser@example.com');
      when(mockGoogleSignInAccount.photoUrl)
          .thenReturn('http://example.com/photo.jpg');

      final result = await authService.loginWithGoogle();

      expect(result, isNotNull);
      expect(result!['displayName'], 'Test User');
      expect(result['ccid'], 'testuser');
      expect(result['photoURL'], 'http://example.com/photo.jpg');
    });

    test('loginWithGoogle returns null when user cancels login', () async {
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      final result = await authService.loginWithGoogle();

      expect(result, isNull);
    });

    test('logout signs out user successfully', () async {
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await authService.logout();

      verify(mockGoogleSignIn.signOut()).called(1);
      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('getAccessToken returns access token', () async {
      final mockGoogleSignInAccount = MockGoogleSignInAccount();
      final mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();

      when(mockGoogleSignIn.currentUser).thenReturn(mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication)
          .thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.accessToken)
          .thenReturn('mockAccessToken');

      final result = await authService.getAccessToken();

      expect(result, 'mockAccessToken');
    });
  });
}
