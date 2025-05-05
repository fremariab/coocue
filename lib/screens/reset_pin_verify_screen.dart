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
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final q = await _storage.read(key: 'sec_question');
    setState(() => _question = q);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _verifySecurityAnswer() async {
    // 1. Read the stored (normalized) answer
    final stored = await _storage.read(key: 'sec_answer');
    final input = _answerController.text.trim().toLowerCase();

    if (stored != null && input == stored) {
      // 2. Clear the PIN salt & hash
      await _storage.delete(key: 'pin_salt');
      await _storage.delete(key: 'pin_hash');

      // 3. Go back to Create PIN
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreatePinScreen()),
      );
    } else {
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
                Text(
                  errorText,
                  style: const TextStyle(
                    color: Color(0xFFB53F3F),
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 50),
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
              Image.asset('assets/images/img4.png', height: 200),
            ],
          ),
        ),
      ),
    );
  }
}
