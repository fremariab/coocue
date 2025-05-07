import 'dart:async';
import 'package:coocue/screens/cot_home_screen.dart';
import 'package:coocue/screens/enter_pin_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';

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
    // start a timer for splash duration
    Timer(const Duration(seconds: 3), () async {
      // load saved role from preferences
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');

      // choose next screen based on role
      if (role == 'parent') {
        // go to pin entry for parent
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EnterPinScreen()),
        );
      } else if (role == 'cot') {
        // go to cot home if paired as cot
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CotHomeScreen()),
        );
      } else {
        // default to welcome screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });

    // animate progress bar to full right away
    Future.delayed(Duration.zero, () {
      setState(() {
        progressValue = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // background color for splash
      backgroundColor: const Color(0xFFF4F6FC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // show app logo
            Image.asset(
              'assets/images/coocue_logo.png',
              height: 250,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 40),

            // progress indicator with tween animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progressValue),
              duration: const Duration(seconds: 4),
              builder: (context, value, _) => SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  value: value,
                  color: const Color(0xFF3F51B5),
                  backgroundColor: const Color(0xFFE0E0E0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
