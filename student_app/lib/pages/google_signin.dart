import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '383013120334-e7qqaa8rjbs1cdp831mddske427s4a0r.apps.googleusercontent.com', // Replace with your Web Client ID
  );

  Future<String?> loginWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        log("Google sign-in canceled by the user.");
        return "Sign-in canceled.";
      }

      // Check if the email is a UAlberta email
      if (!googleUser.email.endsWith("@ualberta.ca")) {
        await _googleSignIn.signOut(); // Sign out the Google account
        log("Non-UAlberta email used: ${googleUser.email}");
        return "Please use your UAlberta email to sign in.";
      }

      // Obtain the auth details from the Google Sign-In process
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a credential using the token and access token
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      log("User signed in: ${userCredential.user?.displayName}");
      return "Welcome, ${userCredential.user?.displayName}!";
    } catch (e) {
      log("Error during Google sign-in: $e");
      return "An error occurred during sign-in: $e";
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      log("User signed out successfully.");
    } catch (e) {
      log("Error during sign-out: $e");
    }
  }
}
