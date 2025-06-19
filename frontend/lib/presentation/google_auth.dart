import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // ✅ Web Login using popup
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await FirebaseAuth.instance.signInWithPopup(googleProvider);
      }

      // ✅ Android/iOS using google_sign_in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('❌ Google sign-in failed: $e');
      return null;
    }
  }
}
