import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soulscript/screens/update_screnn.dart';

class JournalEntriesView extends StatelessWidget {
  final DateTime selectedDate;

  JournalEntriesView({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "You need to log in to view your journal entries.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final userId = currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Journal Entries for ${DateFormat('d MMMM yyyy').format(selectedDate)}"),
        backgroundColor: Colors.deepPurple, // Custom color for app bar
      ),
      body: Column(
        children: [
          // Cover Page with Selected Date
          Container(
            color: Colors.deepPurpleAccent, // Updated color for the cover page
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "Entries for ${DateFormat('d MMMM yyyy').format(selectedDate)}",
                style: TextStyle(
                  fontSize: 24,
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
                  .where('creation_date', isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
              ))
                  .where('creation_date', isLessThan: Timestamp.fromDate(
                DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1),
              ))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No entries found for this date.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final entries = snapshot.data!.docs.where((doc) {
                  return doc['uid'] == userId; // Add the uid filter here
                }).toList();

                // If no entries match the uid filter
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      "No entries found for this user.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final Timestamp createdTimestamp = entry['creation_date'];
                    final Timestamp? lastUpdatedTimestamp = entry['last_update'];

                    final createdDate = createdTimestamp.toDate();
                    final lastUpdatedDate = lastUpdatedTimestamp?.toDate();

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      color: Colors.white, // Background color for each card
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12.0),
                        title: Text(
                          entry['title'],
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Created: ${DateFormat('d MMMM yyyy, hh:mm a').format(createdDate)}",
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            Text(
                              "Last updated: ${lastUpdatedDate != null ? DateFormat('d MMMM yyyy, hh:mm a').format(lastUpdatedDate) : 'Unknown'}",
                              style: TextStyle(fontSize: 14, color: Colors.black54),
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
