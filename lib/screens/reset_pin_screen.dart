import 'package:coocue/screens/reset_pin_verify_screen.dart';
import 'package:flutter/material.dart';

class ResetPinScreen extends StatelessWidget {
  const ResetPinScreen({super.key});

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
              const SizedBox(height: 30),
              const Text(
                'Reset PIN',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Forgot your PIN?\nTo reset, answer your security question.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF656565),
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResetPinVerifyScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'LeagueSpartan',
                      color: Color(0xFFffffff),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Image.asset('assets/images/img4.png', height: 300),
            ],
          ),
        ),
      ),
    );
  }
}
