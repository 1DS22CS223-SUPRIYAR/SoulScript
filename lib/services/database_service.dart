import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Check if a password is set for the user
  Future<bool> isPasswordSet(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        return data['password'] != null;
      }
    } catch (e) {
      debugPrint('Error checking if password is set: $e');
    }
    return false;
  }

  /// Set the password for the user
  Future<void> setPasswordForUser(String uid, String password) async {
    try {
      await _db.collection('users').doc(uid).set(
        {
          'password': password,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error saving password: $e');
    }
  }

  /// Verify the user's password
  Future<bool> verifyPassword(String uid, String password) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        return data['password'] == password;
      }
    } catch (e) {
      debugPrint('Error verifying password: $e');
    }
    return false;
  }

  Future<bool> saveRichJournalEntry({
    required String label,
    required List<dynamic> content, // Updated type to match Quill's Delta JSON
    required List<String> imageUrls,
    required String uid,
  }) async {
    try {
      // Generate a new unique document for the journal entry
      DocumentReference docRef = _db.collection('journal_entries').doc();

      // Create the entry data
      Map<String, dynamic> entryData = {
        'uid': uid,
        'label': label,
        'content': content, // Save Quill's Delta JSON
        'imageUrls': imageUrls,
        'dateTime': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await docRef.set(entryData);

      return true;
    } catch (e) {
      print('Error saving journal entry: $e');
      return false;
    }
  }
}
