import 'package:coocue/screens/parent_dashboard_screen.dart';
import 'package:coocue/screens/reset_pin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:coocue/src/security.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coocue/screens/create_pin_screen.dart';

class EnterPinScreen extends StatefulWidget {
  const EnterPinScreen({super.key});

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  final storage = FlutterSecureStorage();
  String pin = '';
  String errorText = '';
  int attempts = 0;
  bool isLocked = false;
  int lockSeconds = 30;
  Timer? lockTimer;

  void _addDigit(String digit) {
    if (isLocked || pin.length >= 4) return;

    setState(() => pin += digit);
    if (pin.length == 4) _verifyPin();
  }

  void _verifyPin() async {
    // 1. Read salt & stored hash
    final salt = await Security.readSalt();
    final storedHash = await Security.readPinHash();

    // 2. If no salt/hash found, force user to (re)create PIN
    if (salt == null || storedHash == null) {
      // nothing to verify against
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreatePinScreen()),
      );
      return;
    }

    // 3. Compute the hash of the entered PIN
    final inputHash = await Security.hashPin(pin, salt);


    // 4. Compare
    if (inputHash == storedHash) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('last_unlock', DateTime.now().millisecondsSinceEpoch);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
      );
    } else {
      setState(() {
        attempts++;
        errorText = 'Incorrect PIN';
        pin = '';
      });
      if (attempts >= 3) _startLockTimer();
    }
  }

  void _startLockTimer() {
    setState(() => isLocked = true);
    lockTimer = Timer(Duration(seconds: lockSeconds), () {
      setState(() {
        isLocked = false;
        attempts = 0;
        errorText = '';
      });
    });
  }

  void _removeDigit() {
    if (pin.isNotEmpty) {
      setState(() => pin = pin.substring(0, pin.length - 1));
    }
  }

  Widget _buildDot(bool filled) {
    return Container(
      width: 15,
      height: 15,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF3F51B5) : Colors.transparent,
        border: Border.all(color: const Color(0xFF3F51B5)),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildButton(String label, {IconData? icon, VoidCallback? onPressed}) {
    return SizedBox(
      width: 20,
      height: 20,
      child: ElevatedButton(
        onPressed: onPressed ?? () => _addDigit(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFFFF),
          foregroundColor: const Color(0xff94ACFF),
          shape: const CircleBorder(),
          elevation: 0,
        ),
        child:
            icon == null
                ? Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF3F51B5),
                  ),
                )
                : Icon(icon, size: 20, color: const Color(0xFF3F51B5)),
      ),
    );
  }

  @override
  void dispose() {
    lockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/images/coocue_logo2.png', height: 40),

              const SizedBox(height: 30),
              const Text(
                'Enter PIN',
                style: TextStyle(
                  fontSize: 40,
                  fontFamily: 'LeagueSpartan',
                  height: 0.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3F51B5),
                ),
              ),

              const SizedBox(height: 20),
              const Icon(Icons.lock, size: 32, color: Color(0xFF3F51B5)),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => _buildDot(i < pin.length)),
              ),

              if (errorText.isNotEmpty || isLocked) ...[
                const SizedBox(height: 12),
                Text(
                  isLocked ? 'Try again in $lockSeconds seconds' : errorText,
                  style: const TextStyle(
                    color: Color(0xffB53F3F),
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  padding: const EdgeInsets.only(top: 15),
                  children: [
                    ...List.generate(9, (i) => _buildButton('${i + 1}')),
                    _buildButton(
                      '',
                      icon: Icons.check,
                      onPressed: () => _verifyPin(),
                    ),
                    _buildButton('0'),
                    _buildButton(
                      '',
                      icon: Icons.backspace,
                      onPressed: _removeDigit,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResetPinScreen()),
                  );
                },
                child: const Text(
                  'Forgot PIN?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3F51B5),
                    decoration: TextDecoration.underline,
                    fontFamily: 'LeagueSpartan',
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
