import 'package:flutter/material.dart';

class AppLibraryScreen extends StatefulWidget {
  const AppLibraryScreen({super.key});

  @override
  State<AppLibraryScreen> createState() => _AppLibraryScreenState();
}

class _AppLibraryScreenState extends State<AppLibraryScreen> {
  final List<String> tracks = [
    "Twinkle Twinkle",
    "Brahms’ Lullaby",
    "Rain Sounds",
    "White Noise"
  ];
  final List<bool> selected = [false, false, false, false];

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
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: tracks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.volume_up, color: Color(0xFF3F51B5)),
                      title: Text(
                        tracks[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'LeagueSpartan',
                        ),
                      ),
                      trailing: Checkbox(
                        value: selected[index],
                        onChanged: (val) {
                          setState(() => selected[index] = val ?? false);
                        },
                        activeColor: const Color(0xFF3F51B5),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: handle selected items
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
