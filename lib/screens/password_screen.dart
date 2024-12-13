import 'package:flutter/material.dart';
import 'package:soulscript/screens/home.dart';
import 'package:soulscript/services/database_service.dart'; // Import DatabaseService

class PasswordScreen extends StatefulWidget {
  final String uid;

  PasswordScreen({required this.uid});

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordSet = false;
  bool _isPasswordVerified = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfPasswordIsSet();
  }

  // Check if the user already has a password set
  Future<void> _checkIfPasswordIsSet() async {
    bool isPasswordSet = await _dbService.isPasswordSet(widget.uid);
    setState(() {
      _isPasswordSet = isPasswordSet;
    });
  }

  // Set a new password for the user
  Future<void> _setPassword() async {
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (password == confirmPassword) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _dbService.setPasswordForUser(widget.uid, password);
        // After setting the password, navigate to home or next screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(), // Navigate to PasswordScreen
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('Error setting password: $e');
      }
    } else {
      print('Passwords do not match');
    }
  }

  // Verify the existing password for the user
  Future<void> _verifyPassword() async {
    String password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    bool isVerified = await _dbService.verifyPassword(widget.uid, password);

    setState(() {
      _isLoading = false;
      _isPasswordVerified = isVerified;
    });

    if (_isPasswordVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(), // Navigate to PasswordScreen
        ),
      );
    } else {
      print('Incorrect password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isPasswordSet ? "Verify Your Password" : "Set Your Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: _isPasswordSet ? 'Enter Password' : 'Enter New Password'),
              obscureText: !_isPasswordVisible,
            ),
            if (!_isPasswordSet)
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: !_isPasswordVisible,
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isPasswordSet ? _verifyPassword : _setPassword,
              child: _isLoading ? CircularProgressIndicator() : Text(_isPasswordSet ? 'Verify Password' : 'Set Password'),
            ),
            IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
