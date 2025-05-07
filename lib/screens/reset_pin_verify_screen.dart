import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:coocue/screens/create_pin_screen.dart';

class ResetPinVerifyScreen extends StatefulWidget {
  const ResetPinVerifyScreen({super.key});

  @override
  State<ResetPinVerifyScreen> createState() => _ResetPinVerifyScreenState();
}

class _ResetPinVerifyScreenState extends State<ResetPinVerifyScreen> {
  final _storage = FlutterSecureStorage();
  final TextEditingController _answerController = TextEditingController();
  String errorText = '';
  String? _question;

  @override
  void initState() {
    super.initState();
    // loading the saved security question when screen opens
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final q = await _storage.read(key: 'sec_question');
    // storing the question in state so it shows on screen
    setState(() => _question = q);
  }

  @override
  void dispose() {
    // clearing up the controller when screen is closed
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _verifySecurityAnswer() async {
    // getting the saved answer from secure storage
    final stored = await _storage.read(key: 'sec_answer');
    final input = _answerController.text.trim().toLowerCase();

    if (stored != null && input == stored) {
      // if answer is correct, delete the old pin data
      await _storage.delete(key: 'pin_salt');
      await _storage.delete(key: 'pin_hash');

      // going to the CREATEPINSCREEN to set a new pin
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreatePinScreen()),
      );
    } else {
      // if wrong answer, show error text
      setState(() => errorText = 'Verification failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // showing the COOUE LOGO at the top
              Image.asset('assets/images/coocue_logo2.png', height: 40),
              const SizedBox(height: 30),
              // showing the RESET PIN title
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
              // showing the security question to answer
              Text(
                'To reset your PIN, please answer:\n\n${_question ?? ""}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF656565),
                ),
              ),
              const SizedBox(height: 60),
              // input field for typing the answer
              TextField(
                controller: _answerController,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'LeagueSpartan',
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Your Answer',
                  hintStyle: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 16,
                    color: Color(0xff656565),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                  ),
                ),
              ),
              if (errorText.isNotEmpty) ...[
                const SizedBox(height: 8),
                // showing error if answer is wrong
                Text(
                  errorText,
                  style: const TextStyle(
                    color: Color(0xFFB53F3F),
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 50),
              // button to verify the answer
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _verifySecurityAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Verify',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontFamily: 'LeagueSpartan',
                    ),
                  ),
                ),
              ),
              // added image at the bottom for decoration
              Image.asset('assets/images/img4.png', height: 200),
            ],
          ),
        ),
      ),
    );
  }
}
