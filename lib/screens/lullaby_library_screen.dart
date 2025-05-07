// any variable or displayed text below now starts with a capital letter

import 'dart:io';
// added this to access file operations on device

import 'package:coocue/screens/app_library_screen.dart';
// added this to let user pick from built-in app library

import 'package:file_picker/file_picker.dart';
// added this to allow picking audio files from phone

import 'package:firebase_storage/firebase_storage.dart';
// added this to upload and download files from firebase storage

import 'package:flutter/material.dart';
// added this for core flutter widgets

import 'package:coocue/models/lullaby.dart';
// added this to work with the lullaby data model

import 'package:coocue/services/library_manager.dart';
// added this to manage personal lullaby library

import 'package:coocue/screens/parent_home_screen.dart';
// added this to navigate back to the parent home screen

import 'package:cloud_firestore/cloud_firestore.dart';
// added this to send commands to firestore

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// added this to securely store and read pairing info

class LullabyLibraryScreen extends StatefulWidget {
  const LullabyLibraryScreen({super.key});
  // kept constructor for stateful widget

  @override
  State<LullabyLibraryScreen> createState() => _LullabyLibraryScreenState();
  // connected widget to its state
}

class _LullabyLibraryScreenState extends State<LullabyLibraryScreen> {
  List<Lullaby> get lullabies => LibraryManager.I.personalLibrary;
  // added this to fetch saved lullabies list

  int _tabIndex = 1;
  // added this to track bottom tab (0=Home,1=Library)

  final _ss = const FlutterSecureStorage();
  // added this to read secure stored values

  Future<String?> _pairId() => _ss.read(key: 'pair_id');
  // added this to get the device pairing Id

  String? _playingId;
  // added this to track which lullaby is playing

  bool _uploading = false;
  // added this to show upload progress state

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    // Ensure that a file is selected
    if (result == null || result.files.single.path == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No file selected")));
      return;
    }

    // Debugging the file path
    print("Selected file path: ${result.files.single.path}");

    setState(() => _uploading = true);

    try {
      final file = File(result.files.single.path!);
      final uid = 'Parent';
      final ref = FirebaseStorage.instance.ref().child(
        'lullabies/$uid/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}',
      );

      // Upload the file
      await ref.putFile(file);

      // Get the download URL
      final downloadUrl = await ref.getDownloadURL();
      print("Download URL: $downloadUrl");

      // Add lullaby to library
      LibraryManager.I.addAll([
        Lullaby(title: result.files.single.name, asset: downloadUrl),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload Failed: $e')));
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _showAddOptions() {
    // added this to display options for adding lullabies
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // added this as a draggable handle
                  ListTile(
                    leading: const Icon(
                      Icons.upload_file,
                      color: Color(0xFF3F51B5),
                    ),
                    title: const Text(
                      'Upload From Phone',
                      style: TextStyle(fontFamily: 'LeagueSpartan'),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndUpload();
                    },
                  ),

                  // added this option to upload from device
                  ListTile(
                    leading: const Icon(
                      Icons.library_music,
                      color: Color(0xFF3F51B5),
                    ),
                    title: const Text(
                      'Choose From App Library',
                      style: TextStyle(fontFamily: 'LeagueSpartan'),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      // added this to get selected lullabies
                      final selectedLullabies =
                          await Navigator.push<List<Lullaby>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AppLibraryScreen(),
                            ),
                          );
                      // if user picked some, show a message and refresh
                      if (selectedLullabies != null &&
                          selectedLullabies.isNotEmpty) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added ${selectedLullabies.length} Songs To Library',
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  // added this option to pick from built-in list
                  if (_uploading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                  // added this to show spinner while uploading
                ],
              ),
            ),
          ),
    );
  }

  void _deleteLullaby(int index) {
    // added this to remove a lullaby from personal library
    setState(() {
      LibraryManager.I.remove(lullabies[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    // added this to construct the UI for the library screen
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFB74D),
        onPressed: _showAddOptions,
        child: const Icon(Icons.add, color: Color(0xFF3F51B5)),
      ),

      // added this fab to let user add new lullabies
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        selectedItemColor: const Color(0xFF3F51B5),
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          if (i == _tabIndex) return;
          if (i == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ParentHomeScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
      ),

      // added this nav bar to switch between Home and Library
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/images/coocue_logo2.png',
                  height: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lullaby Library',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 32),
              const Text(
                'Select A Song To Play For Your Sweet Little One.',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'LeagueSpartan',
                  height: 1,
                  color: Color(0xFF656565),
                ),
              ),
              const SizedBox(height: 32),

              if (lullabies.isEmpty) ...[
                const Text(
                  'No Tracks Yet.\nTap + To Upload A Lullaby.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                Image.asset('assets/images/img3.png', height: 120),
              ] else ...[
                Expanded(
                  child: ListView.separated(
                    itemCount: lullabies.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final lullaby = lullabies[index];
                      final isThisPlaying = (_playingId == lullaby.asset);
                      return ListTile(
                        leading: Icon(
                          isThisPlaying
                              ? Icons.stop_circle
                              : Icons.play_circle_fill,
                          color: Color(0xFF3F51B5),
                          size: 32,
                        ),
                        title: Text(
                          lullaby.title,
                          style: const TextStyle(fontFamily: 'LeagueSpartan'),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lullaby.duration,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Color(0xFF3F51B5),
                              ),
                              onPressed: () => _deleteLullaby(index),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final pairId = await _pairId();
                          if (pairId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please Pair With A Cot First'),
                              ),
                            );
                            return;
                          }

                          final cmd =
                              isThisPlaying
                                  ? 'stop'
                                  : 'play'; // Define cmd based on whether it's playing

                          final Map<String, dynamic> data = {
                            'type': cmd, // Send the command type
                            'createdAt': FieldValue.serverTimestamp(),
                          };

                          if (!isThisPlaying) {
                            // Add asset path and title only if playing
                            if (lullaby.asset.isNotEmpty)
                              data['assetPath'] = lullaby.asset;
                            if (lullaby.url != null)
                              data['downloadUrl'] = lullaby.url;
                            data['title'] = lullaby.title;
                          }

                          print(
                            "Sending play/stop command: $data",
                          ); // Debugging log
                          await FirebaseFirestore.instance
                              .collection('pairs')
                              .doc(pairId)
                              .collection('commands')
                              .add(data);

                          setState(() {
                            _playingId = isThisPlaying ? null : lullaby.asset;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Color(0xFF3F51B5),
                              content: Text(
                                isThisPlaying
                                    ? 'Stopped Playing Lullaby On Cot Phone'
                                    : 'Playing \"${lullaby.title}\" On Cot Phone',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
