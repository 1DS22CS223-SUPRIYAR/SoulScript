import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soulscript/screens/google_sign_in_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade200, Colors.purple.shade700], // Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo image from the URL
              Image.network(
                'https://cdn-icons-png.flaticon.com/512/3135/3135704.png', // The image URL
                height: 150, // Adjust height as needed
                width: 150, // Adjust width as needed
              ),
              SizedBox(height: 40),

              // App title
              Text(
                'SoulScript',
                style: GoogleFonts.pacifico(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Description text
              Text(
                'Your personal journal, your space to grow.',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),


              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Background color of the button
                  foregroundColor: Colors.purple.shade700, // Text color of the button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GoogleSignInScreen()),
                  );
                },
                icon: Icon(
                  FontAwesomeIcons.google, // Google icon from FontAwesome
                  color: Colors.purple.shade700,
                ),
                label: Text(
                  'Sign Up / Sign In with Google',
                  style: GoogleFonts.poppins(
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
    );
  }
}
