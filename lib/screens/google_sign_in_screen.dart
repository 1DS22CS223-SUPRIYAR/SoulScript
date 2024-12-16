import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soulscript/services/auth_service.dart'; // Import AuthService
import 'package:soulscript/screens/password_screen.dart'; // Import PasswordScreen
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome for Google Icon

class GoogleSignInScreen extends StatefulWidget {
  @override
  _GoogleSignInScreenState createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  void _signInWithGoogle(BuildContext context) async {
    User? user = await _authService.signInWithGoogle(context);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordScreen(uid: user.uid),
        ),
      );
    } else {
      print("Google Sign-In failed.");
    }
  }

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
      appBar: AppBar(
        title: Text("Sign In with Google"),
        backgroundColor: Colors.purple.shade700, // Purple AppBar for consistency with the theme
        elevation: 0, // No elevation for a flat look
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.network(
                  'https://cdn-icons-png.flaticon.com/512/3135/3135704.png', // The image URL
                  height: 150, // Adjust height as needed
                  width: 150, // Adjust width as needed
                ),
                SizedBox(height: 40),

                // App Description
                Text(
                  "Welcome to SoulScript",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),

                // Google Sign-In Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // White background for the button
                    foregroundColor: Colors.purple.shade700, // Purple text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: () => _signInWithGoogle(context),
                  icon: Icon(
                    FontAwesomeIcons.google, // Google Icon
                    color: Colors.purple.shade700,
                  ),
                  label: Text(
                    "Sign in with Google",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
