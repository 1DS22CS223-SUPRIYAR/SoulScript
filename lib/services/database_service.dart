import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Check if password is set for the user
  Future<bool> isPasswordSet(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc['password'] != null) {
        return true;
      }
    } catch (e) {
      print('Error checking if password is set: $e');
    }
    return false;
  }

  // Set the password for the user
  Future<void> setPasswordForUser(String uid, String password) async {
    try {
      await _db.collection('users').doc(uid).set({
        'password': password,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving password: $e');
    }
  }

  // Verify the user's password
  Future<bool> verifyPassword(String uid, String password) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc['password'] == password) {
        return true;
      }
    } catch (e) {
      print('Error verifying password: $e');
    }
    return false;
  }
}
