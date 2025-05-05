import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool audioMonitorEnabled = true;
  bool flashlightBlinkEnabled = true;
  int crySensitivity = 3; // Range: 1 to 5

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset('assets/images/coocue_logo2.png', height: 40),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'LeagueSpartan',
                    color: Color(0xFF3F51B5),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Audio Monitor Toggle
              _buildSwitchTile(
                title: 'Audio Monitor',
                value: audioMonitorEnabled,
                onChanged: (val) => setState(() => audioMonitorEnabled = val),
              ),

              // Flashlight Toggle
              _buildSwitchTile(
                title: 'Night Flashlight Blink',
                value: flashlightBlinkEnabled,
                onChanged: (val) => setState(() => flashlightBlinkEnabled = val),
              ),

              // Cry Sensitivity
              ListTile(
                title: const Text(
                  'Cry Sensitivity',
                  style: TextStyle(fontFamily: 'LeagueSpartan', fontSize: 16),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final isActive = index < crySensitivity;
                    return GestureDetector(
                      onTap: () => setState(() => crySensitivity = index + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          Icons.circle,
                          size: 12,
                          color: isActive ? const Color(0xFFFFC107) : Colors.grey,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Divider(),

              // Set Security Questions
              ListTile(
                title: const Text(
                  'Set Security Questions',
                  style: TextStyle(fontFamily: 'LeagueSpartan', fontSize: 16),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF3F51B5)),
                onTap: () {
                  Navigator.pushNamed(context, '/set_security');
                },
              ),

              // Reset PIN (red)
              ListTile(
                title: const Text(
                  'Reset PIN',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 16,
                    color: Color(0xFFB53F3F),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFFB53F3F)),
                onTap: () {
                  Navigator.pushNamed(context, '/reset_pin');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'LeagueSpartan', fontSize: 16),
      ),
      trailing: Switch(
        activeColor: const Color(0xFF3F51B5),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
