import 'package:flutter/material.dart';

class UnpairScreen extends StatelessWidget {
  const UnpairScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/images/coocue_logo2.png', height: 40),

              const SizedBox(height: 32),
              const Text(
                'Unpair Device',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to\nunpair this device?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3F51B5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF3F51B5),
                    fontSize: 18,
                    fontFamily: 'LeagueSpartan',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // TODO: handle unpair
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Unpair', style: TextStyle(fontSize: 18)),
              ),
              const Spacer(),
              Image.asset('assets/images/img2.png', height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
