import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
    serverClientId:
        '383013120334-e7qqaa8rjbs1cdp831mddske427s4a0r.apps.googleusercontent.com',
  );

  Future<Map<String, String>?> loginWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      log("Google sign-in canceled by the user.");
      return null;
    }

    if (!googleUser.email.endsWith("@ualberta.ca")) {
      await _googleSignIn.signOut();
      log("Non-UAlberta email used: ${googleUser.email}");
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    log("User signed in: ${userCredential.user?.displayName}");

    final String? profilePicUrl = googleUser.photoUrl; // or userCredential.user?.photoURL
    log("Profile picture URL: $profilePicUrl");

    // Process ccid only once.
    final String ccid = userCredential.user?.email?.split('@')[0] ??
        userCredential.user!.uid;

    return {
      'displayName': userCredential.user?.displayName ?? "New User",
      'ccid': ccid,
      'photoURL': profilePicUrl ?? "",
    };
  } catch (e) {
    log("Error during Google sign-in: $e");
    return null;
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

  Future<String?> getAccessToken() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signIn();
    final auth = await account?.authentication;

    return auth?.accessToken;
  }
}
