import 'package:flutter/material.dart';

class Editor extends StatefulWidget {
  @override
  _EditorState createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  TextEditingController _controller = TextEditingController();
  Color _backgroundColor = Colors.deepPurple[50]!; // Default soft lavender background
  String _selectedMood = 'Happy';

  // Mood-specific colors in purple tones
  final Map<String, Color> _moodColors = {
    'Happy': Colors.deepPurple[100]!,
    'Sad': Colors.purple[200]!,
    'Excited': Colors.purpleAccent[100]!, // Custom complementary purple tone
    'Neutral': Colors.purple[50]!,
  };

  void _changeMood(String mood) {
    setState(() {
      _selectedMood = mood;
      _backgroundColor = _moodColors[mood] ?? Colors.deepPurple[50]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Journal Entry',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start your journal entry:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),

            // Mood Selection
            Row(
              children: [
                Text(
                  'Mood: ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedMood,
                  onChanged: (String? newMood) {
                    if (newMood != null) _changeMood(newMood);
                  },
                  items: _moodColors.keys
                      .map<DropdownMenuItem<String>>((String mood) {
                    return DropdownMenuItem<String>(
                      value: mood,
                      child: Text(mood),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Text Field
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Write your thoughts here...',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple),
                  ),
                ),
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.insert_emoticon, color: Colors.purpleAccent),
                  onPressed: () {
                    // Placeholder for mood actions
                  },
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.purpleAccent),
                  onPressed: () {
                    // Placeholder for camera functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.color_lens, color: Colors.purpleAccent),
                  onPressed: () {
                    // Placeholder for color picker
                  },
                ),
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.purpleAccent),
                  onPressed: () {
                    // Placeholder for mic functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
