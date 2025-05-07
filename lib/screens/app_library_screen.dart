import 'package:flutter/material.dart';
import 'package:coocue/services/lullaby_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:coocue/models/lullaby.dart';
import 'package:coocue/services/library_manager.dart';


class AppLibraryScreen extends StatefulWidget {
  const AppLibraryScreen({super.key});

  @override
  State<AppLibraryScreen> createState() => _AppLibraryScreenState();
}

class _AppLibraryScreenState extends State<AppLibraryScreen> {
  // Everything the app ships with by default
  final List<Map<String, String>> _tracks = [
    {'title': 'Ballerina', 'asset': 'assets/lullabies/ballerina.mp3'},
    {'title': 'Rock-a-bye Baby', 'asset': 'assets/lullabies/rockabyebaby.mp3'},
    {
      'title': 'Row Row Row Your Boat',
      'asset': 'assets/lullabies/rowrowrowyourboat.mp3',
    },
  ];

  /// Keeps track of which rows are ticked by the user

  /// Path of the asset currently playing (null ⇒ nothing is playing)
  String? _currentlyPlaying;
  late List<bool> _selected; // ← remove the old initializer

  @override
  void initState() {
    super.initState();
    // Auto‑clear highlight when track ends
    final existing =
        LibraryManager.I.personalLibrary
            .map((e) => e.asset)
            .toSet(); // fast lookup
    _selected = List<bool>.generate(
      _tracks.length,
      (i) => existing.contains(_tracks[i]['asset']),
    );
    LullabyService.I.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) setState(() => _currentlyPlaying = null);
      }
    });
  }

  @override
  void dispose() {
    // Ensure audio stops when leaving the screen
    LullabyService.I.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/images/coocue_logo2.png', height: 40),
              const SizedBox(height: 20),
              const Text(
                'App Library',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Choose songs from our collection you would like to add to the library.',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'LeagueSpartan',
                  height: 1,
                  color: Color(0xFF656565),
                ),
              ),
              const SizedBox(height: 32),

              /// List of built‑in tracks
              Expanded(
                child: ListView.separated(
                  itemCount: _tracks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _tracks[index];
                    final isPlaying = _currentlyPlaying == item['asset'];

                    return ListTile(
                      leading: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: const Color(0xFF3F51B5),
                        size: 32,
                      ),
                      title: Text(
                        item['title']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'LeagueSpartan',
                        ),
                      ),
                      trailing: Checkbox(
                        value: _selected[index],
                        onChanged:
                            (val) =>
                                setState(() => _selected[index] = val ?? false),
                        activeColor: const Color(0xFF3F51B5),
                      ),
                      onTap: () async {
                        if (isPlaying) {
                          // Pause
                          setState(() => _currentlyPlaying = null);
                          await LullabyService.I.stop();
                        } else {
                          // Play this track
                          setState(() => _currentlyPlaying = item['asset']);
                          await LullabyService.I.playAsset(item['asset']!);
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// Confirm button keeps the original logic
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // build a list of selected Lullaby objects
                    final selectedLullabies = <Lullaby>[];
                    for (var i = 0; i < _tracks.length; i++) {
                      if (_selected[i]) {
                        selectedLullabies.add(
                          Lullaby(
                            title: _tracks[i]['title']!,
                            asset: _tracks[i]['asset']!,
                          ),
                        );
                      }
                    }

                    if (selectedLullabies.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor:Color(0xFF3F51B5),content: Text('No tracks selected')),
                      );
                      return;
                    }

                    // Save into shared store and return the selected lullabies
                    LibraryManager.I.addAll(selectedLullabies);
                    
                    // Return the selected lullabies to the previous screen
                    Navigator.pop(context, selectedLullabies);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm Selection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'LeagueSpartan',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}