import 'dart:io';

import 'package:coocue/screens/app_library_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:coocue/models/lullaby.dart';
import 'package:coocue/services/library_manager.dart';
import 'package:coocue/screens/parent_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LullabyLibraryScreen extends StatefulWidget {
  const LullabyLibraryScreen({super.key});

  @override
  State<LullabyLibraryScreen> createState() => _LullabyLibraryScreenState();
}

class _LullabyLibraryScreenState extends State<LullabyLibraryScreen> {
  List<Lullaby> get lullabies => LibraryManager.I.personalLibrary;
  int _tabIndex = 1; // 0 = Home, 1 = Library
  final _ss = const FlutterSecureStorage();
  Future<String?> _pairId() => _ss.read(key: 'pair_id');
  String? _playingId;
  bool _uploading = false; // ← new
  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(result.files.single.path!);
      final uid = 'parent';
      final ref = FirebaseStorage.instance.ref().child(
        'lullabies/$uid/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}',
      );
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      LibraryManager.I.addAll([
        Lullaby(title: result.files.single.name, asset: downloadUrl),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _showAddOptions() {
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
                  // drag handle
                  Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.upload_file,
                      color: Color(0xFF3F51B5),
                    ),
                    title: const Text(
                      'Upload from phone',
                      style: TextStyle(fontFamily: 'LeagueSpartan'),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndUpload();
                    },
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.library_music,
                      color: Color(0xFF3F51B5),
                    ),
                    title: const Text(
                      'Choose from App Library',
                      style: TextStyle(fontFamily: 'LeagueSpartan'),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      // Get selected lullabies from app library
                      final selectedLullabies =
                          await Navigator.push<List<Lullaby>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AppLibraryScreen(),
                            ),
                          );

                      // The LibraryManager.I.addAll() is already called in AppLibraryScreen
                      // Just refresh the UI here
                      if (selectedLullabies != null &&
                          selectedLullabies.isNotEmpty) {
                        setState(() {}); // Refresh UI with new songs
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added ${selectedLullabies.length} songs to library',
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  if (_uploading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  void _deleteLullaby(int index) {
    setState(() {
      LibraryManager.I.remove(lullabies[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFB74D),
        onPressed: _showAddOptions,
        child: const Icon(Icons.add, color: Color(0xff3F51B5)),
        shape: const CircleBorder(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        selectedItemColor: const Color(0xFF3F51B5),
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          if (i == _tabIndex) return; // already on that tab
          if (i == 0) {
            // Swap to ParentHome without stacking
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ParentHomeScreen()),
            );
          }
          // No action needed for i == 1 because we're already here
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
      ),
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
                'Select a song to play for your sweet little one.',
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
                  'No tracks yet.\nTap + to upload a lullaby.',
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
                          // toggle icon
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
                                content: Text('Please pair with a Cot first'),
                              ),
                            );
                            return;
                          }

                          final cmd = isThisPlaying ? 'stop' : 'play';
                          final Map<String, dynamic> data = {
                            'type': cmd,
                            'createdAt': FieldValue.serverTimestamp(),
                          };
                          if (!isThisPlaying) {
                            // only include asset/url on play
                            if (lullaby.asset.isNotEmpty)
                              data['assetPath'] = lullaby.asset;
                            if (lullaby.url != null)
                              data['downloadUrl'] = lullaby.url;
                            data['title'] = lullaby.title;
                          }

                          await FirebaseFirestore.instance
                              .collection('pairs')
                              .doc(pairId)
                              .collection('commands')
                              .add(data);

                          setState(() {
                            if (isThisPlaying) {
                              _playingId = null;
                            } else {
                              _playingId = lullaby.asset;
                            }
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Color(0xFF3F51B5),
                              content: Text(
                                isThisPlaying
                                    ? 'Playing "${lullaby.title}" on cot phone'
                                    : 'Stopped playing lullaby on cot phone',
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
