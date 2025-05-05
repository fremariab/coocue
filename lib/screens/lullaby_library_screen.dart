import 'package:flutter/material.dart';
import '../widgets/upload_lullaby.dart';
import '../models/lullaby.dart';

class LullabyLibraryScreen extends StatefulWidget {
  const LullabyLibraryScreen({super.key});

  @override
  State<LullabyLibraryScreen> createState() => _LullabyLibraryScreenState();
}

class _LullabyLibraryScreenState extends State<LullabyLibraryScreen> {
  List<Lullaby> lullabies = [];

  void _showUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const UploadLullaby(),
    );
  }

  void _deleteLullaby(int index) {
    setState(() {
      lullabies.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        onPressed: _showUploadModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Center(child: Image.asset('assets/images/coocue_logo2.png', height: 40)),
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

              if (lullabies.isEmpty) ...[
                const Text(
                  'No tracks yet.\nTap + to upload a lullaby.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                Image.asset('assets/images/clouds.png', height: 120),
              ] else ...[
                Expanded(
                  child: ListView.separated(
                    itemCount: lullabies.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final lullaby = lullabies[index];
                      return ListTile(
                        leading: const Icon(Icons.volume_up, color: Color(0xFF3F51B5)),
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
                              icon: const Icon(Icons.delete, color: Color(0xFF3F51B5)),
                              onPressed: () => _deleteLullaby(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
