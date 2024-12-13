import 'package:flutter/material.dart';
import 'package:soulscript/main.dart';
import 'package:table_calendar/table_calendar.dart'; // For calendar view
import 'package:firebase_auth/firebase_auth.dart'; // For user authentication
import 'package:soulscript/screens/editor_screen.dart';
import 'package:soulscript/main.dart';// Import TextEditor

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
        title: Text('Journal App'),
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
                    builder: (context) => Editor(),
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
              leading: Icon(Icons.self_improvement),
              title: Text('Personal Growth'),
              onTap: () => _showJournalsByTag('Personal Growth'),
            ),
            ListTile(
              leading: Icon(Icons.search_rounded),
              title: Text('Research Insights'),
              onTap: () => _showJournalsByTag('Research Insights'),
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Creative Writing'),
              onTap: () => _showJournalsByTag('Creative Writing'),
            ),
            ListTile(
              leading: Icon(Icons.travel_explore),
              title: Text('Travel Experiences'),
              onTap: () => _showJournalsByTag('Travel Experiences'),
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

          // Placeholder for Journal Entries
          Expanded(
            child: Center(
              child: Text(
                'Select a date to view journal entries.',
                style: TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJournalsByTag(String tag) {
    // Mock implementation for displaying journals by tag
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$tag Journals'),
          content: Text('Display journals tagged with $tag here.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
