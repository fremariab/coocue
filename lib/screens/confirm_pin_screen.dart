import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:coocue/src/security.dart';
import 'package:coocue/screens/setup_security_question_screen.dart';
import 'package:coocue/screens/parent_dashboard_screen.dart';

class ConfirmPinScreen extends StatefulWidget {
  final String initialPin;

  const ConfirmPinScreen({super.key, required this.initialPin});
  // This is a screen widget class that defines a UI page.

  @override
  State<ConfirmPinScreen> createState() => _ConfirmPinScreenState();
  // This class creates the state object for the screen.
}

class _ConfirmPinScreenState extends State<ConfirmPinScreen> {
  String confirmPin = '';
  String errorText = '';
  final storage = FlutterSecureStorage();

  Future<void> _addDigit(String digit) async {
    // Adds a digit to the current PIN input.
    if (confirmPin.length < 4) {
      setState(() {
        confirmPin += digit;
        errorText = '';
      });
    } else {
      if (confirmPin.length == 4) {
        if (confirmPin == widget.initialPin) {
          // generate & store salt + hash instead of raw PIN
          final salt = Security.generateSalt();

          final hash = await Security.hashPin(confirmPin, salt);

          await Security.storeSalt(salt);
          await Security.storePinHash(hash);

          // check if a security question already exists
          final existingQ = await storage.read(key: 'sec_question');
          if (existingQ != null) {
            // we have a Q&A already -> skip straight to dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
            );
          } else {
            // first time -> let them set up Q&A
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SetupSecurityQuestionScreen(),
              ),
            );
          }

          // Navigates to a new screen.
        } else {
          setState(() {
            errorText = 'PINs do not match';
            confirmPin = '';
          });
        }
      }
    }
  }

  void _removeDigit() {
    // Removes the last digit from the current PIN input.
    if (confirmPin.isNotEmpty) {
      setState(
        () => confirmPin = confirmPin.substring(0, confirmPin.length - 1),
      );
    }
  }

  Widget _buildDot(bool filled) {
    // Builds one of the dots that show PIN entry progress.
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
    // Builds one button in the number pad (or action icons).
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
  Widget build(BuildContext context) {
    // This method describes the part of the UI to display.
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/images/coocue_logo2.png', height: 40),

              // This shows an image from the asset folder.
              const SizedBox(height: 30),
              const Text(
                'Confirm PIN',
                style: TextStyle(
                  fontSize: 40,
                  fontFamily: 'LeagueSpartan',
                  height: 0.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3F51B5),
                ),
              ),

              // This is a text label shown to the user.
              const SizedBox(height: 20),
              const Text(
                'Re-enter the 4-digit PIN to confirm',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff656565),
                  fontFamily: 'LeagueSpartan',
                  height: 0.5,
                ),
              ),

              if (errorText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  errorText,
                  style: const TextStyle(
                    color: Color(0xffB53F3F),
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 32),
              const Icon(Icons.lock, size: 32, color: Color(0xFF3F51B5)),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => _buildDot(index < confirmPin.length),
                ),
              ),

              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  padding: const EdgeInsets.only(top: 15),
                  children: [
                    ...List.generate(9, (i) {
                      final number = '${i + 1}';
                      return _buildButton(number);
                    }),
                    _buildButton(
                      '',
                      icon: Icons.check,
                      onPressed: () async {
                        if (confirmPin.length == 4) {
                          if (confirmPin == widget.initialPin) {
                            // generate & store salt + hash instead of raw PIN
                            final salt = Security.generateSalt();

                            final hash = await Security.hashPin(
                              confirmPin,
                              salt,
                            );

                            await Security.storeSalt(salt);
                            await Security.storePinHash(hash);

                            // check if a security question already exists
                            final existingQ = await storage.read(
                              key: 'sec_question',
                            );
                            if (existingQ != null) {
                              // we have a Q&A already -> skip straight to dashboard
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ParentDashboardScreen(),
                                ),
                              );
                            } else {
                              // first time -> let them set up Q&A
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const SetupSecurityQuestionScreen(),
                                ),
                              );
                            }

                            // Navigates to a new screen.
                          } else {
                            setState(() {
                              errorText = 'PINs do not match';
                              confirmPin = '';
                            });
                          }
                        }
                      },
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
            ],
          ),
        ),
      ),
    );
  }
}
