import 'package:coocue/screens/cot_home_screen.dart';
import 'package:coocue/screens/create_pin_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // showing the COOUE LOGO at the top center
              Center(
                child: Image.asset(
                  'assets/images/coocue_logo2.png',
                  height: 40,
                ),
              ),

              const SizedBox(height: 40),

              // showing the CHOOSE A ROLE title
              const Text(
                'Choose a Role',
                style: TextStyle(
                  fontSize: 40,
                  fontFamily: 'LeagueSpartan',
                  height: 0.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3F51B5),
                ),
              ),

              const SizedBox(height: 20),

              // subtext for giving extra info about the selection
              const Text(
                'Choose how this device will be used',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'LeagueSpartan',
                  height: 0.5,
                  color: Color(0xFF656565),
                ),
              ),

              const SizedBox(height: 40),

              // button for selecting COT role
              SizedBox(
                width: 232,
                height: 243,
                child: ElevatedButton(
                  onPressed: () async {
                    // saving COT role in shared preferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('role', 'cot');

                    // going to COTHOMESCREEN after saving role
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CotHomeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cot\nPhone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontFamily: 'LeagueSpartan',
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // button for selecting PARENT role
              SizedBox(
                width: 232,
                height: 243,
                child: ElevatedButton(
                  onPressed: () async {
                    // saving PARENT role in shared preferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('role', 'parent');

                    // going to CREATEPINSCREEN after saving role
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreatePinScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF94ACFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Parent\nPhone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontFamily: 'LeagueSpartan',
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
