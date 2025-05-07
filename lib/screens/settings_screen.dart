import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool audioMonitorEnabled = true;
  bool flashlightBlinkEnabled = true;
  int crySensitivity = 3;  // range 1 to 5

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
              // display the coocue logo
              Center(
                child: Image.asset('assets/images/coocue_logo2.png', height: 40),
              ),

              const SizedBox(height: 16),

              // show the page title
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

              // toggle for audio monitoring
              _buildSwitchTile(
                title: 'audio monitor',
                value: audioMonitorEnabled,
                onChanged: (val) => setState(() => audioMonitorEnabled = val),
              ),

              // toggle for flashlight blink in night mode
              _buildSwitchTile(
                title: 'night flashlight blink',
                value: flashlightBlinkEnabled,
                onChanged: (val) => setState(() => flashlightBlinkEnabled = val),
              ),

              // slider for cry sensitivity using icons
              ListTile(
                title: const Text(
                  'cry sensitivity',
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

              // navigate to security questions setup
              ListTile(
                title: const Text(
                  'set security questions',
                  style: TextStyle(fontFamily: 'LeagueSpartan', fontSize: 16),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF3F51B5)),
                onTap: () {
                  Navigator.pushNamed(context, '/set_security');
                },
              ),

              // option to reset the pin code
              ListTile(
                title: const Text(
                  'reset pin',
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
      // label for the switch
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'LeagueSpartan', fontSize: 16),
      ),
      // actual switch widget
      trailing: Switch(
        activeColor: const Color(0xFF3F51B5),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
