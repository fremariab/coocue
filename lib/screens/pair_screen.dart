import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:coocue/screens/parent_home_screen.dart';

class PairScreen extends StatefulWidget {
  const PairScreen({super.key});
  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  String codeInput = '';
  String errorText = '';
  final _storage = FlutterSecureStorage();

  final functions = FirebaseFunctions.instance;

  void _onDigit(String d) => setState(() => codeInput += d);
  void _onBackspace() => setState(() {
    if (codeInput.isNotEmpty)
      codeInput = codeInput.substring(0, codeInput.length - 1);
  });

  Future<void> _pair() async {
    if (codeInput.length != 6) {
      setState(() => errorText = 'Enter a valid 6-digit code');
      return;
    }
    final pairId = codeInput;
    debugPrint('▶️ [PairScreen] calling sendPairing with pairId="$pairId"');

    try {
      await FirebaseMessaging.instance.subscribeToTopic('pair_$pairId');
      await _storage.write(key: 'pair_id', value: pairId);

      final callable = functions.httpsCallable(
        'sendPairing',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
      );
      final result = await callable.call(<String, dynamic>{'pairId': pairId});
      debugPrint('✅ [PairScreen] sendPairing result: ${result.data}');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentHomeScreen()),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ [PairScreen] function error: ${e.code} ${e.message}');
      setState(() => errorText = 'Pairing failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ [PairScreen] unexpected error: $e');
      setState(() => errorText = 'Unexpected error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/images/coocue_logo2.png', height: 40),
            const SizedBox(height: 30),
            const Text(
              'Enter Pairing Code',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'LeagueSpartan',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              codeInput.padRight(6, '•'),
              style: const TextStyle(fontSize: 40, letterSpacing: 12),
            ),
            if (errorText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(errorText, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                padding: const EdgeInsets.all(24),
                children: [
                  for (var i = 1; i <= 9; i++)
                    ElevatedButton(
                      onPressed: () => _onDigit('$i'),
                      child: Text('$i', style: const TextStyle(fontSize: 24)),
                    ),
                  ElevatedButton(
                    onPressed: _pair,
                    child: const Icon(Icons.check, size: 24),
                  ),
                  ElevatedButton(
                    onPressed: () => _onDigit('0'),
                    child: const Text('0', style: TextStyle(fontSize: 24)),
                  ),
                  ElevatedButton(
                    onPressed: _onBackspace,
                    child: const Icon(Icons.backspace, size: 24),
                  ),
                ],
              ),
            ),
            ElevatedButton(onPressed: _pair, child: const Icon(Icons.check)),
            if (errorText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  errorText,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
