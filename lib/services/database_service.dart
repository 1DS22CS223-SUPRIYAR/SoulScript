import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Check if a password is set for the user
  Future<bool> isPasswordSet(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        return data['password'] != null;
      }
    } catch (e) {
      print('Error checking if password is set: $e');
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
      print('Error saving password: $e');
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
      print('Error verifying password: $e');
    }
    return false;
  }

  /// Save or update journal entry
  Future<bool> saveJournalEntry({
    String? entryId, // Optional parameter for existing entry ID
    required String label,
    required String content,
    required String base64Image,
    String? uid,
    required String title,
  }) async {
    try {
      uid = uid ?? '';
      if (entryId != null) {
        // If entryId is provided, it's an update
        // Parse the entryId to milliseconds since it's expected to be a timestamp
        DateTime entryDate = DateTime.fromMillisecondsSinceEpoch(int.parse(entryId));

        // Query the 'journal_entries' collection in Firestore by the 'created_at' timestamp
        QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
            .collection('journal_entries')
            .where('created_date', isEqualTo: entryDate)
            .get();
        if (snapshot.docs.isNotEmpty) {
          var journalEntry = snapshot.docs.first;
          await _db.collection('journal_entries').doc(journalEntry.id).update({
            'label': label,
            'content': content,
            'images': base64Image,  // Update the base64 image here
            'title': title,
            'last_update': FieldValue.serverTimestamp(),  // Only update the last update timestamp
          });
          print("Journal entry updated with ID: $entryId");
        } else {
          // If the entry does not exist, create a new one
          await _createJournalEntry(label, content, base64Image, uid, title);
          print("Journal entry created with new ID.");
          return false;
        }
        return true;
      }
      else{
        _createJournalEntry(label = label, content = content, base64Image = base64Image,uid = uid, title = title);
        return true;

      }
    } catch (e) {
      print('Error in saveJournalEntry: $e');
    }
    return false;
  }

  /// Create a new journal entry
  Future<void> _createJournalEntry(
      String label,
      String content,
      String base64Image,
      String uid,
      String title,
      ) async {
    try {
        await _db.collection('journal_entries').add({
          'label': label,
          'content': content,
          'images': base64Image,
          'uid': uid,
          'title': title,
          'creation_date': FieldValue.serverTimestamp(),
          'last_update': FieldValue.serverTimestamp(),
        });
    } catch (e) {
      print('Error creating journal entry: $e');
    }

  }

  // Convert Image to Base64 String
  Future<String> convertImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    Uint8List compressedBytes = compressImage(Uint8List.fromList(imageBytes));
    String base64String = base64Encode(compressedBytes);
    return base64String;
  }

  /// Retrieve journal entries for the user
  Future<List<Map<String, dynamic>>> getJournalEntries(String uid) async {
    try {
      QuerySnapshot snapshot = await _db.collection('journal_entries')
          .where('uid', isEqualTo: uid)
          .get();
      List<Map<String, dynamic>> journalEntries = [];
      snapshot.docs.forEach((doc) {
        journalEntries.add(doc.data() as Map<String, dynamic>);
      });
      return journalEntries;
    } catch (e) {
      print('Error retrieving journal entries: $e');
      return [];
    }
  }

  /// Delete journal entry by entryId
  Future<void> deleteJournalEntry(String entryId) async {
    try {
      await _db.collection('journal_entries').doc(entryId).delete();
      print("Journal entry deleted with ID: $entryId");
    } catch (e) {
      print('Error deleting journal entry: $e');
    }
  }

  /// Retrieve user details
  Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error retrieving user details: $e');
    }
    return null;
  }

  // Compress Image to reduce its size
  Uint8List compressImage(Uint8List originalBytes) {
    img.Image? image = img.decodeImage(originalBytes);
    if (image != null) {
      // Compress the image to a lower quality (e.g., 80)
      return Uint8List.fromList(img.encodeJpg(image, quality: 80));
    }
    return originalBytes;
  }
}
