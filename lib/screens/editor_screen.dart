import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soulscript/services/database_service.dart';
import 'package:permission_handler/permission_handler.dart';


class Editor extends StatefulWidget {
  @override
  _EditorState createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final quill.QuillController _quillController = quill.QuillController.basic();
  List<File> _attachedImages = [];
  Color _backgroundColor = Colors.deepPurple[50]!;
  String _selectedLabel = 'Personal';
  String? _uid;
  // Speech-to-Text and Text-to-Speech objects
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = '';

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }// Ensure this is your correct database service import

  FlutterTts _flutterTts = FlutterTts();

  // Labels for categorizing entries
  final List<String> _labels = ['Personal', 'Daily', 'Work', 'Ideas'];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _speech = stt.SpeechToText();
    _getUserUid();
  }

  // Async method to get user UID
  Future<void> _getUserUid() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _uid = user.uid;  // Assign UID when it's fetched
        });
      } else {
        // Handle the case where the user is not logged in
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in.')),
        );
      }
    } catch (e) {
      print('Error fetching user UID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching UID')),
      );
    }
  }


  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _voiceInput = result.recognizedWords;
          final index = _quillController.document.length;
          _quillController.document.insert(index, _voiceInput);
        });
      });
    } else {
      print('Speech recognition not available or failed to initialize');
      setState(() => _isListening = false);
    }
  }


  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _speakText() async {
    final text = _quillController.document.toPlainText();
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _attachPhoto() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _attachedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _capturePhoto() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _attachedImages.add(File(image.path));
      });
    }
  }

  Future<void> _saveEntry() async {
    if (_quillController.document.isEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot save an empty entry.')),
      );
      return;
    }

    final content = _quillController.document.toDelta().toJson(); // Quill Delta as JSON
    bool isSuccess = await DatabaseService().saveRichJournalEntry(
      label: _selectedLabel,
      content: content, // Pass Delta JSON to the function
      imageUrls: _attachedImages.map((file) => file.path).toList(),
      uid: _uid!, // Pass the user ID
    );

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entry saved successfully!')),
      );
      _quillController.clear();
      setState(() {
        _attachedImages.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save the entry.')),
      );
    }
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
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveEntry,
          ),
        ],
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

            // Label Selection
            Row(
              children: [
                Text(
                  'Label: ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedLabel,
                  onChanged: (String? newLabel) {
                    if (newLabel != null) {
                      setState(() {
                        _selectedLabel = newLabel;
                      });
                    }
                  },
                  items: _labels.map<DropdownMenuItem<String>>((String label) {
                    return DropdownMenuItem<String>(
                      value: label,
                      child: Text(label),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Quill editor wrapped inside Expanded/Flexible
            Expanded(
              child: Flexible(
                child: quill.QuillEditor(
                  controller: _quillController,
                  scrollController: ScrollController(),
                  focusNode: FocusNode(),
                  configurations: quill.QuillEditorConfigurations(
                    scrollable: true,
                    padding: EdgeInsets.all(8.0),
                    autoFocus: true,
                    placeholder: 'Start writing your journal...',
                    checkBoxReadOnly: false,
                    enableInteractiveSelection: true,
                    enableSelectionToolbar: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
            ),

            // Attached Images Preview
            if (_attachedImages.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _attachedImages.map((image) {
                  return Stack(
                    children: [
                      Image.file(
                        image,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _attachedImages.remove(image);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: Colors.purpleAccent,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                IconButton(
                  icon: Icon(Icons.volume_up, color: Colors.purpleAccent),
                  onPressed: _speakText,
                ),
                IconButton(
                  icon: Icon(Icons.photo, color: Colors.purpleAccent),
                  onPressed: _attachPhoto,
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.purpleAccent),
                  onPressed: _capturePhoto,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}