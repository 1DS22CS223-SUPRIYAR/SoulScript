import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth for current user
import 'package:intl/intl.dart'; // For formatting dates
import 'package:soulscript/screens/update_screnn.dart';

class JournalEntriesByLabelView extends StatelessWidget {
  final String label;

  JournalEntriesByLabelView({required this.label});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Journal Entries")),
        body: Center(
          child: Text(
            "You need to log in to view your journal entries.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final userId = currentUser.uid; // Get the current user's ID

    return Scaffold(
      appBar: AppBar(
        title: Text("Journal Entries"),
        backgroundColor: Colors.deepPurple, // Consistent app bar color
        elevation: 0,
      ),
      body: Column(
        children: [
          // Cover Page with Label
          Container(
            color: Colors.deepPurple.shade200,
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "Entries with Label: $label",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Fetch and Display Firestore Data
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('journal_entries')
                  .where('label', isEqualTo: label)
                  .where('uid', isEqualTo: userId) // Filter by current user's ID
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No entries found for this label.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final entries = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final Timestamp createdTimestamp = entry['creation_date'];
                    final Timestamp? lastUpdatedTimestamp = entry['last_update'];

                    final createdDate = createdTimestamp.toDate();
                    final lastUpdatedDate = lastUpdatedTimestamp?.toDate();

                    return Card(
                      margin: EdgeInsets.all(10.0),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12.0),
                        title: Text(
                          entry['title'],
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Created: ${DateFormat('d MMMM yyyy, hh:mm a').format(createdDate)}",
                              style: TextStyle(color: Colors.deepPurple.shade300),
                            ),
                            Text(
                              "Last updated: ${lastUpdatedDate != null ? DateFormat('d MMMM yyyy, hh:mm a').format(lastUpdatedDate) : 'Unknown'}",
                              style: TextStyle(color: Colors.deepPurple.shade300),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('journal_entries')
                                    .doc(entry.id)
                                    .delete();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.open_in_new, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateScreen(entryId: entry.id),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
