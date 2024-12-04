import 'package:soulscript/screens/authenticate/authenticate.dart';
import 'package:flutter/material.dart';

// Assuming you have a Home widget or an authenticated view.
// import 'package:soulscript/screens/home/home.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simulate user being null or not. Replace this with actual logic for checking user.
    final user = null; // Or some actual logic to fetch the current user.

    // Ensure the method always returns a Widget.
    if (user == null) {
      return Authenticate();
    } else {
      return Authenticate(); // Make sure to replace this with your actual authenticated view widget.
    }
  }
}
