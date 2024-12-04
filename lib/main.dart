import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soulscript/models/user.dart';  // User model path
import 'package:soulscript/screens/authenticate/authenticate.dart';
// import 'package:soulscript/screens/home/home.dart';  // Home screen path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Wrapper(),
    );
  }
}

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the user from the provider
    final user = Provider.of<AppUser?>(context);

    // Return either the Home or Authenticate widget based on the user state
    if (user == null) {
      return Authenticate();  // Show Authenticate screen if no user is logged in
    } else {
      return Authenticate();  // Replace with your actual home screen widget
    }
  }
}
