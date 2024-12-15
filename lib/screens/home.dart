import 'package:flutter/material.dart';
import 'package:soulscript/main.dart';
import 'package:table_calendar/table_calendar.dart'; // For calendar view
import 'package:firebase_auth/firebase_auth.dart'; // For user authentication
import 'package:soulscript/screens/editor_screen.dart';
import 'package:soulscript/main.dart';
import 'package:soulscript/screens/journal_entries_screen.dart';
import 'package:soulscript/screens/journal_entries_by_label_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get logged-in user

    return Scaffold(
      appBar: AppBar(
        title: Text('SoulScript'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? "Username"),
              accountEmail: Text(user?.email ?? "No email"),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null ? Icon(Icons.person) : null,
              ),
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Compose'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Editor(
                            entryId: null), // Pass entryId to the Editor page
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sign Out'),
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyApp()),
                        (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sign Out Failed: ${e.toString()}')),
                  );
                }
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.heart_broken_rounded),
              title: Text('Personal'),
              onTap: () => _showJournalsByTag(context, 'Personal'),
            ),
            ListTile(
              leading: Icon(Icons.search_rounded),
              title: Text('Ideas'),
              onTap: () => _showJournalsByTag(context, 'Ideas'),
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Dialy'),
              onTap: () => _showJournalsByTag(context, 'Daily'),
            ),
            ListTile(
              leading: Icon(Icons.travel_explore),
              title: Text('Travel'),
              onTap: () => _showJournalsByTag(context, 'Travel'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Calendar View
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 1, 1),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        JournalEntriesView(selectedDate: selectedDay),

                  )
              );
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showJournalsByTag(BuildContext context, String label) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntriesByLabelView(label: label),
      ),
    );
  }
}