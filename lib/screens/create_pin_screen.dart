import 'package:flutter/material.dart';
import 'package:coocue/screens/confirm_pin_screen.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String pin = ''; // this is where i'm storing the pin user is typing

  void _addDigit(String digit) {
    // adding digit to pin only if it's less than 4
    if (pin.length < 4) {
      setState(() => pin += digit);

      // if 4 digits entered, wait a bit then move to confirm screen
      if (pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConfirmPinScreen(initialPin: pin),
            ),
          );
        });
      }
    }
  }

  void _removeDigit() {
    // removes last digit from pin if there’s anything typed
    if (pin.isNotEmpty) {
      setState(() => pin = pin.substring(0, pin.length - 1));
    }
  }

  void _submitPin() {
    // just in case user hits check button directly
    if (pin.length == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConfirmPinScreen(initialPin: pin)),
      );
    }
  }

  Widget _buildDot(bool filled) {
    // this draws one dot (filled or empty) for the pin
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
    // creates a button (number or icon) for the keypad
    return SizedBox(
      width: 20,
      height: 20,
      child: ElevatedButton(
        onPressed: onPressed ?? () => _addDigit(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFFFF),
          foregroundColor: Color(0xff94ACFF),
          shape: const CircleBorder(),
          elevation: 0,
        ),
        child: icon == null
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // showing logo at top
              Image.asset('assets/images/coocue_logo2.png', height: 40),

              const SizedBox(height: 30),

              // heading text
              const Text(
                'Create PIN',
                style: TextStyle(
                  fontSize: 40,
                  fontFamily: 'LeagueSpartan',
                  height: 0.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3F51B5),
                ),
              ),

              const SizedBox(height: 20),

              // subtitle telling user to set 4-digit pin
              const Text(
                'Set a 4-digit PIN to protect the app',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff656565),
                  fontFamily: 'LeagueSpartan',
                  height: 0.5,
                ),
              ),

              const SizedBox(height: 32),

              // lock icon for visual hint
              const Icon(Icons.lock, size: 38, color: Color(0xFF3F51B5)),

              const SizedBox(height: 20),

              // showing pin dots here
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => _buildDot(index < pin.length),
                ),
              ),

              const SizedBox(height: 40),

              // number pad grid with numbers and icons
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  padding: const EdgeInsets.only(top: 15),
                  children: [
                    ...List.generate(9, (i) {
                      final number = '${i + 1}';
                      return _buildButton(number); // buttons from 1 to 9
                    }),
                    _buildButton('', icon: Icons.check, onPressed: _submitPin), // check icon
                    _buildButton('0'), // 0 button
                    _buildButton('', icon: Icons.backspace, onPressed: _removeDigit), // backspace icon
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
