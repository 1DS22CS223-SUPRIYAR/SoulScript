import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for user details
import 'package:soulscript/services/auth_service.dart';
import 'package:soulscript/screens/auth_screen.dart';// Import AuthService

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  // Method to handle sign-out
  void _signOut(BuildContext context) async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()), // Replace with your login screen
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _signOut(context), // Handle sign-out
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display user's email if logged in
            user != null
                ? Text(
              'Welcome, ${user.email}',
              style: TextStyle(fontSize: 24),
            )
                : Text(
              'No user logged in',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            // Placeholder for more content
            Text(
              'This is your Home screen!',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
