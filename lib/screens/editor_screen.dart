import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soulscript/services/database_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:soulscript/screens/home.dart';

class Editor extends StatefulWidget {
  final String? entryId; // Pass the entryId to identify whether we are in compose or update mode.

  // Constructor with entryId parameter
  Editor({Key? key, this.entryId}) : super(key: key);

  @override
  _EditorState createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final quill.QuillController _quillController = quill.QuillController.basic();
  List<File> _attachedImages = [];
  Color _backgroundColor = Colors.deepPurple[50]!;
  String _selectedLabel = 'Personal';
  String? _uid;
  String _title = '';
  bool _isListening = false;
  String _voiceInput = '';
  late stt.SpeechToText _speech;
  FlutterTts _flutterTts = FlutterTts();
  final List<String> _labels = ['Personal', 'Daily', 'Work', 'Ideas'];
  String? _entryId; // To track the unique identifier for the entry.
  DateTime? _createdAt; // To store the created timestamp.

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _speech = stt.SpeechToText();
    _getUserUid();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> _getUserUid() async {
    try {
      _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    } catch (e) {
      print('Error fetching user UID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching UID')),
      );
    }
  }

  Future<void> _loadExistingEntry() async {
    try {
      // Load the existing entry from the database using the entryId.
      var entry = await DatabaseService().getJournalEntries(_entryId!);
      if (entry != null && entry.isNotEmpty) {
        setState(() {
          _title = entry[0]['title'];
          _selectedLabel = entry[0]['label'];
          _createdAt = DateTime.parse(entry[0]['creation_date']);

          // Convert base64 image strings into Uint8List for use with Image.memory
          _attachedImages = [];
          List<String> imageBase64Strings = entry[0]['image'].split(',');
          for (var base64String in imageBase64Strings) {
            // Decode base64 string into Uint8List
            _attachedImages.add(base64Decode(base64String) as File); // Store as Uint8List
          }

          // Replace text content in Quill editor
          _quillController.replaceText(
            0, // Start replacing from the beginning
            0, // Length of text to replace (0 means inserting)
            entry[0]['content'], // The content you want to insert
            TextSelection.collapsed(offset: 0), // TextSelection defines where the text is inserted
            ignoreFocus: false, // Do not ignore the focus
            shouldNotifyListeners: true, // Notify listeners about the change
          );
        });
      }
    } catch (e) {
      print('Error loading entry: $e');
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
    // Validate title and content are not empty
    if (_title.isEmpty || _quillController.document.isEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Title and content cannot be empty.')),
      );
      return;
    }

    final content = _quillController.document.toDelta().toJson();
    List<String> base64ImageUrls = [];

    // Convert images to base64 and add them to the list
    for (File image in _attachedImages) {
      String base64Image = await DatabaseService().convertImageToBase64(image);
      base64ImageUrls.add(base64Image);
    }

    // Set the current timestamp for creation
    _createdAt = DateTime.now();

    // Try to save or update the journal entry
    try {
      String contentJsonString = jsonEncode(content);
      bool isSuccess = await DatabaseService().saveJournalEntry(
        label: _selectedLabel,
        content: contentJsonString,
        base64Image: base64ImageUrls.join(','),
        uid: _uid,
        title: _title,
        entryId: _entryId,
      );

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entry saved successfully!')),
        );
        setState(() {
          _attachedImages.clear();
          _title = '';
          _quillController.clear();
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()), // Replace HomePage() with your home screen widget
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save entry.')),
        );
      }
    } catch (e) {
      print('Error saving entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while saving the entry.')),
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
          widget.entryId == null ? 'Journal Editor' : 'Update Journal Entry',
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
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter a title for your entry',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _title),
              onChanged: (value) {
                setState(() {
                  _title = value;
                });
              },
            ),
            SizedBox(height: 20),
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
            Expanded(
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
            // Action Buttons
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
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
