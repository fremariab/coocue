import 'package:flutter/material.dart';
import 'package:coocue/screens/role_picker_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC), // Background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20), // Push logo to top
              Center(
                child: Image.asset(
                  'assets/images/coocue_logo2.png',
                  height: 30,
                ),
              ),

              const SizedBox(height: 60),

              // Welcome Texts
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Welcome to',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3F51B5),
                      fontFamily: 'LeagueSpartan',
                      height: 0.5,
                    ),
                  ),
                  Text(
                    'coocue',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'LeagueSpartan',
                      color: Color(0xFFFFB74D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Image.asset(
                'assets/images/img2.png',
                height: 275,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 50),

              const Text(
                'Transform any Android phone\ninto a smart baby monitor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 24,
                  color: Color(0xFF656565),
                ),
              ),

              const SizedBox(height: 70),

              SizedBox(
                width: 341,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RolePickerScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'LeagueSpartan',
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
