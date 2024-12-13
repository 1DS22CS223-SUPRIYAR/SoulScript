import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:soulscript/services/database_service.dart'; // Import DatabaseService
import 'package:soulscript/screens/password_screen.dart'; // Import PasswordScreen

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService(); // Instance of DatabaseService

  // Google sign-in method
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
      await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Redirect to the password screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordScreen(uid: user.uid), // Navigate to PasswordScreen
          ),
        );
      }

      return user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // GitHub sign-in method
  Future<User?> signInWithGitHub(BuildContext context, String token) async {
    try {
      final AuthCredential credential = GithubAuthProvider.credential(token);
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Redirect to the password screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordScreen(uid: user.uid), // Navigate to PasswordScreen
          ),
        );
      }

      return user;
    } catch (e) {
      print('GitHub Sign-In Error: $e');
      return null;
    }
  }

  // Sign-out method
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
