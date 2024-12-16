import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
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
import 'package:speech_to_text/speech_recognition_result.dart';

class Editor extends StatefulWidget {
  final String? entryId; // Pass the entryId to identify whether we are in compose or update mode.

  // Constructor with entryId parameter
  Editor({Key? key, this.entryId}) : super(key: key);

  @override
  _EditorState createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final quill.QuillController _quillController = quill.QuillController(
    document: quill.Document.fromJson([
      {'insert': '\n'}, // Set your initial text here
    ]),
    selection: TextSelection.collapsed(offset: 0),
  );
  List<File> _attachedImages = [];
  Color _backgroundColor = Colors.deepPurple[50]!;
  String _selectedLabel = 'Personal';
  String? _uid;
  String _title = '';

  // bool _isListening = false;
  String _voiceInput = '';
  SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  FlutterTts _flutterTts = FlutterTts();
  final List<String> _labels = ['Personal', 'Ideas', 'Daily', 'Travel', 'Work'];
  String? _entryId; // To track the unique identifier for the entry.
  DateTime? _createdAt;
  // To store the created timestamp.

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _entryId = widget.entryId;
    _getUserUid();
    _initSpeech();
    if (_entryId != null) {
      _loadExistingEntry();
    }
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speech.initialize();
    setState(() {});
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

  Future<void> _loadExistingEntry()  async {
    try {
      Map<String, dynamic> entry = await DatabaseService().getJournalEntry(_entryId!);

      if (entry.isNotEmpty) {
        setState(() async {
          _title = entry['title'];
          _selectedLabel = entry['label'];
          _createdAt = DateTime.parse(entry['creation_date']);

          // Load content into the Quill editor
          final contentJson = jsonDecode(entry['content']);
          _quillController.document = quill.Document.fromJson(contentJson);

          // Load images
          List<String> imageBase64Strings = entry['images']?.split(',') ?? [];
          for (var base64String in imageBase64Strings) {
            Uint8List decodedBytes = base64Decode(base64String);
            final directory = await getApplicationDocumentsDirectory();
            final imagePath = '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final imageFile = File(imagePath)..writeAsBytesSync(decodedBytes);
            _attachedImages.add(imageFile);
          }

          // Debug prints
          print('Loaded content: ${_quillController.document.toPlainText()}');
          print('Number of images loaded: ${_attachedImages.length}');
        });
      }
    } catch (e) {
      print('Error loading entry: $e');
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _speechEnabled = true);
      _speech.listen(
        onResult: _onSpeechResult, // Call the onResult method
      );
    } else {
      print('Speech recognition not available or failed to initialize');
      setState(() => _speechEnabled = false);
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    //   _quillController.document.insert(
    //       _quillController.selection.baseOffset, _lastWords);
    });
  }

  Future<void> _stopListening() async {


    setState(() {
      final int currentOffset = _quillController.selection.baseOffset;
      if (currentOffset != null) {
        _quillController.document.insert(currentOffset, _lastWords);
      }
      _speech.stop();
      _speechEnabled = false;
      _lastWords = '';
    });
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
          MaterialPageRoute(builder: (context) =>
              HomeScreen()), // Replace HomePage() with your home screen widget
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
    if (_entryId != null) {
      _loadExistingEntry();
    }
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
              onChanged: (value) {
                setState(() {
                  _title = value; // Update title as you type
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
                    _speechEnabled ? Icons.mic_off : Icons.mic,
                    color: Colors.deepPurple,
                  ),
                  onPressed: _speechEnabled ? _stopListening : _startListening,
                ),
                IconButton(
                  icon: Icon(Icons.volume_up, color: Colors.deepPurple),
                  onPressed: _speakText,
                ),
                IconButton(
                  icon: Icon(Icons.photo, color: Colors.deepPurple),
                  onPressed: _attachPhoto,
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.deepPurple),
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