// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_quill/flutter_quill.dart' as quill;
// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:soulscript/services/database_service.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class Editor extends StatefulWidget {
//   @override
//   _EditorState createState() => _EditorState();
// }
//
// class _EditorState extends State<Editor> {
//   final quill.QuillController _quillController = quill.QuillController.basic();
//   List<File> _attachedImages = [];
//   Color _backgroundColor = Colors.deepPurple[50]!;
//   String _selectedLabel = 'Personal';
//   String? _uid;
//   String _title = '';
//   bool _isListening = false;
//   String _voiceInput = '';
//   late stt.SpeechToText _speech;
//   FlutterTts _flutterTts = FlutterTts();
//   final List<String> _labels = ['Personal', 'Daily', 'Work', 'Ideas'];
//
//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _speech = stt.SpeechToText();
//     _getUserUid();
//   }
//
//   Future<void> _requestPermissions() async {
//     await Permission.microphone.request();
//   }
//
//   Future<void> _getUserUid() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         setState(() {
//           _uid = user.uid;
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('User not logged in.')),
//         );
//       }
//     } catch (e) {
//       print('Error fetching user UID: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching UID')),
//       );
//     }
//   }
//
//   Future<void> _startListening() async {
//     bool available = await _speech.initialize();
//     if (available) {
//       setState(() => _isListening = true);
//       _speech.listen(onResult: (result) {
//         setState(() {
//           _voiceInput = result.recognizedWords;
//           final index = _quillController.document.length;
//           _quillController.document.insert(index, _voiceInput);
//         });
//       });
//     } else {
//       print('Speech recognition not available or failed to initialize');
//       setState(() => _isListening = false);
//     }
//   }
//
//   Future<void> _stopListening() async {
//     setState(() => _isListening = false);
//     _speech.stop();
//   }
//
//   Future<void> _speakText() async {
//     final text = _quillController.document.toPlainText();
//     if (text.isNotEmpty) {
//       await _flutterTts.speak(text);
//     }
//   }
//
//   Future<void> _attachPhoto() async {
//     final ImagePicker _picker = ImagePicker();
//     final List<XFile>? images = await _picker.pickMultiImage();
//     if (images != null) {
//       setState(() {
//         _attachedImages.addAll(images.map((image) => File(image.path)));
//       });
//     }
//   }
//
//   Future<void> _capturePhoto() async {
//     final ImagePicker _picker = ImagePicker();
//     final XFile? image = await _picker.pickImage(source: ImageSource.camera);
//     if (image != null) {
//       setState(() {
//         _attachedImages.add(File(image.path));
//       });
//     }
//   }
//
//   Future<void> _saveEntry() async {
//     if (_title.isEmpty || _quillController.document.isEmpty()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Title and content cannot be empty.')),
//       );
//       return;
//     }
//
//     final content = _quillController.document.toDelta().toJson();
//     List<String> imageUrls = [];
//
//     for (File image in _attachedImages) {
//       final url = await DatabaseService().uploadImage(image, _uid!);
//       if (url != null) {
//         imageUrls.add(url);
//       }
//     }
//
//     bool isSuccess = await DatabaseService().saveRichJournalEntry(
//       label: _selectedLabel,
//       content: content,
//       imageUrls: imageUrls,
//       uid: _uid!,
//       title: _title,
//     );
//
//     if (isSuccess) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Entry saved successfully!')),
//       );
//       _quillController.clear();
//       setState(() {
//         _title = '';
//         _attachedImages.clear();
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to save the entry.')),
//       );
//     }
//   }
//
//   Future<void> _deleteEntry(String documentId, List<String> imageUrls) async {
//     bool isSuccess = await DatabaseService().deleteJournalEntry(documentId, imageUrls);
//     if (isSuccess) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Entry deleted successfully!')),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to delete the entry.')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: _backgroundColor,
//         appBar: AppBar(
//           backgroundColor: Colors.deepPurple,
//           title: Text(
//             'Journal Editor',
//             style: TextStyle(color: Colors.white),
//           ),
//           iconTheme: IconThemeData(color: Colors.white),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.save),
//               onPressed: _saveEntry,
//             ),
//           ],
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//           TextField(
//           decoration: InputDecoration(
//           hintText: 'Enter a title for your entry',
//             border: OutlineInputBorder(),
//           ),
//           onChanged: (value) {
//             setState(() {
//               _title = value;
//             });
//           },
//         ),
//         SizedBox(height: 20),
//
//         Row(
//           children: [
//             Text(
//               'Label: ',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//             ),
//             SizedBox(width: 10),
//             DropdownButton<String>(
//               value: _selectedLabel,
//               onChanged: (String? newLabel) {
//                 if (newLabel != null) {
//                   setState(() {
//                     _selectedLabel = newLabel;
//                   });
//                 }
//               },
//               items: _labels.map<DropdownMenuItem<String>>((String label) {
//                 return DropdownMenuItem<String>(
//                   value: label,
//                   child: Text(label),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//         SizedBox(height: 20),
//
//         Expanded(
//           child: Flexible(
//             child: quill.QuillEditor(
//               controller: _quillController,
//               scrollController: ScrollController(),
//               focusNode: FocusNode(),
//               configurations: quill.QuillEditorConfigurations(
//                 scrollable: true,
//                 padding: EdgeInsets.all(8.0),
//                 autoFocus: true,
//                 placeholder: 'Start writing your journal...',
//                 checkBoxReadOnly: false,
//                 enableInteractiveSelection: true,
//                 enableSelectionToolbar: true,
//                 textCapitalization: TextCapitalization.sentences,
//               ),
//             ),
//           ),
//         ),
//
//               if (_attachedImages.isNotEmpty)
//                 Wrap(
//                   spacing: 8.0,
//                   runSpacing: 8.0,
//                   children: _attachedImages.map((image) {
//                     return Stack(
//                       children: [
//                         Image.file(
//                           image,
//                           height: 100,
//                           width: 100,
//                           fit: BoxFit.cover,
//                         ),
//                         Positioned(
//                           right: 0,
//                           top: 0,
//                           child: IconButton(
//                             icon: Icon(Icons.close, color: Colors.red),
//                             onPressed: () {
//                               setState(() {
//                                 _attachedImages.remove(image);
//                               });
//                             },
//                           ),
//                         ),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//
//               Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween
//               )
//             ],
//           ),
//         ),
//     );
//   }
// }