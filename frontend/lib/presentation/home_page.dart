import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:frontend/service/api_service.dart';
import 'package:frontend/presentation/google_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ----------------------------
  // Google Sign-In Handler (Fixed)
  // ----------------------------
  Future<void> _signInWithGoogle() async {
    try {
      // Option 1: Use your AuthService (recommended if you have it set up)
      final userCredential = await AuthService.signInWithGoogle();
      if (userCredential != null) {
        print('✅ Google Sign-in Success: ${userCredential.user?.email}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome ${userCredential.user?.displayName ?? userCredential.user?.email}!')),
          );
        }
        // Navigate to your main app screen here
        // Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        print('❌ Google Sign-in Cancelled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign-in was cancelled')),
          );
        }
      }
    } catch (e) {
      print('❗ Google Sign-in Error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
        );
      }
    }
  }

  // Alternative direct implementation (use this if AuthService is not working)
  Future<void> _signInWithGoogleDirect() async {
    try {
      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the Google Sign-In dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign-in was cancelled')),
          );
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google user credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome ${userCredential.user?.displayName ?? userCredential.user?.email}!')),
        );
      }
      
      // Navigate to your main app screen
      // Navigator.pushReplacementNamed(context, '/dashboard');
      
    } catch (e) {
      print('Google sign-in error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: Please try again')),
        );
      }
    }
  }

  // ----------------------------
  // Navigate to Email Page
  // ----------------------------
  void _goToEmailAuth() {
    Navigator.pushNamed(context, '/email');
  }

  // ----------------------------
  // Navigate to Phone Page
  // ----------------------------
  void _goToPhoneAuth() {
    Navigator.pushNamed(context, '/phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Google Sign-In Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: Colors.grey, width: 1),
                ),
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.g_mobiledata, size: 24);
                  },
                ),
                label: const Text('Sign in with Google'),
                onPressed: _signInWithGoogle, // Use the cleaned up method
              ),
              const SizedBox(height: 20),

              // Email/Password Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Register / Sign In with Email'),
                onPressed: _goToEmailAuth,
              ),
              const SizedBox(height: 20),

              // Phone Number Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Sign in with Phone Number'),
                onPressed: _goToPhoneAuth,
              ),
            ],
          ),
        ),
      ),
    );
  }
}