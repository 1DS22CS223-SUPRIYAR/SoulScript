import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_tts/flutter_tts.dart';

class UpdateScreen extends StatefulWidget {
  final String entryId;

  UpdateScreen({required this.entryId});

  @override
  _UpdateScreenState createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  late quill.QuillController _quillController;
  late TextEditingController _titleController;
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _quillController = quill.QuillController.basic();
    _flutterTts = FlutterTts();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "You need to log in to update your journal entry.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Update Journal Entry"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('journal_entries')
            .doc(widget.entryId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "Entry not found.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final entry = snapshot.data!;
          final title = entry['title'];
          final rawContent = entry['content'];
          final creationDate = (entry['creation_date'] as Timestamp).toDate();
          final lastUpdatedDate = entry['last_update'] != null
              ? (entry['last_update'] as Timestamp).toDate()
              : null;

          // Decode content into Quill Document
          _titleController.text = title;
          final quillDocument = _decodeContent(rawContent);
          _quillController = quill.QuillController(
            document: quillDocument,
            selection: const TextSelection.collapsed(offset: 0),
          );

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: "Title"),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Created: ${DateFormat('d MMMM yyyy, hh:mm a').format(creationDate)}",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    if (lastUpdatedDate != null) ...[
                      SizedBox(height: 4),
                      Text(
                        "Last Updated: ${DateFormat('d MMMM yyyy, hh:mm a').format(lastUpdatedDate)}",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                    SizedBox(height: 16),
                    Text(
                      "Content:",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    quill.QuillEditor.basic(
                      controller: _quillController,
                      configurations: quill.QuillEditorConfigurations(
                        scrollable: true,
                        padding: EdgeInsets.all(8.0),
                        checkBoxReadOnly: false,
                        enableInteractiveSelection: true,
                        enableSelectionToolbar: true,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Buttons in a Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: _readContentAloud,
                            icon: Icon(Icons.volume_up),
                            label: Text("Read Aloud"),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(100, 40),
                            ),
                          ),
                        ),
                        SizedBox(width: 8), // Space between buttons
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () => _saveEntry(
                              currentUser.uid,
                              widget.entryId,
                              _titleController.text.trim(),
                              jsonEncode(
                                _quillController.document.toDelta().toJson(),
                              ),
                            ),
                            child: Text("Save Changes"),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(100, 40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _readContentAloud() async {
    final text = _quillController.document.toPlainText();
    await _flutterTts.speak(text);
  }

  Future<void> _saveEntry(String uid, String entryId, String title,
      String content) async {
    await FirebaseFirestore.instance.collection('journal_entries')
        .doc(entryId)
        .update({
      'title': title,
      'content': content,
      'last_update': Timestamp.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Entry updated successfully!")),
    );
  }

  quill.Document _decodeContent(dynamic content) {
    try {
      final delta = jsonDecode(content) as List<dynamic>;
      // Ensure the last item in the delta ends with a newline
      if (delta.isNotEmpty) {
        final lastOp = delta.last;
        if (lastOp is Map && lastOp['insert'] is String) {
          final lastText = lastOp['insert'] as String;
          if (!lastText.endsWith('\n')) {
            lastOp['insert'] = lastText + '\n';
          }
        }
      }
      return quill.Document.fromJson(delta);
    } catch (e) {
      return quill.Document()
        ..insert(0, 'Error decoding content: $e');
    }
  }
}
