import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../models/lullaby.dart';
import '../services/library_manager.dart';

class UploadLullaby extends StatefulWidget {
  const UploadLullaby({Key? key}) : super(key: key);

  @override
  State<UploadLullaby> createState() => _UploadLullabyState();
}

class _UploadLullabyState extends State<UploadLullaby> {
  bool _uploading = false;

  /* ------------------------------------------------------------------------
   *  Choose‑file path: pick a local file, upload to Firebase Storage,
   *  register it in the in‑app library, then close the sheet.
   * --------------------------------------------------------------------- */
  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _uploading = true);

    try {
      final file = File(result.files.single.path!);

      // final uid = FirebaseAuth.instance.currentUser!.uid; // if using auth
      const uid = 'parent';
      final storageRef = FirebaseStorage.instance.ref().child(
        'lullabies/$uid/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}',
      );

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      LibraryManager.I.addAll([
        Lullaby(
          title: result.files.single.name,
          asset: downloadUrl, // ⬅️  drop “url:” and use “asset:”
        ),
      ]);

      if (mounted) Navigator.pop(context); // close bottom sheet
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        setState(() => _uploading = false);
      }
    }
  }

  /* ------------------------------------------------------------------------
   *  Existing “Select from App Library” button — keep whatever logic you had
   * --------------------------------------------------------------------- */
  void _selectFromAppLibrary() {
    Navigator.pop(context, 'select_from_library');
  }

  /* ====================================================================== */

  @override
  Widget build(BuildContext context) {
    if (_uploading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /* ----------------------- title row ----------------------- */
            Row(
              children: [
                const Text(
                  'Upload a Lullaby',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'LeagueSpartan',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F51B5),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            /* ---------------------- action buttons ------------------- */
            _buildActionButton('Choose File', _pickAndUpload),
            const SizedBox(height: 12),
            _buildActionButton(
              'Select from App Library',
              _selectFromAppLibrary,
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------------------------------------------------------------- */
  Widget _buildActionButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3F51B5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'LeagueSpartan', fontSize: 16),
        ),
      ),
    );
  }
}
