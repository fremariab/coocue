import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Replace this with your actual home screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double progressValue = 0.0;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 10), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });

    // Animate the progress line smoothly
    Future.delayed(Duration.zero, () {
      setState(() {
        progressValue = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC), // BG color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/coocue_logo.png',
              height: 250,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 40),

            // Animated Progress Bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progressValue),
              duration: const Duration(seconds: 4),
              builder:
                  (context, value, _) => SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: value,
                      color: const Color(0xFF3F51B5), // blue
                      backgroundColor: const Color(0xFFE0E0E0), // light gray
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
