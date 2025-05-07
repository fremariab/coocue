import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:coocue/screens/parent_home_screen.dart';

class PairScreen extends StatefulWidget {
  const PairScreen({super.key});

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _storage = FlutterSecureStorage();
  final functions = FirebaseFunctions.instance;

  String errorText = '';

  Future<void> _pair() async {
    final codeInput = _controller.text.trim();

    if (codeInput.length != 6) {
      setState(() => errorText = 'Enter a valid 6-digit code');
      return;
    }

    final pairId = codeInput;

    try {
      await FirebaseMessaging.instance.subscribeToTopic('pair_$pairId');
      await _storage.write(key: 'pair_id', value: pairId);

      final callable = functions.httpsCallable(
        'sendPairing',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
      );
      await callable.call(<String, dynamic>{'pairId': pairId});

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentHomeScreen()),
      );
    } on FirebaseFunctionsException catch (e) {
      setState(() => errorText = 'Pairing failed: ${e.message}');
    } catch (_) {
      setState(() => errorText = 'Unexpected error');
    }
  }

  Widget _buildBox(int index) {
    final text = _controller.text;
    final char = index < text.length ? text[index] : '';
    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCACEDA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        char,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Image.asset('assets/images/coocue_logo2.png', height: 40),
                  const SizedBox(height: 20),
                  const Text(
                    'Pair with Cot Phone',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'LeagueSpartan',
                      color: Color(0xFF3F51B5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter the 6-digit code\nshowing on the cot phone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'LeagueSpartan',
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          letterSpacing: 32,
                          color: Colors.transparent,
                        ),
                        cursorColor: Colors.transparent,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        onChanged: (value) {
                          setState(() {});
                          if (value.length == 6) {
                            _pair();
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            List.generate(6, _buildBox)
                                .expand((w) => [w, const SizedBox(width: 8)])
                                .toList()
                              ..removeLast(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (errorText.isNotEmpty)
                    Text(
                      errorText,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: 160,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _pair,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Pair',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'LeagueSpartan',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Image.asset('assets/images/img2.png', height: 200),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
