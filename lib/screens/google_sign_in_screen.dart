import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soulscript/services/auth_service.dart'; // Import AuthService
import 'package:soulscript/screens/password_screen.dart'; // Import PasswordScreen

class GoogleSignInScreen extends StatefulWidget {
  @override
  _GoogleSignInScreenState createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Register observer to listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Method to handle Google Sign-In
  void _signInWithGoogle(BuildContext context) async {
    User? user = await _authService.signInWithGoogle(context);

    if (user != null) {
      // If the user is successfully signed in, redirect to PasswordScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordScreen(uid: user.uid), // Navigate to PasswordScreen
        ),
      );
    } else {
      // Handle Google sign-in failure if needed
      print("Google Sign-In failed.");
    }
  }

  // Lifecycle state change handler
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Sign out the user when the app is paused (backgrounded or closed)
      FirebaseAuth.instance.signOut();
      print("User signed out");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign In with Google")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _signInWithGoogle(context),
          child: Text("Sign in with Google"),
        ),
      ),
    );
  }
}
