import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const CoocueApp());
}

class CoocueApp extends StatelessWidget {
  const CoocueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
