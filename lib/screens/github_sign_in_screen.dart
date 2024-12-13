import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soulscript/services/auth_service.dart';
import 'package:soulscript/screens/password_screen.dart';

class GitHubSignInScreen extends StatelessWidget {
  final AuthService _authService = AuthService();


  void _signInWithGitHub(BuildContext context, String token) async {
    User? user = await _authService.signInWithGitHub(context, token);

    if (user != null) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordScreen(uid: user.uid),
        ),
      );
    } else {
      print("GitHub Sign-In failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign In with GitHub")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {

            String token = "user_github_token"; // Replace with actual GitHub token
            _signInWithGitHub(context, token);
          },
          child: Text("Sign in with GitHub"),
        ),
      ),
    );
  }
}
